//
//  Keychain.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

open class Keychain {
    static let shared = Keychain()
    
    let server = EnvConf.shared.server
    
    let query: [String: Any]
    
    init() {
        query = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server
        ]
    }
    
    func use(token: AccessToken) throws {
        try delete()
        try save(token: token)
    }
    
    func save(token: AccessToken) throws {
        let encodedToken = token.token.data(using: String.Encoding.utf8)!
        var saveQuery = query
        saveQuery.updateValue(encodedToken, forKey: kSecValueData as String)
        let status = SecItemAdd(saveQuery as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }
    
    func update(token: AccessToken) throws {
        let encodedToken = token.token.data(using: String.Encoding.utf8)!
        let attributes: [String: Any] = [kSecValueData as String: encodedToken]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else { throw KeychainError.notFound }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }
    
    func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
    
    func findToken() throws -> AccessToken? {
        do {
            return try readToken()
        } catch KeychainError.notFound {
            return nil
        }
    }
    
    func readToken() throws -> AccessToken {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw KeychainError.notFound }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        guard let existingItem = item as? [String : Any],
            let tokenData = existingItem[kSecValueData as String] as? Data,
            let token = String(data: tokenData, encoding: String.Encoding.utf8)
            else { throw KeychainError.unexpectedTokenData }
        return AccessToken(token)
    }
}

enum KeychainError: Error {
    case unexpectedTokenData
    case notFound
    case unhandledError(status: OSStatus)
}
