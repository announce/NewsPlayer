//
//  Fixture.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/20/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

class Fixtures {
    static func read(name: String, ofType: String = "json") -> NSData {
        let path = NSBundle(forClass:self).pathForResource(name, ofType: ofType)
        return try! NSData(contentsOfURL: NSURL(fileURLWithPath: path!), options: NSDataReadingOptions.DataReadingMappedIfSafe)
    }
}
