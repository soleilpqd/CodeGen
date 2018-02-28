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

    var fullOutputPath = ""

    init?(_ info: NSDictionary) {
        if let output = info[kKeyOutput] as? String {
            self.input = info[kKeyInput] as? String
            self.output = output
            colorListName = info[kKeyColorList] as? String
            isCheckUse = (info[kKeyCheckUse] as? NSNumber)?.boolValue ?? false
            isCheckSame = (info[kKeyCheckSame] as? NSNumber)?.boolValue ?? false
            super.init(task: .color)
        } else {
            return nil
        }
    }

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
                print("\tClean ColorList \"\(clrName)\"")
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
                print("\tColorList \"\(clrName)\" has no change!")
                return
            }
        } else {
            colorList = NSColorList(name: .init(rawValue: clrName))
        }
        print("\tGenerate ColorList:", clrName)
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

    private func generateCommonFunction(swiftlingEnable: Bool, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String  {
        let version = env.deployVersion ?? ""
        let indent1 = makeIndentation(level: 1, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent2 = makeIndentation(level: 2, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent3 = makeIndentation(level: 3, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var content = swiftlingEnable ? indent1 + "// swiftlint:disable:next function_parameter_count\n" : ""
        content += indent1 + "private static func makeColor(name: String, colorSpace: String, red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat, alpha: CGFloat) -> UIColor {\n"
        if version.hasPrefix("11.") {
            if swiftlingEnable {
                content += indent2 + "// swiftlint:disable:next force_cast"
            }
            content += indent2 + "return UIColor(named: name)!\n"
        } else {
            content += indent2 + "var result: UIColor!\n"
            content += indent2 + "if #available(iOS 11.0, *) {\n"
            content += indent3 + "result = UIColor(named: name)\n"
            content += indent2 + "}\n"
            if version.hasPrefix("10.") {
                content += indent2 + "if result == nil, colorSpace == \"\(XCAssetColor.Color.ColorSpace.displayP3.rawValue)\" {\n"
                content += indent3 + "result = UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)\n"
                content += indent2 + "}\n"
            } else {
                content += indent2 + "if result == nil, #available(iOS 10.0, *), colorSpace == \"\(XCAssetColor.Color.ColorSpace.displayP3.rawValue)\" {\n"
                content += indent3 + "result = UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)\n"
                content += indent2 + "}\n"
            }
            content += indent2 + "if result == nil, colorSpace == \"\(XCAssetColor.Color.ColorSpace.grayGamma22.rawValue)\" || colorSpace == \"\(XCAssetColor.Color.ColorSpace.extendedGray.rawValue)\" {\n"
            content += indent3 + "result = UIColor(white: white, alpha: alpha)\n"
            content += indent2 + "}\n"
            content += indent2 + "if result == nil {\n"
            content += indent3 + "result = UIColor(red: red, green: green, blue: blue, alpha: alpha)\n"
            content += indent2 + "}\n"
            content += indent2 + "return result\n"
        }
        content += indent1 + "}\n\n"
        return content
    }

    private func generateSwiftCodeSingleComponent(color: XCAssetColor, prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        let indent1 = makeIndentation(level: 1, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent2 = makeIndentation(level: 2, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let name = color.name ?? ""
        var result = indent1 + "/// " + name + "\n"
        let cl1 = color.colors!.first!
        let (r, g, b, w, a) = cl1.getComponents()
        let componentName = cl1.idiom ?? ""
        let spaceColor = cl1.colorSpace ?? ""
        result += indent1 + "/// \(componentName): \(spaceColor) \(cl1.description)"
        if let readable = cl1.humanReadable {
            result += " \"" + readable + "\"\n"
        } else {
            result += "\n"
        }
        result += indent1 + "static var \(prefix)\(name.replacingOccurrences(of: " ", with: "")): UIColor {\n"
        result += indent2 + "return makeColor(name: \"\(name)\", colorSpace: \"\(spaceColor)\", red: \(r), green: \(g), blue: \(b), white: \(w), alpha: \(a))\n"
        result += indent1 + "}\n"
        return result
    }

    private func genDescription(of color: XCAssetColor, component: XCAssetColor.Color, indentLevel: Int, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        guard let readable = component.humanReadable else {
            return ""
        }
        let indent1 = makeIndentation(level: indentLevel, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var result =  indent1 + "// \(component.idiom ?? ""): \(component.colorSpace ?? "") \(component.description) \"\(readable)\"\n"
        let (r, g, b, w, a) = component.getComponents()
        result += indent1 + "result = makeColor(name: \"\(color.name ?? "")\", colorSpace: \"\(component.colorSpace ?? XCAssetColor.Color.ColorSpace.srgb.rawValue)\", red: \(r), green: \(g), blue: \(b), white: \(w), alpha: \(a))\n"
        return result
    }

    private func genColor(color: XCAssetColor, content: String, prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        let name = color.name ?? ""
        let indent1 = makeIndentation(level: 1, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent2 = makeIndentation(level: 2, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent3 = makeIndentation(level: 3, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var result = indent1 + "/// " + name + "\n"
        result += indent1 + "static var \(prefix)\(name.replacingOccurrences(of: " ", with: "")): UIColor {\n"
        result += indent2 + "var result: UIColor!\n"
        result += indent2 + "if #available(iOS 11.0, *) {\n"
        result += indent3 + "result = UIColor(named: \"\(name)\")\n"
        result += indent2 + "}\n"
        result += indent2 + "if result == nil {\n"
        result += content
        result += indent2 + "}\n"
        result += indent2 + "return result\n"
        result += indent1 + "}\n"
        return result
    }

    private func generateSwiftCodeMultiComponents(color: XCAssetColor, prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        let indent3 = makeIndentation(level: 3, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent4 = makeIndentation(level: 4, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var content = indent3 + "switch UIDevice.current.userInterfaceIdiom {\n"
        var universalComponent: XCAssetColor.Color?
        for component in color.colors! {
            guard let key = XCIdiom.new(component.idiom) else { continue }
            switch key {
            case .iphone:
                content += indent3 + "case .phone:\n"
            case .ipad:
                content += indent3 + "case .pad:\n"
            case .tv:
                content += indent3 + "case .tv:\n"
            case .universal:
                universalComponent = component
            default:
                continue
            }
            content += genDescription(of: color, component: component, indentLevel: 4, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        }
        content += indent3 + "default:\n"
        if let universal = universalComponent {
            content += genDescription(of: color, component: universal, indentLevel: 4, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        } else {
            content += indent4 + "result = UIColor()\n"
        }
        content += indent3 + "}\n"
        return genColor(color: color, content: content, prefix: prefix, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
    }

    private func generateSwiftCode(color: XCAssetColor, prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        if let components = color.colors {
            if components.count > 1 {
                return generateSwiftCodeMultiComponents(color: color, prefix: prefix, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
            } else if components.count > 0 {
                return generateSwiftCodeSingleComponent(color: color, prefix: prefix, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
            }
        }
        return ""
    }

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
                print(fullOutputPath + ": warning: Output color file is not included in build target.")
            }
        } else {
            print(fullOutputPath + ": warning: Output color file is not included in project.")
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
                    if let cl1 = group.firstObject as? XCAssetColor, let component1 = cl1.colors, let component = color.colors, component.count == component1.count {
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
            print("warning: \(name[name.startIndex..<name.index(name.endIndex, offsetBy: -2)]) have same color value.")
        }
    }

    private func checkUsage(pattern: String, content: String, color: XCAssetColor, store: inout [XCAssetColor]) {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
            if matches.count > 0 {
                if let index = store.index(where: { (tmpColor) -> Bool in
                    return tmpColor === color
                }) {
                    store.remove(at: index)
                }
            }
        }
    }

    private func checkUsage(project: XCProject, allColors: [XCAssetColor]) {
        if !isCheckUse { return }
        var sources = [XCFileReference.FileType.swift: project.getSwiftFiles()]
        let version = env.deployVersion ?? ""
        if version.hasPrefix("11.") {
            let result = project.getCopyResourcesFiles(types: [.storyboard, .xib])
            for (key, value) in result {
                sources[key] = value
            }
        }
        var tmpColors = allColors
        let prefix = project.prefix?.lowercased() ?? ""
        for (key, value) in sources {
            for path in value {
                guard let content = try? String(contentsOfFile: path) else { continue }
                switch key {
                case .swift:
                    for color in allColors where tmpColors.contains(where: { (tmpColor) -> Bool in
                        return color === tmpColor
                    }) {
                        let pattern = "\\.\(prefix + (color.name.replacingOccurrences(of: " ", with: "")))(.|\\n|\\)|\\]|\\})?"
                        checkUsage(pattern: pattern, content: content, color: color, store: &tmpColors)
                    }
                case .storyboard, .xib:
                    for color in allColors where !tmpColors.contains(where: { (tmpColor) -> Bool in
                        return color === tmpColor
                    }) {
                        // <color key="backgroundColor" name="Arapawa Light"/>
                        let pattern = "<color .+name=\"\(color.name)\"/>"
                        checkUsage(pattern: pattern, content: content, color: color, store: &tmpColors)
                    }
                default:
                    break
                }
                if tmpColors.count == 0 { return }
            }
        }
        if tmpColors.count > 1 {
            var list = ""
            for color in tmpColors {
                list += "\"\(color.name ?? "")\", "
            }
            print("warning: It seem that colors \(list[list.startIndex..<list.index(list.endIndex, offsetBy: -2)]) are not used.")
        } else if let color = tmpColors.first {
            print("warning: It seem that color \"\(color.name ?? "")\" is not used.")
        }
    }

    override func run(_ project: XCProject) -> Error? {
        fullOutputPath = (project.projectPath as NSString).appendingPathComponent(output)
        checkOutputFile(project)

        var content = project.getHeader(output) + "//  Add colorset into \"\(input ?? "Assets.xcassets")\" and Build project.\n\n"
        content += "import UIKit\n\n"
        content += "extension UIColor {\n\n"

        var allColors: [XCAssetColor]
        if let ipt = input {
            allColors = project.findColorAssets(in: ipt) ?? []
        } else {
            allColors = project.findAllColorAssets()
        }
        allColors = allColors.sorted(by: { (left, right) -> Bool in
            return left.name.compare(right.name) == .orderedAscending
        })

        content += generateCommonFunction(swiftlingEnable: project.swiftlintEnable,
                                          tabWidth: project.tabWidth,
                                          indentWidth: project.indentWidth,
                                          useTab: project.useTab)
        for color in allColors {
            print("\tFound:", color.name ?? "")
            content += generateSwiftCode(color: color, prefix: project.prefix?.lowercased() ?? "", tabWidth: project.tabWidth,
                                         indentWidth: project.indentWidth, useTab: project.useTab) + "\n"
        }
        content += "}\n"

        checkSameValueColors(allColors)
        checkUsage(project: project, allColors: allColors)

        var result: Error?
        if let data = try? String(contentsOfFile: (project.projectPath as NSString).appendingPathComponent(output)) {
            if content != data {
                result = project.write(content: content, target: output)
            } else {
                print("\tThere's no change in output file! Abort writting!")
            }
        }
        makeColorList(project: project, colors: allColors)
        return result
    }

    override func toDic() -> [String : Any] {
        var dic = super.toDic()
        if let inp = input {
            dic[kKeyInput] = input
        }
        dic[kKeyOutput] = output
        if let list = colorListName {
            dic[kKeyColorList] = list
        }
        dic[kKeyCheckUse] = NSNumber(value: isCheckUse)
        dic[kKeyCheckSame] = NSNumber(value: isCheckSame)
        return dic
    }

}
