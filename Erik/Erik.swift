//
//  Erik.swift
//  Erik
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import WebKit

public class Erik {
    
    public var layoutEngine: LayoutEngine
    public var htmlParser: HTMLParser
    
    public init() {
        self.layoutEngine = WebKitLayoutEngine()
        self.htmlParser = KanaParser.instance
    }

    public func visitURL(URL: NSURL, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        layoutEngine.browseURL(URL) {[unowned self] (object, error) -> Void in
            self.publishContent(object, error: error, completionHandler: completionHandler)
        }
    }
    
    public var currentURL: NSURL? {
        return layoutEngine.currentURL
    }
    
    public func currentContent(completionHandler: ((Document?, ErrorType?) -> Void)?) {
        layoutEngine.currentContent {[unowned self] (object, error) -> Void in
            self.publishContent(object, error: error, completionHandler: completionHandler)
        }
    }

    private func publishContent(object: AnyObject?, error: ErrorType?, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        guard let html = object as? String else {
            completionHandler?(nil, ErikError.NoContent)
            return
        }
        
        guard error == nil else {
            completionHandler?(nil, error)
            return
        }
        
        guard let doc = self.htmlParser.parseHTML(html) else {
            completionHandler?(nil, ErikError.HTMLNotParsable(html: html))
            return
        }
        
        doc.layoutEngine = layoutEngine
        completionHandler?(doc, error)
    }

    
}
extension Erik: JavaScriptEvaluator {
    
    public func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        self.layoutEngine.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}

public enum ErikError: ErrorType {
    case JavaScriptError(message: String)
    case TimeOutError
    case NoContent
    case HTMLNotParsable(html: String)
}

// MARK: static
extension Erik {
    public static var sharedInstance: Erik {
        struct Static {
            static let instance: Erik = Erik()
        }
        return Static.instance
    }
    
    public static func visitURL(URL: NSURL, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.visitURL(URL, completionHandler: completionHandler)
    }
    
    public static var currentURL: NSURL? {
        return Erik.sharedInstance.currentURL
    }

    public static func currentContent(completionHandler: ((Document?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.currentContent(completionHandler)
    }
    
    public static func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

}
 