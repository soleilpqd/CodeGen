//
//  MYText.swift
//
//  Generated by CodeGen (by Some1)
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//
//  THIS FILE IS AUTO-GENERATED. DO NOT EDIT!
//  Add text key & content into Localizable.strings and Build project.

import Foundation

extension String {

    struct MYLocalizable {

        /// normal text
        /// - vi: "Văn bản\n bềnh thường"
        /// - Base: "Normal\n text 1"
        static var normalText: String {
            return NSLocalizedString("normal text", tableName: "Localizable", comment: "")
        }

        /// attr_param_text
        /// - Base: "<b>%@</b>\""
        static func attrParamText(param1: Any) -> NSAttributedString? {
            let pattern = NSLocalizedString("attr_param_text", tableName: "Localizable", comment: "")
            let htmlString = String(format: pattern, "\(param1)")
            return makeAttributeString(htmlString)
        }

        /// attr_bold_text
        /// - Base: "<b>Bold text</b>\""
        static var attrBoldText: NSAttributedString? {
            let htmlString = NSLocalizedString("attr_bold_text", tableName: "Localizable", comment: "")
            return makeAttributeString(htmlString)
        }

        /// param text
        /// - Base: "Param: %@"
        static func paramText(param1: Any) -> String {
            let pattern = NSLocalizedString("param text", tableName: "Localizable", comment: "")
            return String(format: pattern, "\(param1)")
        }

        private static func makeAttributeString(_ htmlString: String) -> NSAttributedString? {
            if let data = htmlString.data(using: .utf8) {
                return try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html,
                                                                     .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)],
                                               documentAttributes: nil)
            }
            return nil
        }

    }

}
