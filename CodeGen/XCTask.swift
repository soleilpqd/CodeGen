//
//  XCTask.swift
//  CodeGen
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCTask {

    private static let kKeyType = "type"
    private static let kKeyEnable = "enable"
    private(set) weak var project: XCProject?

    private var logs = [String]()

    enum TaskType: String {
        case color
        case resource
        case string
        case imageUsage = "image_usage"
        case xib
        case tree
        case validate = "Validate Usage"
    }

    let type: TaskType

    init(task: TaskType) {
        type = task
    }

    func indent(_ level: Int) -> String {
        return getIndent(level: level, tabWidth: project?.tabWidth ?? 4, indentWidth: project?.indentWidth ?? 4, useTab: project?.useTab ?? false)
    }

    class func task(_ info: NSDictionary) -> XCTask? {
        if let t = info[kKeyType] as? String, let tt = TaskType(rawValue: t) {
            if let enable = info[kKeyEnable] as? NSNumber, !(enable.boolValue) {
                return nil
            }
            switch tt {
            case .color:
                return XCTaskColor(info)
            case .resource:
                return XCTaskResourcePath(info)
            case .string:
                XCTaskString.shared.appendSubTask(info)
                return XCTaskString.shared
            case .imageUsage:
                XCValidator.shared.shouldCheckImageUsage = true
            case .xib:
                return XCTaskXib(info)
            default:
                break
            }
        }
        return nil
    }

    func run(_ project: XCProject) -> Error? {
        self.project = project
        return nil
    }

    func printLog(_ str: String) {
        logs.append(str)
    }

    func flushLogs() {
        if !Thread.isMainThread {
            fatalError("flushLogs() function should be executed on main thread!") // Just to show logs in order
        }
        print(String.performTask(self.type))
        for s in logs {
            print(s)
        }
    }

    func checkOutputFile(project: XCProject, output: String) -> String {
        var result = output
        if !result.hasPrefix("/") {
            result = (project.projectPath as NSString).appendingPathComponent(output)
        }
        if let chk = project.checkPathInBuildSource(path: output) {
            if !chk {
                printLog(.outputFileNotInTarget(result))
            }
        } else {
            printLog(.outputFileNotInProject(result))
        }
        return result
    }

    func writeOutput(project: XCProject, content: String, fullPath: String) -> (Error?, Bool) {
        var result: Error?
        var isChanged = false
        if let data = try? String(contentsOfFile: fullPath) {
            if content != data {
                result = project.write(content: content, target: fullPath)
                isChanged = true
            }
        } else {
            isChanged = true
            result = project.write(content: content, target: fullPath)
        }
        return (result, isChanged)
    }

}
