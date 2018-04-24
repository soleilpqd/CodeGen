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
private var imageNames = [String: [(String, Int, Int)]]()

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
        let count = regex.numberOfMatches(in: content, options: [], range: NSRange(location: 0, length: content.count))
        return count > 0
    }
    return false
}

private func collectImageNameWithRegex(_ pattern: String, file: String, content: String, offset: Int) {
    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
        for item in matches {
            var word = (content as NSString).substring(with: NSMakeRange(item.range.location + offset, item.range.length - offset - 2))
            if word.lowercased().hasSuffix(".jpg") || word.lowercased().hasSuffix(".png") {
                word = (word as NSString).deletingPathExtension
            }
            let preResult = (content as NSString).substring(to: item.range.location)
            let components = preResult.components(separatedBy: CharacterSet.newlines)
            let row = components.count
            let column = components.last?.count ?? 0
            var array = imageNames[word] ?? []
            array.append((file, row, column))
            imageNames[word] = array
        }
    }
}

private func collectImageName(content: String, file: String) {
    collectImageNameWithRegex("#imageLiteral\\(resourceName: \\\".+\\\"\\)", file: file, content: content, offset: 29)
    collectImageNameWithRegex("UIImage\\(named: \\\".+\\\"\\)", file: file, content: content, offset: 16)
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
        collectImageName(content: content, file: path)
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

private func getAssetsImage(folder: XCAssetFoler, store: inout [XCAssetImage]) {
    if let children = folder.children {
        for child in children {
            if let subFolder = child as? XCAssetFoler {
                getAssetsImage(folder: subFolder, store: &store)
            } else if let image = child as? XCAssetImage {
                store.append(image)
            }
        }
    }
}

private func checkImagesUsage() -> Bool {
    guard let project = projectFile else { return true }
    let copiedResources = project.getCopyResourcesFiles(types: [.assets, .png, .jpg])
    var assetsImages = [XCAssetImage]()
    var fileImages = [String: String]()
    var allAssets = [XCAssets]() // keep assets alive
    for (key, values) in copiedResources {
        switch key {
        case .assets:
            for path in values {
                if let fItem = project.getItem(with: path) as? XCFileReference {
                    let assets = XCAssets(fileReference: fItem, path: path)
                    allAssets.append(assets)
                    getAssetsImage(folder: assets, store: &assetsImages)
                }
            }
        case .png, .jpg:
            for path in values {
                fileImages[((path as NSString).lastPathComponent as NSString).deletingPathExtension] = path
            }
        default:
            break
        }
    }

    let removeArrayItem: (String, inout [String]) -> Void = { (item, array) in
        var index = 0
        var found = true
        for itm in array {
            if item == itm {
                found = true
                break
            }
            index += 1
        }
        if found {
            array.remove(at: index)
        }
    }

    var notFoundImages = Array(imageNames.keys)
    var notUsedFileImages = Array(fileImages.keys)
    var notUsedAssetsImages = assetsImages
    for (name, _) in imageNames {
        for (fileImage, _) in fileImages where name == fileImage {
            removeArrayItem(name, &notFoundImages)
            removeArrayItem(name, &notUsedFileImages)
        }
        for assetsImage in assetsImages where assetsImage.name == name {
            removeArrayItem(name, &notFoundImages)
            var index = 0
            var found = true
            for itm in notUsedAssetsImages {
                if assetsImage === itm {
                    found = true
                    break
                }
                index += 1
            }
            if found {
                notUsedAssetsImages.remove(at: index)
            }
        }
    }
    for item in notUsedFileImages {
        if let path = fileImages[item] {
            print(String.imageNotUsed(path))
        }
    }
    for item in notUsedAssetsImages {
        if let _ = item as? XCAssetAppIcon {
            continue
        }
        var tmp = item.parent
        while tmp != nil {
            if let _ = tmp as? XCAssets {
                break
            }
            tmp = tmp?.parent
        }
        if let assets = tmp as? XCAssets {
            print(String.notUsed(item.name, assets.name + ".xcassets"))
        }
    }
    for item in notFoundImages {
        if let positions = imageNames[item] {
            for (file, row, column) in positions {
                print(String.imageNotFound(str: item, file: file, row: row, column: column))
            }
        }
    }
    return notFoundImages.count == 0
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
        if !checkImagesUsage() {
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
