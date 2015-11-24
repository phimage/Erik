//
//  WebKit.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation

public protocol JavaScriptEvaluator {
    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
}

public protocol URLBrowser {
    func browseURL(URL: NSURL, completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
    var currentURL: NSURL? {get}
    func currentContent(completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
}
public typealias LayoutEngine = protocol<URLBrowser,JavaScriptEvaluator>

let JavascriptErrorHandler = "erikError"
let JavascriptEndHandler = "erikEnd"

import WebKit
public class WebKitLayoutEngine: NSObject, LayoutEngine {
    
    public var javaScriptQueue: Queue = Queue(name: "ErikJavaScript", kind: .Serial)
    public var callBackQueue: Queue = Queue(name: "ErikCallBack", kind: .Serial)
    public var javaScriptWaitTime: NSTimeInterval = 20

    public let webView: WKWebView
    
    init(frame: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 768)) {
        self.webView = WKWebView(frame: frame, configuration:  WKWebViewConfiguration())
        super.init()
        self.webView.configuration.userContentController.addScriptMessageHandler(self, name: JavascriptErrorHandler)
        self.webView.configuration.userContentController.addScriptMessageHandler(self, name: JavascriptEndHandler)
    }
}


// MARK: URLBrowser
extension WebKitLayoutEngine {

    public func browseURL(URL: NSURL, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        let request = NSURLRequest(URL: URL)
        webView.loadRequest(request)
        self.currentContent(completionHandler)
    }

    public var currentURL: NSURL? {
        return self.webView.URL
    }
    
    public func currentContent(completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        handleLoadRequestCompletion {
            self.handleHTML(completionHandler)
        }
    }
    
    private func handleLoadRequestCompletion(completionHandler: () -> Void) {
        // wait load finish
        while(webView.loading) {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }
        // XXX maybe use instead WKNavigationDelegate#webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!)
        // or notification on loading
        completionHandler()
    }
    
    private func handleHTML(completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        javaScriptQueue.async { [unowned self] in
            let js_getDocumentHTML = "document.documentElement.outerHTML"
            self.webView.evaluateJavaScript(js_getDocumentHTML) { [unowned self] (obj, error) -> Void in
                self.callBackQueue.asyncOrCurrent {
                    completionHandler?(obj, error)
                }
            }
        }
    }
}

// MARK: JavaScriptEvaluator
import Eki
extension WebKitLayoutEngine {
    
    public func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        javaScriptQueue.async { [unowned self] in
            let key = NSUUID().UUIDString
            
            var source = "try { "
            source += javaScriptString
            source += " } "
            source += "catch(err) { "
            source += "window.webkit.messageHandlers.\(JavascriptErrorHandler).postMessage({error: err.message, key: '\(key)'});"
            source += "}"
            source += "finally { "
            source += "window.webkit.messageHandlers.\(JavascriptEndHandler).postMessage({key: '\(key)'});"
            source += "}"
            // TODO return last value computed by javaScriptString like $*
            
            self.expect(key)
            self.webView.evaluateJavaScript(source) {[unowned self] (object, error) -> Void in
                self.callBackQueue.asyncOrCurrent { [unowned self] in // XXX maybe if self.callBackQueue.isCurrent execute the block now
                    
                    if let e = error {
                        completionHandler?(object, e) // must not be called
                        return
                    }
                    
                    if self.wait(key, time: self.javaScriptWaitTime) {
                        if let errorMessage = self.getbox(key) {
                            completionHandler?(object, ErikError.JavaScriptError(message: "\(errorMessage)"))
                        }
                        else {
                            completionHandler?(object, error)
                        }
                    }
                    else {
                        completionHandler?(object, ErikError.TimeOutError)
                    }
                }
            }
        }
    }
}

extension Queue {

    func asyncOrCurrent(block: () -> Void) {
        if self.isCurrent { // ASK Eki to add this function
            block()
        } else {
            self.async(block)
        }
    }

}


extension WebKitLayoutEngine: WKScriptMessageHandler {
    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        if message.name == JavascriptErrorHandler {
            if let dico = message.body as? [String: String], key = dico["key"]{
                self.setbox(key, object: message.body)
            }
        }
        else if message.name == JavascriptEndHandler {
            if let dico = message.body as? [String: String], key = dico["key"]{
                self.signal(key)
            }
        }
    }
}

// MARK: wait on semaphore and result object
// XXX  userContentController is called before, semaphore are useless

extension WebKitLayoutEngine: Semaphorable {}

protocol Semaphorable: AnyObject {}

class SemaphoreBox: AnyObject  {
    let semaphore = Semaphore(.Barrier)
    var object: AnyObject?
}

typealias SemaphorableKey = String

private struct SemaphorableKeys {
    static let semaphores = UnsafePointer<Void>(bitPattern: Selector("semaphores").hashValue)
}
extension Semaphorable {
    
    func expect(key: SemaphorableKey) {
        if (self.semaphores[key] != nil) {
            return /// XXX throw?
        }
        self.semaphores[key] = SemaphoreBox()
    }

    func wait(key: SemaphorableKey, time:NSTimeInterval? = nil) -> Bool {
        guard let box = self.semaphores[key] else {
            return true
        }
        return box.semaphore.wait(time)
    }
    func signal(key: SemaphorableKey) {
        guard let box = self.semaphores[key] else {
            return
        }
        box.semaphore.signal()
    }

    func setbox(key: SemaphorableKey, object: AnyObject) {
        guard let box = self.semaphores[key] else {
            return
        }
        box.object = object
    }
    func getbox(key: SemaphorableKey) -> AnyObject? {
        guard let box = self.semaphores[key] else {
            return nil
        }
        return box.object
    }
    
    var semaphores: [SemaphorableKey: SemaphoreBox] {
        get {
            if let o = objc_getAssociatedObject(self, SemaphorableKeys.semaphores) as? [SemaphorableKey: SemaphoreBox]  {
                return o
            }
            else {
                let obj = [SemaphorableKey: SemaphoreBox]()
                objc_setAssociatedObject(self, SemaphorableKeys.semaphores, obj, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return obj
            }
        }
        set {
            objc_setAssociatedObject(self, SemaphorableKeys.semaphores, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }


}
