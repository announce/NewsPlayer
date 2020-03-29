//
//  UITableView+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import UIKit

extension UITableView {
    func registerCell<T: UITableViewCell>(type: T.Type) {
        let className = String(describing: T.Type.self)
        let nib = UINib(nibName: className, bundle: nil)
        register(nib, forCellReuseIdentifier: className)
    }
    
    func registerCells<T: UITableViewCell>(types: [T.Type]) {
        types.forEach { registerCell(type: $0) }
    }
    
    func dequeueCell<T: UITableViewCell>(type: T.Type, indexPath: IndexPath) -> T {
        let className = String(describing: T.Type.self)
        return self.dequeueReusableCell(withIdentifier: className, for: indexPath) as! T
    }
}
