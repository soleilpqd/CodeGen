//
//  XCColor.swift
//  ColorXCode
//
//  Created by DươngPQ on 05/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//
//  Color name matching based on http://chir.ag/projects/name-that-color

import Foundation
import AppKit

struct XCColorComponents {

    enum ColorSpace: String {
        case srgb
        case displayP3 = "display-p3"
        case extendedSRGB = "extended-srgb"
        case extendedLinearSRGB = "extended-linear-srgb"
        case grayGamma22 = "gray-gamma-22"
        case extendedGray = "extended-gray"
    }

    private(set) var colorSpace: ColorSpace
    private(set) var color: NSColor

    init?(space: String, red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat, alpha: CGFloat) {
        if let clSpace = ColorSpace(rawValue: space) {
            colorSpace = clSpace
            switch clSpace {
            case .srgb, .extendedSRGB, .extendedLinearSRGB:
                color = NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
            case .displayP3:
                color = NSColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
            case .grayGamma22:
                color = NSColor(genericGamma22White: white, alpha: alpha)
            case .extendedGray:
                color = NSColor(calibratedWhite: white, alpha: alpha)
            }
        } else {
            return nil
        }
    }

    init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        colorSpace = .srgb
        color = NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    }

    static func ==(left: XCColorComponents, right: XCColorComponents) -> Bool {
        return left.color.isEqual(right)
    }

    var description: String {
        let a = UInt8(color.alphaComponent * 100)
        switch colorSpace {
        case .extendedGray, .grayGamma22:
            let w = UInt8(color.whiteComponent * 255)
            return String(format: "#%02X %d%%", w, a )
        default:
            let r = UInt8(color.redComponent * 255)
            let g = UInt8(color.greenComponent * 255)
            let b = UInt8(color.blueComponent * 255)
            return String(format: "#%02X%02X%02X %d%%", r, g, b, a )
        }
    }

    func toRGBAColor() -> NSColor {
        switch colorSpace {
        case .grayGamma22, .extendedGray:
            return color.usingColorSpaceName(.calibratedRGB)!
        default:
            return color
        }
    }

    func getComponents() -> (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) {
        switch colorSpace {
        case .grayGamma22, .extendedGray:
            return (0, 0, 0, color.whiteComponent, color.alphaComponent)
        default:
            return (color.redComponent, color.greenComponent, color.blueComponent, 0, color.alphaComponent)
        }
    }

}

class XCColor {

    private static let colorNames: [String: XCColorComponents] = {
        return getNames()
    }()

    private(set) var name: String!
    private(set) var components = [String: XCColorComponents]()
    private(set) var humanReadable = [String: (String, XCColorComponents)]()
    
    class func findAllXCodeColors(from assestsPath: String) -> [XCColor] {
        var result = [XCColor]()
        let fileMan = FileManager.default
        if let items = fileMan.subpaths(atPath: assestsPath) {
            for item in items where item.hasSuffix(".colorset/Contents.json") {
                var path = assestsPath
                if path.hasSuffix("/") {
                    path += item
                } else {
                    path += "/" + item
                }
                if let color = self.color(from: path) {
                    result.append(color)
                }
            }
        }
        return result.sorted(by: { (left, right) -> Bool in
            return left.name.compare(right.name) == .orderedAscending
        })
    }

    class func findColorNameMatch(_ color: XCColorComponents) -> (String, XCColorComponents)? {
        var cl: String?
        var ndf1: CGFloat = 0
        var ndf2: CGFloat = 0
        var ndf: CGFloat = 0;
        var df: CGFloat = -1

        for (name, value) in XCColor.colorNames {
            if color == value {
                return (name, value)
            }
            let clr = color.toRGBAColor()
            let vlr = value.toRGBAColor()
            ndf1 = pow(clr.redComponent - vlr.redComponent, 2) + pow(clr.greenComponent - vlr.greenComponent, 2) + pow(clr.blueComponent - vlr.blueComponent, 2)
            ndf2 = pow(clr.hueComponent - vlr.hueComponent, 2) + pow(clr.saturationComponent - vlr.saturationComponent, 2) + pow(clr.brightnessComponent - vlr.brightnessComponent, 2)
            ndf = ndf1 + ndf2 * 2
            if df < 0 || df > ndf {
                df = ndf
                cl = name
            }
        }
        if let name = cl, let bytes = XCColor.colorNames[name] {
            return (name, bytes)
        }
        return nil
    }

