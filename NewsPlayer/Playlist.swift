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
        static let MaxQueueLength = 1000
    }
    
    dynamic var queue: [String] = []
    var videoList: [String: Video] = [:]
    var currentIndex: Int = 0
    var latestEtags: [String: String] = [:]
    var updatingAvailable: Bool = true
    var waitingList: [Video] = []
    var currentNumberOfRows: Int = 0
    var activityApi: ActivityApi
    var videoApi: VideoApi
    
    var delegate: PlaylistRefresher? = nil
    var finishedCount: Int = 0
    
    init(session: NSURLSession = NSURLSession.sharedSession()) {
        self.activityApi = ActivityApi(session: session)
        self.videoApi = VideoApi(session: session)
        super.init()
    }
    
    func enqueue() {
        let channels = Channel.localizedList()
        for channel in channels {
            fetchActivity(channel, handler: fetchVideos)
        }
    }
    
    func refrashChannels() {
        let channels = Channel.localizedList()
        finishedCount = channels.count
        for channel in channels {
            activityApi.resume(channel, handler: insertVideos)
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
        Logger.log?.debug("currentVideo[\(currentIndex)]")
        return getVideoByIndex(currentIndex)
    }
    
    func updateCurrentNumberOfRows() -> Int {
        currentNumberOfRows = queue.count
        Logger.log?.debug("currentNumberOfRows[\(currentNumberOfRows)]")
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
            Logger.log?.info("Out of index[\(index)] against \(queue.count)")
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
            Logger.log?.info("Out of index[\(atIndex)] against \(queue.count) ")
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
            Logger.log?.info("Ignored newVideo[\(newVideo.id)] while table manupulating")
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
    
    func fetchActivity(channel: Channel, pageToken: String = "", handler: NSURLSession.CompletionHandler) {
        if Const.MaxQueueLength <= queue.count || Const.MaxQueueLength <= waitingList.count {
            Logger.log?.debug("Queue count reached max length [\(Const.MaxQueueLength)]")
            return
        }
        return activityApi.resume(channel, pageToken: pageToken, handler: handler)
    }
    
    func finish() {
        finishedCount -= 1
        if finishedCount <= 0 {
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.endRefreshing()
            })
        }
    }
    
    func parseJson(data: NSData?, error: NSError?) -> JSON? {
        if (error != nil) {
            Logger.log?.warning("NSError in response: \(error)")
            return nil
        }
        if (nil == data) {
            Logger.log?.warning("NSData is nil")
            return nil
        }
        
        let json = JSON(data: data!)
        if json.isEmpty || !json["error"].isEmpty {
            Logger.log?.error("Empty data. Check Credentials.plist's `Google API Key` is valid.")
            return nil
        }
        return json
    }
    
    func insertVideos(data: NSData?, _: NSURLResponse?, error: NSError?) {
        guard let activityJson = parseJson(data, error: error) else { return }
        if isLatest(activityJson) {
            finish()
            return
        }
        exctractEmbeddableVideos(activityJson["items"]) { (items:[JSON]) in
            items.forEach {(item: JSON) in
                if let video: Video = self.createVideo(item) {
                    self.insertVideo(video, atIndex: self.currentIndex + 1)
                }
            }
        }
        finish()
    }
    
    func fetchVideos(data: NSData?, _: NSURLResponse?, error: NSError?) {
        guard let activityJson = parseJson(data, error: error) else { return }
        if isLatest(activityJson) {
            // TODO Check all channels and notify to user
            return
        }
        exctractEmbeddableVideos(activityJson["items"]) { (items:[JSON]) in
            items.forEach {(item: JSON) in
                if let video: Video = self.createVideo(item) {
                    self.appendVideo(video)
                }
            }
        }
        fetchNextPage(activityJson)
    }
    
    func exctractEmbeddableVideos(originalItems: JSON, callBack: (items: [JSON]) -> Void) {
        let ids = retreiveVideoIds(originalItems)
        videoApi.resume(ids) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            guard let json = self.parseJson(data, error: error) else { return }
            let embeddables: [JSON] = json["items"].flatMap { (_:String, item:JSON) -> JSON in
                if let embeddable: Bool = item["status", "embeddable"].bool where embeddable == true {
                    return item
                }
                return nil
            }
            callBack(items: embeddables)
        }
    }
    
    func retreiveVideoIds(items: JSON) -> [String] {
        return items.flatMap { (_:String, item: JSON) in
            item["contentDetails", "upload", "videoId"].string
        }
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
            Logger.log?.info("No updates for channelID[\(channelID)]")
            return true
        } else {
            latestEtags.updateValue(etag, forKey: channelID)
            return false
        }
    }
    
    private func createVideo(item: JSON) -> Video? {
        guard let videoId = item["id"].string else {
            return nil
        }
        return Video(id: videoId, item: item)
    }
    
    private func fetchNextPage(activityJson: JSON) {
        guard let channelId = activityJson["items", 0, "snippet", "channelId"].string else {
            Logger.log?.warning("Failed to retrieve channelId")
            return
        }
        guard let nextPageToken = activityJson["nextPageToken"].string else {
            Logger.log?.debug("Chennel[\(channelId)]: Completed to fetch all pages")
            return
        }
        fetchActivity(Channel.init(id: channelId), pageToken: nextPageToken, handler: fetchVideos)
    }
}
