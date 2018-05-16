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
        print(MYResources.Data.SubData.dataJson.path)
        print(MYResources.Data.dataJson.url)
        print(String.MYLocalizable.normalText)
        print(String.MYLocalizable.paramText("test"))
        print(NSAttributedString.MYLocalizable.boldText.string)
        print(NSAttributedString.MYLocalizable.paramText("test").string)
        print(URL.MYURLs.mainApiLogin)
        print(URL.MYURLs.mainApiDetail("001"))
        print(URL.MYURLs.privacy)
        print(MYAlertTitle.title.toString())
        print(MYAlertButton.oKK.toString())
        print(MYAlertMessage.networkError.toString())
//        print(MYAlertMessage.yourName("TEST").toString())
//        let img1 = #imageLiteral(resourceName: "xcode")
        let img2 = #imageLiteral(resourceName: "penguin.png")
        let img3 = UIImage(named: "penguin")
//        let img4 = UIImage(named: "xcode")
//        print(img1.size, img2.size, img3?.size, img4?.size)
        print(self.storyboard?.name)
        print(MYStoryboard.secondViewController.loadStoryboard().instantiateInitialViewController())
        print(MYXib.customTableViewCell.loadView())
        print(MYStoryboard.loadSecondViewController())
        print(MYThirdViewController.TableCellIdentifier.cell.rawValue)
    }

}

