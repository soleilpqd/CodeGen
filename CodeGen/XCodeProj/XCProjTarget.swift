//
//  XCProjTarget.swift
//  XCodeProj
//
//  Created by DươngPQ on 21/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCProjTarget: XCObject {

    var name: String?
    var productName: String?
    var productReference: XCFileReference?
    var productType: String?
    var buildConfigurationList: XCConfigurationList?
    var buildPhases: [XCBuildPhase]?
    var buildRules: [String]? // TODO: class
    var dependencies: [String]? // TODO: class

    var createdOnToolsVersion: String?
    var lastSwiftMigration: String?
    var provisioningStyle: String?
    var systemCapabilities: [String: Any]?

    weak var project: XCProjFile?

    init?(dic: [String : Any], allObjects: [String : Any], parent: XCProjFile) {
        super.init(dic: dic, allObjects: allObjects)
        if isaEnum != .target { return nil }
        project = parent
        name = getString(dic: dic, key: "name")
        productName = getString(dic: dic, key: "productName")
        if let id = getString(dic: dic, key: "productReference") {
            if let mainGround = parent.mainGroup, let item = findItem(group: mainGround, key: id) as? XCFileReference {
                productReference = item
            } else if let pdRefDic = getDic(dic: allObjects, key: id) {
                productReference = XCFileReference(dic: pdRefDic, allObjects: allObjects)
            }
        }
        productType = getString(dic: dic, key: "productType")
        if let id = getString(dic: dic, key: "buildConfigurationList"), let cfgDic = getDic(dic: allObjects, key: id) {
            buildConfigurationList = XCConfigurationList(dic: cfgDic, allObjects: allObjects)
        }
        if let phaseIds = dic["buildPhases"] as? [String], phaseIds.count > 0 {
            var result = [XCBuildPhase]()
            for id in phaseIds {
                if let phaseDic = allObjects[id] as? [String: Any], let type = phaseDic["isa"] as? String,
                    let typeEnum = XCISA(rawValue: type) {
                    switch typeEnum {
                    case .sourceBuildPhase, .resourceBuildPhase, .frameworkBuildPhase:
                        if let phase = XCBuildPhase(dic: phaseDic, allObjects: allObjects, parent: self) {
                            result.append(phase)
                        }
                    case .shellScriptBuildPhase:
                        if let phase = XCShellScriptBuildPhase(dic: phaseDic, allObjects: allObjects, parent: self) {
                            result.append(phase)
                        }
                    default:
                        break
                    }
                }
            }
            buildPhases = result
        }
        buildRules = dic["buildRules"] as? [String]
        dependencies = dic["dependencies"] as? [String]
    }

    func appendAttributes(_ dic: [String: Any]) {
        createdOnToolsVersion = getString(dic: dic, key: "CreatedOnToolsVersion")
        lastSwiftMigration = getString(dic: dic, key: "LastSwiftMigration")
        provisioningStyle = getString(dic: dic, key: "ProvisioningStyle")
        systemCapabilities = getDic(dic: dic, key: "SystemCapabilities")
    }

}
