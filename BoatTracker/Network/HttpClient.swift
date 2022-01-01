//
//  HttpClient.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct Headers {
    static let accept = "Accept", acceptLanguage = "Accept-Language", authorization = "Authorization", contentType = "Content-Type"
}

class HttpClient {
    private let log = LoggerFactory.shared.network(HttpClient.self)
    static let json = "application/json", delete = "DELETE", get = "GET", patch = "PATCH", post = "POST", put = "PUT", basic = "Basic"
    
    static func basicAuthValue(_ username: String, password: String) -> String {
        let encodable = "\(username):\(password)"
        let encoded = encodeBase64(encodable)
        return "\(HttpClient.basic) \(encoded)"
    }
    
    static func authHeader(_ word: String, unencoded: String) -> String {
        let encoded = HttpClient.encodeBase64(unencoded)
        return "\(word) \(encoded)"
    }
    
    static func encodeBase64(_ unencoded: String) -> String {
        return unencoded.data(using: String.Encoding.utf8)!.base64EncodedString(options: NSData.Base64EncodingOptions())
    }
    
    let session: URLSession
    
    init() {
        self.session = URLSession.shared
    }
    
    func get(_ url: URL, headers: [String: String] = [:]) -> Single<HttpResponse> {
        let req = buildRequest(url: url, httpMethod: HttpClient.get, headers: headers)
        return executeHttp(req)
    }
    
    func patchJSON<T: Encodable>(_ url: URL, headers: [String: String] = [:], payload: T) -> Single<HttpResponse> {
        return sendData(url, headers: headers, payload: payload, httpMethod: HttpClient.patch)
    }
    
    func postJSON<T: Encodable>(_ url: URL, headers: [String: String] = [:], payload: T) -> Single<HttpResponse> {
        return sendData(url, headers: headers, payload: payload, httpMethod: HttpClient.post)
    }
    
    func postEmpty(_ url: URL, headers: [String: String] = [:]) -> Single<HttpResponse> {
        let req = buildRequest(url: url, httpMethod: HttpClient.post, headers: headers)
        return executeHttp(req)
    }
    
    func putJSON<T: Encodable>(_ url: URL, headers: [String: String] = [:], payload: T) -> Single<HttpResponse> {
        return sendData(url, headers: headers, payload: payload, httpMethod: HttpClient.put)
    }
    
    func sendData<T: Encodable>(_ url: URL, headers: [String: String] = [:], payload: T?, httpMethod: String) -> Single<HttpResponse> {
        let req = buildRequestWithBody(url: url, httpMethod: httpMethod, headers: headers, body: payload)
        return executeHttp(req)
    }
    
    func delete(_ url: URL, headers: [String: String] = [:]) -> Single<HttpResponse> {
        let req = buildRequest(url: url, httpMethod: HttpClient.delete, headers: headers)
        return executeHttp(req)
    }
    
    func executeHttp(_ req: URLRequest, retryCount: Int = 0) -> Single<HttpResponse> {
        return session.rx.response(request: req).asSingle().flatMap { (result) -> Single<HttpResponse> in
            let (response, data) = result
            return Single.just(HttpResponse(http: response, data: data))
        }
    }
    
    func buildRequestWithBody<T: Encodable>(url: URL, httpMethod: String, headers: [String: String], body: T?) -> URLRequest {
        var req = buildRequest(url: url, httpMethod: httpMethod, headers: headers)
        if let body = body {
            let encoder = JSONEncoder()
            req.httpBody = try? encoder.encode(body)
        }
        return req
    }
    
    func buildRequest(url: URL, httpMethod: String, headers: [String: String]) -> URLRequest {
        var req = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 3600)
        let useCsrfHeader = httpMethod != HttpClient.get
        if useCsrfHeader {
            req.addCsrf()
        }
        req.httpMethod = httpMethod
        for (key, value) in headers {
            req.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }
    
    func executeRequest(_ req: URLRequest, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        let task = session.dataTask(with: req, completionHandler: completionHandler)
        task.resume()
    }
}

extension URLRequest {
    mutating func addCsrf() {
        self.addValue("nocheck", forHTTPHeaderField: "Csrf-Token")
    }
}
