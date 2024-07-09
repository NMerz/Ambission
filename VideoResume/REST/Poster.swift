//
//  Poster.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/6/24.
//

import Foundation



class Poster {
    private static func makeRequest(rawRequest: URLRequest, postContent: Optional<Encodable>) throws -> URLRequest {
        var request = rawRequest
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if postContent != nil {
            request.httpBody = try JSONEncoder().encode(postContent!)
            print(String(data: request.httpBody!, encoding: .utf8)!)
        }
        return request
    }
    
    static func postFor<T: Decodable>(_ _: T.Type, requestURL: URL, postContent: Optional<Encodable> = nil, authorizer: Optional<Authorizer> = nil) async throws -> T {
        var request = URLRequest(url: requestURL)
        if authorizer != nil {
            try await authorizer!.authorizeRequest(toAuthorize: &request)
        }
        return try await postFor(T.self, request: request, postContent: postContent)
    }
    
    static func postFor<T: Decodable>(_ _: T.Type, request: URLRequest, postContent: Optional<Encodable> = nil) async throws -> T {
        let session = URLSession.init(configuration: URLSessionConfiguration.default)
        defer {session.finishTasksAndInvalidate()}
        print(request)
        let (data, resp) = try await session.data(for: try makeRequest(rawRequest: request, postContent: postContent))
        print(resp)
        print(String(data: data, encoding: .utf8) ?? "")
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    static func putFile(_ toPut: URL, destination: URL) async throws {
        let session = URLSession.init(configuration: URLSessionConfiguration.default)
        defer {session.finishTasksAndInvalidate()}
        var request = URLRequest(url: destination)
        request.httpMethod = "PUT"
        let (data, resp) = try await session.upload(for: request, fromFile: toPut)
        print(resp)
        print(String(data: data, encoding: .utf8) ?? "")
    }
    
    static func downloadFile(_ fromUrl: String, params: [String: String], authorizer: Optional<Authorizer> = nil) async throws -> URL {
        let session = URLSession.init(configuration: URLSessionConfiguration.default)
        defer {session.finishTasksAndInvalidate()}
        var paramUrl = fromUrl + "?"
        for (param, value) in params {
            paramUrl += param + "=" + value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! + "&"
        }
        var request = URLRequest(url: URL(string: paramUrl)!)
        if authorizer != nil {
            try await authorizer?.authorizeRequest(toAuthorize: &request)
        }
        let (localUrl, response) = try await session.download(for: request)
        print(response)
        print(localUrl)
        return localUrl
    }
}
