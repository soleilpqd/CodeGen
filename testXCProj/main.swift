//
//  main.swift
//  testXCProj
//
//  Created by Phạm Quang Dương on 25/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import AppKit

var allFileType = [String]()
let env = XCEnvironment()

private func printPrefix(_ level: UInt) -> String {
    var prefix = ""
    for _ in 0..<level {
        prefix += "\t"
    }
    return prefix
}

private func printItem(item: XCItem, level: UInt) {
    let prefix = printPrefix(level)
    if let group = item as? XCGroup {
        print("\(prefix)[\(group.path ?? "<no path>")]")
        if let childs = group.children, childs.count > 0 {
            for child in childs {
                printItem(item: child, level: level + 1)
            }
        }
    } else if let file = item as? XCFileReference {
        let fType = file.lastKnownFileType ?? ""
        print("\(prefix)\(file.path ?? "<no path>") (\(fType))")
        if !allFileType.contains(fType) {
            allFileType.append(fType)
        }
    } else {
        print("\(prefix)\(item.path ?? "<no path>")")
    }
}

private func testProjectFile() {
    if let project = XCProjFile.project(from: "/Users/soleilpqd/Documents/Sample/MyProject.xcodeproj/project.pbxproj") {
        if let main = project.mainGroup {
            printItem(item: main, level: 0)
            print("KNOWN FILE TYPE", allFileType)
        }
        if let targets = project.targets {
            print("TARGETS:")
            for target in targets {
                print(target.name ?? "<no name>")
                if let phases = target.buildPhases {
                    for phase in phases {
                        if let type = phase.type {
                            switch type {
                            case .runScript:
                                if let scriptPhase = phase as? XCShellScriptBuildPhase {
                                    print("\t\(type):", scriptPhase.shellPath ?? "")
                                    print("<<")
                                    print(scriptPhase.shellScript ?? "")
                                    print(">>")
                                }
                            default:
                                print("\t\(type):")
                                if let files = phase.files {
                                    for f in files {
                                        if let fRef = f as? XCFileReference {
                                            print("\t\t\(fRef.path ?? "") (\(fRef.lastKnownFileType ?? "")) \(fRef.getFullPath() ?? "")")
                                        }
                                    }
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }
}

private func printAsset(asset: XCAsset, level: UInt) {
    let prefix = printPrefix(level)
    if let color = asset as? XCAssetColor {
        print("\(prefix)\(color.name) - \(type(of: asset)) - \(color.colors?.first?.humanReadable ?? "<no name>")")
    } else {
        print("\(prefix)\(asset.name) - \(type(of: asset))")
    }
    if let folder = asset as? XCAssetFoler, let children = folder.children {
        for child in children {
            printAsset(asset: child, level: level + 1)
        }
    }
}

private func testAssets() {
    let assets = XCAssets(path: "/Users/soleilpqd/Documents/Sample/MyProject/Colors.xcassets")
    printAsset(asset: assets, level: 0)
}

private func testFindColors() {
    if let project = XCProject(rootPath: "/Users/soleilpqd/Documents/Sample",
                               filePath: "/Users/soleilpqd/Documents/Sample/MyProject.xcodeproj/project.pbxproj") {
        if let colors = project.findColorAssets(in: "/Users/soleilpqd/Documents/Sample/MyProject/Colors.xcassets") {
            for color in colors {
                print(color.name, "-", color.colors?.first?.humanReadable ?? "")
            }
        }
    }
}

//testProjectFile()
//testAssets()
testFindColors()

