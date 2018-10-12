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
    
    static let BoatVersion10 = "application/vnd.boat.v1+json"
    
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
                HttpClient.ACCEPT: BoatHttpClient.BoatVersion10
            ]
        } else {
            self.defaultHeaders = [
                HttpClient.ACCEPT: BoatHttpClient.BoatVersion10
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
        return getParsed("/pingAuth", parse: BackendInfo.parse)
    }
    
    func profile() -> Single<UserProfile> {
        return getParsed("/users/me", parse: UserProfile.parse)
    }
    
    func tracks() -> Single<[TrackSummary]> {
        return getParsed("/tracks", parse: { (json) -> [TrackSummary] in
            try json.readObjectArray("tracks", each: TrackSummary.parse)
        })
    }
    
    func enableNotifications(token: PushToken) -> Single<SimpleMessage> {
        return parsed("/users/notifications", run: { (url) -> Observable<HttpResponse> in
            return client.postJSON(url, headers: postHeaders, payload: ["token": token.token as AnyObject, "device": "iOS" as AnyObject])
        }, parse: { (obj) -> SimpleMessage in
            return try SimpleMessage.parse(obj: obj)
        })
    }
    
    func disableNotifications(token: PushToken) -> Single<SimpleMessage> {
        return parsed("/users/notifications/disable", run: { (url) -> Observable<HttpResponse> in
            return client.postJSON(url, headers: postHeaders, payload: ["token": token.token as AnyObject])
        }, parse: { (obj) -> SimpleMessage in
            return try SimpleMessage.parse(obj: obj)
        })
    }
    
    func renameBoat(boat: Int, newName: BoatName) -> Single<Boat> {
        return parsed("/boats/\(boat)", run: { (url) -> Observable<HttpResponse> in
            client.patchJSON(url, headers: postHeaders, payload: ["boatName": newName.name as AnyObject])
        }) { (obj) -> Boat in
            try obj.readObj("boat", parse: Boat.parse)
        }
    }
    
    func getParsed<T>(_ uri: String, parse: @escaping (JsObject) throws -> T) -> Single<T> {
        return parsed(uri, run: { (url) -> Observable<HttpResponse> in
            client.get(url, headers: defaultHeaders)
        }, parse: parse)
    }
    
    func parsed<T>(_ uri: String, run: (URL) -> Observable<HttpResponse>, parse: @escaping (JsObject) throws -> T) -> Single<T> {
        let url = fullUrl(to: uri)
        return run(url).flatMap { (response) -> Observable<T> in
            return self.statusChecked(url, response: response).flatMap { (checkedResponse) -> Observable<T> in
                return self.parseAs(response: checkedResponse, parse: parse)
            }
        }.asSingle()
    }
    
    func fullUrl(to: String) -> URL {
        return URL(string: to, relativeTo: baseUrl)!
    }
    
    private func parseAs<T>(response: HttpResponse, parse: @escaping (JsObject) throws -> T) -> Observable<T> {
        do {
            let obj = try JsObject.parse(data: response.data)
//            print(obj.stringify())
            return Observable.just(try parse(obj))
        } catch let error as JsonError {
            self.log.error(error.describe)
            return Observable.error(AppError.parseError(error))
        } catch _ {
            return Observable.error(AppError.simple("Unknown parse error."))
        }
    }
    
    func statusChecked(_ url: URL, response: HttpResponse) -> Observable<HttpResponse> {
        if response.isStatusOK {
            return Observable.just(response)
        } else {
            self.log.error("Request to '\(url)' failed with status '\(response.statusCode)'.")
            var errorMessage: String? = nil
            if let json = Json.asJson(response.data) as? NSDictionary {
                errorMessage = json[JsonError.Key] as? String
            }
            return Observable.error(AppError.responseFailure(ResponseDetails(url: url, code: response.statusCode, message: errorMessage)))
        }
    }
}
