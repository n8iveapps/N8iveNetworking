//
//  File.swift
//  
//
//  Created by muhammad on 1/27/20.
//

import Foundation

public struct EndPoint {
    public var path: String
    public var method: HTTPMethod
    public var requiresAuthentication: Bool
    public var parameters: [String: Any]?
    public init(path: String, method: HTTPMethod, requiresAuthentication: Bool, parameters: [String: Any]? = nil) {
        self.path = path
        self.method = method
        self.requiresAuthentication = requiresAuthentication
        self.parameters = parameters
    }
}
