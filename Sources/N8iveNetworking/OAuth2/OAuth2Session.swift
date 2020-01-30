//
//  File.swift
//  
//
//  Created by muhammad on 1/28/20.
//

import Foundation

open class OAuth2Session {
  
  /// The token type.
  open var tokenType: String?
  
  /// The receiver's access token.
  open var accessToken: String?
  
  /// The receiver's id token.
  open var idToken: String?
  
  /// The access token's expiry date.
  open var accessTokenExpiry: Date?
  
  /// The receiver's refresh token.
  open var refreshToken: String?
  
  public init() {
    
  }
  
}
