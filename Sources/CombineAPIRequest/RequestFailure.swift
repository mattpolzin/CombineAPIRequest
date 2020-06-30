//
//  RequestFailure.swift
//  APITest
//
//  Created by Mathew Polzin on 6/29/20.
//  Copyright © 2020 Mathew Polzin. All rights reserved.
//

public enum RequestFailure: Swift.Error {
    case unknown(String)
    case urlConstruction(String)
    case responseError(String)

    public var isUrlConstruction: Bool {
        guard case .urlConstruction = self else {
            return false
        }
        return true
    }

    public var isResponseError: Bool {
        guard case .responseError = self else {
            return false
        }
        return true
    }
}
