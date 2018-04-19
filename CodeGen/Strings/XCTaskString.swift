//
//  XCStringTask.swift
//  CodeGen
//
//  Created by DươngPQ on 18/04/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

let kStringParam = "%@"

class XCTaskString: XCTask {

    class func countParams(_ input: String) -> UInt {
        let array = input.components(separatedBy: kStringParam)
        return UInt(array.count - 1)
    }

    private class SubTask {

        enum OutputType: String {
            case string
            case url
            case enumeration = "enum"
            case validation = "check"
        }

        private(set) var input: String
        private(set) var output: String
        private(set) var type: OutputType

        var logs = [String]()

        func log(_ inpunt: String) {
            logs.append(inpunt)
        }

        init(inp: String, outp: String, oType: OutputType) {
            input = inp
            output = outp
            type = oType
        }

        func getInfo(from info: NSDictionary) {

        }

        func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
            var content = project.getHeader(output) + "//  Add text key & content into \(input) and Build project.\n\n"
            content += "import Foundation\n\n"
            return content
        }

        func run(project: XCProject, tables: [XCStringTable]) -> Error? {
            log(.performTask(.string) + "." + type.rawValue + ": " + input)
            let fullOutputPath = XCTaskString.shared.checkOutputFile(project: project, output: output)
            let content = makeContent(project: project, tables: tables)
            let (error, change) = XCTaskString.shared.writeOutput(project: project, content: content, fullPath: fullOutputPath)
            if !change {
                log(.outputNotChange())
            }
            return error
        }

    }

    private class StringSubTask: SubTask {

        private var attrStringPrefix: String?

        override func getInfo(from info: NSDictionary) {
            super.getInfo(from: info)
            attrStringPrefix = info["attr_prefix"] as? String
        }

        private func makeComment(itemKey: String, item: XCStringItem) -> (String, UInt) {
            let indent2 = XCTaskString.shared.indent(2)
            var result = indent2 +  "/**\n"
            var paramsCount: UInt = 0
            result += indent2 + " \(itemKey)\n"
            for (language, contents) in item.values {
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

        private func makeTextVar(itemKey: String, tableName: String) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            result += indent2 + "static var \(makeFuncVarName(itemKey)): String {\n"
            result += indent3 + "return NSLocalizedString(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            result += indent2 + "}\n\n"
            return result
        }

        private func makeFuncParamsList(_ paramsCount: UInt) -> String {
            var paramsList = ""
            for paramIndex in 1 ... paramsCount {
                paramsList += "param\(paramIndex): Any, "
            }
            return String(paramsList[..<paramsList.index(paramsList.endIndex, offsetBy: -2)])
        }

        private func makePatternParamsList(_ paramsCount: UInt) -> String {
            var paramsList = ""
            for paramIndex in 1 ... paramsCount {
                paramsList += "\"\\(param\(paramIndex))\", "
            }
            return String(paramsList[..<paramsList.index(paramsList.endIndex, offsetBy: -2)])
        }

        private func makeTextParamsFunc(paramsCount: UInt, itemKey: String, tableName: String) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            var paramsList = makeFuncParamsList(paramsCount)
            result += indent2 + "static func \(makeFuncVarName(itemKey))(\(paramsList)) -> String {\n"
            result += indent3 + "let pattern = NSLocalizedString(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            paramsList = makePatternParamsList(paramsCount)
            result += indent3 + "return String(format: pattern, \(paramsList))\n"
            result += indent2 + "}\n\n"
            return result
        }

        private func makeAttrStringCodeGen(_ isSwiftLintEnbale: Bool) -> String {
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            let indent4 = XCTaskString.shared.indent(4)
            let indent5 = XCTaskString.shared.indent(4)

            var result = ""
            if isSwiftLintEnbale {
                result = indent2 + "// swiftlint:disable line_length\n"
            }
            result += indent2 + "private static func makeAttributeString(_ htmlString: String) -> NSAttributedString {\n"
            result += indent3 + "if let data = htmlString.data(using: .utf8),\n"
            result += indent4 + "let result = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html,\n"
            result += indent4 + "                                                           .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)],\n"
            result += indent4 + "                                     documentAttributes: nil) {\n"
            result += indent5 + "return result\n"
            result += indent3 + "}\n"
            result += indent3 + "return NSAttributedString()\n"
            result += indent2 + "}\n\n"
            return result
        }

        private func makeAttrTextVar(itemKey: String, tableName: String) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            result += indent2 + "static var \(makeFuncVarName(itemKey)): NSAttributedString {\n"
            result += indent3 + "let htmlString = NSLocalizedString(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            result += indent3 + "return makeAttributeString(htmlString)\n"
            result += indent2 + "}\n\n"
            return result
        }

        private func makeAttrTextParamsFunc(paramsCount: UInt, itemKey: String, tableName: String) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            var paramsList = makeFuncParamsList(paramsCount)
            result += indent2 + "static func \(makeFuncVarName(itemKey))(\(paramsList)) -> NSAttributedString {\n"
            result += indent3 + "let pattern = NSLocalizedString(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            paramsList = makePatternParamsList(paramsCount)
            result += indent3 + "let htmlString = String(format: pattern, \(paramsList))\n"
            result += indent3 + "return makeAttributeString(htmlString)\n"
            result += indent2 + "}\n\n"
            return result
        }

        override func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
            var result = super.makeContent(project: project, tables: tables)
            let indent1 = XCTaskString.shared.indent(1)
            let tableName = (input as NSString).deletingPathExtension
            result += "extension String {\n\n"
            for table in tables where table.name == input {
                var isAttTextAvailabe = false
                result += indent1 + "struct \(project.prefix ?? "")\(makeKeyword(tableName)) {\n\n"
                for item in table.items {
                    guard let itemKey = item.key else { continue }
                    var paramsCount: UInt = 0

                    log("\t" + .found(itemKey))
                    let (comment, cnt) = makeComment(itemKey: itemKey, item: item)
                    result += comment
                    paramsCount = cnt

                    if let attrPrefix = attrStringPrefix, itemKey.hasPrefix(attrPrefix) {
                        isAttTextAvailabe = true
                        if paramsCount > 0 {
                            result += makeAttrTextParamsFunc(paramsCount: paramsCount, itemKey: itemKey, tableName: tableName)
                        } else {
                            result += makeAttrTextVar(itemKey: itemKey, tableName: tableName)
                        }
                    } else {
                        if paramsCount > 0 {
                            result += makeTextParamsFunc(paramsCount: paramsCount, itemKey: itemKey, tableName: tableName)
                        } else {
                            result += makeTextVar(itemKey: itemKey, tableName: tableName)
                        }
                    }
                }
                if isAttTextAvailabe {
                    result += makeAttrStringCodeGen(project.swiftlintEnable)
                }
                result += indent1 + "}\n\n"
            }
            result += "}\n"
            return result
        }

    }

    private class UrlSubTask: SubTask {

        private var bases = [String: String]() // [Prefix: Domain]

        override func getInfo(from info: NSDictionary) {
            super.getInfo(from: info)
            if let domains = info["bases"] as? [String: String] {
                bases = domains
            }
        }

        override func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
            var result = super.makeContent(project: project, tables: tables)


            return result
        }

    }

    private class EnumSubTask: SubTask {

        private var names = [String: String]() // [Enum name: Prefix]

        override func getInfo(from info: NSDictionary) {
            super.getInfo(from: info)
            if let enumNames = info["names"] as? [String: String] {
                names = enumNames
            }
        }

    }

    static let shared = XCTaskString(task: .string)

    private var isNeedValidate = false
    private let operationQueue = OperationQueue()
    private var subTasks = [SubTask]()

    override init(task: TaskType) {
        super.init(task: .string)
    }

    func appendSubTask(_ info: NSDictionary) {
        if let inp = info["input"] as? String, let outp = info["output"] as? String, let typ = info["output_type"] as? String, let ttyp = SubTask.OutputType(rawValue: typ) {
            var subTask: SubTask?
            switch ttyp {
            case .string:
                subTask = StringSubTask(inp: inp, outp: outp, oType: ttyp)
            case .url:
                subTask = UrlSubTask(inp: inp, outp: outp, oType: ttyp)
            case .enumeration:
                subTask = EnumSubTask(inp: inp, outp: outp, oType: ttyp)
            case .validation:
                isNeedValidate = true
            }
            if let sTask = subTask {
                sTask.getInfo(from: info)
                subTasks.append(sTask)
            }
        }
    }

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)

        var languages = [String]()
        var errors = [String: Error]()
        let strings = project.buildStrings(languages: &languages, errors: &errors)

        if errors.count > 0 {
            for (file, error) in errors {
                if let err = error as? XCStringsParserError {
                    switch err {
                    case .notLoad:
                        printError(String.stringFileNotLoaded(file))
                    case .failed(let row, let column):
                        printError(String.stringFileParsingFailed(file: file, row: row, column: column))
                    }
                }
            }
            return errors.values.first
        }

        var count = 0
        var taskErrors = [Error]()
        for sTask in subTasks {
            operationQueue.addOperation {
                if let result = sTask.run(project: project, tables: strings) {
                    taskErrors.append(result)
                }
                count += 1
            }
        }
        while count < subTasks.count {
            sleep(0)
        }
        for sTask in subTasks {
            for log in sTask.logs {
                printLog(log)
            }
        }
        if isNeedValidate {

        }

        return taskErrors.first
    }

}
