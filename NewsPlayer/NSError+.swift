//
//  NSError+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

extension NSError {
    convenience init(message: String, code: Int = 0) {
        self.init(domain: NSBundle.appId, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
