//
//  XCProject.swift
//  ColorExtension
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCProject {

    private let xcProject: XCProjFile

    var prefix: String? {
        return xcProject.classPrefix
    }

    var organization: String? {
        return xcProject.organizationName
    }

    var indentWidth: Int {
        return xcProject.indentWidth ?? 4
    }

    var tabWidth: Int {
        return xcProject.tabWidth ?? 4
    }

    var useTab: Bool {
        if let num = xcProject.tabWidth {
            return num != 0
        }
        return false
    }

    private func checkSwiftlint(from target: XCProjTarget) -> Bool {
        if let phases = target.buildPhases {
            for phase in phases {
                if let scriptPhase = phase as? XCShellScriptBuildPhase, (scriptPhase.shellScript?.contains("swiftlint") ?? false) {
                    return true
                }
            }
        }
        return false
    }

    var swiftlintEnable: Bool {
        if let targets = xcProject.targets {
            if let targetName = env.targetName {
                for target in targets where target.name == targetName {
                    if checkSwiftlint(from: target) { return true }
                }
            } else {
                for target in targets {
                    if checkSwiftlint(from: target) { return true }
                }
            }
        }
        return false
    }

    let year: Int
    let projectPath: String
    let projectFile: String

    class func findProjectFile(from prjRootPath: String) -> String? {
        guard let allItems = try? FileManager.default.contentsOfDirectory(atPath: prjRootPath) else {
            return nil
        }
        var path: String?
        for item in allItems where item.hasSuffix(".xcodeproj") {
            path = (prjRootPath as NSString).appendingPathComponent(item + "/project.pbxproj")
            break
        }
        if let pPath = path, FileManager.default.fileExists(atPath: pPath) {
            return pPath
        }
        return nil
    }

    init?(rootPath: String, filePath: String) {
        if let proj = XCProjFile.project(from: filePath) {
            projectFile = filePath
            projectPath = rootPath
            xcProject = proj
            var calender = Calendar(identifier: .gregorian)
            calender.locale = Locale.current
            calender.timeZone = NSTimeZone.local
            if let fileAttr = try? FileManager.default.attributesOfItem(atPath: projectFile),
                let date = fileAttr[FileAttributeKey.modificationDate] as? Date {
                year = calender.component(.year, from: date)
            } else {
                year = calender.component(.year, from: Date())
            }
        } else {
            return nil
        }
    }

    func getHeader(_ target: String) -> String {
        var result = "//\n"
        result += "//  " + (target as NSString).lastPathComponent + "\n"
        result += "//\n"
        result += "//  Generated by CodeGen (by Some1)\n"
        if let organ = organization {
            result += "//  Copyright © \(year) \(organ). All rights reserved.\n"
        }
        result += "//\n"
        result += "//  THIS FILE IS AUTO-GENERATED. DO NOT EDIT!\n"
        return result
    }

    func write(content: String, target: String) -> Error? {
        let pathTarget = target.hasPrefix("/") ? target : (projectPath as NSString).appendingPathComponent(target)
        do {
            try (content as NSString).write(toFile: pathTarget, atomically: true, encoding: String.Encoding.utf8.rawValue)
            return nil
        } catch let e {
            return e
        }
    }

    private func findColorAssets(in assetFolder: XCAssetFoler, store: inout [XCAssetColor]) {
        guard let childs = assetFolder.children else { return }
        for item in childs {
            if let d = item as? XCAssetFoler {
                findColorAssets(in: d, store: &store)
            } else if let c = item as? XCAssetColor {
                store.append(c)
            }
        }
    }

    private func findAssets(in group: XCGroup, store: inout [XCAssets]) {
        guard let childs = group.children else { return }
        for item in childs {
            if let g = item as? XCGroup {
                findAssets(in: g, store: &store)
            } else if let f = item as? XCFileReference, f.lastKnownFileTypeEnum == .assets, let path = f.getFullPath() {
                let assets = XCAssets(path: (projectPath as NSString).appendingPathComponent(path))
                store.append(assets)
            }
        }
    }

    private func findItem(in group: XCGroup, with path: String) -> XCItem? {
        if (group.getFullPath() ?? "") == path { return group }
        guard let childs = group.children else { return nil }
        for item in childs {
            if let g = item as? XCGroup {
                if g.getFullPath() == path {
                    return g
                }
                if let result = findItem(in: g, with: path) {
                    return result
                }
            } else if let f = item as? XCFileReference, f.getFullPath() == path {
                return f
            }
        }
        return nil
    }

    private func getItem(with path: String) -> XCItem? {
        var p = path
        if p.hasPrefix(projectPath) {
            p = String(p[p.index(p.startIndex, offsetBy: projectPath.count + 1)...])
        }
        if let main = xcProject.mainGroup {
            return findItem(in: main, with: p)
        }
        return nil
    }

    func findAllColorAssets() -> [XCAssetColor] {
        var allAssets = [XCAssets]()
        var result = [XCAssetColor]()
        if let main = xcProject.mainGroup {
            findAssets(in: main, store: &allAssets)
            for assets in allAssets {
                findColorAssets(in: assets, store: &result)
            }
        }
        return result
    }

    func findColorAssets(in assetsPath: String) -> [XCAssetColor]? {
        if let item = getItem(with: assetsPath) as? XCFileReference, item.lastKnownFileTypeEnum == .assets {
            let assets = XCAssets(path: (projectPath as NSString).appendingPathComponent(item.getFullPath()!))
            var result = [XCAssetColor]()
            findColorAssets(in: assets, store: &result)
            return result
        }
        return nil
    }

}
