//
//  Combine+Request.swift
//  APITest
//
//  Created by Mathew Polzin on 6/29/20.
//  Copyright © 2020 Mathew Polzin. All rights reserved.
//

import Foundation
import Combine

extension Publisher {

    public func chain<Request: Encodable, Response: Decodable>(
        _ partialRequest: PartialAPIRequest<Output?, Request, Response>
    ) -> Publishers.FlatMap<AnyPublisher<Response, Error>, Publishers.TryMap<Self, APIRequest<Request, Response>>> {
        return chain(partialRequest, using: JSONDecoder())
    }

    public func chain<Request: Encodable, Response: Decodable, Decoder: TopLevelDecoder>(
        _ partialRequest: PartialAPIRequest<Output?, Request, Response>,
        using decoder: Decoder
        ) -> Publishers.FlatMap<AnyPublisher<Response, Error>, Publishers.TryMap<Self, APIRequest<Request, Response>>> where Decoder.Input == Data {
        self
            .tryMap(partialRequest.for(context:))
            .flatMap { $0.publisher(using: decoder) }
    }

    public func chain<Request: Encodable, Response: Decodable>(
        _ partialRequest: PartialAPIRequest<Output, Request, Response>
    ) -> Publishers.FlatMap<AnyPublisher<Response, Error>, Publishers.TryMap<Self, APIRequest<Request, Response>>> {
        return chain(partialRequest, using: JSONDecoder())
    }

    public func chain<Request: Encodable, Response: Decodable, Decoder: TopLevelDecoder>(
        _ partialRequest: PartialAPIRequest<Output, Request, Response>,
        using decoder: Decoder
    ) -> Publishers.FlatMap<AnyPublisher<Response, Error>, Publishers.TryMap<Self, APIRequest<Request, Response>>> where Decoder.Input == Data {
        self
            .tryMap(partialRequest.for(context:))
            .flatMap { $0.publisher(using: decoder) }
    }

    public func chain<Request: Encodable, Response: Decodable>(
        _ method: HttpVerb,
        host: URL,
        path: String,
        including includes: [String] = [],
        requestBodyConstructor: @escaping (Output) throws -> Request,
        responseType: Response.Type,
        encode: @escaping (Request) throws -> Data = { try JSONEncoder().encode($0) }
    ) -> Publishers.FlatMap<AnyPublisher<Response, Error>, Publishers.TryMap<Self, APIRequest<Request, Response>>> {
        return chain(
            method,
            host: host,
            path: path,
            including: includes,
            requestBodyConstructor: requestBodyConstructor,
            responseType: responseType,
            encode: encode,
            using: JSONDecoder()
        )
    }

    public func chain<Request: Encodable, Response: Decodable, Decoder: TopLevelDecoder>(
        _ method: HttpVerb,
        host: URL,
        path: String,
        including includes: [String] = [],
        requestBodyConstructor: @escaping (Output) throws -> Request,
        responseType: Response.Type,
        encode: @escaping (Request) throws -> Data = { try JSONEncoder().encode($0) },
        using decoder: Decoder
    ) -> Publishers.FlatMap<AnyPublisher<Response, Error>, Publishers.TryMap<Self, APIRequest<Request, Response>>> where Decoder.Input == Data {
        self.tryMap(
            APIRequest.transformation(
                method,
                host: host,
                path: path,
                including: includes,
                requestBodyConstructor: requestBodyConstructor,
                responseType: responseType,
                encode: encode
            )
        )
        .flatMap { $0.publisher(using: decoder) }
    }
}
