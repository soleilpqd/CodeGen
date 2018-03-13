//
//  XCProject+Strings.swift
//  CodeGen
//
//  Created by DươngPQ on 13/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

extension XCProject {

    private func buildStrings(target: XCProjTarget, store: inout [String: [String : [String: [(String, UInt)]]]], languages: inout [String], errors: inout [String: Error]) {
        if let phases = target.buildPhases {
            for phase in phases {
                if phase.type == XCBuildPhase.PhaseType.copyResources, let files = phase.files {
                    for item in files {
                        if let f = item as? XCFileReference, f.lastKnownFileTypeEnum == .strings, let name = item.path, let path = f.getFullPath() {
                            do {
                                let strings = try parseStringsFile(file: (projectPath as NSString).appendingPathComponent(path))
                                var langStrings = [String: [String: [(String, UInt)]]]()
                                for (key, value) in strings {
                                    langStrings[key] = ["": value]
                                }
                                store[name] = langStrings
                            } catch (let e) {
                                errors[name] = e
                            }
                        } else if let g = item as? XCGroup, let name = g.name, (name as NSString).pathExtension == "strings", let childs = g.children {
                            var result = [String: [String: [(String, UInt)]]]()
                            for child in childs {
                                if let lang = child.name, let f = child as? XCFileReference, f.lastKnownFileTypeEnum == .strings, let path = f.getFullPath()  {
                                    if !languages.contains(lang) {
                                        languages.append(lang)
                                    }
                                    do {
                                        let strings = try parseStringsFile(file: (projectPath as NSString).appendingPathComponent(path))
                                        for (key, value) in strings {
                                            var langStrings: [String: [(String, UInt)]]
                                            if let dic = result[key] {
                                                langStrings = dic
                                            } else {
                                                langStrings = [String: [(String, UInt)]]()
                                            }
                                            langStrings[lang] = value
                                            result[key] = langStrings
                                        }
                                    } catch (let e) {
                                        errors[name + "+" + lang] = e
                                    }
                                }
                            }
                            store[name] = result
                        }
                    }
                }
            }
        }
    }

    /// return: [FileName: [Key: [Language: [(Value, Line)]]]]
    func buildStrings(languages: inout [String], errors: inout [String: Error]) -> [String: [String : [String: [(String, UInt)]]]] {
        var result = [String: [String : [String: [(String, UInt)]]]]()
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
