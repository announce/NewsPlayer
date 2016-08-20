//
//  ChannelModel.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/16/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import Foundation
import SwiftyJSON


protocol ChannelResponseDelegate {
    func endRefreshing()
}

class ChannelModel : NSObject {
    
    class var sharedInstance: ChannelModel {
        struct Singleton {
            static let instance: ChannelModel = ChannelModel()
        }
        return Singleton.instance
    }
    
    struct Const {
        static let Max = 2000
    }
    let activityUrl = "https://www.googleapis.com/youtube/v3/activities"
    
    dynamic var queue: [String] = []
    var videoList: [String: Video] = [:]
    var currentIndex: Int = 0
    var latestEtags: [String: String] = [:]
    var updatingAvailable: Bool = true
    var waitingList: [Video] = []
    var currentNumberOfRows: Int = 0
    
    var delegate: ChannelResponseDelegate? = nil
    var finishedCount: Int = 0
    
    func enqueue() {
        let channels: [String] = channelList()
        for channelID in channels {
            fetchActivities(channelID)
        }
    }
    
    func refrashChannels() {
        let channels: [String] = channelList()
        finishedCount = channels.count
        for channelID in channels {
            refreshActivities(channelID)
        }
    }
    
    func nextVideo() -> Video? {
        if (queue.count > 0) {
            currentIndex += 1
            return currentVideo()
        } else {
            return nil
        }
    }
    
    func currentVideo() -> Video? {
        print("currentVideo[\(currentIndex)]")
        return getVideoByIndex(currentIndex)
    }
    
    func updateCurrentNumberOfRows() -> Int {
        currentNumberOfRows = queue.count
        print("currentNumberOfRows[\(currentNumberOfRows)]")
        return currentNumberOfRows
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
                currentIndex -= 1
            }
            currentNumberOfRows -= 1
            return removedVideo
        } else {
            print("\(#function) -> nil")
            return nil
        }
    }
    
    func insertVideo(newVideo: Video, index: Int) -> Video? {
        if index <= queue.count {
            // Adjust playing video
            if index <= currentIndex {
                currentIndex += 1
            }
            currentNumberOfRows += 1
            // Insert video to videoList first
            // to avoid accessing nil videoList value by observed queue's index
            videoList[newVideo.id] = newVideo
            queue.insert(newVideo.id, atIndex: index)
            return newVideo
        } else {
            print("\(#function) -> nil")
            return nil
        }
    }
    
    func doDataSourceSafely(closure: () -> Void) {
        let originalState = updatingAvailable
        updatingAvailable = false
        closure()
        updatingAvailable = originalState
        for video in waitingList {
            appendVideo(video)
        }
    }
    
    func appendVideo(newVideo: Video) {
        if (videoList[newVideo.id] == newVideo) {
            // newVideo is already in videoList
            return
        }
        if updatingAvailable {
            queue.append(newVideo.id)
            videoList[newVideo.id] = newVideo
        } else {
            waitingList.append(newVideo)
        }
    }
    
    func insertVideo(newVideo: Video, atIndex: Int) {
        if atIndex >= queue.count {
            print("\(#function) Invalid index \(queue.count) is smaller than \(atIndex)")
            return
        }
        if (videoList[newVideo.id] == newVideo) {
            // newVideo is already in videoList
            return
        }
        if updatingAvailable {
            queue.insert(newVideo.id, atIndex: atIndex)
            videoList[newVideo.id] = newVideo
        } else {
            print("\(#function) Ignored newVideo[\(newVideo.id)] while table manupulating")
        }
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
        var key = ""
        if let languageCode = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String {
            key = languageCode == "ja" ? "ja" : "en"
        } else {
            key = "en"
        }
        let channels:Array = registry!.objectForKey("Channels \(key)") as! [String]
        return channels;
    }
    
    func fetchActivities(channelID: String, pageToken: String = "") {
        if Const.Max <= queue.count || Const.Max <= waitingList.count {
            print("Queue count reached Const.Max[\(Const.Max)]")
            return
        }
        
        NSURLConnection.sendAsynchronousRequest(
            createActivityRequest(channelID, pageToken: pageToken),
            queue: NSOperationQueue.mainQueue(),
            completionHandler: appendVideos)
    }
    
    func refreshActivities(channelID: String, pageToken: String = "") {
        NSURLConnection.sendAsynchronousRequest(
            createActivityRequest(channelID, pageToken: pageToken),
            queue: NSOperationQueue.mainQueue(),
            completionHandler: insertVideos)
    }
    
    func createActivityRequest(channelID: String, pageToken: String) -> NSURLRequest {
        let apiKey: String = Credential(key: Credential.Provider.Google).apiKey
        let part = "snippet,contentDetails"
        return NSURLRequest(URL: NSURL(
            string: "\(activityUrl)?part=\(part)&channelId=\(channelID)&pageToken=\(pageToken)&key=\(apiKey)")!)
    }
    
    func finish() {
        finishedCount -= 1
        if finishedCount <= 0 {
            delegate?.endRefreshing()
        }
    }
    
    func insertVideos(_: NSURLResponse?, data: NSData?, error: NSError?) {
        if (error != nil) {
            print("\(#function) NSError in response: \(error)")
            return
        }
        if (nil == data) {
            print("\(#function) NSData is nil")
            return
        }
        
        let json = JSON(data: data!)
        
        if json.isEmpty || !json["error"].isEmpty {
            print("Unxecpected data. Check Credentials.plist's `Google API Key` is valid.")
            return
        }
        
        if isLatest(json) {
            finish()
            return
        }
        
        for (_,item):(String, JSON) in json["items"] {
            if let video: Video = createVideo(item) {
                insertVideo(video, atIndex: currentIndex + 1)
            } else {
                continue
            }
        }
        finish()
    }
    
    func appendVideos(_: NSURLResponse?, data: NSData?, error: NSError?) {
        if (error != nil) {
            print("\(#function) NSError in response: \(error)")
            return
        }
        if (nil == data) {
            print("\(#function) NSData is nil")
            return
        }
        
        let json = JSON(data: data!)
        if json.isEmpty || !json["error"].isEmpty {
            print("Empty data. Check Credentials.plist's `Google API Key` is valid.")
            return
        }
        if isLatest(json) {
            // TODO Check all channels and notify to user
            return
        }
        
        for (_,item):(String, JSON) in json["items"] {
            if let video: Video = createVideo(item) {
                appendVideo(video)
            } else {
                continue
            }
        }
        
        fetchNextPage(json)
    }
    
    private func isLatest(json: JSON) -> Bool {
        guard let channelID = json["items", 0, "snippet", "channelId"].string,
            let etag = json["etag"].string else {
                return false
        }
        
        if let _ = json["prevPageToken"].string {
            // Means not first page
            return false
        }
        
        if latestEtags[channelID] == etag {
            print("No updates for channelID[\(channelID)]")
            return true
        } else {
            latestEtags.updateValue(etag, forKey: channelID)
            return false
        }
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
            return nil
        }
    }
    
    private func fetchNextPage(json: JSON) {
        if let channelID = json["items", 0, "snippet", "channelId"].string,
            nextPageToken: String = json["nextPageToken"].string {
                fetchActivities(channelID, pageToken: nextPageToken)
        } else {
            let chennelID = json["items", 0, "snippet", "channelId"].stringValue
            print("ChennelID[\(chennelID)]: Completed to fetch all pages")
        }
    }
}
