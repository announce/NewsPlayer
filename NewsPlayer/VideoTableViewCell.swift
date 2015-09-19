//
//  VideoTableViewCell.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/19/15.
//  Copyright © 2015 ymkjp. All rights reserved.
//

import UIKit

class VideoTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var abstract: UILabel!
    
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
        if let video = ChannelModel.sharedInstance.getVideoByIndex(index) {
            abstract.numberOfLines = 0
            abstract.text = "\(video.title)\n\(video.description)"
        } else {
            abstract.text = "textLabel #\(index)"
        }
        return self
    }
}
