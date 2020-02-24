//
//  XCColorList.swift
//  CodeGen
//
//  Created by DươngPQ on 2/21/20.
//  Copyright © 2020 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import AppKit

final class XCColorList {

    let colorListName: String?
    weak var owner: XCTask?

    init(_ name: String?) {
        colorListName = name
    }

    // MARK: - ColorList (Color catalog)

    private func findColorList(_ project: XCProject) -> (String?, NSColorList?) {
        guard var clrName = colorListName else { return (nil, nil) }
        if clrName.count == 0 {
            clrName = ((((project.projectFile as NSString).deletingLastPathComponent) as NSString).lastPathComponent as NSString).deletingPathExtension
        }
        var colorList: NSColorList?
        var nameAvailable = true
        for clList in NSColorList.availableColorLists where clList.name == clrName {
            nameAvailable = false
            if clList.isEditable {
                colorList = clList
            }
        }
        if colorList == nil && !nameAvailable {
            var tmpName = clrName
            var index = 1
            while !nameAvailable {
                tmpName = clrName + "\(index)"
                nameAvailable = true
                for clList in NSColorList.availableColorLists where clList.name == tmpName {
                    nameAvailable = false
                }
                index += 1
            }
            clrName = tmpName
        }
        return (clrName, colorList)
    }

    /// return: true if changed
    private func checkKeyOfColorList(key: NSColor.Name, list: NSColorList, color: XCAssetColor.Color) -> Bool {
        if let colorInList = list.color(withKey: key) {
            if let nsColor = color.colorForColorList, XCTaskColorUtils.compareColors(nsColor, colorInList) {
                return false
            }
        }
        return true
    }

    func makeColorList(project: XCProject, colors: [XCAssetColor]) {
        let (name, list) = findColorList(project)
        guard let clrName = name else { return }
        var colorList: NSColorList
        if let clList = list {
            colorList = clList
            if colors.count == 0 {
                clList.removeFile()
                owner?.printLog(.cleanColorList(clrName))
                return
            }
            var isChanged = false
            var allKeys = [NSColor.Name]()
            for color in colors {
                if let components = color.colors {
                    if components.count == 1 {
                        if let cl1 = components.first {
                            let key = color.name
                            if checkKeyOfColorList(key: key, list: clList, color: cl1) {
                                isChanged = true
                                break
                            } else {
                                allKeys.append(key)
                            }
                        }
                    } else {
                        var index = 0
                        for cl1 in components {
                            let key = color.name + " " + (cl1.idiom ?? "\(index)")
                            if checkKeyOfColorList(key: key, list: clList, color: cl1) {
                                isChanged = true
                                break
                            } else {
                                allKeys.append(key)
                            }
                            index += 1
                        }
                        if isChanged {
                            break
                        }
                    }
                }
            }
            if !isChanged {
                for key in clList.allKeys where !allKeys.contains(key) {
                    isChanged = true
                    break
                }
            }
            if !isChanged {
                owner?.printLog(.colorListNoChange(clrName))
                return
            }
        } else {
            colorList = NSColorList(name: clrName)
        }
        owner?.printLog(.generateColorList(clrName))
        let keys = colorList.allKeys
        for key in keys {
            colorList.removeColor(withKey: key)
        }
        for color in colors {
            if let components = color.colors {
                if components.count == 1 {
                    if let cl1 = components.first, let cl = cl1.colorForColorList {
                        colorList.setColor(cl, forKey: color.name)
                    }
                } else {
                    var index = 0
                    for cl1 in components {
                        if let cl = cl1.colorForColorList {
                            colorList.setColor(cl, forKey: color.name + " " + (cl1.idiom ?? "\(index)"))
                        }
                        index += 1
                    }
                }
            }
        }
        _ = colorList.write(toFile: nil)
    }

}
