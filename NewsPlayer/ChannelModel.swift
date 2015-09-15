//
//  ChannelModel.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/16/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import Foundation

class ChannelModel : NSObject {
    
    class var sharedInstance: ChannelModel {
        struct Singleton {
            static let instance: ChannelModel = ChannelModel()
        }
        return Singleton.instance
    }
    let activityUrl = "https://www.googleapis.com/youtube/v3/activities"
    
    dynamic var queue: [String] = []
    
    func enqueue(){
        var channels: [String] = channelList()
        for channelID in channels {
            fetchActivities(channelID: channelID)
        }
    }
    
    func nextVideoId() -> String? {
        if (queue.count > 0) {
            var videoID: String = queue.removeAtIndex(0) as String
            return videoID
        } else {
            return nil
        }
    }
    
    func channelList() -> [String] {
        let plistPath = NSBundle.mainBundle().pathForResource("YouTube", ofType: "plist")
        let registry = NSDictionary(contentsOfFile: plistPath!)
        let channels:Array = registry!.objectForKey("Channels") as! [String]
        return channels;
    }
    
    func fetchActivities(#channelID: String) {
        let apiKey: String = Credential().apiKey
        let part = "contentDetails"
        let request = NSURLRequest(URL: NSURL(
            string: "\(activityUrl)?part=\(part)&channelId=\(channelID)&key=\(apiKey)")!)
        NSURLConnection.sendAsynchronousRequest(request,
            queue: NSOperationQueue.mainQueue(),
            completionHandler: response)
    }

    func response(res: NSURLResponse!, data: NSData!, error: NSError!) {
        if (error != nil) {
            println("NSError in response: \(error)", __FUNCTION__, __LINE__)
            return
        }

        // TODO: SwiftJson
        var json:NSDictionary = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.AllowFragments, error: nil) as! NSDictionary
        
        var items = json.objectForKey("items") as! [NSDictionary]
        
        for item in items {
            var contentDetails:NSDictionary? = item.objectForKey("contentDetails") as? NSDictionary
            if (contentDetails == nil) {continue}
            var video:NSDictionary? = contentDetails!.objectForKey("upload") as? NSDictionary
            if (video == nil) {continue}
            var videoId:String = video!.objectForKey("videoId") as! String
            
            println("VideoID:\(videoId)")
            queue.append(videoId)
        }
    }
}
