//
//  Video.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/23/15.
//  Copyright © 2015 ymkjp. All rights reserved.
//

import Foundation
import SwiftyJSON

class Video: Equatable {
    struct Thumbnail {
        enum Quality: String {
            case Default   = "default"
            case Medium    = "medium"
            case High      = "high"
            case Standard  = "standard"
        }
        var url: String
        var width: Int
        var height: Int
    }
    enum State {
        case Waiting
        case Watching
        case Watched
    }
    
    var id: String
    var title: String
    var description: String
    var thumbnail: Thumbnail
    var state: State

    convenience init(id: String, item: JSON, quality: Thumbnail.Quality = Thumbnail.Quality.High) {
        self.init(
            id: id,
            title: item["snippet", "title"].stringValue,
            description: item["snippet", "description"].stringValue,
            thumbnail: Thumbnail(
                url:    item["snippet", "thumbnails", quality.rawValue, "url"].stringValue,
                width:  item["snippet", "thumbnails", quality.rawValue, "width"].intValue,
                height: item["snippet", "thumbnails", quality.rawValue, "height"].intValue)
        )
    }

    init(id: String, title: String, description: String, thumbnail: Thumbnail) {
        self.id = id
        self.title = title
        self.description = description
        self.thumbnail = thumbnail
        self.state = State.Waiting
    }
}

func ==(lhs: Video, rhs: Video) -> Bool {
    return lhs.id == rhs.id
}
