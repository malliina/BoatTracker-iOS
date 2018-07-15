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
    
    let client: HttpClient
    
    private var defaultHeaders: [String: String]
    
    convenience init(bearerToken: AccessToken) {
        self.init(bearerToken: bearerToken, client: HttpClient())
    }
    
    init(bearerToken: AccessToken, client: HttpClient) {
        self.client = client
        self.defaultHeaders = [
            HttpClient.AUTHORIZATION: BoatHttpClient.authValue(for: bearerToken),
            HttpClient.ACCEPT: BoatHttpClient.BoatVersion10
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
    
    func pingAuth() -> Observable<BackendInfo> {
        return getParsed("/pingAuth", parse: BackendInfo.parse)
    }
    
    func getParsed<T>(_ uri: String, parse: @escaping (JsObject) throws -> T) -> Observable<T> {
        let url = URL(string: uri, relativeTo: EnvConf.BaseUrl)!
        return client.get(url, headers: defaultHeaders).flatMap { (response) -> Observable<T> in
            return self.statusChecked(url, response: response).flatMap { (checkedResponse) -> Observable<T> in
                return self.parseAs(response: checkedResponse, parse: parse)
            }
        }
    }
    
    private func parseAs<T>(response: HttpResponse, parse: @escaping (JsObject) throws -> T) -> Observable<T> {
        do {
            let obj = try JsObject.parse(data: response.data)
            return Observable.just(try parse(obj))
        } catch let error as JsonError {
            self.log.error("Parse error.")
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

class BackendInfo {
    let name: String
    let version: String
    
    static func parse(obj: JsObject) throws -> BackendInfo {
        return BackendInfo(name: try obj.readString("name"), version: try obj.readString("version"))
    }
    
    init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

class TrackSummary {
    let track: TrackRef
    let stats: TrackStats
    
    static func parse(json: JsObject) throws -> TrackSummary {
        return TrackSummary(track: try json.readObj("track", parse: TrackRef.parse), stats: try json.readObj("stats", parse: TrackStats.parse))
    }
    
    init(track: TrackRef, stats: TrackStats) {
        self.track = track
        self.stats = stats
    }
}
