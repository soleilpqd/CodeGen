//
//  XCEnvironment.swift
//  CodeGen
//
//  Created by DươngPQ on 22/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

struct XCEnvironment {

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
    }

}
