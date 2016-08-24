//
//  VideoApi.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/22/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

class VideoApi {
    static let baseUrl = "https://www.googleapis.com/youtube/v3/videos"
    static let defaultPart = "snippet,contentDetails,status"
    let session: NSURLSession
    
    init(session: NSURLSession = NSURLSession.sharedSession()) {
        self.session = session
    }
    
    func resume(ids: [String], handler: NSURLSession.CompletionHandler) {
        return session.dataTaskWithURL(
            requestUrl(ids),
            completionHandler: handler).resume()
    }
    
    func requestUrl(ids: [String], part: String = defaultPart) -> NSURL {
        let apiKey: String = Credential(key:.Google).apiKey
        let id = ids.joinWithSeparator(",")
        return NSURL(string: "\(VideoApi.baseUrl)?part=\(part)&id=\(id)&key=\(apiKey)")!
    }
}
