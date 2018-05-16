//
//  XCEnvironment.swift
//  CodeGen
//
//  Created by DươngPQ on 22/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

struct XCEnvironment {

    enum CompareType {
        case same, newer, sameOrNewer, older, sameOrOlder
    }

    let deployVersion: String?
    let targetName: String?
    let infoPlistPath: String?
    let projectName: String?
    /// Source root: where it stores the `.xcodeproj` file
    let projectRootPath: String?
    /// `.xcodeproj` file path
    let projectFile: String?
    let swiftVersion: String?
    let bundleId: String?
    let productName: String?
    let moduleName: String?
    let sdkVersion: String?

    let infoDict: NSDictionary?

    init() {
        let env = ProcessInfo.processInfo.environment
        deployVersion = env["IPHONEOS_DEPLOYMENT_TARGET"]
        targetName = env["TARGET_NAME"] ?? env["TARGETNAME"]
        infoPlistPath = env["PRODUCT_SETTINGS_PATH"]
        projectName = env["PROJECT_NAME"] ?? env["PROJECT"]
        projectRootPath = env["SOURCE_ROOT"] ?? env["SRCROOT"] ?? env["PROJECT_DIR"]
        projectFile = env["PROJECT_FILE_PATH"]
        swiftVersion = env["SWIFT_VERSION"]
        bundleId = env["PRODUCT_BUNDLE_IDENTIFIER"]
        productName = env["PRODUCT_NAME"]
        moduleName = env["PRODUCT_MODULE_NAME"]
        sdkVersion = env["SDK_VERSION"]
        if let path = infoPlistPath {
            infoDict = NSDictionary(contentsOfFile: path)
        } else {
            infoDict = nil
        }
    }

    static func compareTwoVersions(version: String?, target: String, type: CompareType = .sameOrNewer) -> Bool {
        guard let ver = version else { return false }
        let resut = ver.compare(target, options: .numeric)
        switch type {
        case .same:
            return resut == .orderedSame
        case .newer:
            return resut == .orderedDescending
        case .older:
            return resut == .orderedAscending
        case .sameOrNewer:
            return resut != .orderedAscending
        case .sameOrOlder:
            return resut != .orderedDescending
        }
    }

    func compareDeployVersion(version: String, type: CompareType = .sameOrNewer) -> Bool {
        return XCEnvironment.compareTwoVersions(version: deployVersion, target: version, type: type)
    }

    func compareSDKVerison(version: String, type: CompareType = .sameOrNewer) -> Bool {
        return XCEnvironment.compareTwoVersions(version: sdkVersion, target: version, type: type)
    }

    func compareSwfitVersion(version: String, type: CompareType = .sameOrNewer) -> Bool {
        return XCEnvironment.compareTwoVersions(version: swiftVersion, target: version, type: type)
    }

}
