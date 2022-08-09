//
//  XCStringSubTask.swift
//  CodeGen
//
//  Created by DươngPQ on 4/29/20.
//  Copyright © 2020 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCTaskStringSubTask {

    enum OutputType: String {
        case string
        case url
        case enumeration = "enum"
        case enumString = "enumStr"
        case validation = "check"
    }

    private(set) var input: String
    private(set) var output: String
    private(set) var type: OutputType
    var localizeFunc = "NSLocalizedString"
    let usageCategory: String

    var logs = [String]()

    func log(_ inpunt: String) {
        logs.append(inpunt)
    }

    init(inp: String, outp: String, oType: OutputType) {
        input = inp
        output = outp
        type = oType
        usageCategory = XCTask.TaskType.string.rawValue + "." + type.rawValue + ": " + output
    }

    func getInfo(from info: NSDictionary) {

    }

    func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
        var content = project.getHeader(output) + "//  Add text key & content into \(input) and Build project.\n\n"
        content += "import Foundation\n\n"
        if project.swiftlintEnable {
            content += "// swiftlint:disable\n\n"
        }
        return content
    }

    func makeComment(itemKey: String, item: XCStringItem, indent: Int = 1) -> (String, UInt) {
        let indent2 = XCTaskString.shared.indent(indent)
        var result = indent2 +  "/**\n"
        var paramsCount: UInt = 0
        result += indent2 + " \(itemKey)\n"
        let allLang = item.values.keys.sorted()
        for language in allLang {
            guard let contents = item.values[language] else { continue }
            let content = contents.last?.content ?? ""
            if language.count > 0 {
                result += indent2 + " - \(language): \"\(escapeStringForComment(content))\"\n"
            } else {
                result += indent2 + " - \"\(escapeStringForComment(content))\"\n"
            }
            let cnt = XCTaskString.countParams(content)
            if cnt > paramsCount { paramsCount = cnt }
        }
        result += indent2 + "*/\n"
        return (result, paramsCount)
    }

    func makeFuncParamsList(_ paramsCount: UInt) -> String {
        var paramsList = ""
        for paramIndex in 1 ... paramsCount {
            paramsList += "_ param\(paramIndex): Any, "
        }
        return cropTail(input: paramsList, length: 2)
    }

    func makePatternParamsList(_ paramsCount: UInt) -> String {
        var paramsList = ""
        for paramIndex in 1 ... paramsCount {
            paramsList += "\"\\(param\(paramIndex))\", "
        }
        return cropTail(input: paramsList, length: 2)
    }

    func run(project: XCProject, tables: [XCStringTable]) -> Error? {
        log("\t" + .performTask(.string) + "." + type.rawValue + ": " + input)
        let fullOutputPath = XCTaskString.shared.checkOutputFile(project: project, output: output)
        let content = makeContent(project: project, tables: tables)
        let (error, change) = XCTaskString.shared.writeOutput(project: project, content: content, fullPath: fullOutputPath)
        if !change {
            log("\t" + .outputNotChange())
        }
        return error
    }

}
