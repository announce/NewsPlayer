//
//  Logger.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/21/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import XCGLogger

class Logger {
    static let log = Logger.load()
    static func load() -> XCGLogger? {
        let log = XCGLogger.defaultInstance()
        #if DEBUG
            log.xcodeColorsEnabled = true
            log.setup(.Verbose,
                      showThreadName: true,
                      showLogLevel: true,
                      showFileNames: true,
                      showLineNumbers: true)
        #else
            log.setup(.Info)
        #endif
        return log
    }
}
