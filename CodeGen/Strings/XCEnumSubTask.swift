//
//  XCEnumSubTask.swift
//  CodeGen
//
//  Created by DươngPQ on 4/29/20.
//  Copyright © 2020 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

final class XCEnumSubTask: XCTaskStringSubTask {

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

        let orderedEnumnames = items.keys.sorted()
        for enumName in orderedEnumnames {
            let sItems = items[enumName] ?? []
            if sItems.count == 0 { continue }
            let prefix = names[enumName] ?? ""
            result += "enum \(project.prefix ?? "")\(enumName) {\n\n"
            var convertFunc = ""
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
