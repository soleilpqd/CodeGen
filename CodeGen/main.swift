//
//  main.swift
//  CodeGen
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

func printError(_ error: String) {
    let fileHandle = FileHandle.standardError
    if let data = error.data(using: .utf8) {
        fileHandle.write(data)
    }
    fileHandle.closeFile()
}

var projectDir = FileManager.default.currentDirectoryPath
var tasks = [XCTask]()

if CommandLine.arguments.count > 1 {
    projectDir = CommandLine.arguments[1]
}

if let classFile = XCClassFile(project: projectDir) {
    let configPath = (projectDir as NSString).appendingPathComponent("codegen.plist")
    if let configs = NSArray(contentsOfFile: configPath) {
        for item in configs {
            if let info = item as? NSDictionary, let task = XCTask.task(info) {
                tasks.append(task)
            }
        }
        if tasks.count == 0 {
            printError("Can not load tasks from \"\(configPath)\"!\n")
            exit(3)
        }
        for item in tasks {
            if let err = item.run(classFile) as NSError? {
                printError(err.localizedDescription)
                exit(Int32(err.code))
            }
        }
    } else {
        printError("Can not load configuration at \"\(configPath)\"!\n")
        exit(2)
    }
} else {
    printError("Can not load project at \"\(projectDir)\"!\n")
    exit(1)
}
