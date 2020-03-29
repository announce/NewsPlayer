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
    
    @objc dynamic var queue: [String] = []
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
    
    init(session: URLSession = URLSession.shared) {
        self.activityApi = ActivityApi(session: session)
        self.videoApi = VideoApi(session: session)
        super.init()
    }
    
    func enqueue() {
        let channels = Channel.localizedList()
        for channel in channels {
            fetchActivity(channel: channel, handler: fetchVideos)
        }
    }
    
    func refrashChannels() {
        let channels = Channel.localizedList()
        finishedCount = channels.count
        for channel in channels {
            activityApi.resume(channel: channel, handler: insertVideos)
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
        return getVideoByIndex(index: currentIndex)
    }
    
    func updateCurrentNumberOfRows() -> Int {
        currentNumberOfRows = queue.count
        Logger.log?.debug("currentNumberOfRows[\(currentNumberOfRows)]")
        return currentNumberOfRows
    }
    
    func getVideoByIndex(index: Int) -> Video? {
        if (queue.count > 0) {
            let videoID: String = queue[index]
            if let video: Video = videoList[videoID] {
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
        guard let removedVideo: Video = videoList.removeValue(forKey: videoID) else {
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
            queue.insert(newVideo.id, at: index)
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
            appendVideo(newVideo: video)
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
            queue.insert(newVideo.id, at: atIndex)
            videoList[newVideo.id] = newVideo
        } else {
            Logger.log?.info("Ignored newVideo[\(newVideo.id)] while table manupulating")
        }
    }
    
    func moveVideoByIndex(sourceIndex: Int, destinationIndex: Int) -> Video? {
        let originalIndex = currentIndex
        guard let removedVideo = removeVideoByIndex(index: sourceIndex) else {
            return nil
        }
        let video = insertVideo(newVideo: removedVideo, index: destinationIndex)
        // Adjust playing video
        currentIndex = (originalIndex == sourceIndex) ? destinationIndex : currentIndex
        return video
    }
    
    func fetchActivity(channel: Channel, pageToken: String = "", handler: @escaping URLSession.CompletionHandler) {
        if Const.MaxQueueLength <= queue.count || Const.MaxQueueLength <= waitingList.count {
            Logger.log?.debug("Queue count reached max length [\(Const.MaxQueueLength)]")
            return
        }
        return activityApi.resume(channel: channel, pageToken: pageToken, handler: handler)
    }
    
    func finish() {
        finishedCount -= 1
        if finishedCount <= 0 {
            DispatchQueue.main.async {
                self.delegate?.endRefreshing()
            }
        }
    }
    
    func parseJson(data: Data?, error: Error?) -> JSON? {
//        Logger.log?.info("parseJson\(String(describing: data))")
        if (error != nil) {
            Logger.log?.warning("Error in response: \(String(describing: error))")
            return nil
        }
        if (nil == data) {
            Logger.log?.warning("NSData is nil")
            return nil
        }
        do {
            let json = try JSON(data: data!)
            if json.isEmpty || json["error"].isEmpty {
                Logger.log?.error("Empty data. Check if Credentials.plist's `Google API Key` is valid.")
                return nil
            }
            return json
        } catch (let message) {
            Logger.log?.error("Failed to parse json \(message)")
        }
        return nil
    }
    
    func insertVideos(data: Data?, _: URLResponse?, error: Error?) {
        guard let activityJson = parseJson(data: data, error: error) else { return }
        if isLatest(json: activityJson) {
            finish()
            return
        }
        exctractEmbeddableVideos(originalItems: activityJson["items"]) { (items:[JSON]) in
            items.forEach {(item: JSON) in
                if let video: Video = self.createVideo(item: item) {
                    self.insertVideo(newVideo: video, atIndex: self.currentIndex + 1)
                }
            }
        }
        finish()
    }
    
    func fetchVideos(data: Data?, _: URLResponse?, error: Error?) {
        guard let activityJson = parseJson(data: data, error: error) else { return }
        if isLatest(json: activityJson) {
            // TODO Check all channels and notify to user
            return
        }
        exctractEmbeddableVideos(originalItems: activityJson["items"]) { (items:[JSON]) in
            items.forEach {(item: JSON) in
                if let video: Video = self.createVideo(item: item) {
                    self.appendVideo(newVideo: video)
                }
            }
        }
        fetchNextPage(activityJson: activityJson)
    }
    
    func exctractEmbeddableVideos(originalItems: JSON, callBack: @escaping (_: [JSON]) -> Void) {
        let ids = retreiveVideoIds(items: originalItems)
        videoApi.resume(ids: ids) { (data: Data?, response: URLResponse?, error: Error?) in
            guard let json = self.parseJson(data: data, error: error) else { return }
            let embeddables: [JSON?] = json["items"].compactMap { (_:String, item:JSON) -> JSON? in
                if let _: Bool = item["status", "embeddable"].bool {
                    return item
                }
                return nil
            }
            callBack(embeddables.compactMap{$0})
        }
    }
    
    func retreiveVideoIds(items: JSON) -> [String] {
        return items.compactMap { (_:String, item: JSON) in
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
        fetchActivity(channel: Channel.init(id: channelId), pageToken: nextPageToken, handler: fetchVideos)
    }
}
