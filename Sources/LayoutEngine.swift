//
//  LayoutEngine.swift
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

public typealias CompletionHandler = ((Any?, Error?) -> Void)

public protocol JavaScriptEvaluator {
    func evaluate(javaScript: String, completionHandler: CompletionHandler?)
}

public protocol URLBrowser {
    func browse(url: URL, completionHandler: CompletionHandler?)
    func browse(urlRequest: URLRequest, completionHandler: CompletionHandler?)
    
    func load(htmlString: String, baseURL: URL?)
    
    var url: URL? {get}
    var title: String? {get}
    func currentContent(completionHandler: CompletionHandler?)
    
    func goBack()
    func goForward()
    
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    func reload()
    
    func clear()
}
public typealias LayoutEngine = URLBrowser & JavaScriptEvaluator

let JavascriptErrorHandler = "erikError"
let JavascriptEndHandler = "erikEnd"

// Protocole which define a navigate boolean
// Useful to know if currently in navigation processs
public protocol Navigable {
    var navigate: Bool {get set}
}

import WebKit
open class WebKitLayoutEngine: NSObject, LayoutEngine {

    // Policy to detect page loading end
    public enum PageLoadedPolicy {
        // `webView.isLoading`
        case isLoading
        // `webView.estimatedProgress`
        case estimatedProgress
        // `webView.estimatedProgress`
        case navigationDelegate
        // `navigationDelegate`

        var continueCondition: (WebKitLayoutEngine) -> Bool {
            switch self {
            case .isLoading:
                return { return $0.webView.isLoading }
            case .estimatedProgress:
                return { engine in
                    let estimatedProgress = engine.webView.estimatedProgress
                    if engine.firstPageLoaded {
                         return estimatedProgress != 1.0
                    }
                    return estimatedProgress != 1.0 && estimatedProgress != 0.0
                }
            case .navigationDelegate:
                return { engine in
                    if let delegate = engine.navigable {
                        assert(engine.navigable as? WKNavigationDelegate === engine.webView.navigationDelegate)
                        return delegate.navigate
                    }
                    assertionFailure("No navigation deletage found")
                    return false
                }
            }
        }
    }
    
    // javascript method to get page content
    public enum JavascriptToGetContent {
        case outerHTML
        case innerHTML
        case custom(javascript: String)
        
        var javascript: String {
            switch self {
            case .outerHTML:
                return "document.documentElement.outerHTML.toString()"
            case .innerHTML:
                return  "document.documentElement.innerHTML"
            case .custom(let js):
                return js
            }
        }
        
    }
    
    // policy to detect page loading end
    public var pageLoadedPolicy: PageLoadedPolicy = .isLoading {
        didSet {
            if self.pageLoadedPolicy == .navigationDelegate {
                assert(navigable != nil) // a delegate is already set in webview, cannot use this method
            }
        }
    }
    // javascript used to get page content
    public var javascriptToGetContent: JavascriptToGetContent = .outerHTML
    
    fileprivate var navigable: Navigable?
    // Timeout for page loading end detection
    open var pageLoadTimeout: TimeInterval = 20
    // true if first page loaded
    open fileprivate(set) var firstPageLoaded = false

    // Serial queue where javascript is executed
    open var javaScriptQueue = DispatchQueue(label: "ErikJavaScript")
    // Serial queue where functions callbacks are executed
    open var callBackQueue = DispatchQueue(label: "ErikCallBack")
    // Serial queue where Erik wait for page loading
    open var waitLoadingQueue = DispatchQueue(label: "ErikLoading")
    // Timeout for javascript execution (to get error, or return value)
    open var javaScriptWaitTime: TimeInterval = 20
    // Default name of javascript variable to get a return value
    open var javaScriptResultVarName: String = "resultErik"

    open let webView: WKWebView
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        self.webView.configuration.userContentController.add(self, name: JavascriptErrorHandler)
        self.webView.configuration.userContentController.add(self, name: JavascriptEndHandler)
        
        if self.webView.navigationDelegate == nil {
            let delegate = LayoutEngineNavigationDelegate()
            self.webView.navigationDelegate = delegate
            self.navigable = delegate
            self.pageLoadedPolicy = .navigationDelegate
        } else if let navigable = webView.navigationDelegate as? Navigable {
            self.navigable = navigable
            self.pageLoadedPolicy = .navigationDelegate
        }
    }

    convenience init(frame: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 768)) {
        self.init(webView: WKWebView(frame: frame, configuration:  WKWebViewConfiguration()))
    }
}

// MARK: WKNavigationDelegate
open class LayoutEngineNavigationDelegate: NSObject, WKNavigationDelegate, Navigable {
    
    public var navigate: Bool = false
    public var lastError: Error?
    
    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        //self.navigate = true
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    open func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
       // self.navigate = true
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.navigate = false
    }
    
    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.navigate = false
        self.lastError = error
    }
    
    @available(OSX 10.11, *)
    open func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        self.navigate = false
    }
}

// MARK: URLBrowser
extension WebKitLayoutEngine {

   @nonobjc public func browse(url: Foundation.URL, completionHandler: CompletionHandler?) {
        let request = URLRequest(url: url)
        self.browse(urlRequest: request, completionHandler: completionHandler)
    }
    
