//
//  Authorizer.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/6/24.
//

import Foundation


protocol Authorizer {
    func authorizeRequest(toAuthorize: inout URLRequest) async throws
}

