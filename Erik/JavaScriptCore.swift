//
//  Java​Script​Core.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import JavaScriptCore

extension JSContext: JavaScriptEvaluator {

    public func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
 
        let value: JSValue = self.evaluateScript(javaScriptString)
        
        // TODO: handle exception
        if value.isUndefined {
            completionHandler?(nil, nil)
        }
        else if value.isNull {
            completionHandler?(nil, nil)
        }
        else if value.isString {
            completionHandler?(value.toString(), nil)
        }
        else {
            completionHandler?(value.toObject(), nil)
        }
    }
}
