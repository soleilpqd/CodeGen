//
//  XCStringSubTask.swift
//  CodeGen
//
//  Created by DươngPQ on 4/29/20.
//  Copyright © 2020 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

final class XCStringSubTask: XCTaskStringSubTask {

    var isAttStringMakerAvailable = false
    private var attrStringPrefix: String?

    override func getInfo(from info: NSDictionary) {
        super.getInfo(from: info)
        attrStringPrefix = info["attr_prefix"] as? String
    }

    private func makeTextVar(itemKey: String, tableName: String) -> String {
        var result = ""
        let indent2 = XCTaskString.shared.indent(2)
        let indent1 = XCTaskString.shared.indent(1)
        let varName = makeFuncVarName(itemKey)
        if XCTaskString.shared.isNeedValidate {
            XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
        }
        result += indent1 + "static var \(varName): String {\n"
        result += indent2 + "return \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
        result += indent1 + "}\n\n"
        return result
    }

    private func makeTextParamsFunc(paramsCount: UInt, itemKey: String, tableName: String) -> String {
        var result = ""
        let indent1 = XCTaskString.shared.indent(1)
        let indent2 = XCTaskString.shared.indent(2)
        var paramsList = makeFuncParamsList(paramsCount)
        let varName = makeFuncVarName(itemKey)
        if XCTaskString.shared.isNeedValidate {
            XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
        }
        result += indent1 + "static func \(varName)(\(paramsList)) -> String {\n"
        result += indent2 + "let pattern = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
        paramsList = makePatternParamsList(paramsCount)
        result += indent2 + "return String(format: pattern, \(paramsList))\n"
        result += indent1 + "}\n\n"
        return result
    }

    private func makeAttrStringCodeGen(_ prefix: String) -> String {
        let indent1 = XCTaskString.shared.indent(1)
        let indent2 = XCTaskString.shared.indent(2)

        var result = ""
        result += "func \(prefix)MakeAttributeString(htmlString: String) -> NSAttributedString {\n"
        result += indent1 + "if let data = htmlString.data(using: .utf8),\n"
        if env.compareSwfitVersion(version: "4.0") {
            result += indent2 + "let result = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html,\n"
            result += indent2 + "                                                           .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)],\n"
            result += indent2 + "                                     documentAttributes: nil) {\n"
        } else {
            result += indent2 + "let result = try? NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,\n"
            result += indent2 + "                                                           NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue)],\n"
            result += indent2 + "                                     documentAttributes: nil) {\n"
        }
        result += indent2 + "return result\n"
        result += indent1 + "}\n"
        result += indent1 + "return NSAttributedString(string: htmlString)\n"
        result += "}\n\n"
        return result
    }

    private func makeAttrTextVar(itemKey: String, tableName: String, prefix: String) -> String {
        var result = ""
        let indent1 = XCTaskString.shared.indent(1)
        let indent2 = XCTaskString.shared.indent(2)
        var varName = String(itemKey[itemKey.index(itemKey.startIndex, offsetBy: attrStringPrefix?.count ?? 0)...])
        varName = makeFuncVarName(varName)
        if XCTaskString.shared.isNeedValidate {
            XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
        }
        result += indent1 + "static var \(varName): NSAttributedString {\n"
        result += indent2 + "let htmlString = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
        result += indent2 + "return \(prefix)MakeAttributeString(htmlString: htmlString)\n"
        result += indent1 + "}\n\n"
        return result
    }

    private func makeAttrTextParamsFunc(paramsCount: UInt, itemKey: String, tableName: String, prefix: String) -> String {
        var result = ""
        let indent1 = XCTaskString.shared.indent(1)
        let indent2 = XCTaskString.shared.indent(2)
        var paramsList = makeFuncParamsList(paramsCount)
        var varName = String(itemKey[itemKey.index(itemKey.startIndex, offsetBy: attrStringPrefix?.count ?? 0)...])
        varName = makeFuncVarName(varName)
        if XCTaskString.shared.isNeedValidate {
            XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: varName)
        }
        result += indent1 + "static func \(varName)(\(paramsList)) -> NSAttributedString {\n"
        result += indent2 + "let pattern = \(localizeFunc)(\"\(itemKey)\", tableName: \"\(tableName)\", comment: \"\")\n"
        paramsList = makePatternParamsList(paramsCount)
        result += indent2 + "let htmlString = String(format: pattern, \(paramsList))\n"
        result += indent2 + "return \(prefix)MakeAttributeString(htmlString: htmlString)\n"
        result += indent1 + "}\n\n"
        return result
    }

    override func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
        var result = super.makeContent(project: project, tables: tables)
        let tableName = (input as NSString).deletingPathExtension
        var attributedStrings = [(String, String, UInt)]()
        for table in tables where table.name == input {
            result += "struct \(project.prefix ?? "")\(makeKeyword(tableName)) {\n\n"
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
            result += "}\n\n"
        }
        if attributedStrings.count > 0 {
            if isAttStringMakerAvailable {
                result += makeAttrStringCodeGen(project.prefix ?? "")
            }
            result += "struct \(project.prefix ?? "")\(makeKeyword("Attributed" + tableName)) {\n\n"
            for (item, comment, pcount) in attributedStrings {
                result += comment
                if pcount > 0 {
                    result += makeAttrTextParamsFunc(paramsCount: pcount, itemKey: item, tableName: tableName, prefix: project.prefix ?? "")
                } else {
                    result += makeAttrTextVar(itemKey: item, tableName: tableName, prefix: project.prefix ?? "")
                }
            }
            result += "}\n\n"
        }
        return result.trimmingCharacters(in: .newlines) + "\n"
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
