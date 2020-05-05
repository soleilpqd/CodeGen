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
            let strings = try parseStringsFile(file: file, language: language)
            for item in strings {
                item.filePath = file
                item.table = table
            }
            table.items.append(contentsOf: strings)
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
                            table.sortItems()
                            store.append(table)
                        } else if let g = item as? XCGroup, let name = g.name, (name as NSString).pathExtension == "strings", let childs = g.children {
                            let table = XCStringTable()
                            table.name = name
                            var allItems = [[XCStringItem]]()
                            for child in childs {
                                if let lang = child.name, let f = child as? XCFileReference, f.lastKnownFileTypeEnum == .strings, let path = f.getFullPath()  {
                                    if !languages.contains(lang) {
                                        languages.append(lang)
                                    }
                                    if let e = addStringValues(from: (projectPath as NSString).appendingPathComponent(path), into: table, language: lang) {
                                        errors[name + "+" + lang] = e
                                    }
                                    allItems.append(table.items)
                                    table.items.removeAll()
                                }
                            }
                            // Merge
                            if allItems.count > 1 { // Each item of `allItems` is list of text from 1 strings file
                                var result = allItems[0] // 1st list as result list
                                for index in 1 ..< allItems.count {
                                    var items = allItems[index] // with each others list
                                    for resItem in result { // and with each item in result list
                                        // find item same key from other list
                                        var destination: XCStringItem?
                                        var tmpIndex = -1
                                        var rmIndex = -1
                                        for item in items {
                                            tmpIndex += 1
                                            if resItem.key == item.key {
                                                destination = item
                                                rmIndex = tmpIndex
                                            }
                                        }
                                        // if found, merge value into result list and remove the same key item from other list
                                        if let dest = destination {
                                            items.remove(at: rmIndex)
                                            for (key, values) in dest.values {
                                                if var resValues = resItem.values[key] {
                                                    resValues.append(contentsOf: values)
                                                    resItem.values[key] = resValues
                                                } else {
                                                    resItem.values[key] = values
                                                }
                                            }
                                        }
                                    }
                                    // add the remaining items in other list into result list
                                    result.append(contentsOf: items)
                                }
                                table.items = result
                            } else if let items = allItems.first {
                                table.items = items
                            }
                            table.sortItems()
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
