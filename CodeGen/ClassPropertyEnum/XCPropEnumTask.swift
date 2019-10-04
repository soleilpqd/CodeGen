//
//  XCPropEnumTask.swift
//  CodeGen
//
//  Created by DươngPQ on 26/09/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

final class XCPropEnumTask: XCTask {

    var placeHolderStart = "// == AUTOGEN\n"
    var placeHolderEnd = "// AUTOGEN ==\n"
    var name = "PropertyName"
    let files: [String]
    let classRegex: NSRegularExpression
    let propRegex: NSRegularExpression

    init?(_ info: NSDictionary) {
        if let targets = info["files"] as? [String], targets.count > 0,
            let regex = try? NSRegularExpression(pattern: ".*class .*\\{", options: .init(rawValue: 0)),
            let regex2 = try? NSRegularExpression(pattern: " var .*:", options: .init(rawValue: 0)){
            classRegex = regex
            propRegex = regex2
            files = targets
            if let text = info["placeholder_start"] as? String, text.count > 0 {
                placeHolderStart = text + "\n"
            }
            if let text = info["placeholder_end"] as? String, text.count > 0 {
                placeHolderEnd = text + "\n"
            }
            if let text = info["name"] as? String, text.count > 0 {
                name = text
            }
            super.init(task: .propertyEnum)
        } else {
            return nil
        }
    }

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)
        for item in files {
            let fullPath = (project.projectPath as NSString).appendingPathComponent(item)
            if let data = try? String(contentsOfFile: fullPath) {
                processInputData(data: data, file: fullPath, project: project)
            } else {
                printLog(String.stringFileNotLoaded(fullPath))
            }
        }
        return nil
    }

    private func processInputData(data: String, file: String, project: XCProject) {
        var finalData = ""
        let result = classRegex.matches(in: data, options: .init(rawValue: 0), range: NSMakeRange(0, data.count))
        var curentRange: NSRange?
        var classes = [String]()
        for match in result {
            let range = match.range
            if let cRange = curentRange {
                let clsData = String(data[data.index(data.startIndex, offsetBy: cRange.location)..<data.index(data.startIndex, offsetBy: range.location)])
                classes.append(clsData)
            } else {
                finalData = String(data[..<data.index(data.startIndex, offsetBy: range.location)])
            }
            curentRange = range
        }
        if let cRange = curentRange {
            let clsData = String(data[data.index(data.startIndex, offsetBy: cRange.location)...])
            classes.append(clsData)
        }
        for item in classes {
            finalData += makeDataForClass(item)
        }
        if finalData != data {
            _ = project.write(content: finalData, target: file)
        }
    }

    private func makeDataForClass(_ clsData: String) -> String {
        let indent1 = indent(1)
        let indent2 = indent(2)
        if let startPos = clsData.range(of: placeHolderStart), let endPos = clsData.range(of: placeHolderEnd) {
            let matches = propRegex.matches(in: clsData, options: .init(rawValue: 0), range: NSMakeRange(0, clsData.count))
            if matches.count > 0 {
                var result = String(clsData[..<startPos.upperBound])
                result += indent1 + "// THIS CODE SECTION IS GENERATED. DO NOT EDIT.\n"
                result += indent1 + "struct \(name) {\n"
                for match in matches {
                    let propName = String(clsData[clsData.index(clsData.startIndex, offsetBy: match.range.lowerBound + 5)..<clsData.index(clsData.startIndex, offsetBy: match.range.upperBound - 1)]).trimmingCharacters(in: CharacterSet.whitespaces)
                    let codeName = makeFuncVarName(propName)
                    result += indent2 + "static let \(codeName) = \"\(propName)\"\n"
                }
                result += indent1 + "}\n"
                result += indent1 + String(clsData[endPos.lowerBound...])
                return result
            }
        }
        return clsData
    }

}
