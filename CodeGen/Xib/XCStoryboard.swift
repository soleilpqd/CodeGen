//
//  XCStoryboard.swift
//  CodeGen
//
//  Created by DươngPQ on 05/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCViewController: NSObject {

    enum ViewControllerType: String {
        case placeholder = "viewControllerPlaceholder"
        case viewController
        case tabBarController
        case navigationController
        case tableViewController
        case collectionViewController
        case avPlayerViewController
        case splitViewController
    }

    let type: String
    private(set) var id: String?
    private(set) var storyboardIdentifier: String?
    private(set) var customClass: String?
    private(set) var customModule: String?
    private(set) var customModuleProvider: String?
    fileprivate(set) var segues = [String]()
    fileprivate(set) var tableCells = [(String, String?)]()
    fileprivate(set) var collectionCells = [(String, String?)]()

    var isInitial = false

    weak var storyboard: XCStoryboard?

    init(vcType: String) {
        type = vcType
    }

    func readAttributes(_ attributes: [String: String]) {
        id = attributes["id"]
        storyboardIdentifier = attributes["storyboardIdentifier"]
        customClass = attributes["customClass"]
        customModule = attributes["customModule"]
        customModuleProvider = attributes["customModuleProvider"]
    }

    override var description: String {
        return super.description + (storyboardIdentifier ?? "")
    }

}

class XCIBDocument: NSObject, XMLParserDelegate {

    let path: String
    private(set) var stackKey = [String]()

    private(set) var version: String?
    private(set) var toolsVersion: String?
    private(set) var initialVC: String?
    private(set) var useSafeAreas = false
    private(set) var useAutolayout = false
    private(set) var useTraitCollections = false
    private(set) var type: String? //"com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB"

    private(set) var docName: String = ""
    private(set) var enumName: String = ""

    private var isValid = true

    func generateNames(prefix: String?) {
        docName = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        var name = docName
        if let prefix = prefix, prefix.count > 0, name.hasPrefix(prefix) {
            name = String(name[name.index(name.startIndex, offsetBy: prefix.count)...])
        }
        if name.count > 1 {
            name = String(name[name.startIndex]).lowercased() + String(name[name.index(after: name.startIndex)...])
        }
        enumName = name
    }

    init?(_ path: String) {
        self.path = path
        if let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) {
            super.init()
            parser.delegate = self
            if !parser.parse() { return nil }
            if !isValid { return nil }
        } else {
            return nil
        }
    }

    fileprivate func parseDocumentElement(attributes: [String: String]) {
        type = attributes["type"]
        version = attributes["version"]
        toolsVersion = attributes["toolsVersion"]
        initialVC = attributes["initialViewController"]
        useSafeAreas = attributes["useSafeAreas"] == XCStoryboard.kYesValue
        useAutolayout = attributes["useAutolayout"] == XCStoryboard.kYesValue
        useTraitCollections = attributes["useTraitCollections"] == XCStoryboard.kYesValue
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        stackKey.append(elementName)
        if elementName == "document" && stackKey.count == 1 {
            parseDocumentElement(attributes: attributeDict)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if stackKey.last == elementName {
            _ = stackKey.removeLast()
        } else {
            isValid = false
        }
    }

}

class XCXib: XCIBDocument {

    private(set) var customClass: String?
    private(set) var customModule: String?
    private(set) var customModuleProvider: String?
    private(set) var view: String?

    private(set) var isViewController = false
    private var viewId: String?

    private func readAttributes(_ attributes: [String: String]) {
        customClass = attributes["customClass"]
        customModule = attributes["customModule"]
        customModuleProvider = attributes["customModuleProvider"]
    }

    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        super.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        if stackKey.count == 3 && stackKey[1] == "objects" {
            if elementName == "placeholder" && attributeDict["placeholderIdentifier"] == "IBFilesOwner" {
                readAttributes(attributeDict)
            } else if elementName != "placeholder", let identifier = attributeDict["id"] {
                view = elementName
                if let vId = viewId, vId == identifier {
                    isViewController = true
                } else if attributeDict["customClass"] != nil {
                    readAttributes(attributeDict)
                }
            }
        } else if elementName == "outlet" && stackKey.count == 5 && stackKey[3] == "connections" && stackKey[2] == "placeholder" && attributeDict["property"] == "view" {
            viewId = attributeDict["destination"]
        }
    }


}

class XCStoryboard: XCIBDocument {

    class StoryboardScene: NSObject {

        fileprivate(set) var comment: String?
        fileprivate(set) var objects: [Any]?

    }

    static let kYesValue = "YES"

    private var commentBuffer: String?
    private(set) var scenes: [StoryboardScene]?

    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        super.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
         if elementName == "scenes" && stackKey.count == 2 {
            scenes = []
        } else if elementName == "scene" && stackKey.count == 3, var sceneArray = scenes {
            let scene = StoryboardScene()
            scene.comment = commentBuffer
            commentBuffer = nil
            sceneArray.append(scene)
            scenes = sceneArray
        } else if elementName == "objects" && stackKey.count == 4 && stackKey[2] == "scene", let scene = scenes?.last {
            scene.objects = []
        } else if attributeDict["sceneMemberID"] == "viewController" && stackKey.count == 5 && stackKey[3] == "objects" && stackKey[2] == "scene",
            let scene = scenes?.last, var storage = scene.objects {
            let vc = XCViewController(vcType: elementName)
            vc.readAttributes(attributeDict)
            vc.isInitial = (vc.id == initialVC && initialVC != nil)
            vc.storyboard = self
            storage.append(vc)
            scene.objects = storage
        } else if elementName == "segue" && stackKey.count > 5, let scene = scenes?.last, let vc = scene.objects?.first as? XCViewController, let segue = attributeDict["identifier"] {
            vc.segues.append(segue)
        } else if stackKey.count > 8, let scene = scenes?.last, let vc = scene.objects?.first as? XCViewController {
            if elementName == "tableViewCell", let identifier = attributeDict["reuseIdentifier"] {
                vc.tableCells.append((identifier, attributeDict["customClass"]))
            } else if elementName == "collectionViewCell", let identifier = attributeDict["reuseIdentifier"] {
                vc.collectionCells.append((identifier, attributeDict["customClass"]))
            }
        }
    }

    func parser(_ parser: XMLParser, foundComment comment: String) {
        commentBuffer = comment
    }

}
