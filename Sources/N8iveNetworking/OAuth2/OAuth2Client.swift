//
//  File.swift
//
//
//  Created by muhammad on 1/28/20.
//

import Foundation
import KeychainAccess
import AuthenticationServices

#if os(iOS)
import UIKit
#endif

open class OAuth2Client: NSObject {
  
  /// The OAuth2 client configuration.
  private(set) public var configuration:OAuth2ClientConfiguration
  
  /// The OAuth2 fetched access token.
  private(set)  public var session:OAuth2Session?
  
  private(set) public var networkManager: NetworkManager
  public var clientIsLoadingToken:(() -> Void) = {}
  public var clientDidFinishLoadingToken:(() -> Void) = {}
  public var clientDidFailLoadingToken:((_ NKError:Error) -> Void) = { _ in }
  
  public init(configuration:OAuth2ClientConfiguration, manager: NetworkManager = NetworkManager.shared) {
    self.configuration = configuration
    self.session = nil
    self.networkManager = manager
    super.init()
    self.loadToken()
  }
  
  /// Override to implement your own logic in subclass.
  open func loadToken() {
    if self.configuration.clientId != "" {
      let keychain = Keychain(service: "OAuth2Client.\(self.configuration.clientId)")
      do {
        if let accessToken = try keychain.get("accessToken.accessToken"), let type = try keychain.get("accessToken.tokenType"), let refreshToken = try keychain.get("accessToken.refreshToken") {
          self.session = OAuth2Session()
          self.session?.accessToken = accessToken
          self.session?.tokenType = type
          self.session?.refreshToken = refreshToken
          if let idToken = try keychain.get("accessToken.idToken") {
            self.session?.idToken = idToken
          }
          if let timeIntervalString = try keychain.get("accessToken.accessTokenExpiry") {
            if let timeInterval = Double(timeIntervalString) {
              let accessTokenExpiry = Date(timeIntervalSinceReferenceDate: timeInterval)
              self.session?.accessTokenExpiry = accessTokenExpiry
            }
          }
        }
      } catch let error {
        print("loadToken error: \(error)")
      }
    } else {
      print("error: No client Id provided")
    }
  }
  
  /// Override to implement your own logic in subclass.
  open func saveToken() {
    if self.configuration.clientId != "" {
      let keychain = Keychain(service: "OAuth2Client.\(self.configuration.clientId)")
      if let accessToken = self.session?.accessToken, let type = self.session?.tokenType, let refreshToken = self.session?.refreshToken {
        do {
          try keychain.synchronizable(true).set("\(accessToken)", key: "accessToken.accessToken")
          try keychain.synchronizable(true).set("\(type)", key: "accessToken.tokenType")
          try keychain.synchronizable(true).set("\(refreshToken)", key: "accessToken.refreshToken")
          if let idToken = self.session?.idToken {
            try keychain.synchronizable(true).set("\(idToken)", key: "accessToken.idToken")
          }
          if let accessTokenExpiry = self.session?.accessTokenExpiry {
            let timeInterval = accessTokenExpiry.timeIntervalSinceReferenceDate
            try keychain.synchronizable(true).set("\(timeInterval)", key: "accessToken.accessTokenExpiry")
          }
        } catch let error {
          print("saveToken error: \(error)")
        }
      }
    } else {
      print("error: No client Id provided")
    }
  }
  
  /// Override to implement your own logic in subclass.
  open func clearToken() {
    if self.configuration.clientId != "" {
      let keychain = Keychain(service: "OAuth2Client.\(self.configuration.clientId)")
      do {
        try keychain.remove("accessToken.accessToken")
        try keychain.remove("accessToken.tokenType")
        try keychain.remove("accessToken.refreshToken")
        try keychain.remove("accessToken.idToken")
        try keychain.remove("accessToken.accessTokenExpiry")
      } catch let error {
        print("error: \(error)")
      }
    } else {
      print("clearToken error: No client Id provided")
    }
  }
  
  open func authorize() {
    var urltext = "\(self.configuration.authURL)?client_id=\(self.configuration.clientId)&redirect_uri=\(self.configuration.redirectURL)"
    if self.configuration.scope != "" {
      urltext = "\(urltext)&scope=\(self.configuration.scope)"
    }
    if self.configuration.responseType != "" {
      urltext = "\(urltext)&response_type=\(self.configuration.responseType)"
    }
    for (key, value) in self.configuration.parameters {
      urltext = "\(urltext)&\(key)=\(value)"
    }
    
    #if os(iOS)
    self.authorizeInAuthenticationSession(urlString: urltext)
    #elseif os(macOS)
    NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handle(event:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    if #available(macOS 10.15, *) {
      self.authorizeInAuthenticationSession(urlString: urltext)
    } else {
      self.authorizeInBrowser(urlString: urltext)
    }
    #endif
    
  }
  
