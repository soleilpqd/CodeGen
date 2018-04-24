//
//  XCTaskColor.swift
//  CodeGen
//
//  Created by DươngPQ on 13/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import AppKit

class XCTaskColor: XCTask {

    private let kKeyInput = "input"
    private let kKeyOutput = "output"
    private let kKeyColorList = "list"
    private let kKeyCheckUse = "check_use"
    private let kKeyCheckSame = "check_same"

    let input: String?
    let output: String
    let colorListName: String?
    let isCheckUse: Bool
    let isCheckSame: Bool

    private let usageCheckCategory: String

    var fullOutputPath = ""

    init?(_ info: NSDictionary) {
        if let output = info[kKeyOutput] as? String {
            self.input = info[kKeyInput] as? String
            self.output = output
            colorListName = info[kKeyColorList] as? String
            isCheckUse = (info[kKeyCheckUse] as? NSNumber)?.boolValue ?? false
            isCheckSame = (info[kKeyCheckSame] as? NSNumber)?.boolValue ?? false
            usageCheckCategory = TaskType.color.rawValue + ": " + output
            super.init(task: .color)
        } else {
            return nil
        }
    }

    // MARK: - ColorList (Color catalog)

    private func findColorList(_ project: XCProject) -> (String?, NSColorList?) {
        guard var clrName = colorListName else { return (nil, nil) }
        if clrName.count == 0 {
            clrName = ((((project.projectFile as NSString).deletingLastPathComponent) as NSString).lastPathComponent as NSString).deletingPathExtension
        }
        var colorList: NSColorList?
        var nameAvailable = true
        for clList in NSColorList.availableColorLists where clList.name?.rawValue == clrName {
            nameAvailable = false
            if clList.isEditable {
                colorList = clList
            }
        }
        if colorList == nil && !nameAvailable {
            var tmpName = clrName
            var index = 1
            while !nameAvailable {
                tmpName = clrName + "\(index)"
                nameAvailable = true
                for clList in NSColorList.availableColorLists where clList.name?.rawValue == tmpName {
                    nameAvailable = false
                }
                index += 1
            }
            clrName = tmpName
        }
        return (clrName, colorList)
    }

    /// return: true if changed
    private func checkKeyOfColorList(key: NSColor.Name, list: NSColorList, color: XCAssetColor.Color) -> Bool {
        if let colorInList = list.color(withKey: key) {
            if let nsColor = color.colorForColorList, compareColors(nsColor, colorInList) {
                return false
            }
        }
        return true
    }

    private func makeColorList(project: XCProject, colors: [XCAssetColor]) {
        let (name, list) = findColorList(project)
        guard let clrName = name else { return }
        var colorList: NSColorList
        if let clList = list {
            colorList = clList
            if colors.count == 0 {
                clList.removeFile()
                printLog(.cleanColorList(clrName))
                return
            }
            var isChanged = false
            var allKeys = [NSColor.Name]()
            for color in colors {
                if let components = color.colors {
                    if components.count == 1 {
                        if let cl1 = components.first {
                            let key = NSColor.Name(rawValue: color.name)
                            if checkKeyOfColorList(key: key, list: clList, color: cl1) {
                                isChanged = true
                                break
                            } else {
                                allKeys.append(key)
                            }
                        }
                    } else {
                        var index = 0
                        for cl1 in components {
                            let key = NSColor.Name(rawValue: color.name + " " + (cl1.idiom ?? "\(index)"))
                            if checkKeyOfColorList(key: key, list: clList, color: cl1) {
                                isChanged = true
                                break
                            } else {
                                allKeys.append(key)
                            }
                            index += 1
                        }
                        if isChanged {
                            break
                        }
                    }
                }
            }
            if !isChanged {
                for key in clList.allKeys where !allKeys.contains(key) {
                    isChanged = true
                    break
                }
            }
            if !isChanged {
                printLog(.colorListNoChange(clrName))
                return
            }
        } else {
            colorList = NSColorList(name: .init(rawValue: clrName))
        }
        printLog(.generateColorList(clrName))
        let keys = colorList.allKeys
        for key in keys {
            colorList.removeColor(withKey: key)
        }
        for color in colors {
            if let components = color.colors {
                if components.count == 1 {
                    if let cl1 = components.first, let cl = cl1.colorForColorList {
                        colorList.setColor(cl, forKey: .init(rawValue: color.name))
                    }
                } else {
                    var index = 0
                    for cl1 in components {
                        if let cl = cl1.colorForColorList {
                            colorList.setColor(cl, forKey: .init(rawValue: color.name + " " + (cl1.idiom ?? "\(index)")))
                        }
                        index += 1
                    }
                }
            }
        }
        _ = colorList.write(toFile: nil)
    }

