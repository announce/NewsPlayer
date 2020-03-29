//
//  Channel.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

class Channel {
    var id: String
    static func localizedList() -> [Channel] {
        let plistPath = Bundle.main.path(forResource: "YouTube", ofType: "plist")
        let registry = NSDictionary(contentsOfFile: plistPath!)!
        let key = NSLocale.languageCode == "ja" ? "ja" : "en"
        let channelIds = registry.object(forKey: "Channels \(key)") as! [String]
        return channelIds.map {Channel(id: $0)};
    }
    
    init(id: String) {
        self.id = id
    }
}
