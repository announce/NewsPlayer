//
//  ViewController.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/11/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import UIKit
import youtube_ios_player_helper

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, YTPlayerViewDelegate {
    
    let playerParams = [
        "playsinline":      1,  // TODO: Remember last settings
        "controls":         1,
        "cc_load_policy":   1,
        "showinfo":         0,
        "modestbranding":   1,
    ]
    var playerReady = false;
    
    let cellName = "VideoTableViewCell"
    
    @IBOutlet weak var videoPlayer: YTPlayerView!
    @IBOutlet weak var videoTable: UITableView!
    
    @IBAction func nextVideo(sender: UIBarButtonItem) {
        playNextVideo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayer.delegate = self
        videoPlayer.loadWithVideoId("", playerVars: playerParams)
        ChannelModel.sharedInstance.addObserver(
            self, forKeyPath: "queue", options: .New, context: nil)
        ChannelModel.sharedInstance.enqueue()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool){
        super.viewDidDisappear(animated)
        playerReady = false
        ChannelModel.sharedInstance.removeObserver(self, forKeyPath: "queue")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "queue" && playerReady) {
        }
    }
    
    private func playNextVideo() {
        if let video: ChannelModel.Video = ChannelModel.sharedInstance.nextVideo() {
            videoPlayer.loadVideoById(
                video.id, startSeconds: 0, suggestedQuality: YTPlaybackQuality.Default)
        } else {
            print("No VideoID yet")
        }
    }
    
    // MARK: -
    // MARK UITableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int  {
        return ChannelModel.sharedInstance.queue.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        return initVideoCell(indexPath).render(indexPath.row)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if ChannelModel.sharedInstance.removeVideoByIndex(indexPath.row) {
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)],
                withRowAnimation: UITableViewRowAnimation.Fade)
        } else {
            print("Failed to remove video from list")
        }
    }
    
    func initVideoTable() {
//        videoTable.registerClass(VideoTableViewCell.self, forCellReuseIdentifier: cellName)
        videoTable.dataSource = self
        videoTable.delegate = self
        videoTable.editing = true
    }
    
    func initVideoCell(indexPath: NSIndexPath) -> VideoTableViewCell {
        videoTable.registerNib(UINib(nibName: cellName, bundle:nil), forCellReuseIdentifier:cellName)
        return videoTable.dequeueReusableCellWithIdentifier(
            cellName, forIndexPath: indexPath) as! VideoTableViewCell
    }
    
    // MARK: -
    // MARK: YTPlayerViewDelegate
    func playerViewDidBecomeReady(playerView: YTPlayerView!) {
        print("playerViewDidBecomeReady")
        playerReady = true
        initVideoTable()
        
        playNextVideo()
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToState state: YTPlayerState) {
        switch state {
        case YTPlayerState.Unstarted:
            print("didChangeToState: Unstarted")
        case YTPlayerState.Ended:
            print("didChangeToState: Ended")
            playNextVideo()
        case YTPlayerState.Playing:
            print("didChangeToState: Playing")
        case YTPlayerState.Paused:
            print("didChangeToState: Paused")
        case YTPlayerState.Buffering:
            print("didChangeToState: Buffering")
        case YTPlayerState.Queued:
            print("didChangeToState: Queued")
        default:
            print("didChangeToState: \(state.rawValue)")
        }
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToQuality quality: YTPlaybackQuality) {
        switch quality {
        case YTPlaybackQuality.Small:
            print("didChangeToQuality: Small")
        case YTPlaybackQuality.Medium:
            print("didChangeToQuality: Medium")
        case YTPlaybackQuality.Large:
            print("didChangeToQuality: Large")
        case YTPlaybackQuality.HD720:
            print("didChangeToQuality: HD720")
        case YTPlaybackQuality.HD1080:
            print("didChangeToQuality: HD1080")
        case YTPlaybackQuality.HighRes:
            print("didChangeToQuality: HighRes")
        case YTPlaybackQuality.Auto:
            print("didChangeToQuality: Auto")
        case YTPlaybackQuality.Default:
            print("didChangeToQuality: Default")
        default:
            print("didChangeToQuality: \(quality.rawValue)")
        }
    }
    
    func playerView(playerView: YTPlayerView!, receivedError error: YTPlayerError) {
        switch error {
        case YTPlayerError.InvalidParam:
            print("receivedError: InvalidParam")
        case YTPlayerError.HTML5Error:
            print("receivedError: HTML5Error")
        case YTPlayerError.VideoNotFound:
            print("receivedError: VideoNotFound")
        case YTPlayerError.Unknown:
            print("receivedError: Unknown")
        default:
            print("receivedError: \(error.rawValue)")
        }
    }
    
//    func playerView(playerView: YTPlayerView!, didPlayTime playTime: Float) {
//        println("didPlayTime: \(playTime)")
//    }
}

