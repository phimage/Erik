//
//  Erik.swift
//  Erik
/*
The MIT License (MIT)
Copyright (c) 2015 Eric Marchand (phimage)
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

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
 