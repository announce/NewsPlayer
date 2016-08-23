//
//  ActivityApi.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/22/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

class ActivityApi {
    static let baseUrl = "https://www.googleapis.com/youtube/v3/activities"
    static let defaultPart = "snippet,contentDetails"
    let session: NSURLSession
    
    init(session: NSURLSession = NSURLSession.sharedSession()) {
        self.session = session
    }
    
    func resume(channel: Channel, pageToken: String = "", handler: NSURLSession.CompletionHandler) {
        return session.dataTaskWithURL(
            requestUrl(channel, pageToken: pageToken),
            completionHandler: handler).resume()
    }
    
    func requestUrl(channel: Channel, pageToken: String, part: String = defaultPart) -> NSURL {
        let apiKey: String = Credential(key: .Google).apiKey
        return NSURL(string: "\(ActivityApi.baseUrl)?part=\(part)&channelId=\(channel.id)&pageToken=\(pageToken)&key=\(apiKey)")!
    }
}
