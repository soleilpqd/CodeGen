//
//  XCUrlSubTask.swift
//  CodeGen
//
//  Created by DươngPQ on 4/29/20.
//  Copyright © 2020 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

final class XCUrlSubTask: XCTaskStringSubTask {

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
