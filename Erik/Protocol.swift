//
//  Protocol.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import Kanna

public typealias Resources = [String]

public typealias CallBack = ((AnyObject?, NSError?) -> Void)

public let DefaultDownloader = NSURLSession.sharedSession()

// MARK: - Javascript evaluator
public protocol JavaScriptEvaluator {
     func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?)
}
public extension JavaScriptEvaluator {
    func evaluateResources(resources: Resources) { // add callback or/and return
        for resource in resources {
            // download file
            if let url = NSURL(string: resource) {
                DefaultDownloader.browseURL(url) { (object, error) -> Void in
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


// MARK: - HTML parser
public protocol HTMLParser {
    func parseHTML(html: String) -> HTMLDocument? // add callback or/and return
}

// MARK: - URL browser
public protocol URLBrowser {
    func browseURL(URL: NSURL, completionHandler: ((AnyObject?, NSError?) -> Void)?)
    var resources: Bool {get}
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
