//
//  WKUserContentController+Erik.swift
//  Erik
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import WebKit

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