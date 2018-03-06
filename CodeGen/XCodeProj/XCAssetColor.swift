//
//  XCAssetColor.swift
//  CodeGen
//
//  Created by Phạm Quang Dương on 25/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import AppKit

class XCAssetColor: XCAsset {
    
    struct Color {

        enum ColorSpace: String {
            case srgb
            case displayP3 = "display-p3"
            case extendedSRGB = "extended-srgb"
            case extendedLinearSRGB = "extended-linear-srgb"
            case grayGamma22 = "gray-gamma-22"
            case extendedGray = "extended-gray"
        }

        var idiom: String?
        var colorSpace: String?
        var red: String?
        var green: String?
        var blue: String?
        var white: String?
        var alpha: String?
        var humanReadable: String?

        private(set) var color: NSColor?
        private(set) var colorForColorList: NSColor?

        var colorSpaceEnum: ColorSpace? {
            if let space = colorSpace {
                return ColorSpace(rawValue: space)
            }
            return nil
        }

        private func colorValue(from rawValue: String?) -> CGFloat? {
            guard let value = rawValue else { return nil }
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

        var description: String {
            guard let clr = color, let clSpace = colorSpaceEnum else { return "" }
            let a = UInt8(clr.alphaComponent * 100)
            switch clSpace {
            case .extendedGray, .grayGamma22:
                let w = UInt8(clr.whiteComponent * 255)
                return String(format: "#%02X %d%%", w, a )
            default:
                let r = UInt8(clr.redComponent * 255)
                let g = UInt8(clr.greenComponent * 255)
                let b = UInt8(clr.blueComponent * 255)
                return String(format: "#%02X%02X%02X %d%%", r, g, b, a )
            }
        }

        init?(_ info: [String: Any]) {
            if let colorInfo = info["color"] as? [String: Any],
                let components = colorInfo["components"] as? [String: Any] {
                idiom = info["idiom"] as? String
                colorSpace = colorInfo["color-space"] as? String
                red = components["red"] as? String
                green = components["green"] as? String
                blue = components["blue"] as? String
                white =  components["white"] as? String
                alpha = components["alpha"] as? String
                guard let clSpace = colorSpaceEnum else { return nil }
                switch clSpace {
                case .srgb, .extendedSRGB, .extendedLinearSRGB:
                    if let redF = colorValue(from: red), let greenF = colorValue(from: green),
                        let blueF = colorValue(from: blue), let alphaF = colorValue(from: alpha) {
                        color = NSColor(srgbRed: redF, green: greenF, blue: blueF, alpha: alphaF)
                        colorForColorList = color!.usingColorSpaceName(.deviceRGB)
                    }
                case .displayP3:
                    if let redF = colorValue(from: red), let greenF = colorValue(from: green),
                        let blueF = colorValue(from: blue), let alphaF = colorValue(from: alpha) {
                        color = NSColor(displayP3Red: redF, green: greenF, blue: blueF, alpha: alphaF)
                        colorForColorList = color!.usingColorSpaceName(.deviceRGB)
                    }
                case .grayGamma22:
                    if let whiteF = colorValue(from: white), let alphaF = colorValue(from: alpha) {
                        color = NSColor(genericGamma22White: whiteF, alpha: alphaF)
                        colorForColorList = color!.usingColorSpaceName(.deviceWhite)
                    }
                case .extendedGray:
                    if let whiteF = colorValue(from: white), let alphaF = colorValue(from: alpha) {
                        color = NSColor(calibratedWhite: whiteF, alpha: alphaF)
                        colorForColorList = color!.usingColorSpaceName(.deviceWhite)
                    }
                }
                if let cl = color {
                    humanReadable = cl.getName()
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }

        init(red: CGFloat, green: CGFloat, blue: CGFloat) {
            colorSpace = ColorSpace.srgb.rawValue
            color = NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
            self.red = "\(red)"
            self.green = "\(green)"
            self.blue = "\(blue)"
            self.alpha = "1.0"
        }

        func toRGBAColor() -> NSColor? {
            guard let clSpace = colorSpaceEnum else { return nil }
            switch clSpace {
            case .grayGamma22, .extendedGray:
                return color?.usingColorSpaceName(.calibratedRGB)!
            default:
                return color
            }
        }

        func getComponents() -> (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) {
            guard let clSpace = colorSpaceEnum, let cl = color else { return (0, 0, 0, 0, 0) }
            switch clSpace {
            case .grayGamma22, .extendedGray:
                return (0, 0, 0, cl.whiteComponent, cl.alphaComponent)
            default:
                return (cl.redComponent, cl.greenComponent, cl.blueComponent, 0, cl.alphaComponent)
            }
        }

    }

    var colors: [Color]?

    init?(info: [String: Any], folder: XCAssetFoler) {
        if let clrs = info["colors"] as? [[String: Any]] {
            super.init()
            var result = [Color]()
            for clInfo in clrs {
                if let color = Color(clInfo) {
                    result.append(color)
                }
            }
            if result.count == 0 { return nil }
            colors = result
            parent = folder
        } else {
            return nil
        }
    }

}
