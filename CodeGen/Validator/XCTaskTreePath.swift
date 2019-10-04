//
//  XCTaskTreePath.swift
//  CodeGen
//
//  Created by DươngPQ on 18/05/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

final class XCTaskTreePath: XCTask {

    private func validateItem(project: XCProject, item: XCItem) {
        guard let name = item.name, let path = item.getFullPath() else { return }
        if let p = item.path, p.hasPrefix(name + ".lproj") { return }
        printLog(.pathNotEquivalentTree(file: (project.projectPath as NSString).appendingPathComponent(path)))
    }

    private func validateGroup(project: XCProject, group: XCGroup) {
        if let items = group.children {
            for item in items {
                if let grp = item as? XCGroup {
                    validateGroup(project: project, group: grp)
                } else {
                    validateItem(project: project, item: item)
                }
            }
        }
    }

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)
        if let root = project.xcProject.mainGroup {
            validateGroup(project: project, group: root)
        }
        return nil
    }

}
