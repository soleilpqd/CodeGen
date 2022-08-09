//
//  MYStoryboards.swift
//
//  Generated by CodeGen (by Some1)
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//
//  THIS FILE IS AUTO-GENERATED. DO NOT EDIT!

import UIKit
import AVKit

extension UIStoryboard {

    var name: String? {
        if self.responds(to: NSSelectorFromString("storyboardFileName")) {
            return (self.value(forKey: "storyboardFileName") as? NSString)?.deletingPathExtension
        }
        return nil
    }

}

extension UITableView {

    func registerCells(from xibs: MYXib...) {
        for xib in xibs {
            register(xib.loadNib(), forCellReuseIdentifier: xib.rawValue)
        }
    }

    func dequeReuseCell(xib: MYXib) -> UITableViewCell {
        if let cell = dequeueReusableCell(withIdentifier: xib.rawValue) {
            return cell
        }
        fatalError("DEVELOP ERROR: \"\(xib.rawValue)\" is not registed as reusaable table view cell!")
    }

}

extension UICollectionView {

    func registerCells(from xibs: MYXib...) {
        for xib in xibs {
            register(xib.loadNib(), forCellWithReuseIdentifier: xib.rawValue)
        }
    }

    func dequeReuseCell(xib: MYXib, indexPath: IndexPath) -> UICollectionViewCell {
        return dequeueReusableCell(withReuseIdentifier: xib.rawValue, for: indexPath)
    }

}

enum MYXib: String {

    case customCollectionViewCell = "MYCustomCollectionViewCell"
    case customTableViewCell = "MYCustomTableViewCell"
    case thirdViewController = "MYThirdViewController"

    func loadNib() -> UINib {
        return UINib(nibName: self.rawValue, bundle: nil)
    }

    func loadView(_ owner: Any? = nil) -> UIView {
        let nib = loadNib()
        let views = nib.instantiate(withOwner: owner, options: nil)
        if let view = views.first as? UIView {
            return view
        }
        return UIView()
    }

}

extension MYCustomCollectionViewCell {

    static func dequeueReuse(collectionView: UICollectionView, indexPath: IndexPath) -> MYCustomCollectionViewCell {
        if let cell = collectionView.dequeReuseCell(xib: .customCollectionViewCell, indexPath: indexPath) as? MYCustomCollectionViewCell {
            return cell
        }
        fatalError("DEVELOP ERROR: The registered cell type for identifier \"\(MYXib.customCollectionViewCell.rawValue)\" is not \"MYCustomCollectionViewCell\"!")
    }

}

extension MYCustomTableViewCell {

    static func dequeueReuse(tableView: UITableView) -> MYCustomTableViewCell {
        if let cell = tableView.dequeReuseCell(xib: .customTableViewCell) as? MYCustomTableViewCell {
            return cell
        }
        fatalError("DEVELOP ERROR: The registered cell type for identifier \"\(MYXib.customTableViewCell.rawValue)\" is not \"MYCustomTableViewCell\"!")
    }

}

enum MYStoryboard: String {

    case main = "Main"
    case secondViewController = "MYSecondViewController"

    func loadStoryboard() -> UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }

    private func getStoryboard(originVC: UIViewController?) -> UIStoryboard {
        if let oVC = originVC, let originStoryboard = oVC.storyboard, originStoryboard.name == self.rawValue {
            return originStoryboard
        }
        return loadStoryboard()
    }

    static func loadSecondViewController(_ fromViewController: UIViewController? = nil) -> MYSecondViewController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "MYSecondViewController") as? MYSecondViewController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"MYSecondViewController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadThirdViewControllerTab2FromStoryboardMYSecondViewController(_ fromViewController: UIViewController? = nil) -> MYThirdViewController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "Tab2") as? MYThirdViewController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"MYThirdViewController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadThirdViewControllerView1FromStoryboardMYSecondViewController(_ fromViewController: UIViewController? = nil) -> MYThirdViewController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "View1") as? MYThirdViewController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"MYThirdViewController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadViewController(_ fromViewController: UIViewController? = nil) -> ViewController {
        let storyboard = self.main.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "Main") as? ViewController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"ViewController\" from storyboard \"Main\"")
    }

    static func loadAVPlayerViewController(_ fromViewController: UIViewController? = nil) -> AVPlayerViewController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "Player") as? AVPlayerViewController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"AVPlayerViewController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadUICollectionViewController(_ fromViewController: UIViewController? = nil) -> UICollectionViewController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "Collection") as? UICollectionViewController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"UICollectionViewController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadUINavigationControllerFromStoryboardMYSecondViewController(_ fromViewController: UIViewController? = nil) -> UINavigationController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateInitialViewController() as? UINavigationController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"UINavigationController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadUINavigationControllerNav2FromStoryboardMYSecondViewController(_ fromViewController: UIViewController? = nil) -> UINavigationController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "Nav2") as? UINavigationController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"UINavigationController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadUINavigationControllerFromStoryboardMain(_ fromViewController: UIViewController? = nil) -> UINavigationController {
        let storyboard = self.main.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateInitialViewController() as? UINavigationController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"UINavigationController\" from storyboard \"Main\"")
    }

    static func loadUISplitViewController(_ fromViewController: UIViewController? = nil) -> UISplitViewController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "Split") as? UISplitViewController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"UISplitViewController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadUITabBarController(_ fromViewController: UIViewController? = nil) -> UITabBarController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "Tab") as? UITabBarController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"UITabBarController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadUITableViewController(_ fromViewController: UIViewController? = nil) -> UITableViewController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        if let result = storyboard.instantiateViewController(withIdentifier: "View2") as? UITableViewController {
            return result
        }
        fatalError("DEVELOP ERROR: Fail to load \"UITableViewController\" from storyboard \"MYSecondViewController\"")
    }

    static func loadUIViewController(_ fromViewController: UIViewController? = nil) -> UIViewController {
        let storyboard = self.secondViewController.getStoryboard(originVC: fromViewController)
        return storyboard.instantiateViewController(withIdentifier: "Tab1")
    }

}

extension MYSecondViewController {

    enum SegueIdentifier: String {

        case detailSegue = "DetailSegue"

    }

}

extension MYThirdViewController {

    enum TableCellIdentifier: String {

        /// MYCustomTableViewCell
        case cell = "Cell"

    }

    enum CollectionCellIdentifer: String {

        /// MYCustomCollectionViewCell
        case cell = "Cell"

    }

    func getTableCellViewCell(_ tableView: UITableView) -> MYCustomTableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: TableCellIdentifier.cell.rawValue) as? MYCustomTableViewCell {
            return cell
        }
        fatalError("DEVELOP ERROR: Fail to dequeue cell \"MYCustomTableViewCell\" with identifier \"Cell\"")
    }

    func getCollectionCellViewCell(collectionView: UICollectionView, indexPath: IndexPath) -> MYCustomCollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionCellIdentifer.cell.rawValue, for: indexPath) as? MYCustomCollectionViewCell {
            return cell
        }
        fatalError("DEVELOP ERROR: Fail to dequeue cell \"MYCustomCollectionViewCell\" with identifier \"Cell\" for IndexPath \(indexPath.section)-\(indexPath.row)")
    }

}
