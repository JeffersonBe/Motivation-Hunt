//
//  MHClient.swift
//  OnTheMap
//
//  Created by Jefferson Bonnaire on 22/01/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import UIKit

class MHClient: NSObject {

    // MARK: - Shared Instance
    static var sharedInstance = MHClient()

    typealias CompletionHander = (_ result: AnyObject?, _ error: NSError?) -> Void

    var session: URLSession

    override init() {
        session = URLSession.shared
        super.init()
    }

    // MARK: - Shared Image Cache

    struct Caches {
        static let imageCache = ImageCache()
    }

    // MARK: - All purpose task method for data

    func taskForResource(_ parameters: [String : AnyObject], completionHandler: @escaping CompletionHander) -> URLSessionDataTask {

        let urlString = Resources.searchVideos + MHClient.escapedParameters(parameters)
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)

        let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in

            if let error = downloadError {
                let newError = MHClient.errorForData(data, response: response, error: error as NSError)
                completionHandler(nil, newError)
            } else {
                MHClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }) 

        task.resume()

        return task
    }

    func taskForImage(_ filePath: String, completionHandler: @escaping (_ imageData: Data?, _ error: NSError?) ->  Void) -> URLSessionTask {

        let url = URL(string: filePath)!
        let request = URLRequest(url: url)

        let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in

            if let error = downloadError {
                let newError = MHClient.errorForData(data, response: response, error: error as NSError)
                completionHandler(nil, newError)
            } else {
                completionHandler(data, nil)
            }
        }) 

        task.resume()
        
        return task
    }

    // MARK: - Helpers

    // Try to make a better error, based on the status_message from Youtube. If we cant then return the previous error

    class func errorForData(_ data: Data?, response: URLResponse?, error: NSError) -> NSError {

        if data == nil {
            return error
        }

        do {
            let parsedResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)

            if let parsedResult = parsedResult as? [String : AnyObject], let errorMessage = parsedResult[MHClient.Keys.ErrorStatusMessage] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "Youtube Error", code: 1, userInfo: userInfo)
            }

        } catch _ {}

        return error
    }

    // Parsing the JSON

    class func parseJSONWithCompletionHandler(_ data: Data, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil

        let parsedResult: AnyObject?
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }

        if let error = parsingError {
            completionHandler(nil, error)
        } else {
            completionHandler(parsedResult, nil)
        }
    }

    // URL Encoding a dictionary into a parameter string

    class func escapedParameters(_ parameters: [String : AnyObject]) -> String {

        var urlVars = [String]()

        for (key, value) in parameters {

            // make sure that it is a string value
            let stringValue = "\(value)"

            // Escape it
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)

            // Append it

            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }

        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
}