    @nonobjc public func browse(urlRequest: Foundation.URLRequest, completionHandler: CompletionHandler?) {
        self.firstPageLoaded = true
        self.navigable?.navigate = true
        webView.load(urlRequest)
        self.currentContent(completionHandler: completionHandler)
    }

    public func load(htmlString: String, baseURL: URL?) {
        webView.loadHTMLString(htmlString, baseURL: baseURL)
    }
   
    public var url: URL? {
        return self.webView.url
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

    public func currentContent(completionHandler: CompletionHandler?) {
        waitLoadingQueue.async { [unowned self] in
            self.handleLoadRequestCompletion { error in
                if let error = error  {
                    self.callBackQueue.asyncOrCurrent {
                        completionHandler?(nil, error)
                    }
                } else {
                    self.handleHTML(completionHandler)
                }
            }
        }
    }

    fileprivate func handleLoadRequestCompletion(completionHandler: (Error?) -> Void) {
        // wait load finish
        let condition = pageLoadedPolicy.continueCondition
        let max = NSDate().timeIntervalSince1970 + pageLoadTimeout
        while(condition(self)) {
            if pageLoadTimeout > 0 && NSDate().timeIntervalSince1970 > max  {
                completionHandler(ErikError.timeOutError(time: pageLoadTimeout))
                return
            }
            RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture)
        }
        completionHandler(nil)
    }
    
    fileprivate func handleHTML(_ completionHandler: CompletionHandler?) {
        javaScriptQueue.async { [unowned self] in
         
            self.webView.evaluateJavaScript(self.javascriptToGetContent.javascript) { [unowned self] (obj, error) -> Void in
                self.callBackQueue.async {
                    completionHandler?(obj, error)
                }
            }
        }
    }
    
    public func clear() {
        // try to remove all information
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
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
   public func snapshot(_ size: CGSize) -> ErikImage? {
        #if os(iOS)
            if let capturedView: UIView = self.webView.snapshotView(afterScreenUpdates: false) {
                UIGraphicsBeginImageContextWithOptions(size, true, 0)
                let ctx = UIGraphicsGetCurrentContext()
                let scale: CGFloat! = size.width / capturedView.layer.bounds.size.width
                let transform = CGAffineTransform(scaleX: scale, y: scale)
                ctx?.concatenate(transform)
                capturedView.drawHierarchy(in: capturedView.bounds, afterScreenUpdates: true)
                let image: ErikImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext();
                return image
            }
        #elseif os(OSX)
            if let view = self.webView.subviews.first,
                let rep: NSBitmapImageRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to:rep)
                let image = NSImage(size: size)
                image.addRepresentation(rep)
                return nil //image https://github.com/lemonmojo/WKWebView-Screenshot
            }
        #endif
        return nil
    }
}

// MARK: JavaScriptEvaluator

extension WebKitLayoutEngine {
    
    public func evaluate(javaScript: String, completionHandler: CompletionHandler?) {
        javaScriptQueue.async { [unowned self] in
            let key = UUID().uuidString
            
            
            var source  = "var \(self.javaScriptResultVarName);"
            source += " try { "
            source += javaScript
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
                    let timeout = self.javaScriptWaitTime
                    let result = self.wait(key, timeout: DispatchTime.now() + DispatchTimeInterval.seconds(Int(timeout)))
                    
                    if case DispatchTimeoutResult.success = result {
                        if let errorMessage = self.getbox(key) {
                            completionHandler?(object, ErikError.javaScriptError(message: "\(errorMessage)"))
                        }
                        else {
                            completionHandler?(object, error)
                        }
                        self.removebox(key)
                    }
                    else {
                        completionHandler?(object, ErikError.timeOutError(time: timeout))
                    }
                }
            }
        }
    }
}

extension DispatchQueue {

    func asyncOrCurrent(_ block: @escaping () -> Void) {
        self.async(execute: block)
    }

}


extension WebKitLayoutEngine: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == JavascriptErrorHandler {
            if let dico = message.body as? [String: String], let key = dico["key"]{
                self.setbox(key, object: message.body as AnyObject)
            }
        }
        else if message.name == JavascriptEndHandler {
            if let dico = message.body as? [String: String], let key = dico["key"]{
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
    let semaphore = DispatchSemaphore(value: 0)
    var object: AnyObject?
}

typealias SemaphorableKey = String

private struct SemaphorableKeys {
    static let semaphores = UnsafeRawPointer(bitPattern: Selector(("semaphores")).hashValue)
}
extension Semaphorable {
    
    func expect(_ key: SemaphorableKey) {
        if (self.semaphores[key] != nil) {
            return /// XXX throw?
        }
        self.semaphores[key] = SemaphoreBox()
    }

    func wait(_ key: SemaphorableKey, timeout: DispatchTime) -> DispatchTimeoutResult {
        guard let box = self.semaphores[key] else {
            return DispatchTimeoutResult.success
        }
        return box.semaphore.wait(timeout: timeout)
    }
    func signal(_ key: SemaphorableKey) {
        guard let box = self.semaphores[key] else {
            return
        }
        box.semaphore.signal()
    }

    func setbox(_ key: SemaphorableKey, object: AnyObject) {
        guard let box = self.semaphores[key] else {
            return
        }
        box.object = object
    }
    func getbox(_ key: SemaphorableKey) -> AnyObject? {
        guard let box = self.semaphores[key] else {
            return nil
        }
        return box.object
    }
    func removebox(_ key: String) {
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
