//
//  WebKit.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import WebKit

// MARK: WKWebView as JavaScriptEvaluator & URLBrowser
extension WKWebView: JavaScriptEvaluator {}

extension WKWebView: URLBrowser {

    public func browseURL(URL: NSURL, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
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

// MARK: WKUserContentController as JavaScriptEvaluator

private let JSENotificationKey = "uccjse"
extension WKUserContentController: JavaScriptEvaluator {
    
    func initialize() {
        self.addScriptMessageHandler(self, name: JSENotificationKey)
    }
    
    public func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        
        var source = "try {"
        source +=  "window.webkit.messageHandlers.\(JSENotificationKey).postMessage({body: javaScriptString});"
        source += "}"
        source +=  "catch(err) {"
        source +=  "window.webkit.messageHandlers.\(JSENotificationKey).postMessage({error: err.message});"
        source += "}"
        
        let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
        
        self.addUserScript(userScript)
        
        
        // wait on finish (maybe need some id in js to wait the good one
        
        
    }
}

extension WKUserContentController: WKScriptMessageHandler {
    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        assert(message.name == JSENotificationKey)
        
        print(message.body)
    }
}