    private class func colorValue(from value: String) -> CGFloat {
        if value.hasPrefix("0x") {
            let str = String(value[value.index(value.startIndex, offsetBy: 2)...])
            let iVal = UInt8(str, radix: 16) ?? 0
            let fVal = CGFloat(iVal) / 255.0
            return fVal
        } else if value.contains(".") {
            let fVal = CGFloat(Double(value) ?? 0)
            return fVal
        } else {
            let iVal = UInt8(value) ?? 0
            let fVal = CGFloat(iVal) / 255.0
            return fVal
        }
    }
    
    private class func color(from colorSetPath: String) -> XCColor? {
        if let data = try? NSData(contentsOfFile: colorSetPath) as Data,
            let json = try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)) as? [String: Any],
            let jsonDic = json, let idioms = jsonDic["colors"] as? [[String: Any]] {
            var result = [String: XCColorComponents]()
            var readableResult = [String: (String, XCColorComponents)]()
            let validation = ["universal", "iphone", "ipad", "tv"]
            for dic in idioms {
                guard let idiom = dic["idiom"] as? String else { continue }
                if !validation.contains(idiom) { continue }
                if let color = dic["color"] as? [String: Any], let components = color["components"] as? [String: String],
                    let space = color["color-space"] as? String {
                    var redF: CGFloat = 0
                    var greenF: CGFloat = 0
                    var blueF: CGFloat = 0
                    var alphaF: CGFloat = 0
                    var whiteF: CGFloat = 0
                    if let red = components["red"], let green = components["green"], let blue = components["blue"] {
                        redF = colorValue(from: red)
                        greenF = colorValue(from: green)
                        blueF = colorValue(from: blue)
                    }
                    if let white = components["white"] {
                        whiteF = colorValue(from: white)
                    }
                    if let alpha = components["alpha"] {
                        alphaF = colorValue(from: alpha)
                    }
                    if let comp = XCColorComponents(space: space, red: redF, green: greenF, blue: blueF, white: whiteF, alpha: alphaF) {
                        result[idiom] = comp
                        if let readable = findColorNameMatch(comp) {
                            readableResult[idiom] = readable
                        }
                    }
                }
            }
            if result.count > 0 {
                let obj = XCColor()
                let nsStr = (colorSetPath as NSString).deletingLastPathComponent as NSString
                obj.name = (nsStr.lastPathComponent as NSString).deletingPathExtension
                obj.components = result
                obj.humanReadable = readableResult
                return obj
            }
        }
        return nil
    }

    private func genDescription(of componentName: String, indentLevel: Int, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        guard let component = components[componentName], let (readable, _) = humanReadable[componentName] else {
            return ""
        }
        let indent1 = makeIndentation(level: indentLevel, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var result =  indent1 + "// \(componentName): \(component.colorSpace.rawValue) \(component.description) \"\(readable)\"\n"
        let (r, g, b, w, a) = component.getComponents()
        result += indent1 + "result = makeColor(name: \"\(self.name ?? "")\", colorSpace: \"\(component.colorSpace.rawValue)\", red: \(r), green: \(g), blue: \(b), white: \(w), alpha: \(a))\n"
        return result
    }

    private func genColor(content: String, prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        let indent1 = makeIndentation(level: 1, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent2 = makeIndentation(level: 2, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent3 = makeIndentation(level: 3, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var result = indent1 + "/// " + self.name + "\n"
        result += indent1 + "static var \(prefix)\(self.name.replacingOccurrences(of: " ", with: "")): UIColor {\n"
        result += indent2 + "var result: UIColor!\n"
        result += indent2 + "if #available(iOS 11.0, *) {\n"
        result += indent3 + "result = UIColor(named: \"\(self.name ?? "")\")\n"
        result += indent2 + "}\n"
        result += indent2 + "if result == nil {\n"
        result += content
        result += indent2 + "}\n"
        result += indent2 + "return result\n"
        result += indent1 + "}\n"
        return result
    }

    private func generateSwiftCodeMultiComponents(prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        let indent3 = makeIndentation(level: 3, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent4 = makeIndentation(level: 4, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var content = indent3 + "switch UIDevice.current.userInterfaceIdiom {\n"
        for (key, _) in components where key != "universal" {
            switch key {
            case "iphone":
                content += indent3 + "case .phone:\n"
            case "ipad":
                content += indent3 + "case .pad:\n"
            case "tv":
                content += indent3 + "case .tv:\n"
            default:
                continue
            }
            content += genDescription(of: key, indentLevel: 4, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        }
        content += indent3 + "default:\n"
        if components["universal"] != nil {
            content += genDescription(of: "universal", indentLevel: 4, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        } else {
            content += indent4 + "result = UIColor()\n"
        }
        content += indent3 + "}\n"
        return genColor(content: content, prefix: prefix, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
    }

    class func generateCommonFunction(swiftlingEnable: Bool, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String  {
        let indent1 = makeIndentation(level: 1, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent2 = makeIndentation(level: 2, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent3 = makeIndentation(level: 3, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var content = swiftlingEnable ? indent1 + "// swiftlint:disable:next function_parameter_count\n" : ""
        content += indent1 + "private static func makeColor(name: String, colorSpace: String, red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat, alpha: CGFloat) -> UIColor {\n"
        content += indent2 + "var result: UIColor!\n"
        content += indent2 + "if #available(iOS 11.0, *) {\n"
        content += indent3 + "result = UIColor(named: name)\n"
        content += indent2 + "}\n"
        content += indent2 + "if result == nil, #available(iOS 10.0, *), colorSpace == \"\(XCColorComponents.ColorSpace.displayP3.rawValue)\" {\n"
        content += indent3 + "result = UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)\n"
        content += indent2 + "}\n"
        content += indent2 + "if result == nil, colorSpace == \"\(XCColorComponents.ColorSpace.grayGamma22.rawValue)\" || colorSpace == \"\(XCColorComponents.ColorSpace.extendedGray.rawValue)\" {\n"
        content += indent3 + "result = UIColor(white: white, alpha: alpha)\n"
        content += indent2 + "}\n"
        content += indent2 + "if result == nil {\n"
        content += indent3 + "result = UIColor(red: red, green: green, blue: blue, alpha: alpha)\n"
        content += indent2 + "}\n"
        content += indent2 + "return result\n"
        content += indent1 + "}\n\n"
        return content
    }

    private func generateSwiftCodeSingleComponent(prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        let indent1 = makeIndentation(level: 1, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent2 = makeIndentation(level: 2, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var result = indent1 + "/// " + self.name + "\n"
        let (componentName, component) = self.components.first!
        let (r, g, b, w, a) = component.getComponents()
        result += indent1 + "/// \(componentName): \(component.colorSpace.rawValue) \(component.description)"
        if let (readable, _) = self.humanReadable[componentName] {
            result += " \"" + readable + "\"\n"
        } else {
            result += "\n"
        }
        result += indent1 + "static var \(prefix)\(self.name.replacingOccurrences(of: " ", with: "")): UIColor {\n"
        result += indent2 + "return makeColor(name: \"\(self.name ?? "")\", colorSpace: \"\(component.colorSpace.rawValue)\", red: \(r), green: \(g), blue: \(b), white: \(w), alpha: \(a))\n"
        result += indent1 + "}\n"
        return result
    }

    func generateSwiftCode(prefix: String, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
        if components.count > 1 {
            return generateSwiftCodeMultiComponents(prefix: prefix, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        } else if components.count > 0 {
            return generateSwiftCodeSingleComponent(prefix: prefix, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        }
        return ""
    }

}
