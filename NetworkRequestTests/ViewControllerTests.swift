//
//  ViewControllerTests.swift
//  NetworkRequestTests
//
//  Created by Erich Flock on 19.01.21.
//

import XCTest
@testable import NetworkRequest

class ViewControllerTests: XCTestCase {

    private var sut: ViewController!
    
    override func setUpWithError() throws {
        sut = ViewController()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func test_searchButton_whenButtonTapped_searchShouldStart() {
        let session = MockURLSession()
        sut.session = session
        sut.loadViewIfNeeded()
        
        sut.searchButton.tap()
        
        let request = URLRequest(url: URL(string: "https://itunes.apple.com/search?media=ebook&term=out%20from%20boneville")!)
        session.verifyDataTask(with: request)
    }
    
    func test_searchForBookNetworkCall_withSuccessResponse_shouldSaveDataInResults() {
        let expectedResult: [SearchResult] = [.init(artistName: "Artist", trackName: "Track", averageUserRating: 2.5, genres: ["Foo", "Bar"])]
        let spyURLSession = SpyURLSession()
        sut.session = spyURLSession
        sut.loadViewIfNeeded()
        let handleResultsCalled = expectation(description: "handleResults called")
        sut.handleResults = { _ in
            handleResultsCalled.fulfill()
        }
        sut.searchButton.tap()
        
        spyURLSession.dataTaskArgsCompletionHandler.first? (createJsonData(), createResponse(statusCode: 200), nil)
        
        waitForExpectations(timeout: 0.01)
        XCTAssertEqual(sut.results, expectedResult)
    }
    
    func test_searchForBookNetworkCall_withSuccessBeforeAsync_shouldNotSaveDataInResults() {
        let spyURLSession = SpyURLSession()
        sut.session = spyURLSession
        sut.loadViewIfNeeded()
        sut.searchButton.tap()
        
        spyURLSession.dataTaskArgsCompletionHandler.first? (createJsonData(), createResponse(statusCode: 200), nil)
        
        XCTAssertEqual(sut.results, [])
    }
    
    /*
     Helpers
     */
    
    private func createResponse(statusCode: Int) -> HTTPURLResponse? {
        HTTPURLResponse(url: URL(string: "http://DUMMY")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }
    
    private func createJsonData() -> Data {
        """
        {
            "results": [
                {
                    "artistName": "Artist",
                    "trackName": "Track",
                    "averageUserRating": 2.5,
                    "genres": [
                        "Foo",
                        "Bar"
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
    }
}

extension UIButton {
    func tap() {
        sendActions(for: .touchUpInside)
    }
}
