//
//  Video.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/23/15.
//  Copyright © 2015 ymkjp. All rights reserved.
//

import Foundation

class Video: Equatable {
    struct Thumbnail {
        var url: String
        var width: Int
        var height: Int
    }

    var id: String
    var title: String
    var description: String
    var thumbnail: Thumbnail

    init(id: String, title: String, description: String, thumbnail: Thumbnail) {
        self.id = id
        self.title = title
        self.description = description
        self.thumbnail = thumbnail
    }
}

func ==(lhs: Video, rhs: Video) -> Bool {
    return lhs.id == rhs.id
}