    // MARK: - Generate Swift code

    // MARK: Single component color

    private func generateCommonFunction(commonMulti: Bool, swiftlintEnable: Bool, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String  {
        let indent1 = indent(1)
        let indent2 = indent(2)
        let indent3 = indent(3)
        let indent4 = indent(4)

        var content = ""

        // Common function for single component color
        content = swiftlintEnable ? indent1 + "// swiftlint:disable:next function_parameter_count\n" : ""
        content += indent1 + "private static func makeColor(name: String?, colorSpace: String, red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat, alpha: CGFloat) -> UIColor {\n"
        if env.compareVersion(version: "11.0") {
            content += indent2 + "if let clName = name, let color = UIColor(named: clName) {\n"
        } else {
            content += indent2 + "if #available(iOS 11.0, *), let clName = name, let color = UIColor(named: clName) {\n"
        }
        content += indent3 + "return color\n"
        content += indent2 + "}\n"
        if env.compareVersion(version: "10.0") {
            content += indent2 + "if colorSpace == \"\(XCAssetColor.Color.ColorSpace.displayP3.rawValue)\" {\n"
            content += indent3 + "return UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)\n"
            content += indent2 + "}\n"
        } else {
            content += indent2 + "if #available(iOS 10.0, *), colorSpace == \"\(XCAssetColor.Color.ColorSpace.displayP3.rawValue)\" {\n"
            content += indent3 + "return UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)\n"
            content += indent2 + "}\n"
        }
        content += indent2 + "if colorSpace == \"\(XCAssetColor.Color.ColorSpace.grayGamma22.rawValue)\" || colorSpace == \"\(XCAssetColor.Color.ColorSpace.extendedGray.rawValue)\" {\n"
        content += indent3 + "return UIColor(white: white, alpha: alpha)\n"
        content += indent2 + "}\n"
        content += indent2 + "return UIColor(red: red, green: green, blue: blue, alpha: alpha)\n"
        content += indent1 + "}\n\n"

        // Common function for multiple components color
        if commonMulti {
            if swiftlintEnable {
                content += indent1 + "// swiftlint:disable:next large_tuple\n"
            }
            content += indent1 + "private static func makeColor(name: String?, map: [String: (colorSpace: String, red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat, alpha: CGFloat)]) -> UIColor {\n"
            if env.compareVersion(version: "11.0") {
                content += indent2 + "if let clName = name, let color = UIColor(named: clName) {\n"
            } else {
                content += indent2 + "if #available(iOS 11.0, *), let clName = name, let color = UIColor(named: clName) {\n"
            }
            content += indent3 + "return color\n"
            content += indent2 + "}\n"
            content += indent2 + "switch UIDevice.current.userInterfaceIdiom {\n"
            content += indent2 + "case .phone:\n"
            content += indent3 + "if let data = map[\"phone\"] {\n"
            content += indent4 + "return makeColor(name: nil, colorSpace: data.colorSpace, red: data.red, green: data.green, blue: data.blue, white: data.white, alpha: data.alpha)\n"
            content += indent3 + "}\n"
            content += indent2 + "case .pad:\n"
            content += indent3 + "if let data = map[\"pad\"] {\n"
            content += indent4 + "return makeColor(name: nil, colorSpace: data.colorSpace, red: data.red, green: data.green, blue: data.blue, white: data.white, alpha: data.alpha)\n"
            content += indent3 + "}\n"
            content += indent2 + "case .tv:\n"
            content += indent3 + "if let data = map[\"tv\"] {\n"
            content += indent4 + "return makeColor(name: nil, colorSpace: data.colorSpace, red: data.red, green: data.green, blue: data.blue, white: data.white, alpha: data.alpha)\n"
            content += indent3 + "}\n"
            content += indent2 + "default:\n"
            content += indent3 + "if let data = map[\"default\"] {\n"
            content += indent4 + "return makeColor(name: nil, colorSpace: data.colorSpace, red: data.red, green: data.green, blue: data.blue, white: data.white, alpha: data.alpha)\n"
            content += indent3 + "}\n"
            content += indent2 + "}\n"
            content += indent2 + "return UIColor()\n"
            content += indent1 + "}\n\n"
        }
        return content
    }

    private func generateSwiftCodeSingleComponent(colorNameAvailable: Bool, color: XCAssetColor, level: Int,
                                                  tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        let indent1 = indent(level + 1)
        let indent2 = indent(level + 2)
        let name = color.name ?? ""
        var result = indent1 + "/// " + name + "\n"
        let cl1 = color.colors!.first!
        let (r, g, b, w, a) = cl1.getComponents()
        let componentName = cl1.idiom ?? ""
        let spaceColor = cl1.colorSpace ?? ""
        result += indent1 + "/// - \(componentName): \(spaceColor) \(cl1.description)"
        if let readable = cl1.humanReadable {
            result += " \"" + readable + "\"\n"
        } else {
            result += "\n"
        }
        let varName = makeFuncVarName(name)
        if isCheckUse {
            XCValidator.shared.addKeywordForCheckUsage(category: usageCheckCategory, keyword: varName)
        }
        result += indent1 + "static var \(varName): UIColor {\n"
        if env.compareVersion(version: "11.0") && colorNameAvailable {
            if project?.swiftlintEnable ?? false {
                result += indent2 + "// swiftlint:disable:next force_cast"
            }
            result += indent2 + "return UIColor(named: \"\(name)\")!\n"
        } else {
            result += indent2 + "return makeColor(name: \(colorNameAvailable ? "\"\(name)\"" : "nil"), colorSpace: \"\(spaceColor)\", red: \(r), green: \(g), blue: \(b), white: \(w), alpha: \(a))\n"
        }
        result += indent1 + "}\n"
        return result
    }

