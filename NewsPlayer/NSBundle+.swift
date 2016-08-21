//
//  NSBundle+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

extension NSBundle {
    
    static var appId: String {
        return self.mainBundle().bundleIdentifier!
    }
    
    static var appVersion: String {
        return self.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
    }
    
    static var releaseVersion: String {
        return self.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
    }
}
