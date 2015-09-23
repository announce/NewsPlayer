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
    
    let activityUrl = "https://www.googleapis.com/youtube/v3/activities"
    
    dynamic var queue: [String] = []
    var videoList: [String: Video?] = ["": nil]
    var currentIndex: Int = 0
    
    func enqueue(){
        let channels: [String] = channelList()
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
        print("currentVideo[\(currentIndex)]")
        return getVideoByIndex(currentIndex)
    }
    
    func getVideoByIndex(index: Int) -> Video? {
        if (queue.count > 0) {
            let videoID: String = queue[index]
            if let video: Video? = videoList[videoID] {
                return video
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func removeVideoByIndex(index: Int) -> Video? {
        // Remove from queue first to avoid accessing nil videoList value by observed queue's index
        let videoID: String = queue.removeAtIndex(index)
        if let removedVideo: Video? = videoList.removeValueForKey(videoID) {
            // Adjust playing video
            if index <= currentIndex {
                currentIndex--
            }
            return removedVideo
        } else {
            print("\(__FUNCTION__) -> nil")
            return nil
        }
    }
    
    func insertVideo(newVideo: Video, index: Int) -> Video? {
        if index <= queue.count {
            // Adjust playing video
            if index <= currentIndex {
                currentIndex++
            }
            // Insert video to videoList first
            // to avoid accessing nil videoList value by observed queue's index
            videoList[newVideo.id] = newVideo
            queue.insert(newVideo.id, atIndex: index)
            return newVideo
        } else {
            print("\(__FUNCTION__) -> nil")
            return nil
        }
    }
    
    func appendVideo(newVideo: Video) {
        queue.append(newVideo.id)
        videoList[newVideo.id] = newVideo
    }
    
    func moveVideoByIndex(sourceIndex: Int, destinationIndex: Int) -> Video? {
        let originalIndex = currentIndex
        if let removedVideo = removeVideoByIndex(sourceIndex) {
            let video = insertVideo(removedVideo, index: destinationIndex)
            // Adjust playing video
            currentIndex = (originalIndex == sourceIndex) ? destinationIndex : currentIndex
            return video
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
    
    func fetchActivities(channelID channelID: String) {
        let apiKey: String = Credential(key: "Google API Key").apiKey
        let part = "snippet,contentDetails"
        let request = NSURLRequest(URL: NSURL(
            string: "\(activityUrl)?part=\(part)&channelId=\(channelID)&key=\(apiKey)")!)
        NSURLConnection.sendAsynchronousRequest(request,
            queue: NSOperationQueue.mainQueue(),
            completionHandler: response)
    }
    
    func response(_: NSURLResponse?, data: NSData?, error: NSError?) {
        if (error != nil) {
            print("NSError in response: \(error)", __FUNCTION__, __LINE__)
            return
        }
        if (nil == data) {
            print("NSData is nil", __FUNCTION__, __LINE__)
            return
        }
        
        let json = JSON(data: data!)
        for (_,item):(String, JSON) in json["items"] {
            if let video: Video = createVideo(item) {
                appendVideo(video)
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
            let thumbnail = Video.Thumbnail(
                url:    item["snippet", "thumbnails", quality, "url"].stringValue,
                width:  item["snippet", "thumbnails", quality, "width"].intValue,
                height: item["snippet", "thumbnails", quality, "height"].intValue)
            return Video(
                id:             videoID,
                title:          item["snippet", "title"].stringValue,
                description:    item["snippet", "description"].stringValue,
                thumbnail:      thumbnail)
        } else {
            print("Video ID not found")
            return nil
        }
    }
}
