//
//  XCProjFile.swift
//  XCodeProj
//
//  Created by DươngPQ on 21/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCProjFile: XCObject {

    var archiveVersion: Int?
    var classes: [String: Any]?
    var objectVersion: Int?

    var buildConfigurationList: XCConfigurationList?
    var compatibilityVersion: String?
    /// Development localization ID
    var developmentRegion: String?
    var hasScannedForEncodings: Int?
    /// Localization IDs
    var knownRegions: [String]?
    /// Source tree: main group
    var mainGroup: XCGroup?
    /// Source tree: Product group
    var productRefGroup: XCGroup?
    var projectDirPath: String?
    var projectRoot: String?
    var targets: [XCProjTarget]?

    var classPrefix: String?
    var lastSwiftUpdateCheck: String?
    var lastUpgradeCheck: String?
    var organizationName: String?

    var tabWidth: Int?
    var indentWidth: Int?
    var wrapsLines: Int?

    class func project(from path: String) -> XCProjFile? {
        if let dic = NSDictionary(contentsOfFile: path) as? [String: Any],
            let rootObjId = getString(dic: dic, key: "rootObject"),
            let allObjests = getDic(dic: dic, key: "objects"),
            let rootObj = getDic(dic: allObjests, key: rootObjId),
            let result = XCProjFile(dic: rootObj, allObjects: allObjests) {
//            print(dic.description)
            result.archiveVersion = getInt(dic: dic, key: "archiveVersion")
            result.classes = getDic(dic: dic, key: "classes")
            result.objectVersion = getInt(dic: dic, key: "objectVersion")
            result.compatibilityVersion = getString(dic: rootObj, key: "compatibilityVersion")
            result.developmentRegion = getString(dic: rootObj, key: "developmentRegion")
            result.hasScannedForEncodings = getInt(dic: rootObj, key: "hasScannedForEncodings")
            return result
        }
        return nil
    }

    override init?(dic: [String : Any], allObjects: [String : Any]) {
        super.init(dic: dic, allObjects: allObjects)
        if isaEnum != .project { return nil }
        knownRegions = dic["knownRegions"] as? [String]
        if let id = getString(dic: dic, key: "mainGroup"), let mainGroupDic = getDic(dic: allObjects, key: id),
            let item = XCGroup(dic: mainGroupDic, allObjects: allObjects) {
            item.id = id
            mainGroup = item
            tabWidth = getInt(dic: mainGroupDic, key: "tabWidth")
            indentWidth = getInt(dic: mainGroupDic, key: "indentWidth")
            wrapsLines = getInt(dic: mainGroupDic, key: "wrapsLines")
        }
        if let id = getString(dic: dic, key: "productRefGroup") {
            if let mainGrp = mainGroup, let item = findItem(group: mainGrp, key: id) as? XCGroup {
                productRefGroup = item
            } else if let productDic = getDic(dic: allObjects, key: id),
                let item = XCGroup(dic: productDic, allObjects: allObjects) {
                productRefGroup = item
            }
        }
        projectDirPath = getString(dic: dic, key: "projectDirPath")
        projectRoot = getString(dic: dic, key: "projectRoot")
        if let cfgListId = getString(dic: dic, key: "buildConfigurationList"), let cfgList = getDic(dic: allObjects, key: cfgListId) {
            buildConfigurationList = XCConfigurationList(dic: cfgList, allObjects: allObjects)
        }
        var targetsMap = [String: XCProjTarget]()
        if let ids = dic["targets"] as? [String], ids.count > 0 {
            var allTargets = [XCProjTarget]()
            for id in ids {
                if let targetDic = getDic(dic: allObjects, key: id), let target = XCProjTarget(dic: targetDic, allObjects: allObjects, parent: self) {
                    allTargets.append(target)
                    targetsMap[id] = target
                }
            }
            targets = allTargets
        }
        if let attributes = getDic(dic: dic, key: "attributes") {
            classPrefix = getString(dic: attributes, key: "CLASSPREFIX")
            lastSwiftUpdateCheck = getString(dic: attributes, key: "LastSwiftUpdateCheck")
            lastUpgradeCheck = getString(dic: attributes, key: "LastUpgradeCheck")
            organizationName = getString(dic: attributes, key: "ORGANIZATIONNAME")
            if let targetAttributes = getDic(dic: attributes, key: "TargetAttributes") {
                for (key, value) in targetAttributes {
                    if let target = targetsMap[key], let attributes = value as? [String: Any] {
                        target.appendAttributes(attributes)
                    }
                }
            }
        }
    }

}
