//
//  Erik.swift
//  Erik
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import WebKit

public class Erik {

    public static var sharedInstance: Browser {
        struct Static {
            static let instance: Browser = Browser (
                layoutEngine: WKWebView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768), configuration: WKWebViewConfiguration.build()),
                htmlParser: KanaParser.instance
            )
        }
        return Static.instance
    }
    
    public static func visitURL(URL: NSURL, completionHandler: ((Document?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.visitURL(URL, completionHandler: completionHandler)
    }

    public static func getContent(completionHandler: ((Document?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.getContent(completionHandler)
    }
    
    public static func evaluateJavaScript(javaScriptString: String, completionHandler: ((Any?, ErrorType?) -> Void)?) {
        Erik.sharedInstance.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

}

import Kanna
private class KanaParser: HTMLParser {
    
    private static let instance = KanaParser()
    
    private func parseHTML(html: String) -> Document? {
        if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
            return Document(rawValue: doc)
        }
        return nil
    }
}