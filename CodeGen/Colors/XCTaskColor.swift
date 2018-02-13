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

    let input: String
    let output: String
    let colorListName: String?

    init?(_ info: NSDictionary) {
        if let input = info["input"] as? String, let output = info["output"] as? String {
            self.input = input
            self.output = output
            colorListName = info["list"] as? String
            super.init(task: .color)
        } else {
            return nil
        }
    }

    private func makeColorList(project: XCClassFile, colors: [XCColor]) {
        guard var clrName = colorListName else { return }
        if clrName.count == 0 {
            clrName = ((project.projectFile as NSString).lastPathComponent as NSString).deletingPathExtension
        }
        var colorList: NSColorList?
        var nameAvailable = true
        for clList in NSColorList.availableColorLists where clList.name?.rawValue == clrName {
            nameAvailable = false
            if clList.isEditable {
                colorList = clList
            }
        }
        if colorList == nil {
            if !nameAvailable {
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
            colorList = NSColorList(name: .init(rawValue: clrName))
        }
        if let list = colorList {
            let keys = list.allKeys
            for key in keys {
                list.removeColor(withKey: key)
            }
            for color in colors {
                if color.components.count == 1 {
                    let (_, cl) = color.components.first!
                    list.setColor(cl.color, forKey: .init(rawValue: color.name))
                } else {
                    for (key, value) in color.components {
                        list.setColor(value.color, forKey: .init(rawValue: color.name + " " + key))
                    }
                }
            }
            _ = list.write(toFile: nil)
        }
    }

    override func run(_ project: XCClassFile) -> Error? {
        var content = "//  Add colorset into \"\(input)\" and Build project.\n\n"
        content += "import UIKit\n\n"
        content += "extension UIColor {\n\n"
        let path = input.hasPrefix("/") ? input : (project.projectPath as NSString).appendingPathComponent(input)
        let colors = XCColor.findAllXCodeColors(from: path)
        content += XCColor.generateCommonFunction(swiftlingEnable: project.swiftlintEnable,
                                                  tabWidth: project.tabWidth,
                                                  indentWidth: project.indentWidth,
                                                  useTab: project.useTab)
        for color in colors {
            content += color.generateSwiftCode(prefix: project.prefix?.lowercased() ?? "", tabWidth: project.tabWidth,
                                               indentWidth: project.indentWidth, useTab: project.useTab) + "\n"
        }
        content += "}\n"
        let result = project.write(content: content, target: output)
        makeColorList(project: project, colors: colors)
        return result
    }

}
