//
//  VideoDetailViewController.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/21/15.
//  Copyright © 2015 ymkjp. All rights reserved.
//

import UIKit

class VideoDetailViewController: UIViewController {

    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var abstract: UITextView!
    @IBOutlet weak var detail: UITextView!
    @IBAction func dissmissButton(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func playNext(sender: UIBarButtonItem) {
    }
    @IBAction func playNow(sender: UIBarButtonItem) {
    }
    
    var video: ChannelModel.Video?
    
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