    // MARK: Multiple components color

    private func generateSwiftCodeMultiComponents(colorNameAvailable: Bool, color: XCAssetColor, level: Int,
                                                  tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        let name = color.name ?? ""
        let indent1 = indent(level + 1)
        let indent2 = indent(level + 2)
        var result = indent1 + "/// " + name + "\n"
        for component in color.colors! {
            result += indent1 + "/// - \(component.idiom ?? ""): \(component.colorSpace ?? "") \(component.description) \"\(component.humanReadable ?? "")\"\n"
        }
        let varName = makeFuncVarName(name)
        if isCheckUse {
            XCValidator.shared.addKeywordForCheckUsage(category: usageCheckCategory, keyword: varName)
        }
        result += indent1 + "static var \(varName): UIColor {\n"
        if env.compareVersion(version: "11.0") && colorNameAvailable {
            if project?.swiftlintEnable ?? false {
                result += indent2 + "// swiftlint:disable:next force_cast"
            }
            result += indent2 + "return UIColor(named: \"\(name)\")!\n"
        } else {
            var content = "return makeColor(name: \(colorNameAvailable ? "\"\(name)\"" : "nil"), map: ["
            var head = indent2
            for _ in 0..<content.count {
                head += " "
            }
            content = indent2 + content

            for component in color.colors! {
                guard let key = XCIdiom.new(component.idiom) else { continue }
                var keyName = ""
                switch key {
                case .iphone:
                    keyName = "phone"
                case .ipad:
                    keyName = "pad"
                case .tv:
                    keyName = "tv"
                case .universal:
                    keyName = "default"
                default:
                    continue
                }
                let (r, g, b, w, a) = component.getComponents()
                content += "\"\(keyName)\": (colorSpace: \"\(component.colorSpace ?? XCAssetColor.Color.ColorSpace.srgb.rawValue)\", red: \(r), green: \(g), blue: \(b), white: \(w), alpha: \(a)),\n" + head
            }
            result += String(content[content.startIndex..<content.index(content.endIndex, offsetBy: -(head.count + 2))]) + "])\n"
        }

        result += indent1 + "}\n"
        return result
    }

    private func generateSwiftCode(colorNameAvailable: Bool, color: XCAssetColor, level: Int,
                                   tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        if let components = color.colors {
            if components.count > 1 {
                return generateSwiftCodeMultiComponents(colorNameAvailable: colorNameAvailable, color: color,
                                                        level: level, tabWidth: tabWidth,
                                                        indentWidth: indentWidth, useTab: useTab)
            } else if components.count > 0 {
                return generateSwiftCodeSingleComponent(colorNameAvailable: colorNameAvailable, color: color,
                                                        level: level, tabWidth: tabWidth,
                                                        indentWidth: indentWidth, useTab: useTab)
            }
        }
        return ""
    }

