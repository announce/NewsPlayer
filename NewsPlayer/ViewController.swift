//
//  ViewController.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/11/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import UIKit
import youtube_ios_player_helper
import ReachabilitySwift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, YTPlayerViewDelegate, LPRTableViewDelegate, VideoDetailControllerDelegate, PlaylistRefresher {
    
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
    let reachability = Reachability.reachabilityForInternetConnection()
    var selectedIndex: Int?
    var refreshControl = UIRefreshControl()
    
    lazy private var loadingView:LoadingView = self.createLoadingView()
    
    @IBOutlet weak var videoPlayer: YTPlayerView!
    @IBOutlet weak var videoTable: LPRTableView!
    @IBOutlet weak var videoToolBar: UIToolbar!

    @IBAction func playOrPause(sender: UIBarButtonItem) {
        guard (videoPlayer != nil) else {
            return
        }
        switch videoPlayer.playerState() {
        case .Playing:
            videoPlayer.pauseVideo()
        case .Paused:
            videoPlayer.playVideo()
        default:
            break
        }
    }
    @IBAction func rewindVideo(sender: UIBarButtonItem) {
        let currentTime = videoPlayer?.currentTime() ?? 0
        videoPlayer?.seekToSeconds(currentTime + 10, allowSeekAhead: true)
    }
    @IBAction func forwardVideo(sender: UIBarButtonItem) {
        let currentTime = videoPlayer?.currentTime() ?? 0
        videoPlayer?.seekToSeconds(currentTime - 10, allowSeekAhead: true)
    }
    @IBAction func playNextVideo(sender: UIBarButtonItem) {
        playNextVideo()
    }
    
    private func createLoadingView() -> LoadingView {
        let loadingView = LoadingView.instance().render() as LoadingView
        loadingView.center = view.center
        loadingView.frame = view.bounds
        return loadingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(loadingView)
        videoPlayer.delegate = self
        videoPlayer.loadWithVideoId("", playerVars: playerParams)
        Playlist.sharedInstance.enqueue()
        Playlist.sharedInstance.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: false)
        initVideoTable()
        initRefreshControl()
        reachability?.whenReachable = { reachability in
            self.updateLabelColourWhenReachable(reachability)
        }
        reachability?.whenUnreachable = { reachability in
            self.updateLabelColourWhenNotReachable(reachability)
        }
        reachability?.startNotifier()
        checkNetwork()
    }
    
    override func viewWillAppear(animated: Bool) {
        videoTable.registerNib(
            UINib(nibName: cellName, bundle:nil), forCellReuseIdentifier:cellName)
        super.viewWillAppear(animated)
        Playlist.sharedInstance.addObserver(
            self, forKeyPath: channelKey, options: .New, context: nil)
    }
    
    override func viewDidDisappear(animated: Bool){
        super.viewDidDisappear(animated)
        Playlist.sharedInstance.removeObserver(self, forKeyPath: channelKey)
        reachability?.stopNotifier()
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
    
    func checkNetwork() {
        guard let networkState = reachability else {
            return
        }
        if networkState.isReachable() {
            updateLabelColourWhenReachable(networkState)
        } else {
            updateLabelColourWhenNotReachable(networkState)
        }
    }
    
    func initRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refresh), forControlEvents: UIControlEvents.ValueChanged)
        videoTable?.addSubview(refreshControl)
    }
    
    func refresh(sender: AnyObject)
    {
        Playlist.sharedInstance.refrashChannels()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        let isPortrait: Bool  = UIDevice.currentDevice().orientation.isPortrait
        videoTable?.hidden = !isPortrait
        videoToolBar?.hidden = !isPortrait
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    
    // MARK: -
    // MARK ChannelResponseDelegate
    func endRefreshing() {
        if refreshControl.refreshing
        {
            refreshControl.endRefreshing()
            reloadTable()
            let path = NSIndexPath.init(
                forRow: Playlist.sharedInstance.currentIndex, inSection: 0)
            videoTable?.scrollToRowAtIndexPath(path, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            // TODO Blink
        }
    }
    
    // MARK: -
    // MARK Reachability
    func updateLabelColourWhenReachable(reachability: Reachability) {
    }
    
    func updateLabelColourWhenNotReachable(reachability: Reachability) {
        alertNoNetworkConnection()
    }
    
    func reachabilityChanged(note: NSNotification) {
        guard let reachability = note.object as? Reachability else {
            Logger.log?.warning("Reachability is nil")
            return
        }
        if reachability.isReachable() {
            Logger.log?.info("\(videoPlayer.playerState())")
            if Playlist.sharedInstance.queue.count <= 0 {
                Playlist.sharedInstance.enqueue()
            }
            if videoPlayer.playerState() != YTPlayerState.Playing {
                playerViewDidBecomeReady(videoPlayer)
            }
            updateLabelColourWhenReachable(reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability)
        }
    }
    
    private func alertNoNetworkConnection()
    {
        let alertController = UIAlertController(title: "Network not found", message: "Is this device connected to Internet?", preferredStyle: .Alert)
        
        let defaultAction = UIAlertAction(title: "Check it again", style: .Default, handler: {(_: UIAlertAction) in self.checkNetwork()})
        alertController.addAction(defaultAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: -
    private func playCurrentVideo(startAt: Float = 0) {
        if let video: Video = Playlist.sharedInstance.currentVideo() {
            videoPlayer.loadVideoById(
                video.id, startSeconds: startAt, suggestedQuality: YTPlaybackQuality.Default)
            navigationItem.titleView = createTitleLabel(video.title)
            showPlayingIndicator(Playlist.sharedInstance.currentIndex)
            removeIndicator(Playlist.sharedInstance.currentIndex - 1)
        } else {
            Logger.log?.debug("No VideoID yet")
        }
    }
    
    private func playNextVideo() {
        if let video: Video = Playlist.sharedInstance.nextVideo() {
            videoPlayer.loadVideoById(
                video.id, startSeconds: 0, suggestedQuality: YTPlaybackQuality.Default)
            navigationItem.titleView = createTitleLabel(video.title)
            showPlayingIndicator(Playlist.sharedInstance.currentIndex)
            removeIndicator(Playlist.sharedInstance.currentIndex - 1)
        } else {
            Logger.log?.debug("No VideoID yet")
        }
    }
    
    private func showPlayingIndicator(targetIndex: Int) {
        let path = NSIndexPath.init(forRow: targetIndex, inSection: 0)
        if let cell = videoTable.cellForRowAtIndexPath(path) as? VideoTableViewCell {
            cell.addPlayingIndicator()
        } else {
            Logger.log?.debug("No cell index[\(targetIndex)]")
        }
    }
    
    private func removeIndicator(targetIndex: Int) {
        if targetIndex < 0 {
            return
        }
        let path = NSIndexPath.init(forRow: targetIndex, inSection: 0)
        if let cell = videoTable.cellForRowAtIndexPath(path) as? VideoTableViewCell {
            cell.removeAllIndicator()
        } else {
            Logger.log?.debug("No cell index[\(targetIndex)]")
        }
    }
    
    private func changePlayingAnimation(targetIndex: Int, start: Bool) {
        let path = NSIndexPath.init(forRow: targetIndex, inSection: 0)
        if let cell = videoTable.cellForRowAtIndexPath(path) as? VideoTableViewCell {
            start ? cell.startPlayingAnimation() : cell.stopPlayingAnimation()
        }
    }
    
    private func createTitleLabel(text: String) -> UILabel {
        let label = UILabel.init()
        label.font = UIFont.systemFontOfSize(10)
        label.text = text
        label.sizeToFit()
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleTapped)))
        label.userInteractionEnabled = true
        return label
    }
    
    func titleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let path = NSIndexPath.init(
            forRow: Playlist.sharedInstance.currentIndex, inSection: 0)
        videoTable?.scrollToRowAtIndexPath(path, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
    }
    
    private func reloadTable() {
        Playlist.sharedInstance.updateCurrentNumberOfRows()
        videoTable.reloadData()
    }
    
    private func deleteRow(indexPath: NSIndexPath, tableView: UITableView) {
        Playlist.sharedInstance.doDataSourceSafely({() -> Void in
            if nil != Playlist.sharedInstance.removeVideoByIndex(indexPath.row) {
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)],
                    withRowAnimation: UITableViewRowAnimation.Fade)
            } else {
                Logger.log?.debug("Failed to remove video from list")
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == detailSegueKey && selectedIndex != nil) {
            let nav = segue.destinationViewController as! UINavigationController
            let detail: VideoDetailViewController = nav.topViewController as! VideoDetailViewController
            detail.delegate = self
            detail.originalIndex = selectedIndex!
            detail.video = Playlist.sharedInstance.getVideoByIndex(selectedIndex!)
        }
    }
    
    // MARK: -
    // MARK VideoDetailControllerDelegate
    func execute(command: VideoDetailViewController.Command, targetCellIndex: Int) {
        let path = NSIndexPath.init(forRow: targetCellIndex, inSection: 0)
        switch command {
        case .PlayNext:
            cueToNext(path)
        case .PlayNow:
            playNow(path)
        default:
            Logger.log?.info("Ignoring command[\(command)]")
            break
        }
    }
    
    func cueToNext(path: NSIndexPath) {
        let currentIndex = Playlist.sharedInstance.currentIndex
        if path.row != currentIndex {
            moveUpToNext(path)
            reloadTable()
        }
        let blinkPath = NSIndexPath.init(forRow: Playlist.sharedInstance.currentIndex + 1, inSection: 0)
        guard let cell = videoTable.cellForRowAtIndexPath(blinkPath) as? VideoTableViewCell else {
            Logger.log?.info("No cell index[\(blinkPath.row)]")
            return
        }
        blinkCell(cell, originalColor: cell.backgroundColor, targetColor: UIColor.lightGrayColor())
    }
    
    func playNow(path: NSIndexPath) {
        let isPlayingCell = path.row == Playlist.sharedInstance.currentIndex
        cueToNext(path)
        if !isPlayingCell {
            playNextVideo()
        }
    }
    
    func moveUpToNext(originalPath: NSIndexPath) {
        var targetIndex = Playlist.sharedInstance.currentIndex
        if targetIndex < originalPath.row {
            targetIndex += 1
        }
        Playlist.sharedInstance.moveVideoByIndex(
            originalPath.row, destinationIndex: targetIndex)
    }
    
    private func blinkCell(cell: UITableViewCell, originalColor: UIColor?, targetColor: UIColor, count: Int = 1) {
        let color = count % 2 == 0 ? originalColor : targetColor
        UIView.animateWithDuration(0.6, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            cell.backgroundColor = color
            }, completion: { _ in
                if count > 0 {
                    self.blinkCell(cell, originalColor: originalColor, targetColor: targetColor, count: count - 1)
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
        Playlist.sharedInstance.updatingAvailable = false
        showPlayingIndicator(indexPath.row)
    }
    
    // Called within an animation block when the dragging view is about to hide.
    func tableView(tableView: UITableView, hideDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
        Playlist.sharedInstance.updatingAvailable = true
        removeIndicator(indexPath.row)
    }
    
    // MARK: -
    // MARK UITableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int  {
        return Playlist.sharedInstance.currentNumberOfRows
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
        if editingStyle == UITableViewCellEditingStyle.Delete {
            deleteRow(indexPath, tableView: tableView)
        }
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        Playlist.sharedInstance.doDataSourceSafely({() -> Void in
            self.videoTable.reloadData()
            Playlist.sharedInstance.moveVideoByIndex(sourceIndexPath.row, destinationIndex: destinationIndexPath.row)
        })
    }
    
    func initVideoCell(indexPath: NSIndexPath) -> VideoTableViewCell {
        let cell = videoTable.dequeueReusableCellWithIdentifier(
            cellName, forIndexPath: indexPath) as! VideoTableViewCell
        if indexPath.row != Playlist.sharedInstance.currentIndex {
            cell.removeAllIndicator()
        } else {
            cell.addPlayingIndicator()
            videoPlayer.playerState() == YTPlayerState.Playing ? cell.startPlayingAnimation() : cell.stopPlayingAnimation()
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        performSegueWithIdentifier(detailSegueKey, sender: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let playNextAction = UITableViewRowAction(style: .Normal, title: "Cue") {
            (action, indexPath) in self.cueToNext(indexPath)}
        playNextAction.backgroundColor = UIColor.grayColor()
        
        let playNowAction = UITableViewRowAction(style: .Normal, title: "Play") {
            (action, indexPath) in self.playNow(indexPath)}
        playNowAction.backgroundColor = UIColor.lightGrayColor()
        
        let deleteAction = UITableViewRowAction(style: .Destructive, title: "Delete") {
            (action, indexPath) in
            self.deleteRow(indexPath, tableView: self.videoTable)
        }

        return [playNextAction, playNowAction, deleteAction]
    }
    
    // MARK: -
    // MARK: YTPlayerViewDelegate
    func playerViewDidBecomeReady(playerView: YTPlayerView!) {
        Logger.log?.debug("playerViewDidBecomeReady")
        // FIXME: Not proper timing
        reloadTable()
        playCurrentVideo()
        UIView.animateWithDuration(0.8, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.loadingView.alpha = 0
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            }, completion: { _ in
                self.loadingView.removeFromSuperview()
        })
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToState state: YTPlayerState) {
        switch state {
        case YTPlayerState.Unstarted:
            Logger.log?.debug("didChangeToState: Unstarted")
            changePlayingAnimation(Playlist.sharedInstance.currentIndex, start: false)
        case YTPlayerState.Ended:
            Logger.log?.debug("didChangeToState: Ended")
            changePlayingAnimation(Playlist.sharedInstance.currentIndex, start: false)
            playNextVideo()
        case YTPlayerState.Playing:
            Logger.log?.debug("didChangeToState: Playing")
            changePlayingAnimation(Playlist.sharedInstance.currentIndex, start: true)
        case YTPlayerState.Paused:
            Logger.log?.debug("didChangeToState: Paused")
            changePlayingAnimation(Playlist.sharedInstance.currentIndex, start: false)
        case YTPlayerState.Buffering:
            Logger.log?.debug("didChangeToState: Buffering")
            // TODO Notify user if it keeps long time
        case YTPlayerState.Queued:
            Logger.log?.debug("didChangeToState: Queued")
        default:
            Logger.log?.debug("didChangeToState: \(state.rawValue)")
        }
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToQuality quality: YTPlaybackQuality) {
        switch quality {
        case YTPlaybackQuality.Small:
            Logger.log?.debug("didChangeToQuality: Small")
        case YTPlaybackQuality.Medium:
            Logger.log?.debug("didChangeToQuality: Medium")
        case YTPlaybackQuality.Large:
            Logger.log?.debug("didChangeToQuality: Large")
        case YTPlaybackQuality.HD720:
            Logger.log?.debug("didChangeToQuality: HD720")
        case YTPlaybackQuality.HD1080:
            Logger.log?.debug("didChangeToQuality: HD1080")
        case YTPlaybackQuality.HighRes:
            Logger.log?.debug("didChangeToQuality: HighRes")
        case YTPlaybackQuality.Auto:
            Logger.log?.debug("didChangeToQuality: Auto")
        case YTPlaybackQuality.Default:
            Logger.log?.debug("didChangeToQuality: Default")
        default:
            Logger.log?.debug("didChangeToQuality: \(quality.rawValue)")
        }
    }
    
    func playerView(playerView: YTPlayerView!, receivedError error: YTPlayerError) {
        switch error {
        case YTPlayerError.InvalidParam:
            Logger.log?.warning("receivedError: InvalidParam")
        case YTPlayerError.HTML5Error:
            Logger.log?.warning("receivedError: HTML5Error")
            checkNetwork()
        case YTPlayerError.VideoNotFound:
            Logger.log?.warning("receivedError: VideoNotFound")
        case YTPlayerError.Unknown:
            Logger.log?.warning("receivedError: Unknown")
        default:
            Logger.log?.warning("receivedError: \(error.rawValue)")
        }
    }
    
//    func playerView(playerView: YTPlayerView!, didPlayTime playTime: Float) {
//        Logger.log?.warning("didPlayTime: \(playTime)")
//    }
}

