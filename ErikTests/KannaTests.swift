//
//  Kanna.swift
//  Erik
//
//  Created by phimage on 14/02/2017.
//  Copyright © 2017 phimage. All rights reserved.
//

import Foundation

import XCTest
@testable import Erik
import FileKit
import Kanna


let formSelector = "f"

class KannaTests: XCTestCase {

    func testKannaParsing() {
        guard let url = Bundle(for: KannaTests.self).url(forResource: "google", withExtension: "html") else {
            XCTFail()
            return
        }
        guard let path: Path = Path(url: url) else {
            XCTFail()
            return
        }
        do {
            let html = try TextFile(path: path).read()
            guard let parsed = Kanna.HTML(html: html, encoding: .utf8) else {
                XCTFail("failed to parse")
                return
            }
            
            let doc = Document(rawValue: parsed)
            
            guard  let compare = doc.text else {
                XCTFail("no content")
                return
            }
            
            print(compare)
            
            XCTAssertEqual(html, compare)
        } catch {
            XCTFail("failed to read")
        }
    }
}
