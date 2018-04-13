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

private let kPrjRootPath = env.projectRootPath!
private let kProjFile = (env.projectFile! as NSString).appendingPathComponent("project.pbxproj")
private let kColorAssetsPath = (kPrjRootPath as NSString).appendingPathComponent("myProject/Resources/Colors.xcassets")

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
    if let project = XCProjFile.project(from: kProjFile) {
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
                                            print("\t\t\(fRef.path ?? "") (\(fRef.lastKnownFileType ?? "<type>")) \(fRef.getFullPath() ?? "<nil>")")
                                        } else if let g = f as? XCGroup {
                                            print("\t\t\(g.name ?? "<name>") \(g.isa ?? "<isa>")")
                                            if let children = g.children {
                                                for child in children {
                                                    if let file = child as? XCFileReference {
                                                        print("\t\t\t\(file.name ?? "<name>") \(file.lastKnownFileType ?? "<type>") \(file.getFullPath() ?? "<nil>")")
                                                    } else {
                                                        print("\t\t\t\(f.isa ?? "<isa>")")
                                                    }
                                                }
                                            }
                                        } else {
                                            print("\t\t\(f.isa ?? "<isa>")")
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

private func testResources() {
    if let project = XCProjFile.project(from: kProjFile), let targets = project.targets, targets.count > 0 {
        for target in targets {
            print(target.name ?? "<target>")
            if let phases = target.buildPhases {
                for phase in phases {
                    if phase.type == XCBuildPhase.PhaseType.copyResources, let files = phase.files {
                        for item in files {
                            print("\t", item.name ?? "<name>", item.path ?? "<path>", (item as? XCFileReference)?.lastKnownFileType ?? "<type>")
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
//    let assets = XCAssets(fileReference: <#T##XCFileReference#>, path: <#T##String#>)
//    printAsset(asset: assets, level: 0)
}

private func testGetSwiftFiles() {
    if let project = XCProject(rootPath: kPrjRootPath, filePath: kProjFile) {
//        print(project.getSwiftFiles())
        print(project.getCopyResourcesFiles(types: [.storyboard, .xib]))
    }
}

private func testFindColors() {
    if let project = XCProject(rootPath: kPrjRootPath, filePath: kProjFile) {
        if let result = project.findColorAssets(in: kColorAssetsPath) {
            let (assets, colors) = result
            print(assets.name)
            for color in colors {
                print("\t", color.name, "-", color.colors?.first?.humanReadable ?? "")
            }
        }
    }
}

private func testStringResources() {
     if let project = XCProject(rootPath: kPrjRootPath, filePath: kProjFile) {
        var languages = [String]()
        var errors = [String: Error]()
        let result = project.buildStrings(languages: &languages, errors: &errors)
        print("Strings:")
        for table in result {
            print("TABLE:", table.name)
            for item in table.items {
                print("\tKEY:", "'\(item.key ?? "<key>")'", "'\(item.filePath ?? "<path>")'")
                for (lang, values) in item.values {
                    print("\t\tLANG:", "'\(lang)'")
                    for value in values {
                        print("\t\t\t\(value.line)::'\(value.content)'")
                    }
                }
            }
        }
        print("Languages:", languages)
        print("Errors:", errors)
    }
}

print(Locale.current.languageCode ?? "")

//testProjectFile()
//testAssets()
//testFindColors()
//testGetSwiftFiles()
//testResources()
testStringResources()

