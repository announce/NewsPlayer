//
//  Array+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    
    mutating func remove(index index: Int) -> Element? {
        if (count <= index) {
            return nil
        }
        return removeAtIndex(index)
    }
    
    mutating func remove(element element: Element) -> Element? {
        guard let index = indexOf(element) else {
            return nil
        }
        return removeAtIndex(index)
    }
    
    mutating func remove(elements elements: [Element]) {
        for element in elements {
            remove(element: element)
        }
    }
}
