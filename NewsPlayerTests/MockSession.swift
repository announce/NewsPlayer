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
    
    var completionHandler: NSURLSession.CompletionHandler?
    static var mockResponse: [NSURL: Response] = [:]
    
    static func upsertMockResponse(url: NSURL, data: NSData, statusCode: Int = 200) -> Response? {
        let urlResponse = NSHTTPURLResponse(URL: url, statusCode: statusCode, HTTPVersion: nil, headerFields: nil)
        return mockResponse.updateValue((data: data, urlResponse: urlResponse, error: nil),
                                        forKey: normalizeUrl(url))
    }
    
    static func normalizeUrl(url: NSURL) -> NSURL {
        return NSURL(scheme: url.scheme, host: url.host, path: url.path!)!
    }
    
    override class func sharedSession() -> NSURLSession {
        return MockSession()
    }
    
    override func dataTaskWithURL(url: NSURL, completionHandler: NSURLSession.CompletionHandler) -> NSURLSessionDataTask {
        self.completionHandler = completionHandler
        return MockTask(response: MockSession.mockResponse[MockSession.normalizeUrl(url)]!, completionHandler: completionHandler)
    }
    
    class MockTask: NSURLSessionDataTask {
        typealias Response = (data: NSData?, urlResponse: NSURLResponse?, error: NSError?)
        var mockResponse: Response
        private (set) var called: [String: Response] = [:]
        let completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?
        
        init(response: Response, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
            self.mockResponse = response
            self.completionHandler = completionHandler
        }
        override func resume() {
            called["\(#function)"] = mockResponse
            completionHandler!(mockResponse.data, mockResponse.urlResponse, mockResponse.error)
        }
    }
}