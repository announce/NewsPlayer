//
//  MockYouTubeSession.swift
//  NewsPlayer
//
//  Stubbing NSURLSession With Dependency Injection http://swiftandpainless.com/stubbing-nsurlsession-with-dependency-injection/
//
//  Created by YAMAMOTOKenta on 8/20/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

class MockSession: NSURLSession {
    typealias Response = (data: NSData?, urlResponse: NSURLResponse?, error: NSError?)
    
    var completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?
    
    static var mockResponse: Response = (data: nil, urlResponse: nil, error: nil)
    
    static func createResponse(url: NSURL, data: NSData, statusCode: Int = 200) -> Response {
        let urlResponse = NSHTTPURLResponse(URL: url, statusCode: statusCode, HTTPVersion: nil, headerFields: nil)
        return (data: data, urlResponse: urlResponse, error: nil)
    }
    
    override class func sharedSession() -> NSURLSession {
        return MockSession()
    }
    
    override func dataTaskWithURL(url: NSURL, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) -> NSURLSessionDataTask {
        self.completionHandler = completionHandler
        return MockTask(response: MockSession.mockResponse, completionHandler: completionHandler)
    }
    
    class MockTask: NSURLSessionDataTask {
        typealias Response = (data: NSData?, urlResponse: NSURLResponse?, error: NSError?)
        var mockResponse: Response
        let completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?
        
        init(response: Response, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
            self.mockResponse = response
            self.completionHandler = completionHandler
        }
        override func resume() {
            completionHandler!(mockResponse.data, mockResponse.urlResponse, mockResponse.error)
        }
    }
}