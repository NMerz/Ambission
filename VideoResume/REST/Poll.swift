//
//  Poll.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/8/24.
//

import Foundation

class Poll {
    static func monitor<T: CanVerifyDone & Decodable>(_ toPoll: URL, responseType: T.Type, authorizer: Optional<Authorizer> = nil) async throws {
        let session = URLSession.init(configuration: URLSessionConfiguration.default)
        defer {session.finishTasksAndInvalidate()}
        while true {
            var request = URLRequest(url: toPoll)
            if authorizer != nil {
                try await authorizer?.authorizeRequest(toAuthorize: &request)
            }
            let (data, resp) = try await session.data(for: request)
            let returnObject = try JSONDecoder().decode(T.self, from: data)
            if returnObject.verifyDone() {
                return
            }
            try await Task.sleep(for: Duration.seconds(3))
        }
    }
}
