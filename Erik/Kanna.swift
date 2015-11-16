//
//  Kanna.swift
//  Erik
//
//  Created by phimage on 16/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import Kanna

public class KanaParser: HTMLParser {
    
    public init() {
        
    }

    public func parseHTML(html: String) -> HTMLDocument? {
        return Kanna.HTML(html: html, encoding: NSUTF8StringEncoding)
    }
}