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
    let session: URLSession
    
    init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    func resume(ids: [String], handler: @escaping URLSession.CompletionHandler) {
        return session.dataTask(
            with: requestUrl(ids: ids),
            completionHandler: handler).resume()
    }
    
    func requestUrl(ids: [String], part: String = defaultPart) -> URL {
        let apiKey: String = Credential(key:.Google).apiKey
        let id = ids.joined(separator: ",")
        return URL(string: "\(VideoApi.baseUrl)?part=\(part)&id=\(id)&key=\(apiKey)")!
    }
}
