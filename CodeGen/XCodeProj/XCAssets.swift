//
//  XCAssets.swift
//  CodeGen
//
//  Created by Phạm Quang Dương on 25/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

enum XCIdiom: String {
    case universal
    case iphone
    case ipad
    case watch // colorset
    case tv // colorset
    case mac // colorset
    case artwork = "ios-marketing" // iTunes ArtWork - AppIcon only

    static func new(_ value: String?) -> XCIdiom? {
        if let val = value {
            return XCIdiom(rawValue: val)
        }
        return nil
    }
}

class XCAsset: CustomStringConvertible {

    enum AssetExtension: String {
        case folder = ""
        case colorset
        case imageset
        case appiconset
    }

    weak var parent: XCAsset?

    var name: String = ""

    var description: String {
        let res = type(of: self)
        return "\(res) \"\(name)\""
    }

}

class XCAssetFoler: XCAsset {

    var children: [XCAsset]?

    private class func loadJson(_ path: String) -> [String: Any]? {
        if let data = NSData(contentsOfFile: path) as Data?,
            let json = try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)) as? [String: Any] {
            return json
        }
        return nil
    }

    init(path: String, parentAssets: XCAsset?) {
        super.init()
        parent = parentAssets
        name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        if let subItems = try? FileManager.default.contentsOfDirectory(atPath: path) {
            var result = [XCAsset]()
            for item in subItems where !item.hasPrefix(".") {
                let p = (path as NSString).appendingPathComponent(item)
                let n = (item as NSString).deletingPathExtension
                let contentPath = (p as NSString).appendingPathComponent("Contents.json")
                if let ext = AssetExtension(rawValue: (item as NSString).pathExtension) {
                    switch ext {
                    case .folder:
                        result.append(XCAssetFoler(path: p, parentAssets: self))
                    case .colorset:
                        if let json = XCAssetFoler.loadJson(contentPath), let clSet = XCAssetColor(info: json, folder: self) {
                            clSet.name = n
                            result.append(clSet)
                        }
                    case .imageset:
                        if let json = XCAssetFoler.loadJson(contentPath), let imgSet = XCAssetImage(json) {
                            imgSet.parent = self
                            imgSet.name = n
                            result.append(imgSet)
                        }
                    case .appiconset:
                        if let json = XCAssetFoler.loadJson(contentPath), let imgSet = XCAssetAppIcon(json) {
                            imgSet.name = n
                            imgSet.parent = self
                            result.append(imgSet)
                        }
                    }
                }
            }
            if result.count > 0 { children = result }
        }
    }

}

class XCAssetImage: XCAsset {

    struct ImageInfo {
        var size: String? // AppIcon only
        var idiom: String?
        var filename: String?
        var scale: String? // nil => pdf

        var scaleNum: UInt? {
            if let value = scale, value.hasSuffix("x") {
                return UInt(String(value[value.startIndex..<value.index(value.endIndex, offsetBy: -1)]))
            }
            return nil
        }

        init?(_ info: [String: String]) {
            if let name = info["filename"] {
                filename = name
                size = info["size"]
                idiom = info["idiom"]
                scale = info["scale"]
            } else {
                return nil
            }
        }

    }

    var images: [ImageInfo]?

    init?(_ info: [String: Any]) {
        if let imagesInfo = info["images"] as? [[String: String]] {
            var result = [ImageInfo]()
            for info in imagesInfo {
                if let img = ImageInfo(info) {
                    result.append(img)
                }
            }
            if result.count == 0 { return nil }
            images = result
        } else {
            return nil
        }
    }
}

class XCAssetAppIcon: XCAssetImage {

}

class XCAssets: XCAssetFoler {

    weak var fileRef: XCFileReference?

    init(fileReference: XCFileReference, path: String) {
        fileRef = fileReference
        super.init(path: path, parentAssets: nil)
    }

}
