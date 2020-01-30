//
//  File.swift
//  
//
//  Created by muhammad on 1/27/20.
//

import Foundation

public struct EndPoint {
    var path: String
    var method: HTTPMethod
    var requiresAuthentication: Bool
    var parameters: [String: Any]?
}
