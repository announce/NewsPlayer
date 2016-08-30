//
//  PlaylistTest.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 8/20/16.
//  Copyright © 2016 ymkjp. All rights reserved.
//

import XCTest
import MockURLSession

class PlaylistTest: XCTestCase {
    var subject: Playlist!
    let session = MockURLSession()
    let activitiesEndpoint = NSURL(string: ActivityApi.baseUrl)!
    let videosEndpoint = NSURL(string: VideoApi.baseUrl)!
    
    class Normalizer: MockURLSessionNormalizer {
        func normalizeUrl(url: NSURL) -> NSURL {
            let components = NSURLComponents()
            components.host = url.host
            components.path = url.path
            return components.URL!
        }
    }
    
    override func setUp() {
        super.setUp()
        subject = Playlist(session: session)
        session.normalizer = Normalizer()
        session.registerMockResponse(activitiesEndpoint, data: Fixtures.read("YoutubeActivities02"))
        session.registerMockResponse(videosEndpoint, data: Fixtures.read("YoutubeVideos02"))
    }
    
    func testCurrentIndex() {
        XCTAssert(subject.currentIndex == 0)
    }
    
    func testEnqueue() {
        XCTAssert(subject.queue.isEmpty)
        subject.enqueue()
        XCTAssert(subject.queue.count > 0)
        XCTAssertNotNil(session.resumedResponse(activitiesEndpoint))
        XCTAssertNotNil(session.resumedResponse(videosEndpoint))
    }
    
    func testCurrentVideo() {
        XCTAssertNil(subject.currentVideo())
        subject.enqueue()
        XCTAssertNotNil(subject.currentVideo())
        XCTAssertEqual(subject.currentVideo(), subject.currentVideo())
    }
    
    func testNextVideo() {
        XCTAssertNil(subject.nextVideo())
        subject.enqueue()
        let index = subject.currentIndex
        XCTAssertNotNil(subject.nextVideo())
        XCTAssertNotEqual(subject.currentIndex, index)
    }
    
    func testRefreshChannels() {
        subject.refrashChannels()
        XCTAssertEqual(subject.finishedCount, 0)
    }
    
    func testUpdateCurrentNumberOfRows() {
        XCTAssert(subject.currentNumberOfRows == 0)
        subject.enqueue()
        XCTAssert(subject.updateCurrentNumberOfRows() > 0)
    }
    
    func testGetVideoByIndex() {
        XCTAssertNil(subject.getVideoByIndex(random()))
        subject.enqueue()
        let targetIndex = random() % subject.queue.count
        XCTAssertEqual(subject.getVideoByIndex(targetIndex), subject.getVideoByIndex(targetIndex))
    }
    
    func testRemoveVideoByIndex() {
        subject.doDataSourceSafely({() -> Void in
            XCTAssertNil(self.subject.removeVideoByIndex(0))
        })
        subject.enqueue()
        let targetIndex = random() % subject.queue.count
        let targetVideo = subject.getVideoByIndex(targetIndex)
        subject.doDataSourceSafely({() -> Void in
            XCTAssertEqual(self.subject.removeVideoByIndex(targetIndex), targetVideo)
        })
    }
    
    func testMoveVideoByIndex() {
        subject.doDataSourceSafely({() -> Void in
            XCTAssertNil(self.subject.moveVideoByIndex(0, destinationIndex: 1))
        })
        subject.enqueue()
        let sourceIndex = random() % subject.queue.count
        let destinationIndex = random() % subject.queue.count
        // TODO: Test against current index
        //        let sourceVideo = subject.getVideoByIndex(sourceIndex)
        //        let destinationVideo = subject.getVideoByIndex(sourceIndex)
        subject.doDataSourceSafely({() -> Void in
            XCTAssertNotNil(self.subject.moveVideoByIndex(sourceIndex, destinationIndex: destinationIndex))
            //            XCTAssertEqual(self.subject.getVideoByIndex(sourceIndex), destinationVideo)
            //            XCTAssertEqual(self.subject.getVideoByIndex(destinationIndex), sourceVideo)
        })
    }
}
