//
//  XCTaskColorUtils.swift
//  CodeGen
//
//  Created by DươngPQ on 2/21/20.
//  Copyright © 2020 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import AppKit

final class XCTaskColorUtils {

    static func compareColors(_ left: NSColor, _ right: NSColor) -> Bool {
        let cmpComponent: (CGFloat, CGFloat) -> Bool = {(l, r) in
            return Int(l * 255) == Int(r * 255)
        }

        if left.colorSpaceName != right.colorSpaceName { return false }
        if left.numberOfComponents != right.numberOfComponents { return false }
        if left.numberOfComponents == 4 {
            return cmpComponent(left.alphaComponent, right.alphaComponent) && cmpComponent(left.redComponent, right.redComponent)
                && cmpComponent(left.greenComponent, right.greenComponent) && cmpComponent(left.blueComponent, right.blueComponent)
        } else {
            return cmpComponent(left.alphaComponent, right.alphaComponent) && cmpComponent(left.whiteComponent, right.whiteComponent)
        }
    }

    static func checkOutputFile(project: XCProject, owner: XCTask, output: String, fullOutputPath: String) {
        if let chk = project.checkPathInBuildSource(path: output) {
            if !chk {
                owner.printLog(.outputFileNotInTarget(fullOutputPath))
            }
        } else {
            owner.printLog(.outputFileNotInProject(fullOutputPath))
        }
    }

    static func checkSameValueColors(allColors: [XCAssetColor], owner: XCTask) {
        var tmpColors = allColors
        var groupedColor = [NSMutableArray]()
        while tmpColors.count > 0 {
            let color = tmpColors.removeLast()
            if groupedColor.count == 0 {
                groupedColor.append(NSMutableArray(array: [color]))
            } else {
                var found = false
                for group in groupedColor {
                    if let cl1 = group.firstObject as? XCAssetColor, let component1 = cl1.colors,
                        let component = color.colors, component.count == component1.count {
                        var equalCount = 0
                        for cmp1 in component1 {
                            for cmp in component where cmp.idiom == cmp1.idiom {
                                if let nsCl1 = cmp1.color, let nsCl = cmp.color, compareColors(nsCl1, nsCl) {
                                    equalCount += 1
                                    break
                                }
                            }
                        }
                        if equalCount == component1.count {
                            found = true
                            group.add(color)
                            break
                        }
                    }
                }
                if !found {
                    groupedColor.append([color])
                }
            }
        }
        for group in groupedColor where group.count > 1 {
            var name = ""
            for asset in group {
                if let color = asset as? XCAssetColor {
                    name += color.name + ", "
                }
            }
            owner.printLog(.sameValue(String(name[name.startIndex..<name.index(name.endIndex, offsetBy: -2)])))
        }
    }

    static func checkUsage(project: XCProject, allColors: [XCAssetColor], usageCheckCategory: String) {
        let sources = project.getCopyResourcesFiles(types: [.storyboard, .xib])
        var tmpColors = [XCAssetColor]()
        for (key, value) in sources {
            for path in value {
                guard let content = try? String(contentsOfFile: path) else { continue }
                let comments = XCValidator.commentedRanges(content)
                switch key {
                case .storyboard, .xib:
                    for color in allColors where !tmpColors.contains(where: { (tmpColor) -> Bool in
                        return color === tmpColor
                    }) {
                        let pattern = "<namedColor .+name=\"\(color.name)\"/>"
                        if XCValidator.checkUsageUsingRegex(pattern: pattern, content: content, commentRanges: comments) {
                            tmpColors.append(color)
                        }
                    }
                default:
                    break
                }
            }
        }
        if tmpColors.count > 0 {
            for color in tmpColors {
                XCValidator.shared.removeKeywordForCheckUsage(category: usageCheckCategory, keyword: makeFuncVarName(color.name))
            }
        }
    }

}
