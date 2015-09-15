//
//  ViewController.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/11/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import UIKit
import youtube_ios_player_helper

class ViewController: UIViewController, YTPlayerViewDelegate {
    
    @IBOutlet weak var videoPlayer: YTPlayerView!
    @IBAction func playVideo(sender: UIButton) {
        videoPlayer.playVideo()
    }
    @IBAction func stopVideo(sender: UIButton) {
        videoPlayer.pauseVideo()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayer.delegate = self
        videoPlayer.loadWithVideoId("LxaJMjFvnS8", playerVars: ["playsinline": 1])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func load(sender: UIBarButtonItem) {
        fetchData()
    }
    @IBAction func loadApi(sender: UIButton) {
        fetchData()
    }
    
    // MARK: -
    // MARK: YTPlayerViewDelegate
    func playerViewDidBecomeReady(playerView: YTPlayerView!) {
        println("playerViewDidBecomeReady")
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToState state: YTPlayerState) {
        println("didChangeToState: \(state)")
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToQuality quality: YTPlaybackQuality) {
        println("didChangeToQuality: \(quality)")
    }
    
    func playerView(playerView: YTPlayerView!, receivedError error: YTPlayerError) {
        println("receivedError: \(error)")
    }
    
    func playerView(playerView: YTPlayerView!, didPlayTime playTime: Float) {
        println("didPlayTime: \(playTime)")
    }
    
    // MARK: -
    func fetchData() {
        let credentialsPath = NSBundle.mainBundle().pathForResource("Credentials", ofType: "plist")
        let credentials = NSDictionary(contentsOfFile: credentialsPath!)
        
        let apiKey:String = credentials!.objectForKey("Google API Key") as! String
        let channelId = "UCGCZAYq5Xxojl_tSXcVJhiQ"
        let URL = NSURL(string: "https://www.googleapis.com/youtube/v3/activities?part=snippet%2CcontentDetails&channelId=\(channelId)&key=\(apiKey)")
        let req = NSURLRequest(URL: URL!)
        let connection: NSURLConnection = NSURLConnection(request: req, delegate: self, startImmediately: false)!
        
        NSURLConnection.sendAsynchronousRequest(req,
            queue: NSOperationQueue.mainQueue(),
            completionHandler: response)
    }
    
    func response(res: NSURLResponse!, data: NSData!, error: NSError!){
        // @todo Handle error
        let json:NSDictionary = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.AllowFragments, error: nil) as! NSDictionary
        
        let res:NSArray = json.objectForKey("items")as! NSArray
        
        for var i=0 ; i<res.count ; i++ {
            var snippet:NSDictionary = res[i].objectForKey("snippet") as! NSDictionary
            var title:String = snippet.objectForKey("title") as! String
            
            var contentDetails:NSDictionary = res[i].objectForKey("contentDetails") as! NSDictionary
            var video:NSDictionary = contentDetails.objectForKey("upload") as! NSDictionary
            var videoId:String = video.objectForKey("videoId") as! String
            println("Title:\(title), VideoID:\(videoId)")
        }
    }
    
}