  open func handle(redirectURL: URL) {
    // show loading
    let redirectString = redirectURL.absoluteString
    if self.configuration.redirectURL.isEmpty {
      self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.NoRedirectURL", code: -100001, userInfo: ["message" : "Oauth2 configuration is missing a redirect URL"]))
      return
    }
    let components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: true)
    if !(redirectString.hasPrefix(self.configuration.redirectURL)) && (!(redirectString.hasPrefix("urn:ietf:wg:oauth:2.0:oob")) && "localhost" != components?.host) {
      self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.RedirectURLMismatch", code: -100002, userInfo: ["message" : "Redirect URL mismatch: expecting \(self.configuration.redirectURL) , received: \(redirectString)"]))
      return
    }
    if let queryItems = components?.queryItems {
      let codeItems = queryItems.filter({ (item) -> Bool in
        if item.name == "code" {
          return true
        }
        return false
      })
      if codeItems.count > 0 {
        self.clientIsLoadingToken()
        if let code = codeItems[0].value {
          let parameters = [
            "code": "\(code)",
            "client_id": "\(self.configuration.clientId)",
            "client_secret": "\(self.configuration.clientSecret)",
            "redirect_uri": "\(self.configuration.redirectURL)",
            "grant_type": "authorization_code"
            ]
          self.networkManager.request(fullURL: self.configuration.tokenURL, method: .post, parameters: parameters, headers: nil, encoding: .xwwwform) { (json, error) in
            guard error == nil else {
              self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.AuthenticationFailed", code: -100003, userInfo: ["message" : "\(error?.localizedDescription ?? "")"]))
              return
            }
            guard let json = json, let accessToken = json["access_token"].string, let refreshToken = json["refresh_token"].string, let tokenType = json["token_type"].string, let accessTokenExpiry = json["expires_in"].double else {
              self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.InvalidResponse", code: -100004, userInfo: ["message" : "Invalid JSON response"]))
              return
            }
            self.session = OAuth2Session()
            self.session?.accessToken = accessToken
            self.session?.refreshToken = refreshToken
            self.session?.tokenType = tokenType
            self.session?.accessTokenExpiry = Date().addingTimeInterval(accessTokenExpiry)
            self.session?.idToken = json["id_token"].stringValue
            self.saveToken()
            self.clientDidFinishLoadingToken()
          }
        }
      }
      else {
        self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.UnableToExtractCode", code: -100005, userInfo: ["message" : "Unable to extract code: query parameters has no \"code\" parameter"]))
      }
    }
    else {
      self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.UnableToExtractCode", code: -100005, userInfo: ["message" : "Unable to extract code: No query parameters in redirect URL"]))
    }
  }
  
  open func refreshAccessToken() {
    if let token = self.session?.refreshToken {
      let parameters = [
        "client_id": "\(self.configuration.clientId)",
        "client_secret": "\(self.configuration.clientSecret)",
        "redirect_uri": "\(self.configuration.redirectURL)",
        "refresh_token": "\(token)",
        "grant_type": "refresh_token"
        ]
      
      self.networkManager.request(fullURL: self.configuration.tokenURL, method: .post, parameters: parameters, headers: nil, encoding: .xwwwform) { (json, error) in
        guard error == nil else {
          self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.AuthenticationFailed", code: -100003, userInfo: ["message" : "\(error?.localizedDescription ?? "")"]))
          return
        }
        guard let json = json, let accessToken = json["access_token"].string, let refreshToken = json["refresh_token"].string, let tokenType = json["token_type"].string, let accessTokenExpiry = json["expires_in"].double else {
          self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.InvalidResponse", code: -100004, userInfo: ["message" : "Invalid JSON response"]))
          return
        }
        self.session = OAuth2Session()
        self.session?.accessToken = accessToken
        self.session?.refreshToken = refreshToken
        self.session?.tokenType = tokenType
        self.session?.accessTokenExpiry = Date().addingTimeInterval(accessTokenExpiry)
        self.session?.idToken = json["id_token"].stringValue
        self.saveToken()
        self.clientDidFinishLoadingToken()
      }
    }
    else {
      self.clientDidFailLoadingToken(NSError(domain: "OAuth2Client.MissingRefreshToken", code: -100004, userInfo: ["message" : "Invalid OAuth2 refresh token"]))
    }
  }
  
  open func unauthorize() {
    self.session = nil
    self.clearToken()
  }
  
}

#if os(iOS)
@available(iOS 13.0, *)
extension OAuth2Client: ASWebAuthenticationPresentationContextProviding {
  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let windows = UIApplication.shared.windows.filter { $0.isKeyWindow }
    return windows.last!
  }
}
#endif

extension OAuth2Client {

  #if os(macOS)
  @available(macOS 10.14, *)
  private func authorizeInBrowser(urlString: String) {
    if let escapedURL = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
      if let url = URL(string: escapedURL) {
        NSWorkspace.shared.open(url)
      }
    }
  }
  
  @available(macOS 10.14, *)
  @objc func handle(event: NSAppleEventDescriptor) {
      if let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue {
          if urlString.contains(self.configuration.redirectURL) {
              if let url = URL(string: urlString) {
                  self.handle(redirectURL: url)
              }
          }
      }
  }
  #endif
  
  @available(iOS 12, macOS 10.15, *)
  private func authorizeInAuthenticationSession(urlString: String) {
    if let escapedURL = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
      if let url = URL(string: escapedURL) {
        let safariAuthenticator = ASWebAuthenticationSession(url: url, callbackURLScheme: self.configuration.redirectURL, completionHandler: { (url, error) in
            if let error = error {
                self.clientDidFailLoadingToken(error)
            } else if let url = url {
                self.handle(redirectURL: url)
            }
        })
        #if os(iOS)
        if #available(iOS 13.0, *) {
          safariAuthenticator.presentationContextProvider = self
        }
        #endif
        safariAuthenticator.start()
      }
    }
    
  }
  
}
