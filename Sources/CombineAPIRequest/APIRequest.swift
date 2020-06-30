//
//  APIRequest.swift
//  APITest
//
//  Created by Mathew Polzin on 6/29/20.
//  Copyright © 2020 Mathew Polzin. All rights reserved.
//

import Foundation
import Combine

public enum HttpVerb: String, Equatable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public enum HttpContentType: String, Equatable {
    case plaintext = "text/plain"
    case json = "application/json"
}

public struct APIRequest<Request, Response: Decodable> {
    public let method: HttpVerb
    public let contentType: HttpContentType
    public let url: URL
    public let bodyData: Data?

    public var publisher: AnyPublisher<Response, Error> {
        return publisher(using: JSONDecoder())
    }

    public func publisher<Decoder: TopLevelDecoder>(using decoder: Decoder) -> AnyPublisher<Response, Error> where Decoder.Input == Data {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = bodyData
        request.addValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")

        let dataPublisher = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) -> Data in
                guard let status = (response as? HTTPURLResponse)?.statusCode else {
                    print("something went really wrong with request to \(request.url?.absoluteString ?? "unknown url"). no status code. response body: \(String(data: data, encoding: .utf8) ?? "Not UTF8 encoded")")
                    throw RequestFailure.unknown("something went really wrong with request to \(request.url?.absoluteString ?? "unknown url"). no status code. response body: \(String(data: data, encoding: .utf8) ?? "Not UTF8 encoded")")
                }

                guard status >= 200 && status < 300 else {
                    print("request to \(request.url?.absoluteString ?? "unknown url") failed with status code: \(status)")
                    print("response body: \(String(data: data, encoding: .utf8) ?? "Not UTF8 encoded")")
                    throw URLError(.init(rawValue: status))
                }

                return data
        }

        switch contentType {
        case .json:
            return dataPublisher
                .decode(type: Response.self, decoder: decoder)
                .eraseToAnyPublisher()
        case .plaintext:
            return dataPublisher
                .tryMap { data -> Response in
                    guard let string = String(data: data, encoding: .utf8) else {
                        throw RequestFailure.responseError("Could not decode a UTF8 string from the response data")
                    }
                    guard let response = string as? Response else {
                        throw RequestFailure.responseError("\(self.contentType) could not be cast from String to \(String(describing: Response.self))")
                    }
                    return response
            }
            .eraseToAnyPublisher()
        }
    }
}

extension APIRequest where Request == Void {
    public init(
        _ method: HttpVerb,
        contentType: HttpContentType = .json,
        host: URL,
        path: String,
        including includes: [String] = [],
        responseType: Response.Type
    ) throws {
        try self.init(
            method,
            contentType: contentType,
            host: host,
            path: path,
            including: includes
        )
    }

    public init(
        _ method: HttpVerb,
        contentType: HttpContentType = .json,
        host: URL,
        path: String,
        including includes: [String] = []
    ) throws {
        self.method = method
        self.contentType = contentType
        self.bodyData = nil

        var urlComponents = URLComponents(url: host, resolvingAgainstBaseURL: false)!

        urlComponents.path = path
        if includes.count > 0 {
            urlComponents.queryItems = [.init(name: "include", value: includes.joined(separator: ","))]
        }

        guard let url = urlComponents.url else {
            throw RequestFailure.urlConstruction(String(describing: urlComponents))
        }
        self.url = url
    }
}

extension APIRequest where Request: Encodable {
    public init(
        _ method: HttpVerb,
        contentType: HttpContentType = .json,
        host: URL,
        path: String,
        body: Request,
        including includes: [String] = [],
        encode: (Request) throws -> Data = { try JSONEncoder().encode($0) }
    ) throws {
        try self.init(
            method,
            contentType: contentType,
            host: host,
            path: path,
            body: body,
            including: includes,
            encode: encode
        )
    }

    public init(
        _ method: HttpVerb,
        contentType: HttpContentType = .json,
        host: URL,
        path: String,
        body: Request,
        including includes: [String] = [],
        responseType: Response.Type,
        encode: (Request) throws -> Data = { try JSONEncoder().encode($0) }
    ) throws {
        self.method = method
        self.contentType = contentType
        self.bodyData = try encode(body)

        var urlComponents = URLComponents(url: host, resolvingAgainstBaseURL: false)!

        urlComponents.path = path
        if includes.count > 0 {
            urlComponents.queryItems = [.init(name: "include", value: includes.joined(separator: ","))]
        }

        guard let url = urlComponents.url else {
            throw RequestFailure.urlConstruction(String(describing: urlComponents))
        }
        self.url = url
    }

    public static func transformation<Other>(
        _ method: HttpVerb,
        contentType: HttpContentType = .json,
        host: URL,
        path: String,
        including includes: [String] = [],
        requestBodyConstructor: @escaping (Other) throws -> Request,
        responseType: Response.Type,
        encode: @escaping (Request) throws -> Data = { try JSONEncoder().encode($0) }
    ) -> (Other) throws -> APIRequest {
        return { existingDocument in
            try APIRequest(
                method,
                contentType: contentType,
                host: host,
                path: path,
                body: try requestBodyConstructor(existingDocument),
                including: includes,
                responseType: responseType,
                encode: encode
            )
        }
    }
}
