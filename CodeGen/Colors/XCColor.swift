//
//  XCColor.swift
//  ColorXCode
//
//  Created by DươngPQ on 05/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//
//  Color name matching based on http://chir.ag/projects/name-that-color

import Foundation

struct XCColorComponents {

    var colorSpace: String?

    var red: Float
    var green: Float
    var blue: Float
    var alpha: Float

    var hue: Float = 0
    var saturation: Float = 0
    var lightness: Float = 0

    init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        makeHSL()
    }

    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = Float(red) / 255
        self.green = Float(green) / 255
        self.blue = Float(blue) / 255
        self.alpha = 1.0
        makeHSL()
    }

    static func ==(left: XCColorComponents, right: XCColorComponents) -> Bool {
        return left.red == right.red && left.green == right.green && left.blue == right.blue
    }

    mutating func makeHSL() {
        let minVal = min(red, min(green, blue))
        let maxVal = max(red, max(green, blue))
        let delta = Float(maxVal) - Float(minVal)
        let l = (Float(maxVal) + Float(minVal)) / 2.0
        var s: Float = 0
        if l > 0 && l < 1 {
            s = delta / (l < 0.5 ? (2 * l) : (2 - 2 * l))
        }
        var h: Float = 0
        if delta > 0 {
            if maxVal == red && maxVal != green { h += (Float(green) - Float(blue)) / delta }
            if maxVal == green && maxVal != blue { h += (2 + (Float(blue) - Float(red)) / delta) }
            if maxVal == blue && maxVal != red { h += (4 + (Float(red) - Float(green)) / delta) }
            h /= 6;
        }
        hue = h
        saturation = s
        lightness = l
    }

    var description: String {
        let r = UInt8(red * 255)
        let g = UInt8(green * 255)
        let b = UInt8(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
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
        return result
    }

    class func findColorNameMatch(_ color: XCColorComponents) -> (String, XCColorComponents)? {
        var cl: String?
        var ndf1: Float = 0
        var ndf2: Float = 0
        var ndf: Float = 0;
        var df: Float = -1

        for (name, value) in XCColor.colorNames {
            if color == value {
                return (name, value)
            }
            ndf1 = powf(Float(color.red) - Float(value.red), 2) + powf(Float(color.green) - Float(value.green), 2) + powf(Float(color.blue) - Float(value.blue), 2)
            ndf2 = powf(Float(color.hue) - Float(value.hue), 2) + powf(Float(color.saturation) - Float(value.saturation), 2) + powf(Float(color.lightness) - Float(value.lightness), 2)
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

    private class func colorValue(from value: String) -> Float {
        if value.hasPrefix("0x") {
            let str = String(value[value.index(value.startIndex, offsetBy: 2)...])
            let iVal = UInt8(str, radix: 16) ?? 0
            let fVal = Float(iVal) / 255.0
            return fVal
        } else if value.contains(".") {
            let fVal = Float(value) ?? 0
            return fVal
        } else {
            let iVal = UInt8(value) ?? 0
            let fVal = Float(iVal) / 255.0
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
                if let color = dic["color"] as? [String: Any],
                    let components = color["components"] as? [String: String],
                    let red = components["red"], let green = components["green"], let blue = components["blue"], let alpha = components["alpha"] {
                    let redF = colorValue(from: red)
                    let greenF = colorValue(from: green)
                    let blueF = colorValue(from: blue)
                    let alphaF = colorValue(from: alpha)
                    var comp = XCColorComponents(red: redF, green: greenF, blue: blueF, alpha: alphaF)
                    comp.colorSpace = color["color-space"] as? String
                    result[idiom] = comp
                    if let readable = findColorNameMatch(comp) {
                        readableResult[idiom] = readable
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
        let indent2 = makeIndentation(level: indentLevel + 1, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var result =  indent1 + "// \(componentName): \(component.colorSpace ?? "") \(component.description) \"\(readable)\"\n"
        if component.colorSpace == "display-p3" {
            result += indent1 + "if #available(iOS 10.0, *) {\n"
            result += indent2 + "result = UIColor(displayP3Red: \(component.red), green: \(component.green), blue: \(component.blue), alpha: \(component.alpha))\n"
            result += indent1 + "} else {\n"
            result += indent2 + "result = UIColor(red: \(component.red), green: \(component.green), blue: \(component.blue), alpha: \(component.alpha))\n"
            result += indent1 + "}\n"
        } else {
            result += indent1 + "result = UIColor(red: \(component.red), green: \(component.green), blue: \(component.blue), alpha: \(component.alpha))\n"
        }
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
            content += genDescription(of: key, indentLevel: 5, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
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

    class func genSingleComponentCommonFunction(swiftlingEnable: Bool, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String  {
        let indent1 = makeIndentation(level: 1, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent2 = makeIndentation(level: 2, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        let indent3 = makeIndentation(level: 3, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
        var content = swiftlingEnable ? indent1 + "// swiftlint:disable:next function_parameter_count\n" : ""
        content += indent1 + "private static func makeSingleTypeColor(name: String, colorSpace: String, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {"
        content += indent2 + "var result: UIColor!\n"
        content += indent2 + "if #available(iOS 11.0, *) {\n"
        content += indent3 + "result = UIColor(named: name)\n"
        content += indent2 + "}\n"
        content += indent2 + "if result == nil, #available(iOS 10.0, *), colorSpace == \"display-p3\" {\n"
        content += indent3 + "result = UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)\n"
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
        result += indent1 + "/// \(componentName): \(component.colorSpace ?? "") \(component.description)"
        if let (readable, _) = self.humanReadable[componentName] {
            result += " \"" + readable + "\"\n"
        } else {
            result += "\n"
        }
        result += indent1 + "static var \(prefix)\(self.name.replacingOccurrences(of: " ", with: "")): UIColor {\n"
        result += indent2 + "return makeSingleTypeColor(name: \"\(self.name ?? "")\", colorSpace: \"\(component.colorSpace ?? "")\", red: \(component.red), green: \(component.green), blue: \(component.blue), alpha: \(component.alpha))\n"
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
