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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int  {
        var count = ChannelModel.sharedInstance.queue.count
        return (count > 0) ? count : 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("VideoTable", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel!.text = "textLabel #\(indexPath.row)"
        return cell
    }

    let playerParams = [
        "playsinline":      1,  // TODO: Remember last settings
        "controls":         1,
        "cc_load_policy":   1,
        "showinfo":         0,
        "modestbranding":   0,
    ]
    var playerReady = false;
    
    @IBOutlet weak var videoPlayer: YTPlayerView!
    @IBOutlet weak var videoTable: UITableView!
    
    @IBAction func nextVideo(sender: UIBarButtonItem) {
        playNextVideo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "VideoTable")
        videoTable.dataSource = self
        videoTable.delegate = self
        
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
        ChannelModel.sharedInstance.removeObserver(self, forKeyPath: "queue")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if (keyPath == "queue" && playerReady) {
        }
    }
    
    private func playNextVideo() {
        let videoId: String? = ChannelModel.sharedInstance.nextVideoId()
        if (videoId != nil) {
            videoPlayer.loadVideoById(
                videoId, startSeconds: 0, suggestedQuality: YTPlaybackQuality.Default)
        } else {
            println("No VideoID yet")
        }
    }
    
    // MARK: -
    // MARK: YTPlayerViewDelegate
    func playerViewDidBecomeReady(playerView: YTPlayerView!) {
        println("playerViewDidBecomeReady")
        playerReady = true
        playNextVideo()
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToState state: YTPlayerState) {
        switch state {
        case YTPlayerState.Unstarted:
            println("didChangeToState: Unstarted")
        case YTPlayerState.Ended:
            println("didChangeToState: Ended")
            playNextVideo()
        case YTPlayerState.Playing:
            println("didChangeToState: Playing")
        case YTPlayerState.Paused:
            println("didChangeToState: Paused")
        case YTPlayerState.Buffering:
            println("didChangeToState: Buffering")
        case YTPlayerState.Queued:
            println("didChangeToState: Queued")
        default:
            println("didChangeToState: \(state.rawValue)")
        }
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToQuality quality: YTPlaybackQuality) {
        switch quality {
        case YTPlaybackQuality.Small:
            println("didChangeToQuality: Small")
        case YTPlaybackQuality.Medium:
            println("didChangeToQuality: Medium")
        case YTPlaybackQuality.Large:
            println("didChangeToQuality: Large")
        case YTPlaybackQuality.HD720:
            println("didChangeToQuality: HD720")
        case YTPlaybackQuality.HD1080:
            println("didChangeToQuality: HD1080")
        case YTPlaybackQuality.HighRes:
            println("didChangeToQuality: HighRes")
        case YTPlaybackQuality.Auto:
            println("didChangeToQuality: Auto")
        case YTPlaybackQuality.Default:
            println("didChangeToQuality: Default")
        default:
            println("didChangeToQuality: \(quality.rawValue)")
        }
    }
    
    func playerView(playerView: YTPlayerView!, receivedError error: YTPlayerError) {
        switch error {
        case YTPlayerError.InvalidParam:
            println("receivedError: InvalidParam")
        case YTPlayerError.HTML5Error:
            println("receivedError: HTML5Error")
        case YTPlayerError.VideoNotFound:
            println("receivedError: VideoNotFound")
        case YTPlayerError.VideoNotFound:
            println("receivedError: VideoNotFound")
        default:
            println("receivedError: \(error.rawValue)")
        }
    }
    
//    func playerView(playerView: YTPlayerView!, didPlayTime playTime: Float) {
//        println("didPlayTime: \(playTime)")
//    }
}

