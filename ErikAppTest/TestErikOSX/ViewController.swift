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


class ViewController: NSViewController {
    var browser: Erik!
    var webView: WKWebView!
    @IBOutlet weak var mainView: NSView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: self.mainView.bounds, configuration:  WKWebViewConfiguration())
        self.webView.frame = self.mainView.bounds
        
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.mainView.addSubview(self.webView)
        self.mainView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view":self.webView]))
        self.mainView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view":self.webView]))

        browser = Erik(webView: webView)
        browser.visit(url: googleURL) { object, error in
            if let e = error {
                print(String(describing: e))
            } else if let doc = object {
                print(String(describing: doc))
            }
        }
    }

    @IBAction func testAction(_ sender: AnyObject) {
        
        browser.currentContent { (d, r) in
            if let error = r {
                NSAlert(error: error).runModal()
            }
            else if let doc = d {
                if let input = doc.querySelector("input[name='q']") {
                    print(input)
                    input["value"] = "Erik swift"
                   
                }
                if let form = doc.querySelector("form") as? Form {
                    print(form)
                    form.submit()
                }
                
            }
        }
    }

    @IBAction func reload(_ sender: AnyObject) {
        browser.visit(url: browser.url ?? googleURL) { (object, error) in
            if let e = error {
                print(String(describing: e))
            } else if let doc = object {
                print(String(describing: doc))
            }
        }
    }

}

