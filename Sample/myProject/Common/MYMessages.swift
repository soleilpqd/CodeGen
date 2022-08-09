//
//  MYMessages.swift
//
//  Generated by CodeGen (by Some1)
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//
//  THIS FILE IS AUTO-GENERATED. DO NOT EDIT!
//  Add text key & content into Messages.strings and Build project.

import Foundation

enum MYAlertButton {

    /**
     ALERT_BUTTON_OK
     - Base: "OK"
    */
    case oKK

    func toString() -> String {
        switch self {
        case .oKK:
            return NSLocalizedString("ALERT_BUTTON_OK", tableName: "Messages", comment: "")
        }
    }

}

enum MYAlertMessage {

    /**
     ALERT_MESG_Network Error
     - Base: "Network error"
    */
    case networkError

    /**
     ALERT_MESG_Your Name
     - Base: "Your name is \"%@\""
    */
    case yourName(Any)

    func toString() -> String {
        switch self {
        case .networkError:
            return NSLocalizedString("ALERT_MESG_Network Error", tableName: "Messages", comment: "")
        case .yourName(let param1):
            let pattern = NSLocalizedString("ALERT_MESG_Your Name", tableName: "Messages", comment: "")
            return String(format: pattern, "\(param1)")
        }
    }

}

enum MYAlertTitle {

    /**
     ALERT_TITLE_title
     - Base: "title"
    */
    case title

    func toString() -> String {
        switch self {
        default:
            return NSLocalizedString("ALERT_TITLE_\(self)", tableName: "Messages", comment: "")
        }
    }

}
