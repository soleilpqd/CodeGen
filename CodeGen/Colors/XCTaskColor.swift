//
//  XCTaskColor.swift
//  CodeGen
//
//  Created by DươngPQ on 13/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import AppKit

final class XCTaskColor: XCTask {

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

    // MARK: - Generate Swift code

    // MARK: Single component color

    private func generateCommonFunction(commonMulti: Bool, swiftlintEnable: Bool) -> String  {
        let indent1 = indent(1)
        let indent2 = indent(2)
        let indent3 = indent(3)
        let indent4 = indent(4)

        var content = ""

        // Common function for single component color
        content = swiftlintEnable ? indent1 + "// swiftlint:disable:next function_parameter_count\n" : ""
        content += indent1 + "private static func makeColor(name: String?, colorSpace: String, red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat, alpha: CGFloat) -> UIColor {\n"
        if env.compareSDKVerison(version: "11.0") {
            if env.compareDeployVersion(version: "11.0") {
                content += indent2 + "if let clName = name, let color = UIColor(named: clName) {\n"
            } else {
                content += indent2 + "if #available(iOS 11.0, *), let clName = name, let color = UIColor(named: clName) {\n"
            }
            content += indent3 + "return color\n"
            content += indent2 + "}\n"
        }
        if env.compareDeployVersion(version: "10.0") {
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
            if env.compareSDKVerison(version: "11.0") {
                if env.compareDeployVersion(version: "11.0") {
                    content += indent2 + "if let clName = name, let color = UIColor(named: clName) {\n"
                } else {
                    content += indent2 + "if #available(iOS 11.0, *), let clName = name, let color = UIColor(named: clName) {\n"
                }
                content += indent3 + "return color\n"
                content += indent2 + "}\n"
            }
            content += indent2 + "switch UIDevice.current.userInterfaceIdiom {\n"
            content += indent2 + "case .phone:\n"
            content += indent3 + "if let data = map[\"phone\"] {\n"
            content += indent4 + "return UIColor.makeColor(name: nil, colorSpace: data.colorSpace, red: data.red, green: data.green, blue: data.blue, white: data.white, alpha: data.alpha)\n"
            content += indent3 + "}\n"
            content += indent2 + "case .pad:\n"
            content += indent3 + "if let data = map[\"pad\"] {\n"
            content += indent4 + "return UIColor.makeColor(name: nil, colorSpace: data.colorSpace, red: data.red, green: data.green, blue: data.blue, white: data.white, alpha: data.alpha)\n"
            content += indent3 + "}\n"
            content += indent2 + "case .tv:\n"
            content += indent3 + "if let data = map[\"tv\"] {\n"
            content += indent4 + "return UIColor.makeColor(name: nil, colorSpace: data.colorSpace, red: data.red, green: data.green, blue: data.blue, white: data.white, alpha: data.alpha)\n"
            content += indent3 + "}\n"
            content += indent2 + "default:\n"
            content += indent3 + "if let data = map[\"default\"] {\n"
            content += indent4 + "return UIColor.makeColor(name: nil, colorSpace: data.colorSpace, red: data.red, green: data.green, blue: data.blue, white: data.white, alpha: data.alpha)\n"
            content += indent3 + "}\n"
            content += indent2 + "}\n"
            content += indent2 + "return UIColor()\n"
            content += indent1 + "}\n\n"
        }
        return content
    }

