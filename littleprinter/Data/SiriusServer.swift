//
//  SiriusServer.swift
//  littleprinter
//
//  Created by Michael Colville on 10/01/2018.
//  Copyright © 2018 Nord Projects Ltd. All rights reserved.
//

import UIKit

enum SiriusServerError: Error {
    case UnknownError
    case InvalidURL
    case InvalidData
    case NoDataInResponse
    case PrinterNotFound
    case HttpErrorCode(Int)
}

extension SiriusServerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .UnknownError:
            return "Something happened that isn't handled. Sorry about that."
        case .InvalidURL:
            return "Unable to create a valid URL with this key"
        case .InvalidData:
            return "Unable to create data with this message"
        case .NoDataInResponse:
            return "There was no data in the response"
        case .PrinterNotFound:
            return "This printer key cannot be found, it may have been removed"
        case .HttpErrorCode(let code):
            return "Server responded with error code \(code)"
        }
    }
}

class SiriusServer: NSObject, URLSessionDelegate {
    
    static let shared = SiriusServer()
    
    let foregroundURLSession = URLSession.shared
    lazy var backgroundURLSession: URLSession = URLSession(
        configuration: URLSessionConfiguration.background(withIdentifier: "sirius"),
        delegate: self, delegateQueue: nil
    )
    
    func getPrinterInfo(key: String, completion: @escaping (Result<Data>) -> Void) {
        guard let url = URL(string: key) else {
            completion(.failure(SiriusServerError.InvalidURL))
            return
        }

        foregroundURLSession.dataTask(with: url) {(data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        if let data = data {
                            let string = String(data: data, encoding: String.Encoding.utf8) as String?
                            print("data: " + string!)
                            completion(Result.success(data))
                        } else {
                            completion(.failure(SiriusServerError.NoDataInResponse))
                        }
                    case 404:
                        completion(.failure(SiriusServerError.PrinterNotFound))
                    default:
                        completion(.failure(SiriusServerError.HttpErrorCode(httpResponse.statusCode)))
                    }
                } else {
                    completion(.failure(SiriusServerError.UnknownError))
                }
            }
        }.resume()
    }
    
    @discardableResult
    func sendMessage(_ message: SiriusMessage, completion: @escaping (Error?) -> Void) -> URLSessionTask {
        let task = foregroundURLSession.dataTask(with: message.request) {(data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        completion(nil)
                    case 404:
                        completion(SiriusServerError.PrinterNotFound)
                    default:
                        completion(SiriusServerError.HttpErrorCode(httpResponse.statusCode))
                    }
                } else {
                    completion(SiriusServerError.UnknownError)
                }
            }
        }
        
        task.resume()
        
        return task
    }
    
    func sendMessageInBackground(_ message: SiriusMessage) {
        let task = backgroundURLSession.dataTask(with: message.request)
        task.resume()
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("Background events finished.")
    }
}

class SiriusMessage {
    let request: URLRequest
    
    init(data: Data, to key: String, from username: String, contentType: String) throws {
        let escapedName = username.addingPercentEncoding(withAllowedCharacters: CharacterSet()) ?? "anon"
        guard let url = URL(string: key + "?from=" + escapedName) else {
            throw SiriusServerError.InvalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = data
        self.request = request
    }
    
    convenience init(text: String, to key: String, from username: String) throws {
        guard let data = text.data(using: .utf8) else {
            throw SiriusServerError.InvalidData
        }
        
        try self.init(data: data, to: key, from: username, contentType: "text/plain")
    }
    
    convenience init(html: String, to key: String, from username: String) throws {
        guard let data = html.data(using: .utf8) else {
            throw SiriusServerError.InvalidData
        }
        
        try self.init(data: data, to: key, from: username, contentType: "text/html")
    }
    
    convenience init(image: UIImage, to key: String, from username: String) throws {
        guard let data = image.pngData() else {
            throw SiriusServerError.InvalidData
        }
        
        try self.init(data: data, to: key, from: username, contentType: "image/jpeg")
    }
}
