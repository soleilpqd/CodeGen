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
        print(MYResources.Data.Subdata.dataJson.path)
        print(MYResources.Data.dataJson.url)
        print(String.MYLocalizable.normalText)
        print(String.MYLocalizable.paramText("test"))
        print(String.MYLocalizable.attrBoldText.string)
        print(String.MYLocalizable.attrParamText("test").string)
        print(URL.MYUrls.mainApiLogin)
        print(URL.MYUrls.mainApiDetail("001"))
        print(URL.MYUrls.privacy)
        print(MYAlertTitle.title.toString())
        print(MYAlertButton.okk.toString())
        print(MYAlertMessage.networkError.toString())
//        print(MYAlertMessage.yourName("TEST").toString())
    }

}

