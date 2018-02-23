//
//  XCObject.swift
//  XCodeProj
//
//  Created by DươngPQ on 21/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

func getDic(dic: [String: Any], key: String) -> [String: Any]? {
    return dic[key] as? [String: Any]
}

func getString(dic: [String: Any], key: String) -> String? {
    return dic[key] as? String
}

func getInt(dic: [String: Any], key: String) -> Int? {
    let value = dic[key]
    if let num = value as? NSNumber {
        return num.intValue
    } else if let str = value as? String {
        return Int(str)
    }
    return nil
}

enum XCISA: String {

    case project                = "PBXProject"
    case configList             = "XCConfigurationList"
    case configuration          = "XCBuildConfiguration"
    case target                 = "PBXNativeTarget"
    case fileRef                = "PBXFileReference"
    case sourceBuildPhase       = "PBXSourcesBuildPhase"
    case resourceBuildPhase     = "PBXResourcesBuildPhase"
    case frameworkBuildPhase    = "PBXFrameworksBuildPhase"
    case shellScriptBuildPhase  = "PBXShellScriptBuildPhase"
    case group                  = "PBXGroup"
    case buildFile              = "PBXBuildFile"

}

class XCObject {

    var isa: String?

    var isaEnum: XCISA? {
        get {
            if let str = isa {
                return XCISA(rawValue: str)
            }
            return nil
        }
        set (value) {
            if let val = value {
                isa = val.rawValue
            } else {
                isa = nil
            }
        }
    }

    init?(dic: [String: Any], allObjects: [String: Any]) {
        guard let isaRaw = dic["isa"] as? String else { return nil }
        isa = isaRaw
    }

}
