//
//  main.swift
//  CodeGen
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

/// Build info (XCode Building environment variables)
let env = XCEnvironment()

private var projectFile: XCProject?
private var tasks = [XCTask]()

private var prPath = ""

private let operationQueue = OperationQueue()
private var opCount = 0
private var errors = [Error]()

/// Increase counter when an operation in queue finishes.
/// If counter reaches number of operations, print out errors.
/// In there's error, exit with non-success status
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

// Analyze program arguments
if CommandLine.arguments.count > 1 {
    // There's argument, last arg should be target project path
    let path = CommandLine.arguments.last!
    prPath = "CMD: " + path
    if let fPath = XCProject.findProjectFile(from: path) {
        projectFile = XCProject(rootPath: path, filePath: fPath)
    }
} else if let path = env.projectRootPath, let fPath = env.projectFile {
    // Target project path from Building Environment
    prPath = "ENV: " + path + " - " + fPath
    projectFile = XCProject(rootPath: path, filePath: (fPath as NSString).appendingPathComponent("project.pbxproj"))
} else {
    // Default: target project path is current directory
    let path = FileManager.default.currentDirectoryPath
    prPath = "PWD: " + path
    if let fPath = XCProject.findProjectFile(from: path) {
        projectFile = XCProject(rootPath: path, filePath: fPath)
    }
}

if let classFile = projectFile { // Success parse project file
    XCValidator.shared.projectFile = classFile
    // Reading config file in project root path
    let configPath = (classFile.projectPath as NSString).appendingPathComponent("codegen.plist")
    print(String.loadConfig(configPath))
    if let configs = NSArray(contentsOfFile: configPath) {
        // Make tasks
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
        // Add default task: validate project tree (not available in config)
        tasks.append(XCTaskTreePath(task: .tree))
        // Execute tasks in queue (tasks run parallely)
        for item in tasks {
            operationQueue.addOperation {
                let err = item.run(classFile)
                increaseOpCount(err)
            }
        }
        // Here in main thread, wait for all tasks finishing.
        while opCount < tasks.count {
            sleep(0)
        }
        // Now print out logs of tasks, serial.
        for item in tasks {
            item.flushLogs()
        }
        // Validate usage of genereted code.
        XCValidator.shared.checkUsageInSwiftFiles()
        if !XCValidator.shared.checkImagesUsage() {
            exit(1)
        }
    } else {
        printError("Could not load configuration at \"\(configPath)\"!\n")
        exit(.exitCodeNotLoadConfig)
    }
} else {
    printError("Could not load project at \(prPath)!\n")
    exit(.exitCodeNotLoadProject)
}
