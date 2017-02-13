//
//  Document.swift
//  Erik
/*
The MIT License (MIT)
Copyright (c) 2015-2016 Eric Marchand (phimage)
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
import Foundation

public protocol HTMLParser {
    func parse(_ html: String, encoding: String.Encoding) -> Document?
}

import Kanna
class KanaParser: HTMLParser {
    static let instance = KanaParser()

    func parse(_ html: String, encoding: String.Encoding) -> Document? {
        if let doc = Kanna.HTML(html: html, encoding: encoding) {
            return Document(rawValue: doc)
        }
        return nil
    }
    
    static var escapeJavaScript: (String) -> String = {
        return $0.replacingOccurrences(of: "'", with: "\\'")
    }
}

open class Document: Node {

    init(rawValue: HTMLDocument) {
        super.init(rawValue: rawValue, selectors: [])
    }
    
    open override var document: Document? { get {return self} set {} }

    open var title: String? { return (rawValue as? HTMLDocument)?.title }
    open var head: Element? {
        guard let doc = self.rawValue as? HTMLDocument, let element = doc.head else {
            return nil
        }
        return Element(rawValue: element, selectors: ["head"])
    }
    open var body: Element? {
        guard let doc = self.rawValue as? HTMLDocument, let element = doc.body else {
            return nil
        }
        return Element(rawValue: element, selectors: ["body"])
    }
}

// HTML Node
open class Node {
    var layoutEngine: LayoutEngine?
    open var document: Document?
    
    open var parent: Node? {
        didSet {
            self.layoutEngine = parent?.layoutEngine
            self.document = parent?.document
        }
    }
    
    var rawValue: SearchableNode
    var selectors = [String]()
    var index: Int
    
    open var text: String? { return rawValue.text }
    open var toHTML: String? { return rawValue.toHTML }
    open var toXML: String? { return rawValue.toXML }
    open var innerHTML: String? { return rawValue.innerHTML }
    open var className: String? { return rawValue.className }
    open var tagName: String? { return rawValue.tagName }
    open var content: String? {
        get { return rawValue.content}
        set {
            rawValue.content = newValue

            if let html = document?.text {
                layoutEngine?.load(htmlString: html, baseURL: layoutEngine?.url)
            }
            else {
                assertionFailure("unable to update html")
            }
        }
    }
    
    init(rawValue: SearchableNode, selectors: [String], index: Int = 0) {
        self.selectors = selectors
        self.rawValue = rawValue
        self.index = index
    }
    
    // Select elements using css selector
    open func querySelectorAll(_ selector: String) -> [Element] {
        let selectors = self.selectors + [selector]
        var elements = [Element]()
        for (index, value) in rawValue.css(selector).enumerated() {
            let elem = Element.build(value, selectors: selectors, index: index)
            elem.parent = self
            elements.append(elem)
        }
        return elements
    }
    
    // Select an element using css selector
    open func querySelector(_ selector: String) -> Element? {
        guard let element = rawValue.at_css(selector) else {
            return nil
        }
        let selectors = self.selectors + ["\(selector):erik-child"]
        let elem = Element.build(element, selectors: selectors, index: 0)
        elem.parent = self
        return elem
    }
    
    // Get all children element
    open var elements: [Element] {
        return querySelectorAll("*")
    }
    
    // Get first child element
    open var firstChild: Element? {
        return querySelectorAll(":first-child").first
    }
    
    // Get last child element
    open var lastChild: Element? {
        return querySelectorAll(":last-child").first
    }
    
    open subscript(index: Int) -> Element? {
        let e = elements
        guard index < e.count else {
            return nil
        }
        return e[index]
    }

    open func forEach(body: (Element) throws -> Void) throws {
        try elements.forEach(body)
    }

}

extension Node {
    
    // Fill value of selected child
    public func type(_ selector: String, value: String, key: String = "value") -> Element? {
        if let element = self.querySelector(selector) {
            element[key] = value
            return element
        }
        return nil
    }

    // Click on selected child
    public func click(_ selector: String) -> Element? {
        if let element = self.querySelector(selector) {
            element.click()
            return element
        }
        return nil
    }

}

extension Node: CustomStringConvertible {
    public var description: String {
        return self.toHTML ?? ""
    }
}

open class TextArea: Element {
    
    open func select(_ completionHandler: CompletionHandler? = nil) {
        evaluate(javaScript: jsFunction("select"), completionHandler: completionHandler)
    }
    
}

open class Form: Element {
    
    open func submit(completionHandler: CompletionHandler? = nil) {
        evaluate(javaScript: jsFunction("submit"), completionHandler: completionHandler)
    }
    
    open func reset(completionHandler: CompletionHandler? = nil) {
        evaluate(javaScript: jsFunction("reset"), completionHandler: completionHandler)
    }
}

open class Select: Element {
    open func set(selectedIndex index: Int, completionHandler: CompletionHandler? = nil) {
        let js = jsSelectedIndex(index)
        #if TEST
            print("js:\(js)")
        #endif
        evaluate(javaScript: js, completionHandler: completionHandler)
    }

    func jsSelectedIndex(_ index: Int, varName: String = "erik") -> String {
        var js = jsSelector(varName)
        js += "\(varName).selectedIndex = '\(index)';"
        return js
    }
}
open class Element: Node {
    
    static func build(_ rawValue: Kanna.XMLElement, selectors: [String], index: Int) -> Element {
        if let tagName = rawValue.tagName {
            switch (tagName) {
            case "form":
                return Form(rawValue: rawValue, selectors: selectors, index: index)
            case "textarea":
                return TextArea(rawValue: rawValue, selectors: selectors, index: index)
            case "select":
                return Select(rawValue: rawValue, selectors: selectors, index: index)
            default:
                break
            }
        }
        return Element(rawValue: rawValue, selectors: selectors, index: index)
    }
    
    init(rawValue: Kanna.XMLElement, selectors: [String], index: Int = 0) {
        super.init(rawValue: rawValue, selectors: selectors, index: index)
    }
    
    open subscript(attribute: String) -> String? {
        get {
            return (self.rawValue as! Kanna.XMLElement)[attribute]
        }
        set {
            self.set(attribute: attribute, value: newValue)
        }
    }
    
    open func set(attribute: String, value: String?, completionHandler: CompletionHandler? = nil) {
        let js = jsChangeAttribute(attribute, value: value)
        #if TEST
            print("js:\(js)")
        #endif
        evaluate(javaScript: js, completionHandler: completionHandler)
    }

    open func set(value: String?, completionHandler: CompletionHandler? = nil) {
        let js = jsValue(value)
        #if TEST
            print("js:\(js)")
        #endif
        evaluate(javaScript: js, completionHandler: completionHandler)
    }

    open func click(completionHandler: CompletionHandler? = nil) {
        evaluate(javaScript: jsFunction("click"), completionHandler: completionHandler)
    }

    func jsSelector(_ varName: String = "erik") -> String {
        if let id = self["id"] { // id must be unique
            return "var \(varName) = document.querySelector('[id=\"\(id)\"]');\n"
        }

        return selectors.reduce("var \(varName) = document;\n") { result, selector in
            if selector.hasSuffix(":erik-child") {
                let erikSelector = selector.replacingOccurrences(of: ":erik-child", with: "")
                return result + "\(varName) = \(varName).querySelector('\(KanaParser.escapeJavaScript(erikSelector))');\n"
            }
            else {
                return result + "\(varName) = \(varName).querySelectorAll('\(KanaParser.escapeJavaScript(selector))')[\(index)];\n"
            }
        }
    }
    
    func jsChangeAttribute(_ attr: String, value: String?, varName: String = "erik") -> String {
        var js = jsSelector(varName)
        if let v = value {
            js += "\(varName).setAttribute('\(attr)', '\(v)');\n"
        } else {
            js += "\(varName).removeAttribute('\(attr)');\n"
        }
        return js
    }

    func jsValue(_ value: String?, varName: String = "erik") -> String {
        var js = jsSelector(varName)
        if let v = value {
            js += "\(varName).value = '\(v)';"
        } else {
            js += "\(varName).value = '';"
        }
        return js
    }
    
    func jsFunction(_ name: String, varName: String = "erik") -> String {
        var js = jsSelector(varName) // TODO check undefined?
        js += "\(varName).\(name)();\n"
        #if TEST
            print("js:\(js)")
        #endif
        return js
    }

    func evaluate(javaScript: String, completionHandler: CompletionHandler? = nil) {
        layoutEngine?.evaluate(javaScript: javaScript, completionHandler: completionHandler)
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