    private func generateSwiftCodeSingleComponent(colorNameAvailable: Bool, color: XCAssetColor, level: Int) -> String {
        let indent1 = indent(level + 1)
        let indent2 = indent(level + 2)
        let name = color.name
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
        if env.compareDeployVersion(version: "11.0") && colorNameAvailable {
            if project?.swiftlintEnable ?? false {
                result += indent2 + "// swiftlint:disable:next force_cast\n"
            }
            result += indent2 + "return UIColor(named: \"\(name)\")!\n"
        } else {
            result += indent2 + "return UIColor.makeColor(name: \(colorNameAvailable ? "\"\(name)\"" : "nil"), colorSpace: \"\(spaceColor)\", red: \(r), green: \(g), blue: \(b), white: \(w), alpha: \(a))\n"
        }
        result += indent1 + "}\n"
        return result
    }

    // MARK: Multiple components color

    private func generateSwiftCodeMultiComponents(colorNameAvailable: Bool, color: XCAssetColor, level: Int) -> String {
        let name = color.name
        let indent1 = indent(level + 1)
        let indent2 = indent(level + 2)
        var result = indent1 + "/// " + name + "\n"
        for component in color.colors! {
            if let appearance = component.appearances?["luminosity"] {
                result += indent1 + "/// - \(component.idiom ?? "") (\(appearance)): \(component.colorSpace ?? "") \(component.description) \"\(component.humanReadable ?? "")\"\n"
            } else {
                result += indent1 + "/// - \(component.idiom ?? ""): \(component.colorSpace ?? "") \(component.description) \"\(component.humanReadable ?? "")\"\n"
            }
        }
        let varName = makeFuncVarName(name)
        if isCheckUse {
            XCValidator.shared.addKeywordForCheckUsage(category: usageCheckCategory, keyword: varName)
        }
        result += indent1 + "static var \(varName): UIColor {\n"
        if env.compareDeployVersion(version: "11.0") && colorNameAvailable {
            if project?.swiftlintEnable ?? false {
                result += indent2 + "// swiftlint:disable:next force_cast\n"
            }
            result += indent2 + "return UIColor(named: \"\(name)\")!\n"
        } else {
            var content = "return UIColor.makeColor(name: \(colorNameAvailable ? "\"\(name)\"" : "nil"), map: ["
            var head = indent2
            for _ in 0..<content.count {
                head += " "
            }
            content = indent2 + content

            // filter colors by idiom & appearance => 1 color per idiom to generate code for iOS under 11.0
            var colorComps = [String: XCAssetColor.Color]()
            for component in color.colors ?? [] {
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
                if let oldComp = colorComps[keyName] {
                    // pick color by appearance (priority: default, light, dark)
                    if let compAppearnce = component.appearances?["luminosity"] {
                        if let oldCompAppearance = oldComp.appearances?["luminosity"] {
                            if compAppearnce == "light" && oldCompAppearance == "dark" {
                                colorComps[keyName] = component
                            }
                        } // esle { leave object in colorComps }
                    } else {
                        colorComps[keyName] = component
                    }
                } else {
                    colorComps[keyName] = component
                }
            }

            for keyName in colorComps.keys.sorted() {
                guard let component = colorComps[keyName] else { continue /* unreachable */ }
                let (r, g, b, w, a) = component.getComponents()
                content += "\"\(keyName)\": (colorSpace: \"\(component.colorSpace ?? XCAssetColor.Color.ColorSpace.srgb.rawValue)\", red: \(r), green: \(g), blue: \(b), white: \(w), alpha: \(a)),\n" + head
            }

            result += String(content[content.startIndex..<content.index(content.endIndex, offsetBy: -(head.count + 2))]) + "])\n"
        }

        result += indent1 + "}\n"
        return result
    }

    private func generateSwiftCode(colorNameAvailable: Bool, color: XCAssetColor, level: Int) -> String {
        if let components = color.colors {
            if components.count > 1 {
                return generateSwiftCodeMultiComponents(colorNameAvailable: colorNameAvailable, color: color, level: level)
            } else if components.count > 0 {
                return generateSwiftCodeSingleComponent(colorNameAvailable: colorNameAvailable, color: color, level: level)
            }
        }
        return ""
    }

    private func generateSwiftCode(folder: XCAssetFoler, level: Int, colorNameAvailable: Bool, prefix: String) -> String {
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
            printLog(.found(color.name))
            result += generateSwiftCode(colorNameAvailable: colorNameAvailable, color: color, level: level + 1) + "\n"

        }

        for fdl in folders {
            result += generateSwiftCode(folder: fdl, level: level + 1, colorNameAvailable: colorNameAvailable, prefix: "")
        }

        result += indent1 + "}\n\n"
        return result
    }

    private func generateSwiftCode(assets: XCAssets, project: XCProject, prefix: String) -> String {
        var colorNameAvailable = false
        if let fileRef = assets.fileRef, project.checkItemInCopyResource(fileRef) {
            colorNameAvailable = true
        }
        return generateSwiftCode(folder: assets, level: 0, colorNameAvailable: colorNameAvailable, prefix: prefix)
    }

    // MARK: - Task
    // TODO: diffent color name but same keyword name?

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)
        let isSDK11Only = env.compareDeployVersion(version: "11.0")
        fullOutputPath = (project.projectPath as NSString).appendingPathComponent(output)
        XCTaskColorUtils.checkOutputFile(project: project, owner: self, output: output, fullOutputPath: fullOutputPath)

        var content = project.getHeader(output) + "//  Add colorset into \"\(input ?? "Assets.xcassets")\" and Build project.\n\n"
        content += "import UIKit\n\n"
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
            content += generateCommonFunction(commonMulti: commonMultiColor, swiftlintEnable: project.swiftlintEnable)
        }

        var allColors = [XCAssetColor]()
        for (assets, colors) in assetsColors {
            allColors.append(contentsOf: colors)
            content += generateSwiftCode(assets: assets, project: project, prefix: project.prefix ?? "")
        }
        content += "}\n"

        if isCheckSame { XCTaskColorUtils.checkSameValueColors(allColors: allColors, owner: self) }
        if isCheckUse && env.compareDeployVersion(version: "11.0") {
            XCTaskColorUtils.checkUsage(project: project, allColors: allColors, usageCheckCategory: usageCheckCategory)
        }
        let (error, change) = writeOutput(project: project, content: content, fullPath: fullOutputPath)
        if !change {
            printLog(.outputNotChange())
        }
        if colorListName != nil {
            XCColorList(colorListName).makeColorList(project: project, colors: allColors)
        }
        return error
    }

}
