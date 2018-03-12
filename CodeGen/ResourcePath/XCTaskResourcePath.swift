//
//  XCTaskResourcePath.swift
//  CodeGen
//
//  Created by DươngPQ on 12/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCTaskResourcePath: XCTask {

    private let isNoSubDir: Bool
    private let output: String
    private let extensions: [String]
    private var fullOutputPath: String = ""

    init?(_ info: NSDictionary) {
        if let exts = info["exts"] as? [String], exts.count > 0,
            let target = info["output"] as? String, target.count > 0 {
            extensions = exts
            if let num = info["no_sub_dir"] as? NSNumber {
                isNoSubDir = num.boolValue
            } else {
                isNoSubDir = false
            }
            output = target
            super.init(task: .resource)
        } else {
            return nil
        }
    }

    override func toDic() -> [String : Any] {
        var dic = super.toDic()
        dic["exts"] = extensions
        dic["output"] = output
        if isNoSubDir {
            dic["no_sub_dir"] = NSNumber(booleanLiteral: true)
        }
        return dic
    }

    private func makeVarName(_ input: String) -> String {
        var result = input.replacingOccurrences(of: ".", with: " ")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.capitalized
        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }

    private func makeTypeName(_ name: String) -> String {
        var type = (name as NSString).pathExtension
        if type == "" {
            type = "nil"
        } else {
            type = "\"\(type)\""
        }
        return type
    }

    private func findResource(inFolder: String, originFolder: String, level: Int, content: inout String) {
        let fileMan = FileManager.default
        var items = [String]()
        var subDir = [String]()
        if let subs = try? fileMan.contentsOfDirectory(atPath: inFolder) {
            for item in subs where !item.hasPrefix("."){
                let fullPath = (inFolder as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                _ = fileMan.fileExists(atPath: fullPath, isDirectory: &isDir)
                if isDir.boolValue {
                    subDir.append(fullPath)
                } else if extensions.contains((item as NSString).pathExtension) {
                    items.append(item)
                }
            }
        }
        items.sort()
        subDir.sort()
        let refPath = (originFolder as NSString).lastPathComponent + inFolder.replacingOccurrences(of: originFolder, with: "")
        if !isNoSubDir {
            content += "\n" + indent(level + 1) + "struct \(makeVarName((inFolder as NSString).lastPathComponent)) {\n"
        }
        for item in items {
            printLog(.found("\(refPath)/\(item)"))
            let type = makeTypeName(item)
            if isNoSubDir {
                let varName = makeVarName("\(refPath)/\(item)")
                content += "\n" + indent(1) + "static var \(varName): Resource {\n"
                content += indent(2) + "return Resource(inputName: \"\((item as NSString).deletingPathExtension)\", inputType: \(type), inputFolder: \"\(refPath)\")\n"
                content += indent(1) + "}\n"
            } else {
                let varName = makeVarName(item)
                content += "\n" + indent(level + 2) + "static var \(varName): Resource {\n"
                content += indent(level + 3) + "return Resource(inputName: \"\((item as NSString).deletingPathExtension)\", inputType: \(type), inputFolder: \"\(refPath)\")\n"
                content += indent(level + 2) + "}\n"
            }
        }
        for sub in subDir {
            findResource(inFolder: sub, originFolder: originFolder, level: level + 1, content: &content)
        }
        if !isNoSubDir {
            content += "\n" + indent(level + 1) + "}\n"
        }
    }

    private func checkOutputFile(_ project: XCProject) {
        if let chk = project.checkPathInBuildSource(path: output) {
            if !chk {
                printLog(.outputFileNotInTarget(fullOutputPath))
            }
        } else {
            printLog(.outputFileNotInProject(fullOutputPath))
        }
    }

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)
        fullOutputPath = (project.projectPath as NSString).appendingPathComponent(output)
        checkOutputFile(project)
        let indent1 = indent(1)
        let indent2 = indent(2)
        let indent3 = indent(3)
        var content = project.getHeader(output) + "\nimport Foundation\n\n"
        if project.swiftlintEnable {
            content += "// swiftlint:disable force_cast identifier_name\n\n"
        }
        content += "struct \(project.prefix?.lowercased() ?? "")Resources {\n\n"
        content += indent1 + "struct Resource {\n\n"
        content += indent2 + "let name: String\n"
        content += indent2 + "let type: String?\n"
        content += indent2 + "let folder: String?\n\n"
        content += indent2 + "init(inputName: String, inputType: String?) {\n"
        content += indent3 + "name = inputName\n"
        content += indent3 + "type = inputType\n"
        content += indent3 + "folder = nil\n"
        content += indent2 + "}\n\n"
        content += indent2 + "init(inputName: String, inputType: String?, inputFolder: String) {\n"
        content += indent3 + "name = inputName\n"
        content += indent3 + "type = inputType\n"
        content += indent3 + "folder = inputFolder\n"
        content += indent2 + "}\n\n"
        content += indent2 + "var path: String {\n"
        content += indent3 + "return Bundle.main.path(forResource: name, ofType: type, inDirectory: folder)!\n"
        content += indent2 + "}\n\n"
        content += indent2 + "var url: URL {\n"
        content += indent3 + "return Bundle.main.url(forResource: name, withExtension: type, subdirectory: folder)!\n"
        content += indent2 + "}\n\n"
        content += indent1 + "}\n"
        let allItems = project.getCopyResourcesFiles(types: [])
        var files = [String]()
        var folders = [String]()
        for (key, items) in allItems {
            if key == .folder {
                for item in items {
                    folders.append(item)
                }
            } else {
                for item in items where extensions.contains((item as NSString).pathExtension) {
                    files.append(item)
                }
            }
        }
        files.sort()
        folders.sort()
        for f in files {
            let name = (f as NSString).lastPathComponent
            printLog(.found(name))
            let varName = makeVarName(name)
            content += "\n" + indent1 + "static var \(varName): Resource {\n"
            let type = makeTypeName(name)
            content += indent2 + "return Resource(inputName: \"\((name as NSString).deletingPathExtension)\", inputType: \(type))\n"
            content += indent1 + "}\n"
        }
        for d in folders {
            findResource(inFolder: d, originFolder: d, level: 0, content: &content)
        }
        content += "\n}\n"

        var result: Error?
        if let data = try? String(contentsOfFile: fullOutputPath) {
            if content != data {
                result = project.write(content: content, target: output)
            } else {
                printLog(.outputNotChange())
            }
        } else {
            result = project.write(content: content, target: output)
        }
        return result
    }
    
}
