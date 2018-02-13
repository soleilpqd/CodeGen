//
//  XCTask.swift
//  CodeGen
//
//  Created by DươngPQ on 12/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCTask {

    enum TaskType: String {
        case color
    }

    let type: TaskType

    init(task: TaskType) {
        type = task
    }

    class func task(_ info: NSDictionary) -> XCTask? {
        if let t = info["type"] as? String, let tt = TaskType(rawValue: t) {
            switch tt {
            case .color:
                return XCTaskColor(info)
            }
        }
        return nil
    }

    func run(_ project: XCClassFile) -> Error? {
        return nil
    }

}
