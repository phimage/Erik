//
//  ViewController.swift
//  TestErik
//
//  Created by phimage on 13/12/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import UIKit
import Erik
import Kanna
import WebKit
import Eki

class ViewController: UIViewController, WKNavigationDelegate {
    let url = NSURL(string: "https://www.google.com")!

    @IBOutlet var redView: UIView!

    var browser: Erik!
    var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Erik"


        let frame = UIScreen.mainScreen().bounds
        webView = WKWebView(frame: frame, configuration:  WKWebViewConfiguration())
        webView.allowsBackForwardNavigationGestures = true
       redView.addSubview(webView)

        webView.navigationDelegate = self

        browser = Erik(webView: webView)
        browser.visitURL(url) { object, error in
            if let e = error {

                print(String(e))
            } else if let doc = object {
                // HTML Inspection
                print(String(doc))
            }
        }


    }

}

