//
//  XCProject+Color.swift
//  CodeGen
//
//  Created by DươngPQ on 13/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

extension XCProject {

    private func findAssets(in group: XCGroup, store: inout [XCAssets]) {
        guard let childs = group.children else { return }
        for item in childs {
            if let g = item as? XCGroup {
                findAssets(in: g, store: &store)
            } else if let f = item as? XCFileReference, f.lastKnownFileTypeEnum == .assets, let path = f.getFullPath() {
                let assets = XCAssets(fileReference: f, path: (projectPath as NSString).appendingPathComponent(path))
                store.append(assets)
            }
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

    func findAllColorAssets() -> [(XCAssets, [XCAssetColor])] {
        var result = [(XCAssets, [XCAssetColor])]()
        if let main = xcProject.mainGroup {
            var allAssets = [XCAssets]()
            findAssets(in: main, store: &allAssets)
            for assets in allAssets {
                var colors = [XCAssetColor]()
                findColorAssets(in: assets, store: &colors)
                result.append((assets, colors))
            }
        }
        return result
    }

    func findColorAssets(in assetsPath: String) -> (XCAssets, [XCAssetColor])? {
        if let item = getItem(with: assetsPath) as? XCFileReference, item.lastKnownFileTypeEnum == .assets {
            let assets = XCAssets(fileReference: item, path: (projectPath as NSString).appendingPathComponent(item.getFullPath()!))
            var result = [XCAssetColor]()
            findColorAssets(in: assets, store: &result)
            return (assets, result)
        }
        return nil
    }

    private func getSwiftFiles(target: XCProjTarget, store: inout [String]) {
        guard let phases = target.buildPhases else { return }
        for phase in phases where phase.type == .compileSources {
            guard let items = phase.files else { continue }
            for item in items {
                if let file = item as? XCFileReference, file.lastKnownFileTypeEnum == .swift, let path = file.getFullPath() {
                    store.append((projectPath as NSString).appendingPathComponent(path))
                }
            }
        }
    }

    func getSwiftFiles() -> [String] {
        var result = [String]()
        if let targets = xcProject.targets {
            if let targetName = env.targetName {
                for target in targets where target.name == targetName {
                    getSwiftFiles(target: target, store: &result)
                }
            } else {
                for target in targets {
                    getSwiftFiles(target: target, store: &result)
                }
            }
        }
        return result
    }

    private func checkItemInCopyResources(item: XCFileReference, target: XCProjTarget) -> Bool {
        guard let phases = target.buildPhases else { return false }
        for phase in phases where phase.type == .copyResources {
            guard let items = phase.files else { continue }
            if items.contains(where: { (fItem) -> Bool in
                return fItem === item
            }) {
                return true
            }
        }
        return false
    }

    func checkItemInCopyResource(_ item: XCFileReference) -> Bool {
        if let targets = xcProject.targets {
            if let targetName = env.targetName {
                for target in targets where target.name == targetName && checkItemInCopyResources(item: item, target: target) {
                    return true
                }
            } else {
                for target in targets where checkItemInCopyResources(item: item, target: target) {
                    return true
                }
            }
        }
        return false
    }

}
