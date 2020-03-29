//
//  ViewController.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/11/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import UIKit
import youtube_ios_player_helper
import Reachability

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, YTPlayerViewDelegate, LPRTableViewDelegate, VideoDetailControllerDelegate, PlaylistRefresher {
    
    let playerParams = [
        "playsinline":      1,  // TODO: Remember last settings
        "controls":         1,
        "cc_load_policy":   1,
        "showinfo":         0,
        "modestbranding":   1,
    ]
    let cellFixedHeight: CGFloat = 106
    let channelKey = "queue"
    let detailSegueKey = "showVideoDetail"
    let reachability = try! Reachability()
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
        case .playing:
            videoPlayer.pauseVideo()
        case .paused:
            videoPlayer.playVideo()
        default:
            break
        }
    }
    @IBAction func rewindVideo(sender: UIBarButtonItem) {
        let currentTime = videoPlayer?.currentTime() ?? 0
        videoPlayer?.seek(toSeconds: currentTime + 10, allowSeekAhead: true)
    }
    @IBAction func forwardVideo(sender: UIBarButtonItem) {
        let currentTime = videoPlayer?.currentTime() ?? 0
        videoPlayer?.seek(toSeconds: currentTime - 10, allowSeekAhead: true)
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
        videoPlayer.load(withVideoId: "", playerVars: playerParams)
        Playlist.sharedInstance.enqueue()
        Playlist.sharedInstance.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: false)
        initVideoTable()
        initRefreshControl()
        reachability.whenReachable = { reachability in
            self.updateLabelColourWhenReachable(reachability: reachability)
        }
        reachability.whenUnreachable = { reachability in
            self.updateLabelColourWhenNotReachable(reachability: reachability)
        }
        do {
            try reachability.startNotifier()
        } catch {
            Logger.log?.warning("Unable to start notifier")
        }
        checkNetwork()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        videoTable.registerCell(type: VideoTableViewCell.self)
        super.viewWillAppear(animated)
        Playlist.sharedInstance.addObserver(
            self, forKeyPath: channelKey, options: .new, context: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool){
        super.viewDidDisappear(animated)
        Playlist.sharedInstance.removeObserver(self, forKeyPath: channelKey)
        reachability.stopNotifier()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    // Swift 4
    //    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutableRawPointer) {
    //        if (keyPath == channelKey) {
    //        }
    //    }
    
    func initVideoTable() {
        videoTable.dataSource = self
        videoTable.delegate = self
        videoTable.longPressReorderDelegate = self
    }
    
    func checkNetwork() {
        if reachability.connection != .unavailable {
            updateLabelColourWhenReachable(reachability: reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability: reachability)
        }
    }
    
    func initRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        videoTable?.addSubview(refreshControl)
    }
    
    @objc func refresh(sender: AnyObject)
    {
        Playlist.sharedInstance.refrashChannels()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let isPortrait: Bool  = UIDevice.current.orientation.isPortrait
        videoTable?.isHidden = !isPortrait
        videoToolBar?.isHidden = !isPortrait
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: -
    // MARK ChannelResponseDelegate
    func endRefreshing() {
        if refreshControl.isRefreshing
        {
            refreshControl.endRefreshing()
            reloadTable()
            let path = IndexPath.init(
                row: Playlist.sharedInstance.currentIndex, section: 0)
            videoTable?.scrollToRow(at: path as IndexPath, at: UITableView.ScrollPosition.top, animated: true)
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
        if reachability.connection != .unavailable {
            Logger.log?.info("\(videoPlayer.playerState())")
            if Playlist.sharedInstance.queue.count <= 0 {
                Playlist.sharedInstance.enqueue()
            }
            if videoPlayer.playerState() != YTPlayerState.playing {
                playerViewDidBecomeReady(videoPlayer)
            }
            updateLabelColourWhenReachable(reachability: reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability: reachability)
        }
    }
    
    private func alertNoNetworkConnection()
    {
        let alertController = UIAlertController(title: "Network not found", message: "Is this device connected to Internet?", preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "Check it again", style: .default, handler: {(_: UIAlertAction) in self.checkNetwork()})
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: -
    private func playCurrentVideo(startAt: Float = 0) {
        if let video: Video = Playlist.sharedInstance.currentVideo() {
            videoPlayer.loadVideo(
                byId: video.id, startSeconds: startAt, suggestedQuality: YTPlaybackQuality.default)
            navigationItem.titleView = createTitleLabel(text: video.title)
            showPlayingIndicator(targetIndex: Playlist.sharedInstance.currentIndex)
            removeIndicator(targetIndex: Playlist.sharedInstance.currentIndex - 1)
        } else {
            Logger.log?.debug("No VideoID yet")
        }
    }
    
    private func playNextVideo() {
        if let video: Video = Playlist.sharedInstance.nextVideo() {
            videoPlayer.loadVideo(
                byId: video.id, startSeconds: 0, suggestedQuality: YTPlaybackQuality.default)
            navigationItem.titleView = createTitleLabel(text: video.title)
            showPlayingIndicator(targetIndex: Playlist.sharedInstance.currentIndex)
            removeIndicator(targetIndex: Playlist.sharedInstance.currentIndex - 1)
        } else {
            Logger.log?.debug("No VideoID yet")
        }
    }
    
    private func showPlayingIndicator(targetIndex: Int) {
        let path = IndexPath.init(row: targetIndex, section: 0)
        if let cell = videoTable.cellForRow(at: path as IndexPath) as? VideoTableViewCell {
            cell.addPlayingIndicator()
        } else {
            Logger.log?.debug("No cell index[\(targetIndex)]")
        }
    }
    
    private func removeIndicator(targetIndex: Int) {
        if targetIndex < 0 {
            return
        }
        let path = IndexPath.init(row: targetIndex, section: 0)
        if let cell = videoTable.cellForRow(at: path as IndexPath) as? VideoTableViewCell {
            cell.removeAllIndicator()
        } else {
            Logger.log?.debug("No cell index[\(targetIndex)]")
        }
    }
    
    private func changePlayingAnimation(targetIndex: Int, start: Bool) {
        let path = IndexPath.init(row: targetIndex, section: 0)
        if let cell = videoTable.cellForRow(at: path as IndexPath) as? VideoTableViewCell {
            start ? cell.startPlayingAnimation() : cell.stopPlayingAnimation()
        }
    }
    
    private func createTitleLabel(text: String) -> UILabel {
        let label = UILabel.init()
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = text
        label.sizeToFit()
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleTapped)))
        label.isUserInteractionEnabled = true
        return label
    }
    
    @objc func titleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let path = IndexPath.init(
            row: Playlist.sharedInstance.currentIndex, section: 0)
        videoTable?.scrollToRow(at: path as IndexPath, at: UITableView.ScrollPosition.top, animated: true)
    }
    
    private func reloadTable() {
        let _ = Playlist.sharedInstance.updateCurrentNumberOfRows()
        videoTable.reloadData()
    }
    
    private func deleteRow(indexPath: IndexPath, tableView: UITableView) {
        Playlist.sharedInstance.doDataSourceSafely(closure: {() -> Void in
            if nil != Playlist.sharedInstance.removeVideoByIndex(index: indexPath.row) {
                tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 0) as IndexPath],
                                     with: UITableView.RowAnimation.fade)
            } else {
                Logger.log?.debug("Failed to remove video from list")
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == detailSegueKey && selectedIndex != nil) {
            let nav = segue.destination as! UINavigationController
            let detail: VideoDetailViewController = nav.topViewController as! VideoDetailViewController
            detail.delegate = self
            detail.originalIndex = selectedIndex!
            detail.video = Playlist.sharedInstance.getVideoByIndex(index: selectedIndex!)
        }
    }
    
    // MARK: -
    // MARK VideoDetailControllerDelegate
    func execute(command: VideoDetailViewController.Command, targetCellIndex: Int) {
        let path = IndexPath.init(row: targetCellIndex, section: 0)
        switch command {
        case .PlayNext:
            cueToNext(path: path)
        case .PlayNow:
            playNow(path: path)
        default:
            Logger.log?.info("Ignoring command[\(command)]")
            break
        }
    }
    
    func cueToNext(path: IndexPath) {
        let currentIndex = Playlist.sharedInstance.currentIndex
        if path.row != currentIndex {
            moveUpToNext(originalPath: path)
            reloadTable()
        }
        let blinkPath = IndexPath.init(row: Playlist.sharedInstance.currentIndex + 1, section: 0)
        guard let cell = videoTable.cellForRow(at: blinkPath as IndexPath) as? VideoTableViewCell else {
            Logger.log?.info("No cell index[\(blinkPath.row)]")
            return
        }
        blinkCell(cell: cell, originalColor: cell.backgroundColor, targetColor: UIColor.lightGray)
    }
    
    func playNow(path: IndexPath) {
        let isPlayingCell = path.row == Playlist.sharedInstance.currentIndex
        cueToNext(path: path)
        if !isPlayingCell {
            playNextVideo()
        }
    }
    
    func moveUpToNext(originalPath: IndexPath) {
        var targetIndex = Playlist.sharedInstance.currentIndex
        if targetIndex < originalPath.row {
            targetIndex += 1
        }
        let _ = Playlist.sharedInstance.moveVideoByIndex(
            sourceIndex: originalPath.row, destinationIndex: targetIndex)
    }
    
    private func blinkCell(cell: UITableViewCell, originalColor: UIColor?, targetColor: UIColor, count: Int = 1) {
        let color = count % 2 == 0 ? originalColor : targetColor
        UIView.animate(withDuration: 0.6, delay: 0, options: [.curveEaseIn, .curveEaseOut], animations: { () -> Void in
            cell.backgroundColor = color
            }, completion: { _ in
                if count > 0 {
                    self.blinkCell(cell: cell, originalColor: originalColor, targetColor: targetColor, count: count - 1)
                }
        })
    }
    
    // MARK: -
    // MARK UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (videoTable.contentOffset.y >= (videoTable.contentSize.height - videoTable.bounds.size.height))
        {
            reloadTable()
        }
    }
    
    // MARK: -
    // MARK LPRTableViewDelegate
    // Called within an animation block when the dragging view is about to show.
    private func tableView(tableView: UITableView, showDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
        Playlist.sharedInstance.updatingAvailable = false
        showPlayingIndicator(targetIndex: indexPath.row)
    }
    
    // Called within an animation block when the dragging view is about to hide.
    private func tableView(tableView: UITableView, hideDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
        Playlist.sharedInstance.updatingAvailable = true
        removeIndicator(targetIndex: indexPath.row)
    }
    
    // MARK: -
    // MARK UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int  {
        return Playlist.sharedInstance.currentNumberOfRows
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        return initVideoCell(indexPath: indexPath).render(index: indexPath.row)
    }
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        return cellFixedHeight
    }
    
    private func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            deleteRow(indexPath: indexPath, tableView: tableView)
        }
    }
    
    private func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        Playlist.sharedInstance.doDataSourceSafely(closure: {() -> Void in
            self.videoTable.reloadData()
            let _ = Playlist.sharedInstance.moveVideoByIndex(sourceIndex: sourceIndexPath.row, destinationIndex: destinationIndexPath.row)
        })
    }
    
    func initVideoCell(indexPath: IndexPath) -> VideoTableViewCell {
        let cell = videoTable.dequeueCell(type: VideoTableViewCell.self, indexPath: indexPath)
        if indexPath.row != Playlist.sharedInstance.currentIndex {
            cell.removeAllIndicator()
        } else {
            cell.addPlayingIndicator()
            videoPlayer.playerState() == YTPlayerState.playing ? cell.startPlayingAnimation() : cell.stopPlayingAnimation()
        }
        return cell
    }
    
    private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        selectedIndex = indexPath.row
        performSegue(withIdentifier: detailSegueKey, sender: nil)
        tableView.deselectRow(at: indexPath as IndexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let playNextAction = UITableViewRowAction(style: .normal, title: "Cue") {
            (action, indexPath) in self.cueToNext(path: indexPath)}
        playNextAction.backgroundColor = UIColor.gray
        
        let playNowAction = UITableViewRowAction(style: .normal, title: "Play") {
            (action, indexPath) in self.playNow(path: indexPath)}
        playNowAction.backgroundColor = UIColor.lightGray
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") {
            (action, indexPath) in
            self.deleteRow(indexPath: indexPath, tableView: self.videoTable)
        }

        return [playNextAction, playNowAction, deleteAction]
    }
    
    // MARK: -
    // MARK: YTPlayerViewDelegate
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        Logger.log?.debug("playerViewDidBecomeReady")
        // FIXME: Not proper timing
        DeviceVolume(view: view).showNotice()
        reloadTable()
        playCurrentVideo()
        UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseIn, .curveEaseOut], animations: { () -> Void in
                self.loadingView.alpha = 0
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            }, completion: { _ in
                self.loadingView.removeFromSuperview()
        })
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch state {
        case YTPlayerState.unstarted:
            Logger.log?.debug("didChangeToState: Unstarted")
            changePlayingAnimation(targetIndex: Playlist.sharedInstance.currentIndex, start: false)
        case YTPlayerState.ended:
            Logger.log?.debug("didChangeToState: Ended")
            changePlayingAnimation(targetIndex: Playlist.sharedInstance.currentIndex, start: false)
            playNextVideo()
        case YTPlayerState.playing:
            Logger.log?.debug("didChangeToState: Playing")
            changePlayingAnimation(targetIndex: Playlist.sharedInstance.currentIndex, start: true)
        case YTPlayerState.paused:
            Logger.log?.debug("didChangeToState: Paused")
            changePlayingAnimation(targetIndex: Playlist.sharedInstance.currentIndex, start: false)
        case YTPlayerState.buffering:
            Logger.log?.debug("didChangeToState: Buffering")
            // TODO Notify user if it keeps long time
        case YTPlayerState.queued:
            Logger.log?.debug("didChangeToState: Queued")
        default:
            Logger.log?.debug("didChangeToState: \(state.rawValue)")
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo quality: YTPlaybackQuality) {
        switch quality {
        case YTPlaybackQuality.small:
            Logger.log?.debug("didChangeToQuality: Small")
        case YTPlaybackQuality.medium:
            Logger.log?.debug("didChangeToQuality: Medium")
        case YTPlaybackQuality.large:
            Logger.log?.debug("didChangeToQuality: Large")
        case YTPlaybackQuality.HD720:
            Logger.log?.debug("didChangeToQuality: HD720")
        case YTPlaybackQuality.HD1080:
            Logger.log?.debug("didChangeToQuality: HD1080")
        case YTPlaybackQuality.highRes:
            Logger.log?.debug("didChangeToQuality: HighRes")
        case YTPlaybackQuality.auto:
            Logger.log?.debug("didChangeToQuality: Auto")
        case YTPlaybackQuality.default:
            Logger.log?.debug("didChangeToQuality: Default")
        default:
            Logger.log?.debug("didChangeToQuality: \(quality.rawValue)")
        }
    }
    
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        switch error {
        case YTPlayerError.invalidParam:
            Logger.log?.warning("receivedError: InvalidParam")
        case YTPlayerError.html5Error:
            Logger.log?.warning("receivedError: HTML5Error")
            checkNetwork()
        case YTPlayerError.videoNotFound:
            Logger.log?.warning("receivedError: VideoNotFound")
        case YTPlayerError.unknown:
            Logger.log?.warning("receivedError: Unknown")
        default:
            Logger.log?.warning("receivedError: \(error.rawValue)")
        }
    }
    
//    func playerView(playerView: YTPlayerView!, didPlayTime playTime: Float) {
//        Logger.log?.warning("didPlayTime: \(playTime)")
//    }
}

