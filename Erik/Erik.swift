//
//  Erik.swift
//  Erik
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import WebKit
import Kanna

public class Erik {

    public static var sharedInstance: Browser {
        struct Static {
            static let instance: Browser = Browser(
                layoutEngine:  WKWebView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768), configuration: WKWebViewConfiguration()),
                htmlParser: KanaParser.instance
            )
        }
        return Static.instance
    }
    
    public static func visitURL(URL: NSURL, completionHandler: ((Any?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.visitURL(URL, completionHandler: completionHandler)
    }
    
    public static func evaluateJavaScript(javaScriptString: String, completionHandler: ((Any?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
}

public class KanaParser: HTMLParser {
    
    public static let instance = KanaParser()
    
    public func parseHTML(html: String) -> HTMLDocument? {
        return Kanna.HTML(html: html, encoding: NSUTF8StringEncoding)
    }
}