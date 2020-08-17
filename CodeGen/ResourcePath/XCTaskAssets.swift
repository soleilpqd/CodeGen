//
//  XCTaskAssets.swift
//  CodeGen
//
//  Created by DươngPQ on 10/4/19.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

final class XCTaskAssets: XCTask {

    private let output: String
    private let suffix: [String]?

    init?(_ info: NSDictionary) {
        if let target = info["output"] as? String, target.count > 0 {
            output = target
            if let list = info["suffix"] as? [String], list.count > 0 {
                suffix = list
            } else {
                suffix = nil
            }
            super.init(task: .assets)
        } else {
            return nil
        }
    }

    private func validateAssets(_ assets: XCAssetFoler) -> Bool {
        guard let items = assets.children else { return false }
        for item in items {
            if (item is XCAssetImage) && !(item is XCAssetAppIcon) {
                return true
            } else if let folderAsset = item as? XCAssetFoler, validateAssets(folderAsset) {
                return true
            }
        }
        return false
    }

    private func findSuffix(of image: XCAssetImage, in list: [String]) -> String? {
        for item in list where image.name.hasSuffix(item) {
            return item
        }
        return nil
    }

    /// - returns: [(main-image, [suffix])]
    private func groupImagesForSuffix(_ images: [XCAssetImage]) -> [(XCAssetImage, [String])] {
        guard let list = suffix else { return [] }
        var buffer = [String: [XCAssetImage]]()
        for image in images {
            var name = image.name
            if let suff = findSuffix(of: image, in: list) {
                name = String(name[..<name.index(name.endIndex, offsetBy: -suff.count)])
            }
            var gImages = buffer[name] ?? []
            gImages.append(image)
            buffer[name] = gImages
        }
        var result = [(XCAssetImage, [String])]()
        for (name, imgList) in buffer {
            if imgList.count > 1 {
                var imgSuff = [String]()
                var mainItem: XCAssetImage?
                for image in imgList {
                    if image.name == name {
                        mainItem = image
                    } else {
                        var suff = image.name
                        suff = String(suff[suff.index(suff.startIndex, offsetBy: name.count)...])
                        imgSuff.append(suff)
                    }
                }
                if let item = mainItem {
                    result.append((item, imgSuff.sorted()))
                }
            } else if let onlyItem = imgList.first {
                result.append((onlyItem, []))
            }
        }
        result.sort { (left, right) -> Bool in
            return left.0.name < right.0.name
        }
        return result
    }

    private func generateCode(asset: XCAssetFoler, level: Int, project: XCProject) -> String {
        let indent0 = indent(level)
        let indent1 = indent(level + 1)
        let indent2 = indent(level + 2)
        let indent3 = indent(level + 3)
        let indent4 = indent(level + 4)
        var prefix = ""
        var result = ""
        if level == 0 {
            prefix = project.prefix ?? ""
            if prefix.count > 0, asset.name.hasPrefix(prefix) {
                prefix = ""
            }
            if let assetFolder = asset as? XCAssets, let path = assetFolder.fileRef?.getFullPath() {
                result += "/// Image assets from '\(path)'\n"
            } else {
                result += "/// Image assets from '\(asset.name).xcassets'\n"
            }
        }
        result += indent0 + "struct " + prefix + makeKeyword(asset.name) + " {\n\n"
        let assetChildren = asset.children?.sorted(by: { (left, right) -> Bool in
            return left.name < right.name
        })
        if let children = assetChildren {
            var images = [XCAssetImage]()
            for item in children {
                if let folder = item as? XCAssetFoler {
                    result += generateCode(asset: folder, level: level + 1, project: project)
                } else if let image = item as? XCAssetImage, !(image is XCAssetAppIcon) {
                    printLog(.foundIn(item: "\(image)", container: "\(asset)"))
                    images.append(image)
                }
            }
            if let list = suffix {
                let gImages = groupImagesForSuffix(images)
                for (mainImg, listSuff) in gImages {
                    if listSuff.count > 0 {
                        let pref = project.prefix ?? ""
                        result += indent1 + "static var " + makeFuncVarName(mainImg.name) + ": UIImage {\n"
                        result += indent2 + "if let curr = \(pref)AssetSuffix.current {\n"
                        result += indent3 + "switch curr {\n"
                        for suff in listSuff {
                            result += indent3 + "case .\(makeFuncVarName(suff)):\n"
                            result += indent4 + "return #imageLiteral(resourceName: \"\(mainImg.name)\(suff)\")" + "\n"
                        }
                        if list.count > listSuff.count {
                            result += indent3 + "default:\n"
                            result += indent4 + "return #imageLiteral(resourceName: \"\(mainImg.name)\")" + "\n"
                        }
                        result += indent3 + "}\n"
                        result += indent2 + "}\n"
                        result += indent2 + "return #imageLiteral(resourceName: \"\(mainImg.name)\")" + "\n"
                        result += indent1 + "}\n"
                    } else {
                        result += indent1 + "static var " + makeFuncVarName(mainImg.name) + ": UIImage {\n"
                        result += indent2 + "return #imageLiteral(resourceName: \"\(mainImg.name)\")" + "\n"
                        result += indent1 + "}\n"
                    }
                }
            } else {
                images.sort { (left, right) -> Bool in
                    return left.name < right.name
                }
                for item in images {
                    result += indent1 + "static var " + makeFuncVarName(item.name) + ": UIImage {\n"
                    result += indent2 + "return #imageLiteral(resourceName: \"\(item.name)\")" + "\n"
                    result += indent1 + "}\n"
                }
            }
            if images.count > 0 {
                result += "\n"
            }
        }
        return result + indent0 + "}\n\n"
    }

    private func generateSuffixEnums(_ project: XCProject) -> String {
        guard let list = suffix?.sorted() else { return "" }
        let indent1 = indent(1)
        let prefix = project.prefix ?? ""
        var result = "enum \(prefix)AssetSuffix: String {\n\n"
        for item in list {
            let name = makeFuncVarName(item)
            result += indent1 + "case " + name
            if name != item {
                result += " = \"\(item)\""
            }
            result += "\n"
        }
        result += "\n" + indent1 + "static var current: \(prefix)AssetSuffix?\n\n"
        result += "}\n\n"
        return result
    }

    private func makeContent(assets: [XCAssets], project: XCProject) -> String {
        var validAssets = [XCAssets]()
        for item in assets where validateAssets(item) {
            validAssets.append(item)
        }
        guard validAssets.count > 0 else { return "" }
        validAssets.sort { (left, right) -> Bool in
            return left.name < right.name
        }
        var result = generateSuffixEnums(project)
        for item in validAssets {
            result += generateCode(asset: item, level: 0, project: project)
        }
        return result
    }

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)
        let fullPath = checkOutputFile(project: project, output: output)
        let assests = project.findAllAssets()
        var content = makeContent(assets: assests, project: project)
        if content.hasSuffix("\n\n") {
            content = cropTail(input: content, length: 1)
        }
        content = project.getHeader(output) + "\nimport UIKit\n\n" + content
        return writeOutput(project: project, content: content, fullPath: fullPath).0
    }

}
