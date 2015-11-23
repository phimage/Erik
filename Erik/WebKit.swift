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

    public func browseURL(URL: NSURL, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        let request = NSURLRequest(URL: URL)
        self.loadRequest(request)
        self.getContent(completionHandler)
    }
    public var resources: Bool {return true}
    
    public func getContent(completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        handleLoadRequestCompletion {
            self.handleHTML(completionHandler)
        }
    }
    
    private func handleLoadRequestCompletion(completionHandler: () -> Void) {
        // wait load finish
        while(self.loading) {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }
        // XXX maybe use instead WKNavigationDelegate#webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!)
        // or notification on loading
        completionHandler()
    }
    
    private func handleHTML(completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        let js_getDocumentHTML = "document.documentElement.outerHTML"
        self.evaluateJavaScript(js_getDocumentHTML) { (obj, error) -> Void in
            completionHandler?(obj, error)
        }
    }
}

let JSENotificationKey = "erik"
extension WKWebViewConfiguration {
    
    static func build() -> WKWebViewConfiguration {
        let conf = WKWebViewConfiguration()
        conf.userContentController.addScriptMessageHandler(conf, name: JSENotificationKey)
        return conf
    }
    
}

extension WKWebViewConfiguration: WKScriptMessageHandler {
    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        assert(message.name == JSENotificationKey)
        
        print(message.body)
    }
}
