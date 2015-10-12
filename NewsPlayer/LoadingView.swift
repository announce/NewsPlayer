//
//  LoadingView.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/22/15.
//  Copyright © 2015 ymkjp. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    
    struct Const {
        static let xibName = "LoadingView"
        static let agifUrl = "https://image.xn--nyqr7s4vc72p.com/ZapApp/giraffe.gif"
    }
    
    @IBOutlet weak var loadingImage: UIImageView!
    
    class func instance() -> LoadingView {
        return UINib(nibName: Const.xibName, bundle: nil).instantiateWithOwner(self, options: nil)[0] as! LoadingView
    }
 
    func render() -> LoadingView {
        if let localImage = UIImage(named: "Giraffe") {
            loadingImage.sd_setImageWithURL(NSURL(string: Const.agifUrl), placeholderImage: localImage)
        }
        
        return self
    }
}
