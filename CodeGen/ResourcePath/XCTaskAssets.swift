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

    init?(_ info: NSDictionary) {
        if let target = info["output"] as? String, target.count > 0 {
            output = target
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

    private func generateCode(asset: XCAssetFoler, level: Int, project: XCProject) -> String {
        let indent0 = indent(level)
        let indent1 = indent(level + 1)
        let indent2 = indent(level + 2)
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
        if let children = asset.children {
            var images = [XCAssetImage]()
            for item in children {
                if let folder = item as? XCAssetFoler {
                    result += generateCode(asset: folder, level: level + 1, project: project)
                } else if let image = item as? XCAssetImage, !(image is XCAssetAppIcon) {
                    printLog(.foundIn(item: "\(image)", container: "\(asset)"))
                    images.append(image)
                }
            }
            for item in images {
                result += indent1 + "static var " + makeFuncVarName(item.name) + ": UIImage {\n"
                result += indent2 + "return #imageLiteral(resourceName: \"\(item.name)\")" + "\n"
                result += indent1 + "}\n"
            }
            if images.count > 0 {
                result += "\n"
            }
        }
        return result + indent0 + "}\n\n"
    }

    private func makeContent(assets: [XCAssets], project: XCProject) -> String {
        var validAssets = [XCAssets]()
        for item in assets where validateAssets(item) {
            validAssets.append(item)
        }
        guard validAssets.count > 0 else { return "" }
        var result = ""
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
