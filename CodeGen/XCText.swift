//
//  XCText.swift
//  CodeGen
//
//  Created by DươngPQ on 06/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

private let local = Locale.current.languageCode ?? ""

extension Int32 {

    static var exitCodeNormal: Int32 {
        return 0
    }

    static var exitCodeNotLoadProject: Int32 {
        return 1
    }

    static var exitCodeNotLoadConfig: Int32 {
        return 2
    }

}

extension String {

    static func performTask(_ task: XCTask.TaskType) -> String {
        switch local {
        case "vi":
            return "Thực hiện: \(task.rawValue)"
        default:
            return "Perform task: \(task.rawValue)"
        }
    }

    static func found(_ string: String) -> String {
        switch local {
        case "vi":
            return "\tTìm thấy: \(string)"
        default:
            return "\tFound: \(string)"
        }
    }

    static func errorNotExist(_ string: String) -> String {
        switch local {
        case "vi":
            return "\(string): error: Không tồn tại!"
        default:
            return "\(string): error: Not exist!"
        }
    }

    static func loadConfig(_ str: String) -> String {
        switch local {
        case "vi":
            return "Lấy cấu hình từ: \(str)"
        default:
            return "Load configuration from: \(str)"
        }
    }

    static func configNoTask(_ str: String) -> String {
        switch local {
        case "vi":
            return "\(str):0 warning: Không có công việc cần thực hiện!"
        default:
            return "\(str):0 warning: No enabled task!"
        }
    }

    static func cleanColorList(_ str: String) -> String {
        switch local {
        case "vi":
            return "\tXoá ColorList \"\(str)\""
        default:
            return "\tClean ColorList \"\(str)\""
        }
    }

    static func colorListNoChange(_ str: String) -> String {
        switch local {
        case "vi":
            return "\tColorList \"\(str)\" không thay đổi!"
        default:
            return "\tColorList \"\(str)\" has no change!"
        }
    }

    static func generateColorList(_ str: String) -> String {
        switch local {
        case "vi":
            return "\tTạo ColorList: \(str)"
        default:
            return "\tGenerate ColorList: \(str)"
        }
    }

    static func outputFileNotInTarget(_ str: String) -> String {
        switch local {
        case "vi":
            return "\(str): warning: Tệp đầu ra không nằm trong Build Target."
        default:
            return "\(str): warning: Output file is not included in build target."
        }
    }

    static func outputFileNotInProject(_ str: String) -> String {
        switch local {
        case "vi":
            return "\(str): warning: Tệp đầu ra không nằm trong Project."
        default:
            return "\(str): warning: Output color file is not included in project."
        }
    }

    static func sameValue(_ str: String) -> String {
        switch local {
        case "vi":
            return "warning: \(str) có cùng giá trị."
        default:
            return "warning: \(str) have same value."
        }
    }

    static func notUsed(_ str: String, _ target: String) -> String {
        switch local {
        case "vi":
            return "warning: Có vẻ như \(str) trong \(target) không được sử dụng đến."
        default:
            return "warning: It seem that \(str) in \(target) is/are not used."
        }
    }

    static func outputNotChange() -> String {
        switch local {
        case "vi":
            return "\tĐầu ra không đổi! Bỏ qua việc ghi!"
        default:
            return "\tThere's no change in output file! Abort writting!"
        }
    }

    static func stringFileNotLoaded(_ file: String) -> String {
        switch local {
        case "vi":
            return "\(file): error: Không đọc được hoặc không tìm thấy."
        default:
            return "\(file): error: Loading failed (unreadable or not found)."
        }
    }

    static func stringFileParsingFailed(file: String, row: UInt, column: UInt) -> String {
        switch local {
        case "vi":
            return "\(file):\(row):\(column): error: Sai cú pháp."
        default:
            return "\(file):\(row):\(column): error: Parsing failed."
        }
    }

    static func duplicatedStringKey(file: String, line: UInt, key: String) -> String {
        switch local {
        case "vi":
            return "\(file):\(line):0: error: '\(key)' lặp lại."
        default:
            return "\(file):\(line):0: error: '\(key)' repeats."
        }
    }

    static func duplicatedStringValue(file: String, line: UInt, key: String, value: String) -> String {
        switch local {
        case "vi":
            return "\(file):\(line):0: warning: Nội dung của '\(key)' lặp lại: '\(value)'."
        default:
            return "\(file):\(line):0: warning: Value of key '\(key)' repeats: '\(value)'."
        }
    }

    static func stringParamsCountNotEquivalent(file: String, line: UInt, key: String, language: String, count: UInt, value: String) -> String {
        switch local {
        case "vi":
            return "\(file):\(line):0: error: Số lượng tham số (\(count)) của từ khoá '\(key)' ('\(value)') trong ngôn ngữ '\(language)' không tương đương với các ngôn ngữ khác."
        default:
            return "\(file):\(line):0: error: Number of parameters (\(count)) of key '\(key)' ('\(value)') in language '\(language)' is not equivalent with one in other languages."
        }
    }

}

func printError(_ error: String) {
    let fileHandle = FileHandle.standardError
    if let data = error.data(using: .utf8) {
        fileHandle.write(data)
    }
}