    private func generateSwiftCode(folder: XCAssetFoler, level: Int, colorNameAvailable: Bool,
                                   prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        guard let children = folder.children else {
            return ""
        }
        var result = ""
        var colors = [XCAssetColor]()
        var folders = [XCAssetFoler]()

        for item in children {
            if let color = item as? XCAssetColor {
                colors.append(color)
            } else if let subFolder = item as? XCAssetFoler {
                folders.append(subFolder)
            }
        }
        colors.sort { (left, right) -> Bool in
            return left.name.compare(right.name) == .orderedAscending
        }
        folders.sort { (left, right) -> Bool in
            return left.name.compare(right.name) == .orderedAscending
        }

        let indent1 = indent(level + 1)
        result += indent1 + "struct \(prefix)\(makeKeyword(folder.name)) {\n\n"

        for color in colors {
            printLog(.found(color.name ?? ""))
            result += generateSwiftCode(colorNameAvailable: colorNameAvailable, color: color,
                                        level: level + 1, tabWidth: tabWidth,
                                        indentWidth: indentWidth, useTab: useTab) + "\n"

        }

        for fdl in folders {
            result += generateSwiftCode(folder: fdl, level: level + 1, colorNameAvailable: colorNameAvailable,
                                        prefix: "", tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        }

        result += indent1 + "}\n\n"
        return result
    }

    private func generateSwiftCode(assets: XCAssets, project: XCProject, prefix: String, tabWidth: Int,
                                   indentWidth: Int, useTab: Bool) -> String {
        var colorNameAvailable = false
        if let fileRef = assets.fileRef, project.checkItemInCopyResource(fileRef) {
            colorNameAvailable = true
        }
        return generateSwiftCode(folder: assets, level: 0, colorNameAvailable: colorNameAvailable,
                                 prefix: prefix, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
    }

    // MARK: - Validation

    private func compareColors(_ left: NSColor, _ right: NSColor) -> Bool {
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

    private func checkOutputFile(_ project: XCProject) {
        if let chk = project.checkPathInBuildSource(path: output) {
            if !chk {
                printLog(.outputFileNotInTarget(fullOutputPath))
            }
        } else {
            printLog(.outputFileNotInProject(fullOutputPath))
        }
    }

    private func checkSameValueColors(_ allColors: [XCAssetColor]) {
        if !isCheckSame { return }
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
            printLog(.sameValue(String(name[name.startIndex..<name.index(name.endIndex, offsetBy: -2)])))
        }
    }

    private func checkUsage(project: XCProject, allColors: [XCAssetColor]) {
        if !isCheckUse || !env.compareVersion(version: "11.0") { return }
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

    // MARK: - Task
    // TODO: diffent color name but same keyword name?

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)
        let isSDK11Only = env.compareVersion(version: "11.0")
        fullOutputPath = (project.projectPath as NSString).appendingPathComponent(output)
        checkOutputFile(project)

        var content = project.getHeader(output) + "//  Add colorset into \"\(input ?? "Assets.xcassets")\" and Build project.\n\n"
        content += "import UIKit\n\n"
        if project.swiftlintEnable {
            content += "// swiftlint:disable nesting line_length\n"
        }
        content += "extension UIColor {\n\n"

        var assetsColors = [(XCAssets, [XCAssetColor])]()
        if let ipt = input {
            if let res = project.findColorAssets(in: ipt) {
                assetsColors.append(res)
            }
        } else {
            assetsColors = project.findAllColorAssets()
        }

        var commonSingleColor = false
        var commonMultiColor = false
        for (assets, allColors) in assetsColors {
            var multiColor = false
            for color in allColors where (color.colors?.count ?? 0) > 1 {
                multiColor = true
                break
            }
            if multiColor {
                if isSDK11Only {
                    var colorNameAvailable = false
                    if let fileRef = assets.fileRef, project.checkItemInCopyResource(fileRef) {
                        colorNameAvailable = true
                    }
                    if !colorNameAvailable {
                        commonMultiColor = true
                        break
                    }
                } else {
                    commonMultiColor = true
                    break
                }
            }
        }

        if commonMultiColor {
            commonSingleColor = true
        } else {
            if !isSDK11Only {
                commonSingleColor = true
            } else {
                for (assets, _) in assetsColors {
                    var colorNameAvailable = false
                    if let fileRef = assets.fileRef, project.checkItemInCopyResource(fileRef) {
                        colorNameAvailable = true
                    }
                    if !colorNameAvailable {
                        commonSingleColor = true
                        break
                    }
                }
            }
        }
        if commonSingleColor {
            content += generateCommonFunction(commonMulti: commonMultiColor, swiftlintEnable: project.swiftlintEnable,
                                              tabWidth: project.tabWidth,
                                              indentWidth: project.indentWidth,
                                              useTab: project.useTab)
        }

        var allColors = [XCAssetColor]()
        for (assets, colors) in assetsColors {
            allColors.append(contentsOf: colors)
            content += generateSwiftCode(assets: assets, project: project,
                                         prefix: project.prefix ?? "",
                                         tabWidth: project.tabWidth,
                                         indentWidth: project.indentWidth,
                                         useTab: project.useTab)
        }
        content += "}\n"

        checkSameValueColors(allColors)
        checkUsage(project: project, allColors: allColors)

        let (error, change) = writeOutput(project: project, content: content, fullPath: fullOutputPath)
        if !change {
            printLog(.outputNotChange())
        }
        makeColorList(project: project, colors: allColors)
        return error
    }

}
