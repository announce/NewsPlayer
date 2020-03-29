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
    let session: URLSession
    
    init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    func resume(channel: Channel, pageToken: String = "", handler: @escaping URLSession.CompletionHandler) {
        return session.dataTask(
            with: requestUrl(channel: channel, pageToken: pageToken),
            completionHandler: handler).resume()
    }
    
    func requestUrl(channel: Channel, pageToken: String, part: String = defaultPart) -> URL {
        let apiKey: String = Credential(key: .Google).apiKey
        return URL(string: "\(ActivityApi.baseUrl)?part=\(part)&channelId=\(channel.id)&pageToken=\(pageToken)&key=\(apiKey)")!
    }
}
