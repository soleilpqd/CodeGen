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
            return "• Thực hiện: \(task.rawValue)"
        default:
            return "• Perform task: \(task.rawValue)"
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
            return "\(string):0:0: error: Không tồn tại!"
        default:
            return "\(string):0:0: error: Not exist!"
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
            return "\(str):0:0: warning: Không có công việc cần thực hiện!"
        default:
            return "\(str):0:0: warning: No enabled task!"
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
            return "\(str):0:0: warning: Tệp đầu ra không nằm trong Build Target."
        default:
            return "\(str):0:0: warning: Output file is not included in build target."
        }
    }

    static func outputFileNotInProject(_ str: String) -> String {
        switch local {
        case "vi":
            return "\(str):0:0: warning: Tệp đầu ra không nằm trong Project."
        default:
            return "\(str):0:0: warning: Output color file is not included in project."
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
            return "warning: Có vẻ như '\(str)' trong '\(target)' không được sử dụng đến."
        default:
            return "warning: It seem that '\(str)' in '\(target)' is/are not used."
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
            return "\(file):0:0: error: Không đọc được hoặc không tìm thấy."
        default:
            return "\(file):0:0: error: Loading failed (unreadable or not found)."
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
            return "\(file):\(line):1: error: '\(key)' lặp lại."
        default:
            return "\(file):\(line):1: error: '\(key)' repeats."
        }
    }

    static func duplicatedStringValue(file: String, line: UInt, key: String, value: String) -> String {
        switch local {
        case "vi":
            return "\(file):\(line):1: warning: Nội dung của '\(key)' lặp lại: '\(value)'."
        default:
            return "\(file):\(line):1: warning: Value of key '\(key)' repeats: '\(value)'."
        }
    }

    static func stringParamsCountNotEquivalent(file: String, line: UInt, key: String, language: String, count: UInt, value: String) -> String {
        switch local {
        case "vi":
            return "\(file):\(line):1: error: Số lượng tham số (\(count)) của từ khoá '\(key)' ('\(value)') trong ngôn ngữ '\(language)' không tương đương với các ngôn ngữ khác."
        default:
            return "\(file):\(line):1: error: Number of parameters (\(count)) of key '\(key)' ('\(value)') in language '\(language)' is not equivalent with one in other languages."
        }
    }

    static func imageNotUsed(_ str: String) -> String {
        switch local {
        case "vi":
            return "\(str):0:0: warning: Có vẻ như ảnh không được sử dụng đến."
        default:
            return "\(str):0:0: warning: It seem that the image is not used."
        }
    }

    static func imageNotFound(str: String, file: String, row: Int, column: Int) -> String {
        switch local {
        case "vi":
            return "\(file):\(row):\(column): error: Không tìm thấy '\(str)'."
        default:
            return "\(file):\(row):\(column): error: '\(str)' not found."
        }
    }

    static func invalidOutlet(propName: String, vcName: String, file: String, row: UInt, column: UInt) -> String {
        switch local {
        case "vi":
            return "\(file):\(row):\(column): error: Outlet '\(propName)' thuộc '\(vcName)' được kết nối không đúng."
        default:
            return "\(file):\(row):\(column): error: Outlet '\(propName)' of '\(vcName)' destination is invalid."
        }
    }

    static func invalidStoryboardItem(item: String, vcName: String, file: String, row: UInt, column: UInt) -> String {
        switch local {
        case "vi":
            return "\(file):\(row):\(column): error: mục '\(item)' thuộc '\(vcName)' của storyboard được kết nối không đúng."
        default:
            return "\(file):\(row):\(column): error: item '\(item)' of '\(vcName)' has invalid destination."
        }
    }

    static func placeHolderVCDestinationStoryboardNotFound(destName: String, file: String, row: UInt, column: UInt) -> String {
        switch local {
        case "vi":
            return "\(file):\(row):\(column): error: Không tìm thấy storyboard đích '\(destName)' của Storyboard Reference."
        default:
            return "\(file):\(row):\(column): error: Destination storyboard '\(destName)' of Storyboard Reference is not found."
        }
    }

    static func placeHolderVCDestinationVCNotFound(destName: String, destStroyboard: String, file: String, row: UInt, column: UInt) -> String {
        switch local {
        case "vi":
            return "\(file):\(row):\(column): error: Không tìm thấy View controller đích '\(destName)' trong storyboard '\(destStroyboard)' của Storyboard Reference."
        default:
            return "\(file):\(row):\(column): error: Destination view controller '\(destName)' of Storyboard Reference is not found in storyboard '\(destStroyboard)'."
        }
    }

    static func placeHolderVCDestinationInitialVCNotFound(destName: String, file: String, row: UInt, column: UInt) -> String {
        switch local {
        case "vi":
            return "\(file):\(row):\(column): error: Storyboard đích '\(destName)' của Storyboard Reference không có Initial View Controller."
        default:
            return "\(file):\(row):\(column): error: Destination storyboard '\(destName)' of Storyboard Reference does not have Initial View Controller."
        }
    }

    static func pathNotEquivalentTree(file: String) -> String {
        switch local {
        case "vi":
            return "\(file):0:0: warning: \((file as NSString).lastPathComponent): Đường dẫn trên ổ cứng không tương ứng với cây thư mục của project."
        default:
            return "\(file):0:0: warning: \((file as NSString).lastPathComponent): File path on disk is not equivalent with project tree path."
        }
    }

}

func printError(_ error: String) {
    let fileHandle = FileHandle.standardError
    if let data = error.data(using: .utf8) {
        fileHandle.write(data)
    }
}
