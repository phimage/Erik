//
//  Browser.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation

public let ErikErrorKey = "ErikError"

public class Browser {
    var layoutEngine: LayoutEngine
    var htmlParser: HTMLParser
    
    public init(layoutEngine: LayoutEngine, htmlParser: HTMLParser) {
        self.layoutEngine = layoutEngine
        self.htmlParser = htmlParser
    }
    
    public func visitURL(URL: NSURL, completionHandler: ((Any?, ErrorType?) -> Void)?) {
        layoutEngine.browseURL(URL) {[unowned self] (object, error) -> Void in
            guard let html = object as? String else {
                let error = NSError(domain: ErikErrorKey, code: 1, userInfo: ["message": "No content"])
                completionHandler?(object, error)
                return
            }
            
            guard error == nil else {
                completionHandler?(object, error)
                return
            }

            guard let doc = self.htmlParser.parseHTML(html) else {
                let error = NSError(domain: ErikErrorKey, code: 1, userInfo: ["message": "HTML not parsable"])
                completionHandler?(object, error)
                return
            }

            // if browser is just request, download additional files(js,css,image) from parser html
            if !self.layoutEngine.resources {
                let resources = self.layoutEngine.fetchResources(doc)
                self.layoutEngine.evaluateResources(resources)
            }

            completionHandler?(doc, error)
        }
    }
}
extension Browser: JavaScriptEvaluator {

    public func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        self.layoutEngine.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}