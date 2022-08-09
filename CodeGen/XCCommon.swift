//
//  XCCommon.swift
//  ColorXCode
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

private var indents = [Int: String]()

struct XCIndentConfig {
    let tabWidth: Int
    let indentWidth: Int
    let useTab: Bool

    static var `default`: XCIndentConfig {
        return XCIndentConfig(tabWidth: 4, indentWidth: 4, useTab: false)
    }
}

private func makeIndentation(level: Int, config: XCIndentConfig) -> String {
    if level <= 0 { return "" }
    var result = ""
    for _ in 0..<level {
        for _ in 0..<config.indentWidth {
            result += " "
        }
    }
    if config.useTab && config.tabWidth > 0 {
        var tabSpaces = ""
        for _ in 0..<config.tabWidth {
            tabSpaces += " "
        }
        while result.contains(tabSpaces) {
            result = result.replacingOccurrences(of: tabSpaces, with: "\t")
        }
    }
    return result
}

/**
 Get indent spaces

 - Parameter level: number of indent level
 - Parameter tabWidth: size of Tab (how many Space equivalent 1 Tab) (get in XCProject)
 - Parameter indentWidth: size of indent (how many Space for 1 indent) (get in XCProject)
 - Parameter useTab: use Tab of Space only (get in XCProject)

 - Returns: Indent text to use as prefix of line
 */
func getIndent(level: Int, config: XCIndentConfig) -> String {
    if let result = indents[level] {
        return result
    }
    let result = makeIndentation(level: level, config: config)
    indents[level] = result
    return result
}

/// Validate `input` to use as code keyword (remove special characters, check length)
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

/// Make keyword for `func`/`var`
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
