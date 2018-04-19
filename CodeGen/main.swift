//
//  main.swift
//  CodeGen
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

let env = XCEnvironment()

private var projectFile: XCProject?
private var tasks = [XCTask]()

private var prPath = ""

private let operationQueue = OperationQueue()
private var opCount = 0
private var errors = [Error]()

private var usageKeywords = [String: [String]]()

func addKeywordForCheckUsage(category: String, keyword: String) {
    var keywords = usageKeywords[category] ?? []
    if !keywords.contains(keyword) {
        keywords.append(keyword)
        usageKeywords[category] = keywords
    }
}

func removeKeywordForCheckUsage(category: String, keyword: String) {
    guard var keywords = usageKeywords[category] else { return }
    var index = 0
    for kwd in keywords {
        if kwd == keyword {
            keywords.remove(at: index)
            usageKeywords[category] = keywords
            break
        }
        index += 1
    }
}

func checkUsageUsingRegex(pattern: String, content: String) -> Bool {
    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
        return matches.count > 0
    }
    return false
}

private func checkUsageInSwiftFiles() {
    guard let project = projectFile else { return }
    let sources = project.getSwiftFiles()
    for path in sources {
        guard let content = try? String(contentsOfFile: path) else { continue }
        for (category, keywords) in usageKeywords {
            var tmpKeywords = keywords
            for keyword in keywords {
                let pattern = "\\.\(keyword)(.|\\n|\\)|\\]|\\})?"
                if checkUsageUsingRegex(pattern: pattern, content: content) {
                    var index = 0
                    for item in tmpKeywords {
                        if item == keyword {
                            tmpKeywords.remove(at: index)
                            break
                        }
                        index += 1
                    }
                }
            }
            usageKeywords[category] = tmpKeywords
        }
    }
    for (category, keywords) in usageKeywords where keywords.count > 0 {
        var list = ""
        for kwd in keywords {
            list += "\(kwd), "
        }
        list = cropTail(input: list, length: 2)
        print(String.notUsed(list, category))
    }
    
}

private func increaseOpCount(_ error: Error?) {
    opCount += 1
    if let err = error {
        errors.append(err)
    }
    if opCount == tasks.count, errors.count > 0 {
        for err in errors {
            printError((err as NSError).localizedDescription)
        }
        exit(1)
    }
}

if CommandLine.arguments.count > 1 {
    let path = CommandLine.arguments.last!
    prPath = "CMD: " + path
    if let fPath = XCProject.findProjectFile(from: path) {
        projectFile = XCProject(rootPath: path, filePath: fPath)
    }
} else if let path = env.projectRootPath, let fPath = env.projectFile {
    prPath = "ENV: " + path + " - " + fPath
    projectFile = XCProject(rootPath: path, filePath: (fPath as NSString).appendingPathComponent("project.pbxproj"))
} else {
    let path = FileManager.default.currentDirectoryPath
    prPath = "PWD: " + path
    if let fPath = XCProject.findProjectFile(from: path) {
        projectFile = XCProject(rootPath: path, filePath: fPath)
    }
}

if let classFile = projectFile {
    let configPath = (classFile.projectPath as NSString).appendingPathComponent("codegen.plist")
    print(String.loadConfig(configPath))
    if let configs = NSArray(contentsOfFile: configPath) {
        for item in configs {
            if let info = item as? NSDictionary, let task = XCTask.task(info) {
                var found = false
                for item in tasks where item === task {
                    found = true
                    break
                }
                if !found {
                    tasks.append(task)
                }
            }
        }
        if tasks.count == 0 {
            print(String.configNoTask(configPath))
            exit(.exitCodeNormal)
        }
        for item in tasks {
            operationQueue.addOperation {
                let err = item.run(classFile)
                // TODO: which task should save data into codegen.plist
                //        let array = NSMutableArray()
                //        for item in tasks {
                //            let dic = item.toDic()
                //            array.add(dic)
                //        }
                //        array.write(toFile: configPath, atomically: true)
                increaseOpCount(err)
            }
        }
        while opCount < tasks.count {
            sleep(0)
        }
        for item in tasks {
            item.flushLogs()
        }
        checkUsageInSwiftFiles()
    } else {
        printError("Could not load configuration at \"\(configPath)\"!\n")
        exit(.exitCodeNotLoadConfig)
    }
} else {
    printError("Could not load project at \(prPath)!\n")
    exit(.exitCodeNotLoadProject)
}
