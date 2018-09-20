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
            usageCategory = TaskType.string.rawValue + "." + type.rawValue + ": " + output
        }

        func getInfo(from info: NSDictionary) {

        }

        func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
            var content = project.getHeader(output) + "//  Add text key & content into \(input) and Build project.\n\n"
            content += "import Foundation\n\n"
            if project.swiftlintEnable {
                content += "// swiftlint:disable identifier_name\n"
            }
            return content
        }

        func makeComment(itemKey: String, item: XCStringItem, indent: Int = 2) -> (String, UInt) {
            let indent2 = XCTaskString.shared.indent(indent)
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
                let cnt = countParams(content)
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

    private class StringSubTask: SubTask {

        var isAttStringMakerAvailable = false
        private var attrStringPrefix: String?

        override func getInfo(from info: NSDictionary) {
            super.getInfo(from: info)
            attrStringPrefix = info["attr_prefix"] as? String
        }

        private func makeTextVar(itemKey: String, tableName: String) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            let varName = makeFuncVarName(itemKey)
            if XCTaskString.shared.isNeedValidate {
                XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
            }
            result += indent2 + "static var \(varName): String {\n"
            result += indent3 + "return \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            result += indent2 + "}\n\n"
            return result
        }

        private func makeTextParamsFunc(paramsCount: UInt, itemKey: String, tableName: String) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            var paramsList = makeFuncParamsList(paramsCount)
            let varName = makeFuncVarName(itemKey)
            if XCTaskString.shared.isNeedValidate {
                XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
            }
            result += indent2 + "static func \(varName)(\(paramsList)) -> String {\n"
            result += indent3 + "let pattern = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            paramsList = makePatternParamsList(paramsCount)
            result += indent3 + "return String(format: pattern, \(paramsList))\n"
            result += indent2 + "}\n\n"
            return result
        }

        private func makeAttrStringCodeGen(_ isSwiftLintEnbale: Bool) -> String {
            let indent1 = XCTaskString.shared.indent(1)
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)

            var result = ""
            if isSwiftLintEnbale {
                result = indent1 + "// swiftlint:disable line_length\n"
            }
            result += indent1 + "static func makeAttributeString(htmlString: String) -> NSAttributedString {\n"
            result += indent2 + "if let data = htmlString.data(using: .utf8),\n"
            if env.compareSwfitVersion(version: "4.0") {
                result += indent3 + "let result = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html,\n"
                result += indent3 + "                                                           .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)],\n"
                result += indent3 + "                                     documentAttributes: nil) {\n"
            } else {
                result += indent3 + "let result = try? NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,\n"
                result += indent3 + "                                                           NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue)],\n"
                result += indent3 + "                                     documentAttributes: nil) {\n"
            }
            result += indent3 + "return result\n"
            result += indent2 + "}\n"
            result += indent2 + "return NSAttributedString(string: htmlString)\n"
            result += indent1 + "}\n\n"
            return result
        }

        private func makeAttrTextVar(itemKey: String, tableName: String) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            var varName = String(itemKey[itemKey.index(itemKey.startIndex, offsetBy: attrStringPrefix?.count ?? 0)...])
            varName = makeFuncVarName(varName)
            if XCTaskString.shared.isNeedValidate {
                XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
            }
            result += indent2 + "static var \(varName): NSAttributedString {\n"
            result += indent3 + "let htmlString = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            result += indent3 + "return NSAttributedString.makeAttributeString(htmlString: htmlString)\n"
            result += indent2 + "}\n\n"
            return result
        }

        private func makeAttrTextParamsFunc(paramsCount: UInt, itemKey: String, tableName: String) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            var paramsList = makeFuncParamsList(paramsCount)
            var varName = String(itemKey[itemKey.index(itemKey.startIndex, offsetBy: attrStringPrefix?.count ?? 0)...])
            varName = makeFuncVarName(varName)
            if XCTaskString.shared.isNeedValidate {
                XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
            }
            result += indent2 + "static func \(varName)(\(paramsList)) -> NSAttributedString {\n"
            result += indent3 + "let pattern = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            paramsList = makePatternParamsList(paramsCount)
            result += indent3 + "let htmlString = String(format: pattern, \(paramsList))\n"
            result += indent3 + "return NSAttributedString.makeAttributeString(htmlString: htmlString)\n"
            result += indent2 + "}\n\n"
            return result
        }

        override func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
            var result = super.makeContent(project: project, tables: tables)
            let indent1 = XCTaskString.shared.indent(1)
            let tableName = (input as NSString).deletingPathExtension
            result += "extension String {\n\n"
            var attributedStrings = [(String, String, UInt)]()
            for table in tables where table.name == input {
                result += indent1 + "struct \(project.prefix ?? "")\(makeKeyword(tableName)) {\n\n"
                for item in table.items {
                    guard let itemKey = item.key else { continue }
                    var paramsCount: UInt = 0

                    log("\t" + .found(itemKey))
                    let (comment, cnt) = makeComment(itemKey: itemKey, item: item)
                    paramsCount = cnt

                    if let attrPrefix = attrStringPrefix, itemKey.hasPrefix(attrPrefix) {
                        attributedStrings.append((itemKey, comment, paramsCount))
                    } else {
                        result += comment
                        if paramsCount > 0 {
                            result += makeTextParamsFunc(paramsCount: paramsCount, itemKey: itemKey, tableName: tableName)
                        } else {
                            result += makeTextVar(itemKey: itemKey, tableName: tableName)
                        }
                    }
                }
                result += indent1 + "}\n\n"
            }
            result += "}\n"
            if attributedStrings.count > 0 {
                result += "extension NSAttributedString {\n\n"
                if isAttStringMakerAvailable {
                    result += makeAttrStringCodeGen(project.swiftlintEnable)
                }
                result += indent1 + "struct \(project.prefix ?? "")\(makeKeyword(tableName)) {\n\n"
                for (item, comment, pcount) in attributedStrings {
                    result += comment
                    if pcount > 0 {
                        result += makeAttrTextParamsFunc(paramsCount: pcount, itemKey: item, tableName: tableName)
                    } else {
                        result += makeAttrTextVar(itemKey: item, tableName: tableName)
                    }
                }
                result += indent1 + "}\n\n}\n\n"
            }
            return result
        }

        func checkAttributedStringAvailable(tables: [XCStringTable]) -> Bool {
            guard let attrPrefix = attrStringPrefix else { return false }
            for table in tables where table.name == input {
                for item in table.items {
                    guard let itemKey = item.key else { continue }
                    if itemKey.hasPrefix(attrPrefix) {
                        return true
                    }
                }
            }
            return false
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

        private func makeUrlVar(itemKey: String, tableName: String, domain: String?) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            let indent4 = XCTaskString.shared.indent(4)
            let varName = makeFuncVarName(itemKey)
            if XCTaskString.shared.isNeedValidate {
                XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
            }
            result += indent2 + "static var \(varName): URL {\n"
            if let host = domain {
                result += indent3 + "let urlStr = \"\(host)\" + \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            } else {
                result += indent3 + "let urlStr = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            }
            result += indent3 + "if let url = URL(string: urlStr) {\n"
            result += indent4 + "return url\n"
            result += indent3 + "} else {\n"
            result += indent4 + "fatalError(\"DEVELOP ERROR: Invalid URL '\\(urlStr)'\")\n"
            result += indent3 + "}\n"
            result += indent2 + "}\n\n"
            return result
        }

        private func makeUrlParamsFunc(itemKey: String, tableName: String, paramsCount: UInt, domain: String?) -> String {
            var result = ""
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            let indent4 = XCTaskString.shared.indent(4)
            var paramsList = makeFuncParamsList(paramsCount)
            let varName = makeFuncVarName(itemKey)
            if XCTaskString.shared.isNeedValidate {
                XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
            }
            result += indent2 + "static func \(varName)(\(paramsList)) -> URL {\n"
            if let host = domain {
                result += indent3 + "let pattern = \"\(host)\" + \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            } else {
                result += indent3 + "let pattern = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
            }
            paramsList = makePatternParamsList(paramsCount)
            result += indent3 + "let urlStr = String(format: pattern, \(paramsList))\n"
            result += indent3 + "if let url = URL(string: urlStr) {\n"
            result += indent4 + "return url\n"
            result += indent3 + "} else {\n"
            result += indent4 + "fatalError(\"DEVELOP ERROR: Invalid URL '\\(urlStr)'\")\n"
            result += indent3 + "}\n"
            result += indent2 + "}\n\n"
            return result
        }

        override func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
            var result = super.makeContent(project: project, tables: tables)
            let indent1 = XCTaskString.shared.indent(1)
            let tableName = (input as NSString).deletingPathExtension
            result += "extension URL {\n\n"
            for table in tables where table.name == input {
                result += indent1 + "struct \(project.prefix ?? "")\(makeKeyword(tableName)) {\n\n"
                for item in table.items {
                    guard let itemKey = item.key else { continue }
                    var paramsCount: UInt = 0

                    var domain: String?
                    for (key, value) in bases where itemKey.hasPrefix(key) {
                        domain = value
                        break
                    }

                    log("\t" + .found(itemKey))
                    let (comment, cnt) = makeComment(itemKey: itemKey, item: item)
                    result += comment
                    paramsCount = cnt
                    if paramsCount > 0 {
                        result += makeUrlParamsFunc(itemKey: itemKey, tableName: tableName, paramsCount: paramsCount, domain: domain)
                    } else {
                        result += makeUrlVar(itemKey: itemKey, tableName: tableName, domain: domain)
                    }
                }
                result += indent1 + "}\n\n"
            }
            result += "}\n"
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

        private func makeEnumParams(_ paramsCount: UInt) -> String {
            var result = ""
            for _ in 0..<paramsCount {
                result += "Any, "
            }
            return cropTail(input: result, length: 2)
        }

        private func makeCaseParams(_ paramsCount: UInt) -> String {
            var result = ""
            for index in 1...paramsCount {
                result += "let param\(index), "
            }
            return cropTail(input: result, length: 2)
        }

        override func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
            var result = super.makeContent(project: project, tables: tables)
            let indent1 = XCTaskString.shared.indent(1)
            let indent2 = XCTaskString.shared.indent(2)
            let indent3 = XCTaskString.shared.indent(3)
            let tableName = (input as NSString).deletingPathExtension

            var items = [String: [XCStringItem]]()
            for table in tables where table.name == input {
                for item in table.items {
                    guard let itemKey = item.key else { continue }
                    for (enumName, prefix) in names where itemKey.hasPrefix(prefix) && itemKey.count > prefix.count {
                        var array = items[enumName] ?? []
                        array.append(item)
                        items[enumName] = array
                        break
                    }
                }
            }

            for (enumName, sItems) in items where sItems.count > 0 {
                let prefix = names[enumName] ?? ""
                result += "enum \(project.prefix ?? "")\(enumName) {\n\n"
                var convertFunc = ""
                if project.swiftlintEnable {
                    convertFunc += indent1 + "// swiftlint:disable:next function_body_length\n"
                }
                convertFunc += indent1 + "func toString() -> String {\n"
                convertFunc += indent2 + "switch self {\n"
                var specialCaseCount = 0
                for item in sItems {
                    guard let itemKey = item.key else { continue }
                    let croppedKey = cropHead(input: itemKey, length: prefix.count)
                    let caseName = makeFuncVarName(croppedKey)
                    if XCTaskString.shared.isNeedValidate {
                        XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: caseName)
                    }
                    var paramsCount: UInt = 0
                    log("\t" + .found(itemKey))
                    let (comment, cnt) = makeComment(itemKey: itemKey, item: item, indent: 1)
                    result += comment
                    paramsCount = cnt

                    if paramsCount > 0 {
                        let paramsList = makeEnumParams(paramsCount)
                        result += indent1 + "case \(caseName)(\(paramsList))\n"
                        specialCaseCount += 1
                        convertFunc += indent2 + "case .\(caseName)(\(makeCaseParams(paramsCount))):\n"
                        convertFunc += indent3 + "let pattern = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
                        convertFunc += indent3 + "return String(format: pattern, \(makePatternParamsList(paramsCount)))\n"
                    } else {
                        result += indent1 + "case \(caseName)\n"
                        if croppedKey != caseName {
                            specialCaseCount += 1
                            convertFunc += indent2 + "case .\(caseName):\n"
                            convertFunc += indent3 + "return \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
                        }
                    }
                    result += "\n"
                }
                if specialCaseCount < sItems.count {
                    convertFunc += indent2 + "default:\n"
                    convertFunc += indent3 + "return \(localizeFunc)(\"\(prefix)\\(self)\", tableName: \"\(tableName)\", comment: \"\")\n"
                }
                convertFunc += indent2 + "}\n"
                convertFunc += indent1 + "}\n\n"
                result += convertFunc
                result += "}\n\n"
            }

            return cropTail(input: result, length: 1)
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
        guard let typ = info["output_type"] as? String, let ttyp = SubTask.OutputType(rawValue: typ) else { return }
        if ttyp == .validation {
            isNeedValidate = true
            return
        }
        if let inp = info["input"] as? String, let outp = info["output"] as? String {
            var subTask: SubTask?
            switch ttyp {
            case .string:
                subTask = StringSubTask(inp: inp, outp: outp, oType: ttyp)
            case .url:
                subTask = UrlSubTask(inp: inp, outp: outp, oType: ttyp)
            case .enumeration:
                subTask = EnumSubTask(inp: inp, outp: outp, oType: ttyp)
            default:
                break;
            }
            if let sTask = subTask {
                if let funcName = info["func"] as? String {
                    sTask.localizeFunc = funcName
                }
                sTask.getInfo(from: info)
                subTasks.append(sTask)
            }
        }
    }

    private func buildValuesMapAndCheckKeys(table: XCStringTable, valuesMap: inout [String: [XCStringItem]]) {
        for item in table.items {
            var paramsCount = [UInt]()
            for (language, values) in item.values {
                for val in values {
                    if values.count > 1 {
                        printLog(.duplicatedStringKey(file: item.filePath ?? "", line: val.line, key: item.key ?? ""))
                    }
                    let key = "\(language)::\(val.content)"
                    var array = valuesMap[key] ?? []
                    array.append(item)
                    valuesMap[key] = array
                }
                let pCount = XCTaskString.countParams(values.last?.content ?? "")
                paramsCount.append(pCount)
            }
            var last: UInt?
            var isEquivalent = true
            for cnt in paramsCount {
                if let lst = last {
                    if lst != cnt {
                        isEquivalent = false
                        break
                    }
                } else {
                    last = cnt
                }
            }
            if !isEquivalent {
                for (language, values) in item.values {
                    if let val = values.last {
                        printLog(.stringParamsCountNotEquivalent(file: item.filePath ?? "", line: val.line,
                                                                 key: item.key ?? "", language: language,
                                                                 count: XCTaskString.countParams(val.content),
                                                                 value: val.content))
                    }
                }
            }
        }
    }

    private func checkValues(valuesMap: [String: [XCStringItem]]) {
        for (key, array) in valuesMap where array.count > 1 {
            let tmp = key.components(separatedBy: "::")
            let language = tmp.first ?? ""
            let value = tmp.last ?? ""
            for item in array {
                if let itemValues = item.values[language] {
                    for val in itemValues where val.content == value {
                        printLog(.duplicatedStringValue(file: item.filePath ?? "", line: val.line,
                                                        key: item.key ?? "", value: value))
                    }
                }
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

        for sTask in subTasks {
            if let txtTask = sTask as? StringSubTask, txtTask.checkAttributedStringAvailable(tables: strings) {
                txtTask.isAttStringMakerAvailable = true
                break
            }
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
            var values = [String: [XCStringItem]]()
            for table in strings {
                buildValuesMapAndCheckKeys(table: table, valuesMap: &values)
            }
            checkValues(valuesMap: values)
        }

        return taskErrors.first
    }

}
