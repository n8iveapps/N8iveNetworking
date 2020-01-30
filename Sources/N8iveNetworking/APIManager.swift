//
//  File.swift
//  
//
//  Created by muhammad on 1/28/20.
//

import Foundation
import SwiftyJSON

open class APIManager {
  
  //public static let shared = APIManager()
  open var baseURL = ""                                   // the base URL for API endpoints
  open var session = OAuth2Session()                      // the access token to use in API requests
  open var shouldAuthorizeGetRequests = false
  open var mainHeaders:[String: String] = [:]
  private(set) public var networkManager: NetworkManager
  
  public init(manager: NetworkManager = NetworkManager.shared) {
    self.networkManager = manager
    self.initConfiguration()
    self.loadSavedToken()
  }
  
  /// Override to implement your own init logic
  open func initConfiguration() {
    
  }
  
  /// Override to implement your own token loading method
  open func loadSavedToken() {
    
  }
  
  /// Override to implement your own token caching method
  open func saveToken() {
    
  }
  
  /// Override to implement your own token caching method
  open func clearToken() {
    
  }
  
  @discardableResult public func request(to endPoint:EndPoint, completion: @escaping ((_ result:JSON) -> Void)) -> URLSessionDataTask? {
    var headers = self.mainHeaders
    if endPoint.requiresAuthentication {
      guard let token = self.session.accessToken, token != "", let type = self.session.tokenType, type != "" else {
        completion(JSON(["error":"Please login first"]))
        return nil
      }
      headers["Authorization"] = "\(type) \(token)"
    }
    return self.networkManager.request(fullURL: "\(self.baseURL)\(endPoint.path)", method: endPoint.method, parameters: endPoint.parameters, headers: headers, encoding: .json) { (json, error) in
      guard let json = json else {
        completion(JSON(["error":"\(error?.localizedDescription ?? "Couldn't load request")"]))
        return
      }
      completion(json)
    }
  }
  
}
