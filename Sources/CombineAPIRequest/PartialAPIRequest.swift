//
//  PartialAPIRequest.swift
//  APITest
//
//  Created by Mathew Polzin on 6/29/20.
//  Copyright © 2020 Mathew Polzin. All rights reserved.
//

import Foundation
import Combine

public struct PartialAPIRequest<Context, Request: Encodable, Response: Decodable> {
    public let method: HttpVerb
    public let contentType: HttpContentType
    public let additionalHeaders: [String: String]
    public let url: (Context) throws -> URL
    public let bodyData: (Context) throws -> Data?

    public func `for`(context: Context) throws -> APIRequest<Request, Response> {
        return APIRequest(
            method: method,
            contentType: contentType,
            additionalHeaders: additionalHeaders,
            url: try url(context),
            bodyData: try bodyData(context)
        )
    }

    public init(
        _ method: HttpVerb,
        contentType: HttpContentType = .json,
        url: @escaping (Context) -> URL,
        body: @escaping (Context) throws -> Request?,
        additionalHeaders: [String: String] = [:],
        responseType: Response.Type,
        encode: @escaping (Request) throws -> Data = { try JSONEncoder().encode($0) }
    ) {
        self.method = method
        self.contentType = contentType
        self.additionalHeaders = additionalHeaders
        self.url = url
        self.bodyData = { context in try body(context).map(encode) }
    }

    public init(
        _ method: HttpVerb,
        contentType: HttpContentType = .json,
        host: URL,
        path: String,
        body: @escaping (Context) throws -> Request?,
        including includes: [String] = [],
        additionalHeaders: [String: String] = [:],
        responseType: Response.Type,
        encode: @escaping (Request) throws -> Data = { try JSONEncoder().encode($0) }
    ) throws {
        try self.init(
            method,
            contentType: contentType,
            host: host,
            path: path,
            body: body,
            including: includes,
            additionalHeaders: additionalHeaders,
            encode: encode
        )
    }

    public init(
        _ method: HttpVerb,
        contentType: HttpContentType = .json,
        host: URL,
        path: String,
        body: @escaping (Context) throws -> Request?,
        including includes: [String] = [],
        additionalHeaders: [String: String] = [:],
        encode: @escaping (Request) throws -> Data = { try JSONEncoder().encode($0) }
    ) throws {
        var urlComponents = URLComponents(url: host, resolvingAgainstBaseURL: false)!

        urlComponents.path = path
        if includes.count > 0 {
            urlComponents.queryItems = [.init(name: "include", value: includes.joined(separator: ","))]
        }

        guard let url = urlComponents.url else {
            throw RequestFailure.urlConstruction(String(describing: urlComponents))
        }
        self.url = { _ in url }

        self.method = method
        self.contentType = contentType
        self.additionalHeaders = additionalHeaders
        self.bodyData = { context in try body(context).map(encode) }
    }
}
