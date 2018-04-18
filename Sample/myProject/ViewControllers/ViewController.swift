//
//  ViewController.swift
//  myProject
//
//  Created by DươngPQ on 26/02/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print(MYResources.Data.Subdata.DataJson.path)
        print(MYResources.Data.DataJson.url)
        print(String.MYLocalizable.normalText)
        print(String.MYLocalizable.paramText(param1: "test"))
        print(String.MYLocalizable.attrBoldText?.string ?? "<nil>")
        print(String.MYLocalizable.attrParamText(param1: "test")?.string ?? "<nil>")
    }

}

