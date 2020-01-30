//
//  File.swift
//  
//
//  Created by muhammad on 1/28/20.
//

import Foundation
import SwiftyJSON

open class NetworkManager {
  
  public static var shared = NetworkManager(configuration: .default)
  
  var session: URLSession
  
  public init(configuration: URLSessionConfiguration) {
    self.session = URLSession(configuration: configuration)
  }
  
  @discardableResult public func request(fullURL: String, method: HTTPMethod = .get, parameters: [String: Any]? = nil, headers: [String: String]? = nil, encoding: ParameterEncoding = .json, completion: @escaping (JSON?, Error?) -> Void) -> URLSessionDataTask? {
    if let url = URL(string: fullURL) {
      var request = URLRequest(url: url)
      request.httpMethod = method.rawValue
      if let parameters = parameters {
        switch encoding {
        case .json:
          do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
          } catch (let error) {
            print("NetworkManager.request failed to serialize parameters with error : \(error)")
            return nil
          }
        case .xwwwform:
          let parameterArray = parameters.map { (arg) -> String in
            let (key, value) = arg
            return "\(key)=\(self.percentEscapeString("\(value)"))"
          }
          request.httpBody = parameterArray.joined(separator: "&").data(using: .utf8)
        }
        request.setValue(encoding.rawValue, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
      }
      if let headers = headers {
        for (key, value) in headers {
          request.setValue(value, forHTTPHeaderField: key)
        }
      }
      let task = self.session.dataTask(with: request) { (data, response, error) in
        guard error == nil else {
          DispatchQueue.main.async() {
            completion(nil, error)
          }
          return
        }
        
        guard let data = data else {
          DispatchQueue.main.async() {
            completion(nil, NSError(domain: "dataNilError", code: -100001, userInfo: nil))
          }
          return
        }
        
        let json = JSON(data)
        //print(json)
        DispatchQueue.main.async() {
          completion(json, nil)
        }
      }
      task.resume()
      return task
    } else {
      return nil
    }
  }
  
  @discardableResult public func download(fullURL: String, completion: @escaping (Data?) -> Void) -> URLSessionDataTask? {
    if let url = URL(string: fullURL) {
      let task = self.session.dataTask(with: url) { data, response, error in
        guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200, let data = data else {
            completion(nil)
            return
        }
        DispatchQueue.main.async() {
          completion(data)
        }
      }
      task.resume()
    }
    return nil
  }
  
  /// Percent escape
  ///
  /// Percent escape in conformance with W3C HTML spec:
  ///
  /// See http://www.w3.org/TR/html5/forms.html#application/x-www-form-urlencoded-encoding-algorithm
  ///
  /// - parameter string:   The string to be percent escaped.
  /// - returns:            Returns percent-escaped string.
  
  private func percentEscapeString(_ string: String) -> String {
    var characterSet = CharacterSet.alphanumerics
    characterSet.insert(charactersIn: "-._* ")
    return string.addingPercentEncoding(withAllowedCharacters: characterSet)?.replacingOccurrences(of: " ", with: "+") ?? ""
  }
  
  
}
