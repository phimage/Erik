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

// MARK: Error
public enum ErikError: ErrorType {
    // Error provided by javascript
    case JavaScriptError(message: String)
    // A timeout occurs
    case TimeOutError(time: NSTimeInterval)
    // No content returned
    case NoContent
    // HTML is not parsable
    case HTMLNotParsable(html: String)
    // Invalid url submited (NSURL init failed)
    case InvalidURL(urlString: String)
}

// MARK: Erik class

// Instance of headless browser
public class Erik {
    
    public var layoutEngine: LayoutEngine
    public var htmlParser: HTMLParser
    
    public var noContentPattern: String? = "<html><head></head><body></body></html>"
    
    // Init the headless browser
    public init(webView: WKWebView? = nil) {
        if let view = webView {
            self.layoutEngine = WebKitLayoutEngine(webView: view)
        } else {
            self.layoutEngine = WebKitLayoutEngine()
        }
        self.htmlParser = KanaParser.instance
    }

    @available(*, deprecated=1.1, obsoleted=2.0, message="Use url")
    public var currentURL: NSURL? {
        return layoutEngine.url
    }

    // Get current url
    public var url: NSURL? {
        return layoutEngine.url
    }
    
    // Get current title
    public var title: String? {
        return layoutEngine.title
    }

    // Go to specific url
    public func visitURL(URL: NSURL, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        layoutEngine.browseURL(URL) {[unowned self] (object, error) -> Void in
            self.publishContent(object, error: error, completionHandler: completionHandler)
        }
    }
    
    // Go to specific url
    public func visitURL(urlString: String, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        if let url = NSURL(string: urlString) {
            visitURL(url, completionHandler: completionHandler)
        } else {
            completionHandler?(nil, ErikError.InvalidURL(urlString: urlString))
        }
    }
    
    // Go to specific url using url request
    public func loadURLRequest(URLRequest: NSURLRequest, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        layoutEngine.browseURL(URLRequest) {[unowned self] (object, error) -> Void in
            self.publishContent(object, error: error, completionHandler: completionHandler)
        }
    }

    // Get current content
    public func currentContent(completionHandler: ((Document?, ErrorType?) -> Void)?) {
        layoutEngine.currentContent {[unowned self] (object, error) -> Void in
            self.publishContent(object, error: error, completionHandler: completionHandler)
        }
    }
    
    // Navigates to the previous loaded page.
    public func goBack() {
        layoutEngine.goBack()
    }
    
    // Navigates to the next page ie. the one loaded before `goBack`
    public func goForward() {
        layoutEngine.goForward()
    }
    
    // A Boolean value indicating whether browser can go back
    public var canGoBack: Bool {
        return layoutEngine.canGoBack
    }

    // A Boolean value indicating whether browser can go forward
    public var canGoForward: Bool {
        return layoutEngine.canGoForward
    }

    // Reloads the current page
    public func reload() {
        layoutEngine.reload()
    }

    // MARK: private
    private func publishContent(object: AnyObject?, error: ErrorType?, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        guard let html = object as? String else {
            completionHandler?(nil, ErikError.NoContent)
            return
        }
        
        if let pattern = noContentPattern where html.rangeOfString(pattern, options: .RegularExpressionSearch) != nil {
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

// MARK: javascript
extension Erik: JavaScriptEvaluator {
    
    public func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        self.layoutEngine.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}


// MARK: Erik static
extension Erik {
    // Shared instance used for static functions
    public static let sharedInstance = Erik()
    
    public static func visitURL(URL: NSURL, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.visitURL(URL, completionHandler: completionHandler)
    }

    public static func visitURL(urlString: String, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.visitURL(urlString, completionHandler: completionHandler)
    }

    public static func loadURLRequest(URLRequest: NSURLRequest, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.loadURLRequest(URLRequest, completionHandler: completionHandler)
    }

    @available(*, deprecated=1.1, obsoleted=1.2, message="Use url")
    public static var currentURL: NSURL? {
        return Erik.sharedInstance.url
    }
    
    public static var url: NSURL? {
        return Erik.sharedInstance.url
    }
 
    public static var title: String? {
        return Erik.sharedInstance.title
    }

    public static func currentContent(completionHandler: ((Document?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.currentContent(completionHandler)
    }
    
    public static func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    public static func goBack() {
        Erik.sharedInstance.goBack()
    }
    public static func goForward() {
        Erik.sharedInstance.goForward()
    }
    
    public static var canGoBack: Bool {
        return Erik.sharedInstance.canGoBack
    }
    
    public static var canGoForward: Bool {
        return Erik.sharedInstance.canGoForward
    }
    
    public static func reload() {
         Erik.sharedInstance.reload()
    }

}
