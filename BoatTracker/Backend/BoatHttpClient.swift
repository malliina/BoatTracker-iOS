//
//  BoatHttpClient.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox
import RxSwift

class BoatHttpClient {
    private let log = LoggerFactory.shared.network(BoatHttpClient.self)
    
    static let BoatVersion = "application/vnd.boat.v2+json"
    
    let baseUrl: URL
    let client: HttpClient
    
    private var defaultHeaders: [String: String]
    private let postSpecificHeaders: [String: String]
    
    var postHeaders: [String: String] { return defaultHeaders.merging(postSpecificHeaders)  { (current, _) in current } }
    
    convenience init(bearerToken: AccessToken, baseUrl: URL, language: Language) {
        self.init(bearerToken: bearerToken, baseUrl: baseUrl, client: HttpClient())
    }
    
    init(bearerToken: AccessToken?, baseUrl: URL, client: HttpClient) {
        self.baseUrl = baseUrl
        self.client = client
        if let token = bearerToken {
            self.defaultHeaders = [
                Headers.authorization: BoatHttpClient.authValue(for: token),
                Headers.accept: BoatHttpClient.BoatVersion,
//                Headers.acceptLanguage: language.rawValue
            ]
        } else {
            self.defaultHeaders = [
                Headers.accept: BoatHttpClient.BoatVersion,
//                Headers.acceptLanguage: language.rawValue
            ]
        }
        self.postSpecificHeaders = [
            Headers.contentType: HttpClient.json
        ]
    }
    
    func updateToken(token: AccessToken?) {
        if let token = token {
            self.defaultHeaders.updateValue(BoatHttpClient.authValue(for: token), forKey: Headers.authorization)
        } else {
            self.defaultHeaders.removeValue(forKey: Headers.authorization)
        }
    }
    
    static func authValue(for token: AccessToken) -> String {
        return "bearer \(token.token)"
    }
    
    func pingAuth() -> Single<BackendInfo> {
        return getParsed(BackendInfo.self, "/pingAuth")
    }
    
    func profile() -> Single<UserProfile> {
        return getParsed(UserContainer.self, "/users/me").map { $0.user }
    }
    
    func tracks() -> Single<[TrackRef]> {
        return getParsed(TracksResponse.self, "/tracks").map { $0.tracks }
    }
    
    func stats() -> Single<StatsResponse> {
        return getParsed(StatsResponse.self, "/stats?order=desc")
    }
    
    func changeTrackTitle(name: TrackName, title: TrackTitle) -> Single<TrackResponse> {
        return parsed(TrackResponse.self, "/tracks/\(name)", run: { (url) in
            return self.client.putJSON(url, headers: self.postHeaders, payload: ChangeTrackTitle(title: title))
        })
    }
    
    func conf() -> Single<ClientConf> {
        return getParsed(ClientConf.self, "/conf")
    }
    
    func enableNotifications(token: PushToken) -> Single<SimpleMessage> {
        return parsed(SimpleMessage.self, "/users/notifications", run: { (url) -> Single<HttpResponse> in
            return self.client.postJSON(url, headers: self.postHeaders, payload: PushPayload(token))
        })
    }
    
    func disableNotifications(token: PushToken) -> Single<SimpleMessage> {
        return parsed(SimpleMessage.self, "/users/notifications/disable", run: { (url) -> Single<HttpResponse> in
            return self.client.postJSON(url, headers: self.postHeaders, payload: DisablePush(token: token))
        })
    }
    
    func renameBoat(boat: Int, newName: BoatName) -> Single<Boat> {
        return parsed(BoatResponse.self, "/boats/\(boat)", run: { (url) -> Single<HttpResponse> in
            self.client.patchJSON(url, headers: self.postHeaders, payload: ChangeBoatName(boatName: newName))
        }).map { $0.boat }
    }
    
    func changeLanguage(to: Language) -> Single<SimpleMessage> {
        return parsed(SimpleMessage.self, "/users/me", run: { (url) in
            return self.client.putJSON(url, headers: self.postHeaders, payload: ChangeLanguage(language: to))
        })
    }
    
    func shortestRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Single<RouteResult> {
        return getParsed(RouteResult.self, "/routes/\(from.latitude)/\(from.longitude)/\(to.latitude)/\(to.longitude)")
    }
    
    func getParsed<T: Decodable>(_ t: T.Type, _ uri: String) -> Single<T> {
        return parsed(t, uri, run: { (url) -> Single<HttpResponse> in
            self.client.get(url, headers: self.defaultHeaders)
        })
    }
    
    func parsed<T : Decodable>(_ t: T.Type, _ uri: String, run: @escaping (URL) -> Single<HttpResponse>, attempt: Int = 1) -> Single<T> {
        let url = fullUrl(to: uri)
        return run(url).flatMap { (response) -> Single<T> in
            if response.isStatusOK {
                return self.parseAs(t, response: response)
            } else {
                self.log.error("Request to '\(url)' failed with status '\(response.statusCode)'.")
                if attempt == 1 && response.isTokenExpired {
                    return RxGoogleAuth().signIn().flatMap { (token) -> Single<T> in
                        self.updateToken(token: token.token)
                        return self.parsed(t, uri, run: run, attempt: 2)
                    }
                } else {
                    let decoder = JSONDecoder()
                    let errors = (try? decoder.decode(Errors.self, from: response.data))?.errors ?? []
                    return Single.error(AppError.responseFailure(ResponseDetails(url: url, code: response.statusCode, errors: errors)))
                }
            }
        }
    }
    
    func fullUrl(to: String) -> URL {
        return URL(string: to, relativeTo: baseUrl)!
    }
    
    private func parseAs<T: Decodable>(_ t: T.Type, response: HttpResponse) -> Single<T> {
        do {
            let decoder = JSONDecoder()
//            if let str = String(data: response.data, encoding: .utf8) {
//                log.info("Response is: \(str)")
//            }
            return Single.just(try decoder.decode(t, from: response.data))
        } catch let error as JsonError {
            self.log.error(error.describe)
            return Single.error(AppError.parseError(error))
        } catch DecodingError.dataCorrupted(let ctx) {
            self.log.error("Corrupted: \(ctx)")
            return Single.error(AppError.simple("Unknown parse error."))
        } catch DecodingError.typeMismatch(let t, let context) {
            self.log.error("Type mismatch: \(t) ctx \(context)")
            return Single.error(AppError.simple("Unknown parse error."))
        } catch DecodingError.keyNotFound(let key, let context) {
            self.log.error("Key not found: \(key) ctx \(context)")
            return Single.error(AppError.simple("Unknown parse error."))
        } catch let error {
            self.log.error(error.localizedDescription)
            return Single.error(AppError.simple("Unknown parse error."))
        }
    }
}
