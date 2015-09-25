//
//  ViewController.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/11/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import UIKit
import youtube_ios_player_helper

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, YTPlayerViewDelegate, VideoDetailControllerDelegate, LPRTableViewDelegate {
    
    let playerParams = [
        "playsinline":      1,  // TODO: Remember last settings
        "controls":         1,
        "cc_load_policy":   1,
        "showinfo":         0,
        "modestbranding":   1,
    ]
    let cellFixedHeight: CGFloat = 106
    let cellName = "VideoTableViewCell"
    let channelKey = "queue"
    let detailSegueKey = "showVideoDetail"
    var selectedIndex: Int?
    var refreshControl = UIRefreshControl()
    
    lazy private var loadingView:LoadingView = self.createLoadingView()
    
    @IBOutlet weak var videoPlayer: YTPlayerView!
    @IBOutlet weak var videoTable: LPRTableView!
    
    @IBAction func nextVideo(sender: UIBarButtonItem) {
        playNextVideo()
    }
    
    private func createLoadingView() -> LoadingView {
        let loadingView = LoadingView.instance().render() as LoadingView
        loadingView.center = view.center
        return loadingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(loadingView)
        videoPlayer.delegate = self
        videoPlayer.loadWithVideoId("", playerVars: playerParams)
        ChannelModel.sharedInstance.enqueue()
        initVideoTable()
        initRefreshControl()
    }
    
    override func viewWillAppear(animated: Bool) {
        videoTable.registerNib(
            UINib(nibName: cellName, bundle:nil), forCellReuseIdentifier:cellName)
        super.viewWillAppear(animated)
        ChannelModel.sharedInstance.addObserver(
            self, forKeyPath: channelKey, options: .New, context: nil)
    }
    
    override func viewDidDisappear(animated: Bool){
        super.viewDidDisappear(animated)
        ChannelModel.sharedInstance.removeObserver(self, forKeyPath: channelKey)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == channelKey) {
        }
    }
    
    func initVideoTable() {
        videoTable.dataSource = self
        videoTable.delegate = self
        videoTable.longPressReorderDelegate = self
    }
    
    func initRefreshControl() {
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        videoTable?.addSubview(refreshControl)
    }
    
    func refresh(sender:AnyObject)
    {
        print("refreshing")
        if self.refreshControl.refreshing
        {
            self.refreshControl.endRefreshing()
            print("refreshed")
        }
    }
    
    private func playCurrentVideo() {
        if let video: Video = ChannelModel.sharedInstance.currentVideo() {
            videoPlayer.loadVideoById(
                video.id, startSeconds: 0, suggestedQuality: YTPlaybackQuality.Default)
            navigationItem.titleView = createTitleLabel(video.title)
        } else {
            print("No VideoID yet")
        }
    }
    
    private func playNextVideo() {
        if let video: Video = ChannelModel.sharedInstance.nextVideo() {
            videoPlayer.loadVideoById(
                video.id, startSeconds: 0, suggestedQuality: YTPlaybackQuality.Default)
            navigationItem.titleView = createTitleLabel(video.title)
        } else {
            print("No VideoID yet")
        }
    }
    
    private func createTitleLabel(text: String) -> UILabel {
        let label = UILabel.init()
        label.font = UIFont.systemFontOfSize(10)
        label.text = text
        label.sizeToFit()
        return label
    }
    
    private func reloadTable() {
        ChannelModel.sharedInstance.updateCurrentNumberOfRows()
        videoTable.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == detailSegueKey && selectedIndex != nil) {
            let nav = segue.destinationViewController as! UINavigationController
            let detail: VideoDetailViewController = nav.topViewController as! VideoDetailViewController
            detail.delegate = self
            detail.originalIndex = selectedIndex!
            detail.video = ChannelModel.sharedInstance.getVideoByIndex(selectedIndex!)
        }
    }
    
    // MARK: -
    // MARK VideoDetailControllerDelegate
    func execute(command: VideoDetailViewController.Command) {
        switch command {
        case VideoDetailViewController.Command.PlayNextVideo:
            playNextVideo()
        case VideoDetailViewController.Command.ReloadTable:
            reloadTable()
        default:
            print("command[\(command)]")
            break
        }
    }
    
    func execute(_: VideoDetailViewController.Command, targetCellIndex: Int) {
        let path = NSIndexPath.init(forRow: targetCellIndex, inSection: 0)
        if let cell = videoTable.cellForRowAtIndexPath(path) as? VideoTableViewCell {
            blinkCell(cell, targetColor: UIColor.lightGrayColor())
        } else {
            print("Cell index[\(targetCellIndex)] is not visible")
        }
    }
    
    private func blinkCell(cell: UITableViewCell, targetColor: UIColor, count: Int = 1) {
        let color = count % 2 == 0 ? UIColor.whiteColor() : targetColor
        UIView.animateWithDuration(0.6, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            cell.backgroundColor = color
            }, completion: { _ in
                if count > 0 {
                    self.blinkCell(cell, targetColor: targetColor, count: count - 1)
                }
        })
    }
    
    // MARK: -
    // MARK UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (videoTable.contentOffset.y >= (videoTable.contentSize.height - videoTable.bounds.size.height))
        {
            reloadTable()
        }
    }
    
    // MARK: -
    // MARK LPRTableViewDelegate
    // Called within an animation block when the dragging view is about to show.
    func tableView(tableView: UITableView, showDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
        ChannelModel.sharedInstance.updatingAvailable = false
    }
    
    // Called within an animation block when the dragging view is about to hide.
    func tableView(tableView: UITableView, hideDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
        ChannelModel.sharedInstance.updatingAvailable = true
    }
    
    // MARK: -
    // MARK UITableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int  {
        return ChannelModel.sharedInstance.currentNumberOfRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        return initVideoCell(indexPath).render(indexPath.row)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellFixedHeight
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        ChannelModel.sharedInstance.doDataSourceSafely({() -> Void in
            if nil != ChannelModel.sharedInstance.removeVideoByIndex(indexPath.row) {
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)],
                    withRowAnimation: UITableViewRowAnimation.Fade)
            } else {
                print("Failed to remove video from list")
            }
        })
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        ChannelModel.sharedInstance.doDataSourceSafely({() -> Void in
            self.videoTable.reloadData()
            ChannelModel.sharedInstance.moveVideoByIndex(sourceIndexPath.row, destinationIndex: destinationIndexPath.row)
        })
    }
    
    func initVideoCell(indexPath: NSIndexPath) -> VideoTableViewCell {
        return videoTable.dequeueReusableCellWithIdentifier(
            cellName, forIndexPath: indexPath) as! VideoTableViewCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        performSegueWithIdentifier(detailSegueKey, sender: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    // MARK: -
    // MARK: YTPlayerViewDelegate
    func playerViewDidBecomeReady(playerView: YTPlayerView!) {
        print("playerViewDidBecomeReady")
        // FIXME: Not proper timing
        reloadTable()
        playCurrentVideo()
        UIView.animateWithDuration(0.8, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.loadingView.alpha = 0
            }, completion: { _ in
                self.loadingView.removeFromSuperview()
        })
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

