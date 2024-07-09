//
//  BasicAuthorizer.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/6/24.
//

import Foundation


class BasicAuthorizer: Authorizer {
    let user: String
    let password: String
    
    init(user: String, password: String) {
        self.user = user
        self.password = password
    }
    
    func authorizeRequest(toAuthorize: inout URLRequest) async throws {
        let rawAuthString = user + ":" + password
        toAuthorize.setValue("Basic " + (rawAuthString.data(using: .utf8)?.base64EncodedString() ?? ""), forHTTPHeaderField: "Authorization")
    }
}
