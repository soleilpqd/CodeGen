//
//  XCBuildPhase.swift
//  XCodeProj
//
//  Created by DươngPQ on 21/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCBuildPhase: XCObject {

    var buildActionMask: String?
    var files: [XCItem]?
    var runOnlyForDeploymentPostprocessing: Int?
    weak var target: XCProjTarget?

    enum PhaseType: String {
        case compileSources = "PBXSourcesBuildPhase"
        case linkFrameworks = "PBXFrameworksBuildPhase"
        case copyResources = "PBXResourcesBuildPhase"
        case runScript = "PBXShellScriptBuildPhase"
    }

    var type: PhaseType? {
        if let t = isa {
            return PhaseType(rawValue: t)
        }
        return nil
    }

    init?(dic: [String : Any], allObjects: [String : Any], parent: XCProjTarget) {
        super.init(dic: dic, allObjects: allObjects)
        if let type = isa, type.hasPrefix("PBX") && type.hasSuffix("BuildPhase") {
            target = parent
            buildActionMask = getString(dic: dic, key: "buildActionMask")
            if let ids = dic["files"] as? [String] {
                var result = [XCItem]()
                for id in ids {
                    if let buildFileDic = getDic(dic: allObjects, key: id),
                        let type = getString(dic: buildFileDic, key: "isa"), type == XCISA.buildFile.rawValue,
                        let fileRef = getString(dic: buildFileDic, key: "fileRef") {
                        if let mainGroup = parent.project?.mainGroup, let item = findItem(group: mainGroup, key: fileRef) {
                            result.append(item)
                        } else if let itemDic = getDic(dic: allObjects, key: fileRef),
                            let item = XCItem.item(from: itemDic, allObjects: allObjects) {
                            result.append(item)
                        }
                    }
                }
                files = result
            }
            runOnlyForDeploymentPostprocessing = getInt(dic: dic, key: "runOnlyForDeploymentPostprocessing")
        } else {
            return nil
        }
    }

}

class XCShellScriptBuildPhase: XCBuildPhase {

    var shellPath: String?
    var shellScript: String?
    var name: String?
    var inputPaths: [String]?
    var outputPaths: [String]?

    override init?(dic: [String : Any], allObjects: [String : Any], parent: XCProjTarget) {
        super.init(dic: dic, allObjects: allObjects, parent: parent)
        shellPath = getString(dic: dic, key: "shellPath")
        shellScript = getString(dic: dic, key: "shellScript")
        name = getString(dic: dic, key: "name")
        inputPaths = dic["inputPaths"] as? [String]
        outputPaths = dic["outputPaths"] as? [String]
    }

}
