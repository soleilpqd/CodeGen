//
//  XCStringsParser.swift
//  CodeGen
//
//  Created by DươngPQ on 13/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

enum XCStringsParserError: Error {
    case notLoad
    case failed(row: UInt, column: UInt)
}

/// return: [key: [(value: line)]] (key may be duplicated so it has more than 1 value)
func parseStringsFile(file: String, language: String) throws -> [XCStringItem] {
    guard let content = try? String(contentsOfFile: file) else {
        throw XCStringsParserError.notLoad
    }
    enum XCStringsContext {
        case none
        case commentLine
        case commentBlock
        case key
        case keyEnd
        case valueBegin
        case value
        case valuEnd
    }

    var context: XCStringsContext = .none
    var line: UInt = 1
    var col: UInt = 1
    var result = [XCStringItem]()
    var preChar: Character?
    var curKey: String?
    var curValue: String?
    for char in content {
        col += 1
        if char == "\n" {
            line += 1
            col = 1
        }
        switch context {
        case .none:
            switch char {
            case "/":
                if let preC = preChar, preC == "/" {
                    context = .commentLine
                }
            case "*":
                if let preC = preChar, preC == "/" {
                    context = .commentBlock
                }
            case "\"":
                context = .key
                curKey = ""
            default:
                break
            }
        case .commentBlock:
            if char == "/" && preChar == "*" {
                context = .none
            }
        case .commentLine:
            if char == "\n" {
                context = .none
            }
        case .key:
            if char == "\"" {
                context = .keyEnd
            } else {
                curKey = (curKey ?? "") + String(char)
            }
        case .keyEnd:
            switch char {
            case "=":
                context = .valueBegin
            case " ", "\t":
                break
            default:
                throw XCStringsParserError.failed(row: line, column: col)
            }
        case .valueBegin:
            switch char {
            case "\"":
                context = .value
                curValue = ""
            case " ", "\t":
                break
            default:
                throw XCStringsParserError.failed(row: line, column: col)
            }
        case .value:
            if let preC = preChar, char == "\"" && preC != "\\" {
                context = .valuEnd
            } else {
                curValue = (curValue ?? "") + String(char)
            }
        case .valuEnd:
            switch char {
            case ";":
                context = .none
                if let key = curKey?.replacingOccurrences(of: "\n", with: "\\n"), let val = curValue?.replacingOccurrences(of: "\n", with: "\\n") {
                    var resItem: XCStringItem!
                    for item in result where item.key == key {
                        resItem = item
                        break
                    }
                    if resItem == nil {
                        resItem = XCStringItem()
                        resItem.key = key
                        result.append(resItem)
                    }
                    var resLines = resItem.values[language] ?? []
                    let resLine = XCStringValue()
                    resLine.content = val
                    resLine.line = line
                    resLines.append(resLine)
                    resItem.values[language] = resLines
                } else {
                    throw XCStringsParserError.failed(row: line, column: col)
                }
            case " ", "\t":
                break
            default:
                throw XCStringsParserError.failed(row: line, column: col)
            }
        }
        preChar = char
    }
    return result
}
