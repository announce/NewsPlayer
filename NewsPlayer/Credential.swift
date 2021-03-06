//
//  Credential.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/16/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import Foundation

class Credential {
    enum Provider: String {
        case Google = "Google API Key"
    }
    var apiKey: String
    init(key: Provider) {
        let credentialsPath = NSBundle.mainBundle().pathForResource("Credentials", ofType: "plist")!
        let credentials = NSDictionary(contentsOfFile: credentialsPath)!
        self.apiKey = credentials.objectForKey(key.rawValue) as! String
    }
}