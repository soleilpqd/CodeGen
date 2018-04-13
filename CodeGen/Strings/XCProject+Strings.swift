//
//  XCProject+Strings.swift
//  CodeGen
//
//  Created by DươngPQ on 13/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

extension XCProject {

    private func addStringValues(from file: String, into table: XCStringTable, language: String) -> Error? {
        do {
            let strings = try parseStringsFile(file: file)
            for (key, values) in strings {
                let item = XCStringItem()
                item.key = key
                item.filePath = file
                var result = [XCStringValue]()
                for (value, line) in values {
                    let sVal = XCStringValue()
                    sVal.content = value
                    sVal.line = line
                    result.append(sVal)
                }
                if result.count > 0 { item.values[language] = result }
                item.table = table
                table.items.append(item)
            }
            return nil
        } catch (let e) {
            return e
        }
    }

    private func buildStrings(target: XCProjTarget, store: inout [XCStringTable], languages: inout [String], errors: inout [String: Error]) {
        if let phases = target.buildPhases {
            for phase in phases {
                if phase.type == XCBuildPhase.PhaseType.copyResources, let files = phase.files {
                    for item in files {
                        if let f = item as? XCFileReference, f.lastKnownFileTypeEnum == .strings, let name = item.path, let path = f.getFullPath() {
                            let table = XCStringTable()
                            table.name = name
                            if let e = addStringValues(from: (projectPath as NSString).appendingPathComponent(path), into: table, language: XCStringItem.kLanguageNone) {
                                errors[name] = e
                            }
                            store.append(table)
                        } else if let g = item as? XCGroup, let name = g.name, (name as NSString).pathExtension == "strings", let childs = g.children {
                            let table = XCStringTable()
                            table.name = name
                            for child in childs {
                                if let lang = child.name, let f = child as? XCFileReference, f.lastKnownFileTypeEnum == .strings, let path = f.getFullPath()  {
                                    if !languages.contains(lang) {
                                        languages.append(lang)
                                    }
                                    if let e = addStringValues(from: (projectPath as NSString).appendingPathComponent(path), into: table, language: lang) {
                                        errors[name + "+" + lang] = e
                                    }
                                }
                            }
                            store.append(table)
                        }
                    }
                }
            }
        }
    }

    /// return: [FileName: [Key: [Language: [(Value, Line)]]]]
    func buildStrings(languages: inout [String], errors: inout [String: Error]) -> [XCStringTable] {
        var result = [XCStringTable]()
        if let targets = xcProject.targets {
            if let targetName = env.targetName {
                for target in targets where target.name == targetName {
                    buildStrings(target: target, store: &result, languages: &languages, errors: &errors)
                }
            } else {
                for target in targets {
                    buildStrings(target: target, store: &result, languages: &languages, errors: &errors)
                }
            }
        }
        languages.sort()
        return result
    }

}
