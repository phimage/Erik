//
//  ViewController.swift
//  TestErikOSX
//
//  Created by phimage on 13/12/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Cocoa
import Erik
import Kanna
import WebKit
import Eki


class ViewController: NSViewController {
    var browser: Erik!
    var webView: WKWebView!
    let url = NSURL(string: "http://www.google.com")!

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame:  self.view.bounds, configuration:  WKWebViewConfiguration())
        self.webView.frame = self.view.bounds

         self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.webView)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view":self.webView]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view":self.webView]))

        browser = Erik(webView: webView)
        browser.visitURL(url) { object, error in
            if let e = error {
                print(String(e))
            } else if let doc = object {
                print(String(doc))
            }
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

