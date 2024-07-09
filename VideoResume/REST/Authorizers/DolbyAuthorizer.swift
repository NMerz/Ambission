//
//  DolbyAuthorizer.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/6/24.
//

import Foundation

struct DolbyTokenReturn: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct DolbyTokenRequest: Codable {
    let grantType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case expiresIn = "expires_in"
    }
}

class DolbyAuthorizer: Authorizer {
    static let tokenUrl = URL(string: "https://api.dolby.io/v1/auth/token")!
    
    var expireTime = Date.now
    var savedToken = ""
    
    func getNewToken() async throws -> String {
        if expireTime <= Date.now {
            let newToken = try await Poster.postFor(DolbyTokenReturn.self, requestURL: DolbyAuthorizer.tokenUrl, postContent: DolbyTokenRequest(grantType: "client_credentials", expiresIn: 1800), authorizer: BasicAuthorizer(user: "w7pNB78_9T8mBAB3LdL8iQ==", password: "6nw_oPYfp4X6CSULDYOmaafLIjyIFdCw38Erh-cqAFA=")).accessToken
            expireTime = Date.now
            expireTime.addTimeInterval(1700)
            savedToken = newToken
        }
        return savedToken
    }
    
    func authorizeRequest(toAuthorize: inout URLRequest) async throws {
        try await toAuthorize.setValue("Bearer " + getNewToken(), forHTTPHeaderField:  "Authorization")
    }
}
