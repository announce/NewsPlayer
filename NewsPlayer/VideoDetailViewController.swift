//
//  VideoDetailViewController.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/21/15.
//  Copyright © 2015 ymkjp. All rights reserved.
//

import UIKit
import SDWebImage

protocol VideoDetailControllerDelegate {
    func execute(command: VideoDetailViewController.Command)
    func execute(command: VideoDetailViewController.Command, targetCellIndex: Int)
}

class VideoDetailViewController: UIViewController {
    
    enum Command {
        case DoNothing
        case PlayNextVideo
        case ReloadTable
        case BlinkCell
    }
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var abstract: UITextView!
    @IBOutlet weak var detail: UITextView!
    @IBAction func shareVideo(sender: UIBarButtonItem) {
        guard let index = originalIndex,
            let video: Video = ChannelModel.sharedInstance.getVideoByIndex(index),
            let videoUrl = NSURL(string: "https://youtu.be/\(video.id)") else {
                return
        }
        SDWebImageDownloader.sharedDownloader().downloadImageWithURL(NSURL(string: video.thumbnail.url), options: SDWebImageDownloaderOptions.HighPriority, progress: nil, completed: {(image, data, error, finished) in
            if image != nil && finished {
                self.shareViaActivity([video.title, videoUrl, image])
            }
        })
    }
    @IBAction func dissmissButton(sender: UIBarButtonItem) {
        dismiss()
    }
    @IBAction func playNext(sender: UIBarButtonItem) {
        if (originalIndex == ChannelModel.sharedInstance.currentIndex) {
            delegate.execute(Command.BlinkCell, targetCellIndex: ChannelModel.sharedInstance.currentIndex)
        } else {
            moveUpToNext()
            delegate.execute(Command.ReloadTable)
            delegate.execute(Command.BlinkCell, targetCellIndex: ChannelModel.sharedInstance.currentIndex + 1)
        }
        dismiss()
    }
    @IBAction func playNow(sender: UIBarButtonItem) {
        if (originalIndex == ChannelModel.sharedInstance.currentIndex) {
            delegate.execute(Command.BlinkCell, targetCellIndex: ChannelModel.sharedInstance.currentIndex)
        } else {
            moveUpToNext()
            delegate.execute(Command.ReloadTable)
            delegate.execute(Command.BlinkCell, targetCellIndex: ChannelModel.sharedInstance.currentIndex + 1)
            delegate.execute(Command.PlayNextVideo)
        }
        dismiss()
    }
    
    var delegate: VideoDetailControllerDelegate! = nil
    var video: Video?
    var originalIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if video != nil {
            thumbnail.sd_setImageWithURL(NSURL(string: video!.thumbnail.url))
            abstract.text = "\(video!.title)"
            detail.text = "\(video!.description)"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func moveUpToNext() {
        if video != nil && originalIndex != nil {
            let targetIndex = ChannelModel.sharedInstance.currentIndex + 1
            ChannelModel.sharedInstance.moveVideoByIndex(
                originalIndex!, destinationIndex: targetIndex)
        } else {
            print("moveUpToNext nil")
        }
    }

    func shareViaActivity(items: [AnyObject]) {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypePrint,
            UIActivityTypeAssignToContact,
        ]
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(activityViewController, animated: true, completion: nil)
        })
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
