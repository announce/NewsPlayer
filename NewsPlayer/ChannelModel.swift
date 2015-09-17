//
//  ChannelModel.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/16/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import Foundation
import SwiftyJSON

class ChannelModel : NSObject {
    
    class var sharedInstance: ChannelModel {
        struct Singleton {
            static let instance: ChannelModel = ChannelModel()
        }
        return Singleton.instance
    }
    
    struct Thumbnail {
        var url: String
        var width: Int
        var height: Int
    }
    
    struct Video {
        var id: String
        var title: String
        var description: String
        var thumbnail: Thumbnail
    }
    
    let activityUrl = "https://www.googleapis.com/youtube/v3/activities"
    
    dynamic var queue: [String] = []
    var videoList: [String: Video?] = ["": nil]
    var currentIndex: Int = 0
    
    func enqueue(){
        var channels: [String] = channelList()
        for channelID in channels {
            fetchActivities(channelID: channelID)
        }
    }
    
    func nextVideo() -> Video? {
        if (queue.count > 0) {
            currentIndex++
            return currentVideo()
        } else {
            return nil
        }
    }
    
    func currentVideo() -> Video? {
        return getVideoByIndex(currentIndex)
    }
    
    func getVideoByIndex(index: Int) -> Video? {
        if (queue.count > 0) {
            var videoID: String = queue[index]
            if var video: Video? = videoList[videoID] {
                return video
            } else {
                return nil
            }
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
        let part = "snippet,contentDetails"
        let request = NSURLRequest(URL: NSURL(
            string: "\(activityUrl)?part=\(part)&channelId=\(channelID)&key=\(apiKey)")!)
        NSURLConnection.sendAsynchronousRequest(request,
            queue: NSOperationQueue.mainQueue(),
            completionHandler: response)
    }
    
    func response(_: NSURLResponse!, data: NSData!, error: NSError!) {
        if (error != nil) {
            println("NSError in response: \(error)", __FUNCTION__, __LINE__)
            return
        }
        
        let json = JSON(data: data)
        for (_,item):(String, JSON) in json["items"] {
            if var video: Video = createVideo(item) {
                queue.append(video.id)
                videoList[video.id] = video
            } else {
                continue
            }
        }
        
        // TODO Fetch other pages
    }
    
    enum Quality: String {
        case Default   = "default"
        case Medium    = "medium"
        case High      = "high"
        case Standard  = "standard"
    }
    
    let quality = Quality.Default.rawValue
    
    private func createVideo(item: JSON) -> Video? {
        if let videoID: String = item["contentDetails", "upload", "videoId"].string {
            let thumbnail = Thumbnail(
                url:    item["thumbnails", quality, "url"].stringValue,
                width:  item["thumbnails", quality, "width"].intValue,
                height: item["thumbnails", quality, "height"].intValue)
            return Video(
                id:             videoID,
                title:          item["snippet", "title"].stringValue,
                description:    item["snippet", "description"].stringValue,
                thumbnail:      thumbnail)
        } else {
            println("Video ID not found")
            return nil
        }
    }
}
