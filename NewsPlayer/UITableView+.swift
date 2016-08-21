//
//  UITableView+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import UIKit

extension UITableView {
    func registerCell<T: UITableViewCell>(type type: T.Type) {
        let className = type.className
        let nib = UINib(nibName: className, bundle: nil)
        registerNib(nib, forCellReuseIdentifier: className)
    }
    
    func registerCells<T: UITableViewCell>(types types: [T.Type]) {
        types.forEach { registerCell(type: $0) }
    }
    
    func dequeueCell<T: UITableViewCell>(type: T.Type, indexPath: NSIndexPath) -> T {
        return self.dequeueReusableCellWithIdentifier(type.className, forIndexPath: indexPath) as! T
    }
}
