# Erik

[![Join the chat at https://gitter.im/phimage/Erik](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/phimage/Erik?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat
            )](http://mit-license.org) [![Platform](http://img.shields.io/badge/platform-ios_osx-lightgrey.svg?style=flat
             )](https://developer.apple.com/resources/) [![Language](http://img.shields.io/badge/language-swift-orange.svg?style=flat
             )](https://developer.apple.com/swift) [![Issues](https://img.shields.io/github/issues/phimage/Erik.svg?style=flat
           )](https://github.com/phimage/Erik/issues) [![Cocoapod](http://img.shields.io/cocoapods/v/Erik.svg?style=flat)](http://cocoadocs.org/docsets/Erik/)


[<img align="left" src="logo.png" hspace="20">](#logo) Erik (The Phantom of Opera) is an headless browser based on WebKit and HTML parser [Kanna](https://github.com/tid-kijyun/Kanna).

An headless browser allow to run functional tests, to access and manipulate webpages.

```swift
let browser = Erik.visitURL(url]) { document, error in
    // browse HTML element, click, submit form
}
```

## Navigation
Go to an url
```swift
Erik.visitURL(url]) { object, error in
   if let e = error {

   } else if let doc = object as? Document {
     // HTML Inspection
   }
}
```
Host to get current url
```swift
Erik.currentURL
```

For multiple browsing you can create an instance of headless browser and use same functions
```swift
let browser = Erik()
browser.visitURL...
```

## HTML Inspection
Search for nodes by CSS selector
```swift
for link in doc.querySelectorAll("a, link") {
    print(link.text)
    print(link["href"])
 }
```
Edit first input field with name "user"
```swift
if let input = doc.querySelectorAll("input[name=\"user\"]").first {
    input["value"] = "Eric"
 }
```

Submit a form
```swift
if let form = doc.querySelector("form[id='search']") as? Form {
    form.submit()
 }
```

:warning: All action on Dom use JavaScript and do not modify the actual
`Document` object and its children `Element`.

You must use `currentContent` to get a refreshed `Document` object
```swift
Erik.currentContent { (obj, err) -> Void in
    if let error = err {
    }
    else if let document = obj {
       // HTML Inspection
    }
}
```
## Links
- [A list of (almost) all headless web browsers in existence](https://github.com/dhamaniasad/HeadlessBrowsers)
- [Wikipédia](https://en.wikipedia.org/wiki/Headless_browser)

# Setup #

## Using [cocoapods](http://cocoapods.org/) ##

Add `pod 'Erik'` to your `Podfile` and run `pod install`.

*Add `use_frameworks!` to the end of the `Podfile`.*

## Roadmap
- [ ] Make javascript evaluation return the last result in callback
- [ ] Refresh Dom element or give a new Document in function callback

## Lisense
The MIT License. See the LICENSE file for more information.
