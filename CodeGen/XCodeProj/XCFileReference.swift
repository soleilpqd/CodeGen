//
//  XCFileReference.swift
//  XCodeProj
//
//  Created by DươngPQ on 21/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCItem: XCObject {

    enum SourceTree: String {
        case group = "<group>"
        case root = "SOURCE_ROOT"
    }

    var name: String? // VariantGroup + FileRefernce child of VariantGroup
    var path: String?
    var sourceTree: String?
    weak var parent: XCItem?
    var id: String?

    var sourceTreeEnum: SourceTree? {
        if let sTree = sourceTree {
            return SourceTree(rawValue: sTree)
        }
        return nil
    }

    override init?(dic: [String : Any], allObjects: [String : Any]) {
        super.init(dic: dic, allObjects: allObjects)
        name = getString(dic: dic, key: "name")
        path = getString(dic: dic, key: "path")
        sourceTree = getString(dic: dic, key: "sourceTree")
    }

    class func item(from dic: [String : Any], allObjects: [String : Any], itemId: String, parentItem: XCItem?) -> XCItem? {
        if let type = getString(dic: dic, key: "isa"), let typeEnum = XCISA(rawValue: type) {
            var result: XCItem?
            switch typeEnum {
            case .group, .variantGroup:
                result = XCGroup(dic: dic, allObjects: allObjects)
            case .fileRef:
                result = XCFileReference(dic: dic, allObjects: allObjects)
            default:
                break
            }
            if let res = result {
                res.id = itemId
                res.parent = parentItem
            }
            return result
        }
        return nil
    }

    func getFullPath() -> String? {
        var parentPath: String?
        if let p = self.parent, let path = p.getFullPath() {
            parentPath = path
        }
        if let result = path {
            if sourceTreeEnum == .root {
                return result
            } else if let pPath = parentPath {
                return (pPath as NSString).appendingPathComponent(result)
            } else {
                return result
            }
        } else if self.isaEnum == .variantGroup {
            return parentPath
        }
        return nil
    }

}

class XCGroup: XCItem {

    var children: [XCItem]?

    override init?(dic: [String : Any], allObjects: [String : Any]) {
        super.init(dic: dic, allObjects: allObjects)
        if isaEnum != .group && isaEnum != .variantGroup { return nil }
        if let childIds = dic["children"] as? [String] {
            var result = [XCItem]()
            for id in childIds {
                if let itemDic = getDic(dic: allObjects, key: id),
                    let item = XCItem.item(from: itemDic, allObjects: allObjects, itemId: id, parentItem: self) {
                    result.append(item)
                }
            }
            children = result
        }
    }

}

class XCFileReference: XCItem {

    var explicitFileType: String?
    var includeInIndex: Int?
    var lastKnownFileType: String?
    var fileEncoding: Int?

    enum FileType: String {
        case cHeader = "sourcecode.c.h"
        case objc = "sourcecode.c.objc"
        case swift = "sourcecode.swift"
        case storyboard = "file.storyboard"
        case xib = "file.xib"
        case file
        case text
        case gif = "image.gif"
        case png = "image.png"
        case folder = "folder"
        case assets = "folder.assetcatalog"
        case xml = "text.plist.xml"
        case json = "text.json"
        case markdown = "net.daringfireball.markdown"
        case coreDataModel = "wrapper.xcdatamodel"
        case framwork = "wrapper.framework"
        case xcconfig = "text.xcconfig"
        case strings = "text.plist.strings"
    }

    var lastKnownFileTypeEnum: FileType? {
        get {
            if let type = lastKnownFileType {
                return FileType(rawValue: type)
            }
            return nil
        }
        set (value) {
            lastKnownFileType = value?.rawValue
        }
    }

    override init?(dic: [String : Any], allObjects: [String : Any]) {
        super.init(dic: dic, allObjects: allObjects)
        if isaEnum != .fileRef { return nil }
        explicitFileType = getString(dic: dic, key: "explicitFileType")
        includeInIndex = getInt(dic: dic, key: "includeInIndex")
        lastKnownFileType = getString(dic: dic, key: "lastKnownFileType")
        fileEncoding = getInt(dic: dic, key: "fileEncoding")
    }

}

func findItem(group: XCGroup, key: String) -> XCItem? {
    if group.id == key { return group }
    if let children = group.children {
        for item in children {
            if item.id == key { return item }
            if let grp = item as? XCGroup, let subItem = findItem(group: grp, key: key) {
                return subItem
            }
        }
    }
    return nil
}
