//
//  XCStoryboard.swift
//  CodeGen
//
//  Created by DươngPQ on 05/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCInterfaceObject {

    var id: String?
    var customClass: String?

}

class XCFont {

    var key: String?
    var type: String?
    var name: String?
    var family: String?
    var pointSize: String?

}

class XCColor {

    var key: String?
    var name: String?
    var catalog: String?

    var red: String?
    var green: String?
    var blue: String?

    var white: String?

    var cyan: String?
    var magenta: String?
    var yellow: String?
    var black: String?

    var alpha: String?
    var colorSpace: String?
    var customColorSpace: String?

}

class XCNamedColor {

    var name: String?
    var color: XCColor?

}

class XCView: XCInterfaceObject {

    var name = ""
    var subviews: [XCView]?
    var contentMode: String?
    var attributes: [String: String]?
    var font: XCFont?
    var colors = [XCColor]()

}

class XCViewController: XCInterfaceObject {

    var storyboardIdentifier: String?
    var view: XCView?

}

class XCScene: XCInterfaceObject {

    var comment: String?
    var viewControlelr: XCViewController?

}

class XCStoryboard: NSObject, XMLParserDelegate {

    var scenes: [XCScene]?

    private var stack = [Any]()
    private var stackKey = [String]()
    private var commentBuffer: String?

    private(set) var initialVC: String?
    private(set) var useSafeAreas = false
    private(set) var useAutolayout = false
    private(set) var useTraitCollections = false
    private(set) var type = "com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB"
    private(set) var resources = [Any]()

    init?(_ path: String) {
        if let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) {
            super.init()
            parser.delegate = self
            if !parser.parse() { return nil }
        } else {
            return nil
        }
    }

    func parserDidStartDocument(_ parser: XMLParser) {
//        print("START")
    }

    func parserDidEndDocument(_ parser: XMLParser) {
//        print("END")
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
//        print("Start:", elementName, attributeDict)
        let lastKey = stackKey.last ?? ""
        stackKey.append(elementName)
        switch elementName {
        case "document":
            initialVC = attributeDict["initialViewController"]
            useSafeAreas = attributeDict["useSafeAreas"] == "YES"
            useAutolayout = attributeDict["useAutolayout"] == "YES"
            useTraitCollections = attributeDict["useTraitCollections"] == "YES"
            if let t = attributeDict["type"] {
                type = t
            }
        case "scenes":
            scenes = []
        case "scene":
            if lastKey == "scenes" {
                let scene = XCScene()
                stack.append(scene)
                scenes?.append(scene)
                scene.comment = commentBuffer
                commentBuffer = nil
                scene.id = attributeDict["sceneID"]
            }
        case "viewController":
            if lastKey == "objects", let last = stack.last as? XCScene {
                let vc = XCViewController()
                vc.id = attributeDict["id"]
                vc.storyboardIdentifier = attributeDict["storyboardIdentifier"]
                vc.customClass = attributeDict["customClass"]
                last.viewControlelr = vc
                stack.append(vc)
            }
        case "view":
            let v = XCView()
            v.contentMode = attributeDict["contentMode"]
            v.id = attributeDict["id"]
            v.name = elementName
            v.attributes = attributeDict;
            v.subviews = []
            if lastKey == "viewController", let lastObj = stack.last as? XCViewController {
                lastObj.view = v
            } else if lastKey == "subviews", let lastObj = stack.last as? XCView {
                lastObj.subviews?.append(v)
            }
            stack.append(v)
        case "fontDescription":
            if let last = stack.last as? XCView {
                let f = XCFont()
                f.type = attributeDict["type"]
                f.key = attributeDict["key"]
                f.pointSize = attributeDict["pointSize"]
                f.name = attributeDict["name"]
                f.family = attributeDict["family"]
                last.font = f
            }
        case "color":
            let c = XCColor()
            c.key = attributeDict["key"]
            c.name = attributeDict["name"]
            c.catalog = attributeDict["catalog"]
            c.red = attributeDict["red"]
            c.green = attributeDict["blue"]
            c.blue = attributeDict["blue"]
            c.white = attributeDict["white"]
            c.cyan = attributeDict["cyan"]
            c.magenta = attributeDict["magenta"]
            c.yellow = attributeDict["yellow"]
            c.black = attributeDict["black"]
            c.alpha = attributeDict["alpha"]
            c.colorSpace = attributeDict["colorSpace"]
            c.customColorSpace = attributeDict["customColorSpace"]
            if let last = stack.last as? XCView {
                last.colors.append(c)
            } else if let last = stack.last as? XCNamedColor {
                last.color = c
            }
        case "namedColor":
            if lastKey == "resources", stack.count == 0 {
                let nC = XCNamedColor()
                nC.name = attributeDict["name"]
                resources.append(nC)
                stack.append(nC)
            }
        default:
            if lastKey == "subviews", let lastObj = stack.last as? XCView {
                let v = XCView()
                v.name = elementName
                v.contentMode = attributeDict["contentMode"]
                v.id = attributeDict["id"]
                v.name = elementName
                v.attributes = attributeDict;
                v.subviews = []
                lastObj.subviews?.append(v)
                stack.append(v)
            }
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        print("End:", elementName)
        stackKey.removeLast()
        switch elementName {
        case "scene":
            if let _ = stack.last as? XCScene {
                _ = stack.removeLast()
            }
        case "viewController":
            if let _ = stack.last as? XCViewController {
                _ = stack.removeLast()
            }
        case "namedColor":
            if let _ = stack.last as? XCNamedColor {
                _ = stack.removeLast()
            }
        default:
            if let last = stack.last as? XCView, last.name == elementName {
                _ = stack.removeLast()
            }
            break;
        }
    }

    func parser(_ parser: XMLParser, foundComment comment: String) {
        if let cmt = commentBuffer {
            commentBuffer = cmt + "\n" + comment
        } else {
            commentBuffer = comment
        }
    }

}
