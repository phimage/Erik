//
//  Foundation.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation

extension NSURLSession: URLBrowser {
    
    public func browseURL(URL: NSURL, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        self.dataTaskWithURL(URL) { (data, response, error) -> Void in
            if let e = error {
                completionHandler?(data, e)
            }
            else if let d = data, string = String(data: d, encoding: NSUTF8StringEncoding){
                completionHandler?(string, nil)
            }
            else {
                let e = NSError(domain: ErikErrorKey, code: 1, userInfo: ["message": "Cannot get HTML"])
                completionHandler?(nil, e)
            }
        }
    }

    public var resources: Bool {return false}
    
}

