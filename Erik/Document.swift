//
//  HTMLDocument.swift
//  Erik
//
//  Created by phimage on 18/11/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation

public protocol HTMLParser {
    func parseHTML(html: String) -> Document?
}

import Kanna
class KanaParser: HTMLParser {
    static let instance = KanaParser()

    func parseHTML(html: String) -> Document? {
        if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
            return Document(rawValue: doc)
        }
        return nil
    }
    
    static var escapeJavaScript: String -> String = {
        return $0.stringByReplacingOccurrencesOfString("'", withString: "\\'")
    }
}

public class Document : Node {
    

    
    init(rawValue: HTMLDocument) {
        super.init(rawValue: rawValue, selectors: [])
    }

    var title: String? { return (rawValue as? HTMLDocument)?.title }
    var head: Element? {
        guard let doc = self.rawValue as? HTMLDocument, element = doc.head else {
            return nil
        }
        return Element(rawValue: element, selectors: ["head"])
    }
    var body: Element? {
        guard let doc = self.rawValue as? HTMLDocument, element = doc.body else {
            return nil
        }
        return Element(rawValue: element, selectors: ["body"])
    }
}

public class Node {
    var layoutEngine: LayoutEngine?
    
    var rawValue: SearchableNode
    var selectors = [String]()
    
    public var text: String? { return rawValue.text }
    public var toHTML: String? { return rawValue.toHTML }
    public var innerHTML: String? { return rawValue.innerHTML }
    public var className: String? { return rawValue.className }
    public var tagName:   String? { return rawValue.tagName }
    
    init(rawValue: SearchableNode, selectors: [String]) {
        self.selectors = selectors
        self.rawValue = rawValue
    }
    
    public func querySelectorAll(selector: String) -> [Element] {
        let selectors = self.selectors + [selector]
        return rawValue.css(selector).map {
            let elem = Element.build($0, selectors: selectors)
            elem.layoutEngine = self.layoutEngine
            return elem
        }
    }
    
    public func querySelector(selector: String) -> Element? {
        guard let element = rawValue.at_css(selector) else {
            return nil
        }
        let selectors = self.selectors + ["\(selector):erik-child"]
        let elem = Element.build(element, selectors: selectors)
        elem.layoutEngine = self.layoutEngine
        return elem
    }
    
    public var elements: [Element] {
        return querySelectorAll("*")
    }
    
    public var firstChild: Element? {
        return querySelectorAll(":first-child").first
    }
    
    public var lastChild: Element? {
        return querySelectorAll(":last-child").first
    }
    
}

extension Node: CustomStringConvertible {
    public var description: String {
        return self.toHTML ?? ""
    }
}

public class TextArea: Element {
    
    public func select(completionHandler: ((AnyObject?, ErrorType?) -> Void)? = nil) {
        evaluateJavaScript(jsFunction("select"), completionHandler: completionHandler)
    }
    
}

public class Form: Element {
    
    public func submit(completionHandler: ((AnyObject?, ErrorType?) -> Void)? = nil) {
        evaluateJavaScript(jsFunction("submit"), completionHandler: completionHandler)
    }
    
    public func reset(completionHandler: ((AnyObject?, ErrorType?) -> Void)? = nil) {
        evaluateJavaScript(jsFunction("reset"), completionHandler: completionHandler)
    }
}

public class Element: Node {
    
    static func build(rawValue: XMLElement, selectors: [String]) -> Element {
        if let tagName = rawValue.tagName {
            switch (tagName) {
            case "form":
                return Form(rawValue: rawValue, selectors: selectors)
            case "textarea":
                return TextArea(rawValue: rawValue, selectors: selectors)
            default:
                break
            }
        }
        return Element(rawValue: rawValue, selectors: selectors)
    }
    
    init(rawValue: XMLElement, selectors: [String]) {
        super.init(rawValue: rawValue, selectors: selectors)
    }
    
    public subscript(attr: String) -> String? {
        get {
            return (self.rawValue as! XMLElement)[attr]
        }
        set {
            self.setAttribute(attr, value: newValue)
        }
    }
    
    public func setAttribute(attr: String, value: String?, completionHandler: ((AnyObject?, ErrorType?) -> Void)? = nil) {
        let js = jsChangeAttribute(attr, value: value)
        #if TEST
            print("js:\(js)")
        #endif
        evaluateJavaScript(js, completionHandler: completionHandler)
    }
    
    func jsSelector(varName: String = "erik") -> String {
        if let id = self["id"] { // id must be unique
            return "var \(varName) = document.querySelector('[id=\(id)]')"
        }
        
        return selectors.reduce("var \(varName) = document;\n") { result, selector in
            if selector.endsWith(":erik-child") {
                let erikSelector = selector.stringByReplacingOccurrencesOfString(":erik-child", withString: "")
                return result + "\(varName) = \(varName).querySelector('\(KanaParser.escapeJavaScript(erikSelector))');\n"
            }
            else {
                return result + "\(varName) = \(varName).querySelectorAll('\(KanaParser.escapeJavaScript(selector))')[0];\n"
            }
        }
    }
    
    func jsChangeAttribute(attr: String, value: String?, varName: String = "erik") -> String {
        var js = jsSelector(varName)
        if let v = value {
            js += "\(varName).setAttribute('\(attr)', '\(v)');\n"
        } else {
            js += "\(varName).removeAttribute('\(attr)');\n"
        }
        return js
    }
    
    func jsFunction(name: String, varName: String = "erik") -> String {
        var js = jsSelector(varName) // TODO check undefined?
        js += "\(varName).\(name)();\n"
        #if TEST
            print("js:\(js)")
        #endif
        return js
    }
    
    public func click(completionHandler: ((AnyObject?, ErrorType?) -> Void)? = nil) {
        evaluateJavaScript(jsFunction("click", varName: "testvar"), completionHandler: completionHandler)
    }
    
    func evaluateJavaScript(js: String, completionHandler: ((AnyObject?, ErrorType?) -> Void)? = nil) {
        layoutEngine?.evaluateJavaScript(js, completionHandler: completionHandler)
    }
    
}

extension String {
    func beginsWith (str: String) -> Bool {
        if let range = self.rangeOfString(str) {
            return range.startIndex == self.startIndex
        }
        return false
    }
    
    func endsWith (str: String) -> Bool {
        if let range = self.rangeOfString(str, options:NSStringCompareOptions.BackwardsSearch) {
            return range.endIndex == self.endIndex
        }
        return false
    }
}


public extension Array where Element: Node {
    
    public var toHTML: String? {
        let html = reduce("") {
            if let text = $1.toHTML {
                return $0 + text
            }
            return $0
        }
        return html.isEmpty == false ? html : nil
    }
    
    public var innerHTML: String? {
        let html = reduce("") {
            if let text = $1.innerHTML {
                return $0 + text
            }
            return $0
        }
        return html.isEmpty == false ? html : nil
    }
    
    public var text: String? {
        let html = reduce("") {
            if let text = $1.text {
                return $0 + text
            }
            return $0
        }
        return html
    }
    
}





