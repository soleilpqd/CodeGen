//
//  XCTask.swift
//  CodeGen
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCTask {

    private static let kKeyType = "type"
    private static let kKeyEnable = "enable"
    private(set) weak var project: XCProject?

    enum TaskType: String {
        case color
    }

    let type: TaskType

    init(task: TaskType) {
        type = task
    }

    class func task(_ info: NSDictionary) -> XCTask? {
        if let t = info[kKeyType] as? String, let tt = TaskType(rawValue: t) {
            if let enable = info[kKeyEnable] as? NSNumber, !(enable.boolValue) {
                return nil
            }
            switch tt {
            case .color:
                return XCTaskColor(info)
            }
        }
        return nil
    }

    func run(_ project: XCProject) -> Error? {
        self.project = project
        return nil
    }

    func toDic() -> [String: Any] {
        return [XCTask.kKeyType: type.rawValue]
    }

}
