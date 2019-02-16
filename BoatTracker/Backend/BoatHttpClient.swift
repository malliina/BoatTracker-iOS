//
//  BoatHttpClient.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import RxSwift

class BoatHttpClient {
    private let log = LoggerFactory.shared.network(BoatHttpClient.self)
    
    static let BoatVersion = "application/vnd.boat.v2+json"
    
    let baseUrl: URL
    let client: HttpClient
    
    private var defaultHeaders: [String: String]
    private let postSpecificHeaders: [String: String]
    
    var postHeaders: [String: String] { return defaultHeaders.merging(postSpecificHeaders)  { (current, _) in current } }
    
    convenience init(bearerToken: AccessToken, baseUrl: URL) {
        self.init(bearerToken: bearerToken, baseUrl: baseUrl, client: HttpClient())
    }
    
    init(bearerToken: AccessToken?, baseUrl: URL, client: HttpClient) {
        self.baseUrl = baseUrl
        self.client = client
        if let token = bearerToken {
            self.defaultHeaders = [
                HttpClient.AUTHORIZATION: BoatHttpClient.authValue(for: token),
                HttpClient.ACCEPT: BoatHttpClient.BoatVersion
            ]
        } else {
            self.defaultHeaders = [
                HttpClient.ACCEPT: BoatHttpClient.BoatVersion
            ]
        }
        self.postSpecificHeaders = [
            HttpClient.CONTENT_TYPE: HttpClient.JSON
        ]
    }
    
    func updateToken(token: AccessToken?) {
        if let token = token {
            self.defaultHeaders.updateValue(BoatHttpClient.authValue(for: token), forKey: HttpClient.AUTHORIZATION)
        } else {
            self.defaultHeaders.removeValue(forKey: HttpClient.AUTHORIZATION)
        }
    }
    
    static func authValue(for token: AccessToken) -> String {
        return "bearer \(token.token)"
    }
    
    func pingAuth() -> Single<BackendInfo> {
        return getParsed2(BackendInfo.self, "/pingAuth")
    }
    
    func profile() -> Single<UserProfile> {
        return getParsed2(UserContainer.self, "/users/me").map { $0.user }
    }
    
    func tracks() -> Single<[TrackRef]> {
        return getParsed2(TracksResponse.self, "/tracks").map { $0.tracks }
    }
    
    func conf() -> Single<ClientConf> {
        return getParsed2(ClientConf.self, "/conf")
    }
    
    func enableNotifications(token: PushToken) -> Single<SimpleMessage> {
        return parsed2(SimpleMessage.self, "/users/notifications", run: { (url) -> Single<HttpResponse> in
            return self.client.postJSON(url, headers: self.postHeaders, payload: ["token": token.token as AnyObject, "device": "ios" as AnyObject])
        })
    }
    
    func disableNotifications(token: PushToken) -> Single<SimpleMessage> {
        return parsed2(SimpleMessage.self, "/users/notifications/disable", run: { (url) -> Single<HttpResponse> in
            return self.client.postJSON(url, headers: self.postHeaders, payload: ["token": token.token as AnyObject])
        })
    }
    
    func renameBoat(boat: Int, newName: BoatName) -> Single<Boat> {
        return parsed2(BoatResponse.self, "/boats/\(boat)", run: { (url) -> Single<HttpResponse> in
            self.client.patchJSON(url, headers: self.postHeaders, payload: ["boatName": newName.name as AnyObject])
        }).map { $0.boat }
    }
    
//    func getParsed<T>(_ uri: String, parse: @escaping (JsObject) throws -> T) -> Single<T> {
//        return parsed(uri, run: { (url) -> Single<HttpResponse> in
//            self.client.get(url, headers: self.defaultHeaders)
//        }, parse: parse)
//    }
    
    func getParsed2<T: Decodable>(_ t: T.Type, _ uri: String) -> Single<T> {
        return parsed2(t, uri, run: { (url) -> Single<HttpResponse> in
            self.client.get(url, headers: self.defaultHeaders)
        })
    }
    
//    func parsed<T>(_ uri: String, run: @escaping (URL) -> Single<HttpResponse>, parse: @escaping (JsObject) throws -> T, attempt: Int = 1) -> Single<T> {
//        let url = fullUrl(to: uri)
//        return run(url).flatMap { (response) -> Single<T> in
//            if (response.isStatusOK) {
//                return self.parseAs(response: response, parse: parse)
//            } else {
//                self.log.error("Request to '\(url)' failed with status '\(response.statusCode)'.")
//                if attempt == 1 && response.isTokenExpired {
//                    return RxGoogleAuth().signIn().flatMap { (token) -> Single<T> in
//                        self.updateToken(token: token.token)
//                        return self.parsed(uri, run: run, parse: parse, attempt: 2)
//                    }
//                } else {
//                    var errorMessage: String? = nil
//                    if let json = Json.asJson(response.data) as? NSDictionary {
//                        errorMessage = json[JsonError.Key] as? String
//                    }
//                    return Single.error(AppError.responseFailure(ResponseDetails(url: url, code: response.statusCode, message: errorMessage)))
//                }
//            }
//        }
//    }
    
    func parsed2<T : Decodable>(_ t: T.Type, _ uri: String, run: @escaping (URL) -> Single<HttpResponse>, attempt: Int = 1) -> Single<T> {
        let url = fullUrl(to: uri)
        return run(url).flatMap { (response) -> Single<T> in
            if response.isStatusOK {
                return self.parseAs2(t, response: response)
            } else {
                self.log.error("Request to '\(url)' failed with status '\(response.statusCode)'.")
                if attempt == 1 && response.isTokenExpired {
                    return RxGoogleAuth().signIn().flatMap { (token) -> Single<T> in
                        self.updateToken(token: token.token)
                        return self.parsed2(t, uri, run: run, attempt: 2)
                    }
                } else {
                    var errorMessage: String? = nil
                    if let json = Json.asJson(response.data) as? NSDictionary {
                        errorMessage = json[JsonError.Key] as? String
                    }
                    return Single.error(AppError.responseFailure(ResponseDetails(url: url, code: response.statusCode, message: errorMessage)))
                }
            }
        }
    }
    
    func fullUrl(to: String) -> URL {
        return URL(string: to, relativeTo: baseUrl)!
    }
    
//    private func parseAs<T>(response: HttpResponse, parse: @escaping (JsObject) throws -> T) -> Single<T> {
//        do {
//            let obj = try JsObject.parse(data: response.data)
////            print(obj.stringify())
//            return Single.just(try parse(obj))
//        } catch let error as JsonError {
//            self.log.error(error.describe)
//            return Single.error(AppError.parseError(error))
//        } catch _ {
//            return Single.error(AppError.simple("Unknown parse error."))
//        }
//    }
    
    private func parseAs2<T: Decodable>(_ t: T.Type, response: HttpResponse) -> Single<T> {
        do {
            let decoder = JSONDecoder()
//            content = try JsObject.parse(data: response.data).stringify()
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
