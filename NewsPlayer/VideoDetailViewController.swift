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
    func execute(command: VideoDetailViewController.Command, targetCellIndex: Int)
}

class VideoDetailViewController: UIViewController {
    
    enum Command {
        case DoNothing
        case PlayNext
        case PlayNow
    }
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var abstract: UITextView!
    @IBOutlet weak var detail: UITextView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBAction func shareVideo(sender: UIBarButtonItem) {
        guard let index = originalIndex,
            let video: Video = Playlist.sharedInstance.getVideoByIndex(index: index),
            let videoUrl = URL(string: "https://youtu.be/\(video.id)") else {
                return
        
        }
        SDWebImageDownloader.shared.downloadImage(with: URL(string: video.thumbnail.url), options: SDWebImageDownloaderOptions.highPriority, progress: nil, completed: {(image, data, error, finished) in
            if image != nil && finished {
                self.shareViaActivity(items: [video.title, videoUrl, image!])
            }
        })
    }
    @IBAction func dissmissButton(sender: UIBarButtonItem) {
        dismiss()
    }
    @IBAction func playNext(sender: UIBarButtonItem) {
        guard let targetIndex = originalIndex else {
            dismiss()
            return
        }
        delegate.execute(command: Command.PlayNext, targetCellIndex: targetIndex)
        dismiss()
    }
    @IBAction func playNow(sender: UIBarButtonItem) {
        guard let targetIndex = originalIndex else {
            dismiss()
            return
        }
        delegate.execute(command: Command.PlayNow, targetCellIndex: targetIndex)
        dismiss()
    }
    
    var delegate: VideoDetailControllerDelegate! = nil
    var video: Video?
    var originalIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if video != nil {
            thumbnail.sd_setImage(with: URL(string: video!.thumbnail.url))
            abstract.text = "\(video!.title)"
            detail.text = "\(video!.description)"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    func shareViaActivity(items: [Any]) {
        loading.startAnimating()
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
        ]
        DispatchQueue.main.async {
            self.present(activityViewController, animated: true, completion: nil)
            self.loading.stopAnimating()
        }
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
