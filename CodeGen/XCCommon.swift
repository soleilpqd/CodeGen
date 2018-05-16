//
//  XCCommon.swift
//  ColorXCode
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

private var indents = [Int: String]()

private func makeIndentation(level: Int, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
    if level <= 0 { return "" }
    var result = ""
    for _ in 0..<level {
        for _ in 0..<indentWidth {
            result += " "
        }
    }
    if useTab && tabWidth > 0 {
        var tabSpaces = ""
        for _ in 0..<tabWidth {
            tabSpaces += " "
        }
        while result.contains(tabSpaces) {
            result = result.replacingOccurrences(of: tabSpaces, with: "\t")
        }
    }
    return result
}

func getIndent(level: Int, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
    if let result = indents[level] {
        return result
    }
    let result = makeIndentation(level: level, tabWidth: tabWidth, indentWidth: indentWidth, useTab: useTab)
    indents[level] = result
    return result
}

func makeKeyword(_ input: String) -> String {
    var result = input
    let specialChars = "'\"`~!@#$%^&*()_+-=[]\\{}|;:,./<>?\t\n"
    for c in specialChars {
        result = result.replacingOccurrences(of: String(c), with: " ")
    }
    if result.contains(" ") {
        result = result.capitalized
    }
    if result.count < 3 {
        let lastChar = String(result[result.index(before: result.endIndex)...])
        while result.count < 3 {
            result += lastChar
        }
    }
    return result.replacingOccurrences(of: " ", with: "")
}

func makeFuncVarName(_ input: String) -> String {
    let result = makeKeyword(input)
    if result.count > 1 {
        return String(result[result.startIndex]).lowercased() + String(result[result.index(after: result.startIndex)...])
    }
    return result
}

func escapeStringForComment(_ input: String) -> String {
    let escapeChars = ["&", "<", ">"]
    var result = input
    for char in escapeChars {
        result = result.replacingOccurrences(of: char, with: "\\" + char)
    }
    return result
}

func cropTail(input: String, length: Int) -> String {
    if input.count < length { return "" }
    return String(input[..<input.index(input.endIndex, offsetBy: -length)])
}

func cropHead(input: String, length: Int) -> String {
    if input.count < length { return "" }
    return String(input[input.index(input.startIndex, offsetBy: length)...])
}
