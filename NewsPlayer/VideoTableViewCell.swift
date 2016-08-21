//
//  VideoTableViewCell.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/19/15.
//  Copyright © 2015 ymkjp. All rights reserved.
//

import UIKit
import FLAnimatedImage

class VideoTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var abstract: UILabel!
    @IBOutlet weak var indicator: UIView!
    
    let animatedImageView = FLAnimatedImageView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // :param: index Let them know the indexPath.row, cell does not remember wchich indexPath it belongs
    func render(index: Int) -> VideoTableViewCell {
        if let video = Playlist.sharedInstance.getVideoByIndex(index) {
            abstract?.numberOfLines = 0
            abstract?.text = "\(video.title)\n\(video.description)"
            thumbnail?.sd_setImageWithURL(NSURL(string: video.thumbnail.url))
        } else {
            abstract.text = "textLabel #\(index)"
        }
        return self
    }
    
    func addPlayingIndicator() {
        indicator?.addSubview(createIndicationView())
    }
    
    func removeAllIndicator() {
        guard let subviews = indicator?.subviews else {
            return
        }
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }
    
    func startPlayingAnimation() {
        animatedImageView.startAnimating()
    }
    
    func stopPlayingAnimation() {
        animatedImageView.stopAnimating()
    }
    
    private func createIndicationView() -> UIImageView {
        let path = NSBundle.mainBundle().pathForResource("equalizer", ofType: "gif")!
        let url = NSURL(fileURLWithPath: path)
        let animatedImage = FLAnimatedImage(animatedGIFData: NSData(contentsOfURL: url))
        animatedImageView.animatedImage = animatedImage
        animatedImageView.frame = indicator.bounds
        animatedImageView.contentMode = UIViewContentMode.ScaleAspectFit
        return animatedImageView
    }
}
