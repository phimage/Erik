//
//  WebKit.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import WebKit

// MARK: WKWebView as JavaScriptEvaluator & URLBrowserluator {}

extension WKWebView: LayoutEngine {

    public func browseURL(URL: NSURL, completionHandler: ((Any?, ErrorType?) -> Void)?) {
        let request = NSURLRequest(URL: URL)
        self.loadRequest(request)
        handleLoadRequestCompletion {
            self.handleHTML(completionHandler)
        }
    }
    public var resources: Bool {return true}
    
    private func handleLoadRequestCompletion(completionHandler: () -> Void) {
        // wait load finish
        while(self.loading) {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }
        // XXX maybe use instead WKNavigationDelegate#webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!)
        completionHandler()
    }
    
    private func handleHTML(completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        let js_getDocumentHTML = "document.documentElement.outerHTML"
        self.evaluateJavaScript(js_getDocumentHTML) { (obj, error) -> Void in
            completionHandler?(obj,error)
        }
    }
}
