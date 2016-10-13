//
//  Common.swift
//  TestErik
//
//  Created by phimage on 13/10/16.
//  Copyright © 2016 phimage. All rights reserved.
//

import Foundation

let googleURL = URL(string: "https://www.google.com")!


#if os(OSX)
let googleFormSelector = "f"
#elseif os(iOS)
let googleFormSelector = "gs"
#endif
