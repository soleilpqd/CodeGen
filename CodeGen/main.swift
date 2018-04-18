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
    } else {
        printError("Could not load configuration at \"\(configPath)\"!\n")
        exit(.exitCodeNotLoadConfig)
    }
} else {
    printError("Could not load project at \(prPath)!\n")
    exit(.exitCodeNotLoadProject)
}
