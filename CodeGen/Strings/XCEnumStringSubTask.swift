//
//  XCEnumStringSubTask.swift
//  CodeGen
//
//  Created by DươngPQ on 4/29/20.
//  Copyright © 2020 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

final class XCEnumStringSubTask: XCTaskStringSubTask {

    override func makeContent(project: XCProject, tables: [XCStringTable]) -> String {
        var result = super.makeContent(project: project, tables: tables)
        let indent1 = XCTaskString.shared.indent(1)
        let indent2 = XCTaskString.shared.indent(2)
        let tableName = (input as NSString).deletingPathExtension

        result += "enum \(project.prefix ?? "")\(tableName): String {\n\n"

        for table in tables where table.name == input {
            for item in table.items {
                guard let itemKey = item.key else { continue }
                let caseName = makeFuncVarName(itemKey)
                if XCTaskString.shared.isNeedValidate {
                    XCValidator.shared.addKeywordForCheckUsage(category: usageCategory, keyword: caseName)
                }
                log("\t" + .found(itemKey))
                let (comment, _) = makeComment(itemKey: itemKey, item: item, indent: 1)
                result += comment
                result += indent1 + "case " + caseName
                if caseName != itemKey {
                    result += " = \"" + itemKey + "\""
                }
                result += "\n"
            }
        }

        result += "\n"
        result += indent1 + "func toString() -> String {\n"
        result += indent2 + "return \(localizeFunc)(self.rawValue, tableName: \"\(tableName)\", comment: \"\")\n"
        result += indent1 + "}\n"
        result += "\n}\n"

        return result
    }

}
