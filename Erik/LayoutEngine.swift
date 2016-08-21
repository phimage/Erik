//
//  LayoutEngine.swift
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

public protocol JavaScriptEvaluator {
    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
}

public protocol URLBrowser {
    func browseURL(URL: NSURL, completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
    func browseURL(URLRequest: NSURLRequest, completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
    var url: NSURL? {get}
    var title: String? {get}
    func currentContent(completionHandler: ((AnyObject?, ErrorType?) -> Void)?)
    
    func goBack()
    func goForward()
    
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    func reload()
    
    func clear()
}
public typealias LayoutEngine = protocol<URLBrowser,JavaScriptEvaluator>

let JavascriptErrorHandler = "erikError"
let JavascriptEndHandler = "erikEnd"

import WebKit
public class WebKitLayoutEngine: NSObject, LayoutEngine {
    
    public var javaScriptQueue: Queue = Queue(name: "ErikJavaScript", kind: .Serial)
    public var callBackQueue: Queue = Queue(name: "ErikCallBack", kind: .Serial)
    public var javaScriptWaitTime: NSTimeInterval = 20
    public var javaScriptResultVarName: String = "resultErik"

    public let webView: WKWebView
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        self.webView.configuration.userContentController.addScriptMessageHandler(self, name: JavascriptErrorHandler)
        self.webView.configuration.userContentController.addScriptMessageHandler(self, name: JavascriptEndHandler)
    }

    convenience init(frame: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 768)) {
        self.init(webView: WKWebView(frame: frame, configuration:  WKWebViewConfiguration()))
    }
}


// MARK: URLBrowser
extension WebKitLayoutEngine {

    public func browseURL(URL: NSURL, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        let request = NSURLRequest(URL: URL)
        self.browseURL(request, completionHandler: completionHandler)
    }
    
    public func browseURL(URLRequest: NSURLRequest, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        webView.loadRequest(URLRequest)
        self.currentContent(completionHandler)
    }
    
    @available(*, deprecated=1.1, obsoleted=2.0, message="Use url")
    public var currentURL: NSURL? {
        return self.webView.URL
    }
    
    public var url: NSURL? {
        return self.webView.URL
    }
    
    public var title: String? {
        return self.webView.title
    }

    public func goBack() {
        self.webView.goBack()
    }
    public func goForward() {
        self.webView.goForward()
    }
    
    public var canGoBack: Bool {
        return self.webView.canGoBack
    }

    public var canGoForward: Bool {
        return self.webView.canGoForward
    }

    public func reload() {
        self.webView.reload()
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
    
    public func clear() {
        // try to remove all information
        if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
            for cookie in cookies {
                NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
            }
        }
        webView.configuration.processPool = WKProcessPool()
        // maybe reset url?
    }
}

#if os(iOS)
    public typealias ErikImage = UIImage
#elseif os(OSX)
    public typealias ErikImage = NSImage
#endif
extension WebKitLayoutEngine {
   public func snapshot(size: CGSize) -> ErikImage? {
        #if os(iOS)
            if let capturedView : UIView = self.webView.snapshotViewAfterScreenUpdates(false) {
                UIGraphicsBeginImageContextWithOptions(size, true, 0)
                let ctx = UIGraphicsGetCurrentContext()
                let scale : CGFloat! = size.width / capturedView.layer.bounds.size.width
                let transform = CGAffineTransformMakeScale(scale, scale)
                CGContextConcatCTM(ctx, transform)
                capturedView.drawViewHierarchyInRect(capturedView.bounds, afterScreenUpdates: true)
                let  image : ErikImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext();
                return image
            }
        #elseif os(OSX)
            if let view = self.webView.subviews.first,
                rep: NSBitmapImageRep = view.bitmapImageRepForCachingDisplayInRect(view.bounds) {
                view.cacheDisplayInRect(view.bounds, toBitmapImageRep:rep)
                let image = NSImage(size: size)
                image.addRepresentation(rep)
                return nil //image https://github.com/lemonmojo/WKWebView-Screenshot
            }
        #endif
        return nil
    }
}

// MARK: JavaScriptEvaluator
import Eki
extension WebKitLayoutEngine {
    
    public func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)?) {
        javaScriptQueue.async { [unowned self] in
            let key = NSUUID().UUIDString
            
            
            var source  = "var \(self.javaScriptResultVarName);"
            source += " try { "
            source += javaScriptString
            source += " } catch(err) { "
            source += "window.webkit.messageHandlers.\(JavascriptErrorHandler).postMessage({error: err.message, key: '\(key)'});"
            source += " } finally { "
            source += "window.webkit.messageHandlers.\(JavascriptEndHandler).postMessage({key: '\(key)'});"
            source += " } "
            // TODO return last value computed by javaScriptString like $*
            source +=  "if (\(self.javaScriptResultVarName) != undefined) { var tmpResult = \(self.javaScriptResultVarName); \(self.javaScriptResultVarName) = undefined; tmpResult; };"
  
            
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
                        self.removebox(key)
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
    func removebox(key: String) {
        self.semaphores[key] = nil
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
