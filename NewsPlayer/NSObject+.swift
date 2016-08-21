//
//  NSObject+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

extension NSObject {
    class var className: String {
        return String(self)
    }
    
    var className: String {
        return self.dynamicType.className
    }
}
