//
//  Array+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    
    mutating func remove(index i: Int) -> Element? {
        if (count <= i) {
            return nil
        }
        return remove(at: i)
    }
    
    mutating func remove(element e: Element) -> Element? {
        guard let index = index(of: e) else {
            return nil
        }
        return remove(at: index)
    }
    
}
