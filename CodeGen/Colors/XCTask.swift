//
//  XCTask.swift
//  CodeGen
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCTask {

    enum TaskType: String {
        case color
    }

    let type: TaskType

    init(task: TaskType) {
        type = task
    }

    class func task(_ info: NSDictionary) -> XCTask? {
        if let t = info["type"] as? String, let tt = TaskType(rawValue: t) {
            switch tt {
            case .color:
                return XCTaskColor(info)
            }
        }
        return nil
    }

    func run(_ project: XCClassFile) -> Error? {
        return nil
    }

}

class XCTaskColor: XCTask {

    let input: String
    let output: String

    init?(_ info: NSDictionary) {
        if let input = info["input"] as? String, let output = info["output"] as? String {
            self.input = input
            self.output = output
            super.init(task: .color)
        } else {
            return nil
        }
    }

    override func run(_ project: XCClassFile) -> Error? {
        var content = "//  Add colorset into \"\(input)\" and Build project.\n\n"
        content += "import UIKit\n\n"
        content += "extension UIColor {\n\n"
        let path = input.hasPrefix("/") ? input : (project.projectPath as NSString).appendingPathComponent(input)
        let colors = XCColor.findAllXCodeColors(from: path)
        for color in colors where color.components.count == 1 {
            content += XCColor.genSingleComponentCommonFunction(swiftlingEnable: project.swiftlintEnable,
                                                                tabWidth: project.tabWidth,
                                                                indentWidth: project.indentWidth,
                                                                useTab: project.useTab)
            break
        }
        for color in colors {
            content += color.generateSwiftCode(prefix: project.prefix?.lowercased() ?? "", tabWidth: project.tabWidth,
                                               indentWidth: project.indentWidth, useTab: project.useTab) + "\n"
        }
        content += "}\n"
        return project.write(content: content, target: output)
    }

}
