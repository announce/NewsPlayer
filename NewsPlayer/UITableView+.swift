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
        register(nib, forCellReuseIdentifier: className)
    }
    
    func registerCells<T: UITableViewCell>(types types: [T.Type]) {
        types.forEach { registerCell(type: $0) }
    }
    
    func dequeueCell<T: UITableViewCell>(type: T.Type, indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: type.className, for: indexPath) as! T
    }
}
