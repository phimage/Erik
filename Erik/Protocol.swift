//
//  Protocol.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation

// MARK: - protocols

public protocol JavaScriptEvaluator {
     func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?)
}
public protocol HTMLParser {
    func parseHTML(html: String) -> Document? // add callback instead of return ?
}

public protocol URLBrowser {
    func browseURL(URL: NSURL, completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
    func getContent(completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
    var resources: Bool {get} // browser fetch all resources or not
}

public typealias LayoutEngine = protocol<URLBrowser,JavaScriptEvaluator>

// MARK: - default impl
public typealias Resources = [String]

public extension URLBrowser {

    var resources: Bool {return false}

    func fetchResources(doc: Document) -> Resources {
        var resources = [String]()
        for node in doc.querySelectorAll("script") {
            if let src = node["src"] {
                 resources.append(src)
            }
        }
        return resources
    }
}
