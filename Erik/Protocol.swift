//
//  Protocol.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import Kanna


// MARK: - protocols

public protocol JavaScriptEvaluator {
     func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?)
}
public protocol HTMLParser {
    func parseHTML(html: String) -> HTMLDocument? // add callback instead of return ?
}

public protocol URLBrowser {
    func browseURL(URL: NSURL, completionHandler: ((Any?, ErrorType?) -> Void)?)
    var resources: Bool {get} // browser fetch all resources or not
}

public typealias LayoutEngine = protocol<URLBrowser,JavaScriptEvaluator>

// MARK: - default impl
public typealias Resources = [String]

public extension JavaScriptEvaluator {
    func evaluateResources(resources: Resources) { // add callback or/and return
        for resource in resources {
            // download file
            if let url = NSURL(string: resource) {
                NSURLSession.sharedSession().browseURL(url) { (object, error) -> Void in
                    guard let script = object as? String else {
                        // let error = NSError(domain: ErikErrorKey, code: 1, userInfo: ["message": "No resource content"])
                        // completionHandler?(object, error)
                        return
                    }
                    
                    self.evaluateJavaScript(script , completionHandler: nil)
                }
            }
        }
        
    }
    func evaluateHTMLDoc(doc: HTMLDocument) { // add callback or/and return
        for node in doc.css("script") {
            if let text = node.text where node["src"] == nil { // ignore resources
                self.evaluateJavaScript(text , completionHandler: nil)
            }
        }
    }
}

public extension URLBrowser {

    var resources: Bool {return false}

    func fetchResources(doc: HTMLDocument) -> Resources {
        var resources = [String]()
        for node in doc.css("script") {
            if let src = node["src"] {
                 resources.append(src)
            }
        }
        return resources
    }
}
