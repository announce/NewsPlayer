//
//  DeviceVolume.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation
import MediaPlayer

class DeviceVolume {
    static let threshold: Float = 0
    
    var baseView: UIView!
    var volumeSlider: UISlider?
    var mpVolumeView: MPVolumeView!
    
    init(view: UIView, threshold: Float = 0) {
        baseView = view
        mpVolumeView = MPVolumeView(frame: view.bounds)
        mpVolumeView.isHidden = true;
        view.addSubview(mpVolumeView)
        for childView in mpVolumeView.subviews {
            if (childView is UISlider) {
                self.volumeSlider = childView as? UISlider
            }
        }
    }
    
    func currentVolume() -> Float? {
        return volumeSlider?.value
    }
    
    func hasEnoughVolume(target: Float = threshold) -> Bool {
        guard let volume = currentVolume() else {
            return false
        }
        return volume > target
    }
    
    func showNotice(duration: Double = 3) {
        Logger.log?.info("Volume \(String(describing: currentVolume()))")
        if hasEnoughVolume() {
            return
        }
        let image = UIImage(named: "speaker-sound-muted.png")!
        let imageView = UIImageView(image: image)
        let size = (image.size.width < baseView.frame.size.width * 0.5) ?
            image.size :
            CGSize(width: baseView.bounds.size.width * 0.5, height: baseView.bounds.size.width * 0.5)
        
        imageView.frame = CGRect(x: baseView.frame.size.width/2 - size.width/2,
                                  y: baseView.frame.size.height/2 - size.height/2,
                                  width: size.width,
                                  height: size.height)
        imageView.backgroundColor = UIColor.lightGray
        baseView.addSubview(imageView)
        UIView.animate(withDuration: duration, animations: {
            imageView.alpha = 0
            }, completion: { finished in
                imageView.removeFromSuperview()
        })
    }
}
