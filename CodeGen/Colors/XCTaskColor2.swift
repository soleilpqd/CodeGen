//
//  XCTaskColor2.swift
//  CodeGen
//
//  Created by DươngPQ on 2/21/20.
//  Copyright © 2020 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import AppKit

final class XCTaskColor2: XCTask {

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

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)
        fullOutputPath = (project.projectPath as NSString).appendingPathComponent(output)
        XCTaskColorUtils.checkOutputFile(project: project, owner: self, output: output, fullOutputPath: fullOutputPath)
        let prefix = project.prefix ?? ""
        var content = project.getHeader(output) + "//  Add colorset into \"\(input ?? "Assets.xcassets")\" and Build project.\n\n"
        content += "import UIKit\n\n"
        content += """
enum \(prefix)ColorAppearance: String {
    case dark
    case light
    case any = ""
}

private struct \(prefix)ColorInfo {

    enum ColorIdiom: String {
        case iphone
        case ipad
        case car
        case watch
        case mac
        case macCatalyst = "mac-catalyst"
        case tv
        case universal
    }

    private struct ColorComponent {
        let colorSpace: String
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
        let white: CGFloat
    }

    let idiom: ColorIdiom
    let appearance: \(prefix)ColorAppearance
    private let component: ColorComponent

    init(d device: String, m mode: String?, s clSpace: String, r clRed: CGFloat, g clGreen: CGFloat, b clBlue: CGFloat, a clAlpha: CGFloat, w clWhite: CGFloat) {
        idiom = ColorIdiom(rawValue: device) ?? .universal
        appearance = \(prefix)ColorAppearance(rawValue: mode ?? "") ?? .any
        component = ColorComponent(colorSpace: clSpace, red: clRed, green: clGreen, blue: clBlue, alpha: clAlpha, white: clWhite)
    }

    var color: UIColor {
        switch component.colorSpace {
        case "display-p3":
            if #available(iOS 10.0, *) {
                return UIColor(displayP3Red: component.red, green: component.green, blue: component.blue, alpha: component.alpha)
            }
            return UIColor(red: component.red, green: component.green, blue: component.blue, alpha: component.alpha)
        case "gray-gamma-22", "extended-gray":
            return UIColor(white: component.white, alpha: component.alpha)
        default:
            return UIColor(red: component.red, green: component.green, blue: component.blue, alpha: component.alpha)
        }
    }

}

struct \(prefix)Color {

    /**
     Appearance mode for `color` of `\(prefix)Color` returning.
     - `nil`: return color of `UIColor(named:)`.
     - Otherwise: try to return color of given appearance mode.
     */
    static var appearanceMode: \(prefix)ColorAppearance?

    private let name: String
    private let info: [\(prefix)ColorInfo]

    fileprivate init(clName: String, clInfo: [\(prefix)ColorInfo]) {
        name = clName
        info = clInfo
    }

    /// Find color info with given idiom, if not found, return color info for universal idiom
    private func findInfo(forIdiom: \(prefix)ColorInfo.ColorIdiom) -> [\(prefix)ColorInfo] {
        var result = [\(prefix)ColorInfo]()
        var universal = [\(prefix)ColorInfo]()
        for item in info {
            if item.idiom == forIdiom {
                result.append(item)
            }
            if item.idiom == .universal {
                universal.append(item)
            }
        }
        return result.count > 0 ? result : universal
    }

    private func getColorInfoListForCurrentDevice() -> [\(prefix)ColorInfo] {
        let listColors: [\(prefix)ColorInfo]
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            listColors = findInfo(forIdiom: .iphone)
        case .pad:
            listColors = findInfo(forIdiom: .ipad)
        case .tv:
            listColors = findInfo(forIdiom: .tv)
        case .carPlay:
            listColors = findInfo(forIdiom: .car)
        default:
            listColors = findInfo(forIdiom: .universal)
        }
        return listColors
    }

    /// Try to find color info with appearance priority: given appearance, any, light, dark
    private func pickColor(appearance: \(prefix)ColorAppearance) -> \(prefix)ColorInfo? {
        let list = getColorInfoListForCurrentDevice()
        var dark: \(prefix)ColorInfo?
        var light: \(prefix)ColorInfo?
        var clAny: \(prefix)ColorInfo?
        for item in list {
            if appearance == item.appearance {
                return item
            }
            switch item.appearance {
            case .any:
                clAny = item
            case .dark:
                dark = item
            case .light:
                light = item
            }
        }
        if let item = clAny {
            return item
        }
        if let item = light {
            return item
        }
        return dark
    }

    /**
     Get default color
     - iOS 11.0 and later: color by `UIColor(named:)` (so iOS picks color for device type (from iOS 13.0 for current appearance mode also))
     - iOS &lt; 11.0: try to simulate iOS 11.0
     */
    private var `default`: UIColor {
        if #available(iOS 11.0, *), let color = UIColor(named: name) {
            return color
        }
        if let color = pickColor(appearance: .any) {
            return color.color
        }
        fatalError("DEV BUG: Fail to pick auto color for '\\(name)'!")
    }

    /// Force to get color for any appearance, use `default` on failure
    private var `any`: UIColor {
        return pickColor(appearance: .any)?.color ?? self.default
    }

    /// Force to get color for light appearance, use `default` on failure
    private var light: UIColor {
        return pickColor(appearance: .light)?.color ?? self.default
    }

    /// Force to get color for dark appearance, use `default` on failure
    private var dark: UIColor {
        return pickColor(appearance: .dark)?.color ?? self.default
    }

    /// - return: `UIColor(named:)` if `appearanceMode` is `nil`, otherwise color for specified appearance mode.
    var color: UIColor {
        if let mode = \(prefix)Color.appearanceMode {
            switch mode {
            case .any:
                return self.any
            case .light:
                return self.light
            case .dark:
                return self.dark
            }
        }
        return self.default
    }

}


"""

        var assetsColors = [(XCAssets, [XCAssetColor])]()
        if let ipt = input {
            if let res = project.findColorAssets(in: ipt) {
                assetsColors.append(res)
            }
        } else {
            assetsColors = project.findAllColorAssets()
        }

        var allColors = [XCAssetColor]()
        for (assets, colors) in assetsColors {
            allColors.append(contentsOf: colors)
            content += generateSwiftCode(assets: assets, project: project, prefix: prefix)
        }

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

    private func generateSwiftCode(assets: XCAssets, project: XCProject, prefix: String) -> String  {
        return generateSwiftCode(folder: assets, level: 0, prefix: prefix)
    }

    private func generateSwiftCode(folder: XCAssetFoler, level: Int, prefix: String) -> String {
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

        let indent1 = indent(level)
        var strPref = prefix
        if level > 0 {
            strPref = ""
        }
        result += indent1 + "struct \(strPref)\(makeKeyword(folder.name))Color {\n\n"

        for color in colors {
            printLog(.found(color.name))
            result += generateSwiftCode(color: color, level: level + 1, prefix: prefix) + "\n"

        }

        for fdl in folders {
            result += generateSwiftCode(folder: fdl, level: level + 1, prefix: prefix)
        }

        result += indent1 + "}\n\n"
        return result
    }

    private func generateSwiftCode(color: XCAssetColor, level: Int, prefix: String) -> String {
        let name = color.name
        let indent1 = indent(level + 1)
        let indent2 = indent(level + 2)
        let indent3 = indent(level + 3)
        var result = indent1 + "/**\n" + indent1 + " " + name + "\n\n"
        result += indent1 + " - &lt;idiom&gt; (&lt;appearance&gt;): &lt;colorspace&gt; &lt;RGB&gt; &lt;alpha&gt; &lt;name&gt;\n"
        var resultComponent = ""
        for component in color.colors! {
            if let appearance = component.appearances?["luminosity"] {
                result += indent1 + " - \(component.idiom ?? "") (\(appearance)): \(component.colorSpace ?? "") \(component.description) \"\(component.humanReadable ?? "")\"\n"
            } else {
                result += indent1 + " - \(component.idiom ?? ""): \(component.colorSpace ?? "") \(component.description) \"\(component.humanReadable ?? "")\"\n"
            }
            var appearance = "nil"
            if let appr = component.appearances?["luminosity"] {
                appearance = "\"\(appr)\""
            }
            let (red, green, blue, white, alpha) = component.getComponents()
            resultComponent += indent3 + "\(prefix)ColorInfo(d: \"\(component.subtype ?? component.idiom ?? "")\", m: \(appearance), s: \"\(component.colorSpace ?? "")\", r: \(red), g: \(green), b: \(blue), a: \(alpha), w: \(white)),\n"
        }
        result += indent1 + " */\n"
        if resultComponent.count > 1 {
            resultComponent = cropTail(input: resultComponent, length: 2)
        }
        let varName = makeFuncVarName(name)
        if isCheckUse {
            XCValidator.shared.addKeywordForCheckUsage(category: usageCheckCategory, keyword: varName)
        }
        result += indent1 + "static var \(varName): UIColor {\n"
        result += indent2 + "return \(prefix)Color(clName: \"\(color.name)\", clInfo: [\n"
        result += resultComponent + "\n"
        result += indent2 + "]).color\n"
        result += indent1 + "}\n"
        return result
    }

}
