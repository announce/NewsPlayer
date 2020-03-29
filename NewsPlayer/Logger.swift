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
        let log = XCGLogger.default
        #if DEBUG
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
        #else
        log.setup(level: .severe, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
        #endif
        return log
    }
}
