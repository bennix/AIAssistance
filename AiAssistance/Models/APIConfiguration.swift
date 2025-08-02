//
//  APIConfiguration.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import Foundation
import Security

struct APIConfiguration {
    static let shared = APIConfiguration()
    
    // MARK: - Constants
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    private let keychainService = "com.aiassistance.apikey"
    private let keychainAccount = "glm-api-key"
    
    // MARK: - Properties
    var apiURL: URL? {
        URL(string: baseURL)
    }
    
    // MARK: - API Key Management
    func setAPIKey(_ key: String) {
        saveToKeychain(key: key)
    }
    
    func getAPIKey() -> String? {
        loadFromKeychain()
    }
    
    func hasValidAPIKey() -> Bool {
        guard let key = getAPIKey() else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Request Headers
    func authHeaders() -> [String: String] {
        guard let apiKey = getAPIKey() else {
            return [:]
        }
        
        return [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "Accept": "text/event-stream"
        ]
    }
    
    // MARK: - Private Keychain Methods
    private func saveToKeychain(key: String) {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
}