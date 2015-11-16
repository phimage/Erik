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
    var urlBrowser: URLBrowser
    var htmlParser: HTMLParser
    var javaScriptEvaluator: JavaScriptEvaluator
    
    public init(urlBrowser: URLBrowser, htmlParser: HTMLParser, javaScriptEvaluator: JavaScriptEvaluator) {
        self.urlBrowser = urlBrowser
        self.htmlParser = htmlParser
        self.javaScriptEvaluator = javaScriptEvaluator
    }
    
    public func visitURL(URL: NSURL, completionHandler: ((Any?, NSError?) -> Void)?) { // return or/and callback
        urlBrowser.browseURL(URL) {[unowned self] (object, error) -> Void in
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
            if !self.urlBrowser.resources {
                let resources = self.urlBrowser.fetchResources(doc)
                self.javaScriptEvaluator.evaluateResources(resources)
            }
            // if browser is not js evaluator, give all html code to evaluator for context
            if self.urlBrowser as? JavaScriptEvaluator == nil {
                self.javaScriptEvaluator.evaluateHTMLDoc(doc)
            }
            completionHandler?(doc, error)
        }
    }
}