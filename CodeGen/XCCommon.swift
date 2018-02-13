//
//  XCCommon.swift
//  ColorXCode
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

func makeIndentation(level: Int, tabWidth: Int, indentWidth: Int, useTab: Bool) -> String {
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
