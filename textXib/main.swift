//
//  main.swift
//  textXib
//
//  Created by DươngPQ on 05/03/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

if let storyboard = XCStoryboard("/Users/soleilpqd/PROJECTS/COMMONS/CodeGen/Sample/myProject/ViewControllers/MYSecondViewController.storyboard") {
    print( storyboard );
}
if let xib = XCXib("/Users/soleilpqd/PROJECTS/COMMONS/CodeGen/Sample/myProject/ViewControllers/MYThirdViewController.xib") {
    print(xib)
}
if let xib = XCXib("/Users/soleilpqd/PROJECTS/COMMONS/CodeGen/Sample/myProject/ViewControllers/MYCustomTableViewCell.xib") {
    print(xib)
}
