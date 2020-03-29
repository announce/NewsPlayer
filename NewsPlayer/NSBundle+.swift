//
//  NSBundle+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

extension Bundle {
    
    static var appId: String {
        return self.main.bundleIdentifier!
    }
    
    static var appVersion: String {
        return self.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    static var releaseVersion: String {
        return self.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }
}
