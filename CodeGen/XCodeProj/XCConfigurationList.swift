//
//  XCConfigurationList.swift
//  XCodeProj
//
//  Created by DươngPQ on 21/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCConfiguration: XCObject {

    var name: String?
    var buildSettings: [String: Any]?

    override init?(dic: [String : Any], allObjects: [String : Any]) {
        super.init(dic: dic, allObjects: allObjects)
        if isaEnum != .configuration { return nil }
        name = getString(dic: dic, key: "name")
        buildSettings = getDic(dic: dic, key: "buildSettings")
    }

}

class XCConfigurationList: XCObject {

    var defaultConfigurationIsVisible: Int?
    var defaultConfigurationName: String?
    var buildConfigurations: [XCConfiguration]?

    override init?(dic: [String : Any], allObjects: [String : Any]) {
        super.init(dic: dic, allObjects: allObjects)
        if isaEnum != .configList { return nil }
        defaultConfigurationIsVisible = getInt(dic: dic, key: "defaultConfigurationIsVisible")
        defaultConfigurationName = getString(dic: dic, key: "defaultConfigurationName")
        if let configs = dic["buildConfigurations"] as? [String], configs.count > 0 {
            var result = [XCConfiguration]()
            for key in configs {
                if let cfgDic = allObjects[key] as? [String: Any], let cfg = XCConfiguration(dic: cfgDic, allObjects: allObjects) {
                    result.append(cfg)
                }
            }
            buildConfigurations = result
        }
    }

}
