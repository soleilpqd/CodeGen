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
}

let env = XCEnvironment()

private var projectFile: XCProject?
private var tasks = [XCTask]()

private var prPath = ""

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
    print("Load configuration from:", configPath)
    if let configs = NSArray(contentsOfFile: configPath) {
        for item in configs {
            if let info = item as? NSDictionary, let task = XCTask.task(info) {
                tasks.append(task)
            }
        }
        if tasks.count == 0 {
            print("\"\(configPath)\":0 warning: No enabled task!\n")
            exit(0)
        }
        for item in tasks {
            print("Perform task:", item.type.rawValue)
            if let err = item.run(classFile) as NSError? {
                printError(err.localizedDescription)
                exit(Int32(err.code))
            }
        }
        let array = NSMutableArray()
        for item in tasks {
            let dic = item.toDic()
            array.add(dic)
        }
        array.write(toFile: configPath, atomically: true)
    } else {
        printError("Could not load configuration at \"\(configPath)\"!\n")
        exit(2)
    }
} else {
    printError("Could not load project at \(prPath)!\n")
    exit(1)
}
