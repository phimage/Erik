//
//  Erik.swift
//  Erik
/*
The MIT License (MIT)
Copyright (c) 2015-2016 Eric Marchand (phimage)
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

public typealias DocumentCompletionHandler = ((Document?, Error?) -> Void)

// MARK: Error
public enum ErikError: Error {
    // Error provided by javascript
    case javaScriptError(message: String)
    // A timeout occurs
    case timeOutError(time: TimeInterval)
    // No content returned
    case noContent
    // HTML is not parsable
    case htmlNotParsable(html: String)
    // Invalid url submited (NSURL init failed)
    case invalidURL(urlString: String)
}

// MARK: Erik class

// Instance of headless browser
open class Erik {
    
    open var layoutEngine: LayoutEngine
    open var htmlParser: HTMLParser
    open var encoding: String.Encoding = .utf8
    
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

    // Get current url
    open var url: URL? {
        return layoutEngine.url
    }
    
    // Get current title
    open var title: String? {
        return layoutEngine.title
    }

    // Go to specific url
    open func visit(url: Foundation.URL, completionHandler: DocumentCompletionHandler?) {
        layoutEngine.browse(url: url) {[unowned self] (object, error) -> Void in
            self.publish(content: object, error: error, completionHandler: completionHandler)
        }
    }
    
    // Go to specific url
    open func visit(urlString: String, completionHandler: DocumentCompletionHandler?) {
        if let url = URL(string: urlString) {
            visit(url: url, completionHandler: completionHandler)
        } else {
            completionHandler?(nil, ErikError.invalidURL(urlString: urlString))
        }
    }
    
    // Go to specific url using url request
    open func load(urlRequest: Foundation.URLRequest, completionHandler: DocumentCompletionHandler?) {
        layoutEngine.browse(urlRequest: urlRequest) {[unowned self] (object, error) -> Void in
            self.publish(content: object, error: error, completionHandler: completionHandler)
        }
    }

    // Get current content
    open func currentContent(completionHandler: DocumentCompletionHandler?) {
        layoutEngine.currentContent {[unowned self] (object, error) -> Void in
            self.publish(content: object, error: error, completionHandler: completionHandler)
        }
    }
    
    // Navigates to the previous loaded page.
    open func goBack() {
        layoutEngine.goBack()
    }
    
    // Navigates to the next page ie. the one loaded before `goBack`
    open func goForward() {
        layoutEngine.goForward()
    }
    
    // A Boolean value indicating whether browser can go back
    open var canGoBack: Bool {
        return layoutEngine.canGoBack
    }

    // A Boolean value indicating whether browser can go forward
    open var canGoForward: Bool {
        return layoutEngine.canGoForward
    }

    // Reloads the current page
    open func reload() {
        layoutEngine.reload()
    }

    // MARK: private
    fileprivate func publish(content: Any?, error: Error?, completionHandler: DocumentCompletionHandler?) {
        guard let html = content as? String else {
            completionHandler?(nil, ErikError.noContent)
            return
        }
        
        if let pattern = noContentPattern , html.range(of: pattern, options: .regularExpression) != nil {
            completionHandler?(nil, ErikError.noContent)
            return
        }

        guard error == nil else {
            completionHandler?(nil, error)
            return
        }
        
        guard let doc = self.htmlParser.parse(html, encoding: encoding) else {
            completionHandler?(nil, ErikError.htmlNotParsable(html: html))
            return
        }
        
        doc.layoutEngine = layoutEngine
        completionHandler?(doc, error)
    }

}

// MARK: javascript
extension Erik: JavaScriptEvaluator {
    
    public func evaluate(javaScript: String, completionHandler: CompletionHandler?) {
        self.layoutEngine.evaluate(javaScript: javaScript, completionHandler: completionHandler)
    }
}


// MARK: Erik static
extension Erik {
    // Shared instance used for static functions
    public static let sharedInstance = Erik()
    
    public static func visit(url: Foundation.URL, completionHandler: DocumentCompletionHandler?) {
        Erik.sharedInstance.visit(url: url, completionHandler: completionHandler)
    }

    public static func visit(urlString: String, completionHandler: DocumentCompletionHandler?) {
        Erik.sharedInstance.visit(urlString: urlString, completionHandler: completionHandler)
    }

    public static func load(urlRequest: Foundation.URLRequest, completionHandler: DocumentCompletionHandler?) {
        Erik.sharedInstance.load(urlRequest: urlRequest, completionHandler: completionHandler)
    }

    @available(*, deprecated: 1.1, obsoleted: 1.2, message: "Use url")
    public static var currentURL: URL? {
        return Erik.sharedInstance.url
    }
    
    public static var url: URL? {
        return Erik.sharedInstance.url
    }
 
    public static var title: String? {
        return Erik.sharedInstance.title
    }

    public static func currentContent(completionHandler: DocumentCompletionHandler?) {
        Erik.sharedInstance.currentContent(completionHandler: completionHandler)
    }
    
    public static func evaluate(javaScript: String, completionHandler: CompletionHandler?) {
        Erik.sharedInstance.evaluate(javaScript: javaScript, completionHandler: completionHandler)
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
