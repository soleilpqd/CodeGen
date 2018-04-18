//
//  XCStrings.swift
//  CodeGen
//
//  Created by DươngPQ on 13/04/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCStringValue {

    var line: UInt = 0
    var content = ""

}

class XCStringItem: NSObject {

    static let kLanguageNone = ""
    static let kLanguageBase = "Base"

    var key: String?
    var values = [String: [XCStringValue]]()
    var filePath: String?
    weak var table: XCStringTable?

    override var description: String {
        return "XCStringItem: \(key ?? "")"
    }

}

class XCStringTable {

    var name = ""
    var items = [XCStringItem]()

}
