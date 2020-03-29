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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // :param: index Let them know the indexPath.row, cell does not remember wchich indexPath it belongs
    func render(index: Int) -> VideoTableViewCell {
        if let video = Playlist.sharedInstance.getVideoByIndex(index: index) {
            abstract?.numberOfLines = 0
            abstract?.text = "\(video.title)\n\(video.description)"
            thumbnail?.sd_setImage(with: URL(string: video.thumbnail.url))
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
        let path = Bundle.main.path(forResource: "equalizer", ofType: "gif")!
        let url = URL(fileURLWithPath: path)
        let animatedImage = FLAnimatedImage(animatedGIFData: try? Data(contentsOf: url))
        animatedImageView.animatedImage = animatedImage
        animatedImageView.frame = indicator.bounds
        animatedImageView.contentMode = UIView.ContentMode.scaleAspectFit
        return animatedImageView
    }
}
