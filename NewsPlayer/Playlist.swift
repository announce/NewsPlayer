//
//  Playlist.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/16/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import Foundation
import SwiftyJSON

class Playlist : NSObject {
    
    class var sharedInstance: Playlist {
        struct Singleton {
            static let instance: Playlist = Playlist()
        }
        return Singleton.instance
    }
    
    struct Const {
        static let Max = 2000
    }
    let activityUrl = "https://www.googleapis.com/youtube/v3/activities"
    let session: NSURLSession
    
    dynamic var queue: [String] = []
    var videoList: [String: Video] = [:]
    var currentIndex: Int = 0
    var latestEtags: [String: String] = [:]
    var updatingAvailable: Bool = true
    var waitingList: [Video] = []
    var currentNumberOfRows: Int = 0
    
    var delegate: PlaylistRefresher? = nil
    var finishedCount: Int = 0
    
    init(session: NSURLSession = NSURLSession.sharedSession()) {
        self.session = session
        super.init()
    }

    func enqueue() {
        let channels = Channel.localizedList()
        for channel in channels {
            fetchActivities(channel)
        }
    }
    
    func refrashChannels() {
        let channels = Channel.localizedList()
        finishedCount = channels.count
        for channel in channels {
            refreshActivities(channel)
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
        guard let videoID: String = queue.remove(index: index) else {
            return nil
        }
        guard let removedVideo: Video? = videoList.removeValueForKey(videoID) else {
            return nil
        }
        // Adjust playing video
        if index <= currentIndex {
            currentIndex -= 1
        }
        currentNumberOfRows -= 1
        return removedVideo
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
        guard let removedVideo = removeVideoByIndex(sourceIndex) else {
            return nil
        }
        let video = insertVideo(removedVideo, index: destinationIndex)
        // Adjust playing video
        currentIndex = (originalIndex == sourceIndex) ? destinationIndex : currentIndex
        return video
    }
    
    func fetchActivities(channel: Channel, pageToken: String = "") {
        if Const.Max <= queue.count || Const.Max <= waitingList.count {
            print("Queue count reached Const.Max[\(Const.Max)]")
            return
        }
        
        session.dataTaskWithURL(
            createActivityRequest(channel, pageToken: pageToken),
            completionHandler: appendVideos).resume()
    }
    
    func refreshActivities(channel: Channel, pageToken: String = "") {
        session.dataTaskWithURL(
            createActivityRequest(channel, pageToken: pageToken),
            completionHandler: insertVideos).resume()
    }
    
    func createActivityRequest(channel: Channel, pageToken: String) -> NSURL {
        let apiKey: String = Credential(key: Credential.Provider.Google).apiKey
        let part = "snippet,contentDetails"
        return NSURL(string: "\(activityUrl)?part=\(part)&channelId=\(channel.id)&pageToken=\(pageToken)&key=\(apiKey)")!
    }
    
    func finish() {
        finishedCount -= 1
        if finishedCount <= 0 {
            delegate?.endRefreshing()
        }
    }
    
    func insertVideos(data: NSData?, _: NSURLResponse?, error: NSError?) {
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
    
    func appendVideos(data: NSData?, _: NSURLResponse?, error: NSError?) {
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
    
    private func createVideo(item: JSON) -> Video? {
        guard let videoId = item["contentDetails", "upload", "videoId"].string else {
            return nil
        }
        return Video(id: videoId, item: item)
    }
    
    private func fetchNextPage(json: JSON) {
        guard let channelId = json["items", 0, "snippet", "channelId"].string else {
            return
        }
        guard let nextPageToken = json["nextPageToken"].string else {
            return print("Chennel[\(channelId)]: Completed to fetch all pages")
        }
        fetchActivities(Channel.init(id: channelId), pageToken: nextPageToken)
    }
}
