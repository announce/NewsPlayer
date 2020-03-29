//
//  NSLocale+.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import Foundation

extension NSLocale {
    static var languageCode: String {
        guard let code = Locale.current.languageCode else {
            return "en"
        }
        return code
    }
}
