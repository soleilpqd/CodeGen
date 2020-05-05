//
//  XCStringTask.swift
//  CodeGen
//
//  Created by DươngPQ on 18/04/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

let kStringParam = "%@"

final class XCTaskString: XCTask {

    class func countParams(_ input: String) -> UInt {
        let array = input.components(separatedBy: kStringParam)
        return UInt(array.count - 1)
    }

    static let shared = XCTaskString(task: .string)

    var isNeedValidate = false
    private let operationQueue = OperationQueue()
    private var subTasks = [XCTaskStringSubTask]()

    override init(task: TaskType) {
        super.init(task: .string)
    }

    func appendSubTask(_ info: NSDictionary) {
        guard let typ = info["output_type"] as? String, let ttyp = XCTaskStringSubTask.OutputType(rawValue: typ) else { return }
        if ttyp == .validation {
            isNeedValidate = true
            return
        }
        if let inp = info["input"] as? String, let outp = info["output"] as? String {
            var subTask: XCTaskStringSubTask?
            switch ttyp {
            case .string:
                subTask = XCStringSubTask(inp: inp, outp: outp, oType: ttyp)
            case .url:
                subTask = XCUrlSubTask(inp: inp, outp: outp, oType: ttyp)
            case .enumeration:
                subTask = XCEnumSubTask(inp: inp, outp: outp, oType: ttyp)
            case .enumString:
                subTask = XCEnumStringSubTask(inp: inp, outp: outp, oType: ttyp)
            default:
                break;
            }
            if let sTask = subTask {
                if let funcName = info["func"] as? String {
                    sTask.localizeFunc = funcName
                }
                sTask.getInfo(from: info)
                subTasks.append(sTask)
            }
        }
    }

    private func buildValuesMapAndCheckKeys(table: XCStringTable, valuesMap: inout [String: [XCStringItem]]) {
        for item in table.items {
            var paramsCount = [UInt]()
            for (language, values) in item.values {
                for val in values {
                    if values.count > 1 {
                        printLog(.duplicatedStringKey(file: item.filePath ?? "", line: val.line, key: item.key ?? ""))
                    }
                    let key = "\(language)::\(val.content)"
                    var array = valuesMap[key] ?? []
                    array.append(item)
                    valuesMap[key] = array
                }
                let pCount = XCTaskString.countParams(values.last?.content ?? "")
                paramsCount.append(pCount)
            }
            var last: UInt?
            var isEquivalent = true
            for cnt in paramsCount {
                if let lst = last {
                    if lst != cnt {
                        isEquivalent = false
                        break
                    }
                } else {
                    last = cnt
                }
            }
            if !isEquivalent {
                for (language, values) in item.values {
                    if let val = values.last {
                        printLog(.stringParamsCountNotEquivalent(file: item.filePath ?? "", line: val.line,
                                                                 key: item.key ?? "", language: language,
                                                                 count: XCTaskString.countParams(val.content),
                                                                 value: val.content))
                    }
                }
            }
        }
    }

    private func checkValues(valuesMap: [String: [XCStringItem]]) {
        for (key, array) in valuesMap where array.count > 1 {
            let tmp = key.components(separatedBy: "::")
            let language = tmp.first ?? ""
            let value = tmp.last ?? ""
            for item in array {
                if let itemValues = item.values[language] {
                    for val in itemValues where val.content == value {
                        printLog(.duplicatedStringValue(file: item.filePath ?? "", line: val.line,
                                                        key: item.key ?? "", value: value))
                    }
                }
            }
        }
    }

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)

        var languages = [String]()
        var errors = [String: Error]()
        let strings = project.buildStrings(languages: &languages, errors: &errors)

        if errors.count > 0 {
            for (file, error) in errors {
                if let err = error as? XCStringsParserError {
                    switch err {
                    case .notLoad:
                        printError(String.stringFileNotLoaded(file))
                    case .failed(let row, let column):
                        printError(String.stringFileParsingFailed(file: file, row: row, column: column))
                    }
                }
            }
            return errors.values.first
        }

        for sTask in subTasks {
            if let txtTask = sTask as? XCStringSubTask, txtTask.checkAttributedStringAvailable(tables: strings) {
                txtTask.isAttStringMakerAvailable = true
                break
            }
        }

        var count = 0
        var taskErrors = [Error]()
        for sTask in subTasks {
            operationQueue.addOperation {
                if let result = sTask.run(project: project, tables: strings) {
                    taskErrors.append(result)
                }
                count += 1
            }
        }
        while count < subTasks.count {
            sleep(0)
        }
        for sTask in subTasks {
            for log in sTask.logs {
                printLog(log)
            }
        }
        if isNeedValidate {
            var values = [String: [XCStringItem]]()
            for table in strings {
                buildValuesMapAndCheckKeys(table: table, valuesMap: &values)
            }
            checkValues(valuesMap: values)
        }

        return taskErrors.first
    }

}
