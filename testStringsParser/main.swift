//
//  main.swift
//  testStringsParser
//
//  Created by DươngPQ on 13/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
let path = CommandLine.arguments[1]

do {
    let result = try parseStringsFile(file: path, language: XCStringItem.kLanguageNone)
    print(result)
} catch (let e) {
    print(e)
}
