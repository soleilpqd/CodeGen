//
//  XCTaskXib.swift
//  CodeGen
//
//  Created by DươngPQ on 15/05/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

final class XCTaskXib: XCTask {

    private let output: String

    init?(_ info: NSDictionary) {
        if let target = info["output"] as? String, target.count > 0 {
            output = target
            super.init(task: .xib)
        } else {
            return nil
        }
    }

    private func generateCommonFunc(xibEnum: String?) -> String {
        let indent1 = indent(1)
        let indent2 = indent(2)
        let indent3 = indent(3)
        var result = "extension UIStoryboard {\n\n"
        result += indent1 + "var name: String? {\n"
        result += indent2 + "if self.responds(to: NSSelectorFromString(\"storyboardFileName\")) {\n"
        result += indent3 + "return (self.value(forKey: \"storyboardFileName\") as? NSString)?.deletingPathExtension\n"
        result += indent2 + "}\n"
        result += indent2 + "return nil\n"
        result += indent1 + "}\n\n"
        result += "}\n\n"

        guard let xib = xibEnum else { return result }
        result += "extension UITableView {\n\n"
        result += indent1 + "func registerCells(from xibs: \(xib)...) {\n"
        result += indent2 + "for xib in xibs {\n"
        result += indent3 + "register(xib.loadNib(), forCellReuseIdentifier: xib.rawValue)\n"
        result += indent2 + "}\n"
        result += indent1 + "}\n\n"
        result += indent1 + "func dequeReuseCell(xib: \(xib)) -> UITableViewCell {\n"
        result += indent2 + "if let cell = dequeueReusableCell(withIdentifier: xib.rawValue) {\n"
        result += indent3 + "return cell\n"
        result += indent2 + "}\n"
        result += indent2 + "fatalError(\"DEVELOP ERROR: \\\"\\(xib.rawValue)\\\" is not registed as reusaable table view cell!\")\n"
        result += indent1 + "}\n\n"
        result += "}\n\n"
        result += "extension UICollectionView {\n\n"
        result += indent1 + "func registerCells(from xibs: \(xib)...) {\n"
        result += indent2 + "for xib in xibs {\n"
        result += indent3 + "register(xib.loadNib(), forCellWithReuseIdentifier: xib.rawValue)\n"
        result += indent2 + "}\n"
        result += indent1 + "}\n\n"
        result += indent1 + "func dequeReuseCell(xib: \(xib), indexPath: IndexPath) -> UICollectionViewCell {\n"
        result += indent2 + "return dequeueReusableCell(withReuseIdentifier: xib.rawValue, for: indexPath)\n"
        result += indent1 + "}\n\n"
        result += "}\n\n"

        return result
    }

    private func generateEnums(project: XCProject, storyboards: [XCStoryboard], xibs: [XCXib], launchScreenStoryboard: String?) -> String {
        var result = ""
        let indent1 = indent(1)
        let indent2 = indent(2)
        let indent3 = indent(3)
        if xibs.count > 0 {
            result += "enum " + (project.prefix ?? "") + "Xib: String {\n\n"
            for item in xibs {
                if item.enumName != item.docName {
                    result += indent1 + "case " + item.enumName + " = \"" + item.docName + "\"\n"
                } else {
                    result += indent1 + "case " + item.enumName + "\n"
                }
            }
            result += "\n" + indent1 + "func loadNib() -> UINib {\n"
            result += indent2 + "return UINib(nibName: self.rawValue, bundle: nil)\n"
            result += indent1 + "}\n\n"
            result += indent1 + "func loadView(_ owner: Any? = nil) -> UIView {\n"
            result += indent2 + "let nib = loadNib()\n"
            result += indent2 + "let views = nib.instantiate(withOwner: owner, options: nil)\n"
            result += indent2 + "if let view = views.first as? UIView {\n"
            result += indent3 + "return view\n"
            result += indent2 + "}\n"
            result += indent2 + "return UIView()\n"
            result += indent1 + "}\n\n}\n\n"

            for item in xibs {
                if item.view == "tableViewCell" {
                    guard let cls = item.customClass else { continue }
                    result += "extension \(cls) {\n\n"
                    result += indent1 + "static func dequeueReuse(tableView: UITableView) -> \(cls) {\n"
                    result += indent2 + "if let cell = tableView.dequeReuseCell(xib: .\(item.enumName)) as? \(cls) {\n"
                    result += indent3 + "return cell\n"
                    result += indent2 + "}\n"
                    result += indent2 + "fatalError(\"DEVELOP ERROR: The registered cell type for identifier \\\"\\(\(project.prefix ?? "")Xib.\(item.enumName).rawValue)\\\" is not \\\"\(cls)\\\"!\")\n"
                    result += indent1 + "}\n\n"
                    result += "}\n\n"
                }
                if item.view == "collectionViewCell" {
                    guard let cls = item.customClass else { continue }
                    result += "extension \(cls) {\n\n"
                    result += indent1 + "static func dequeueReuse(collectionView: UICollectionView, indexPath: IndexPath) -> \(cls) {\n"
                    result += indent2 + "if let cell = collectionView.dequeReuseCell(xib: .\(item.enumName), indexPath: indexPath) as? \(cls) {\n"
                    result += indent3 + "return cell\n"
                    result += indent2 + "}\n"
                    result += indent2 + "fatalError(\"DEVELOP ERROR: The registered cell type for identifier \\\"\\(\(project.prefix ?? "")Xib.\(item.enumName).rawValue)\\\" is not \\\"\(cls)\\\"!\")\n"
                    result += indent1 + "}\n\n"
                    result += "}\n\n"
                }
            }
        }
        if storyboards.count > 0 {
            result += "enum " + (project.prefix ?? "") + "Storyboard: String {\n\n"
            for item in storyboards {
                if let launchName = launchScreenStoryboard, item.docName == launchName {
                    continue
                }
                if item.enumName != item.docName {
                    result += indent1 + "case " + item.enumName + " = \"" + item.docName + "\"\n"
                } else {
                    result += indent1 + "case " + item.enumName + "\n"
                }
            }
            result += "\n" + indent1 + "func loadStoryboard() -> UIStoryboard {\n"
            result += indent2 + "return UIStoryboard(name: self.rawValue, bundle: nil)\n"
            result += indent1 + "}\n\n"
            result += indent1 + "private func getStoryboard(originVC: UIViewController?) -> UIStoryboard {\n"
            result += indent2 + "if let oVC = originVC, let originStoryboard = oVC.storyboard, originStoryboard.name == self.rawValue {\n"
            result += indent3 + "return originStoryboard\n"
            result += indent2 + "}\n"
            result += indent2 + "return loadStoryboard()\n"
            result += indent1 + "}\n\n"
        }
        return result
    }

    private func getClassName(vc: XCViewController) -> String? {
        if let customCls = vc.customClass {
            return customCls
        }
        if let type = XCViewController.ViewControllerType(rawValue: vc.type) {
            switch type {
            case .navigationController:
                return "UINavigationController"
            case .tabBarController:
                return "UITabBarController"
            case .viewController:
                return "UIViewController"
            case .avPlayerViewController:
                return "AVPlayerViewController"
            case .collectionViewController:
                return "UICollectionViewController"
            case .splitViewController:
                return "UISplitViewController"
            case .tableViewController:
                return "UITableViewController"
            default:
                break
            }
        }
        return nil
    }

    private func makeVCFunctionName(project: XCProject, vcClass: String) -> String {
        var result = vcClass
        if let prefix = project.prefix, prefix.count > 0, result.hasPrefix(prefix) {
            result = String(result[result.index(result.startIndex, offsetBy: prefix.count)...])
        }
        return String(result[result.startIndex]).uppercased() + String(result[result.index(after: result.startIndex)...])
    }

    private func generateViewController(vc: XCViewController, funcName: String, className: String, storyboard: XCStoryboard) -> String {
        let indent1 = indent(1)
        let indent2 = indent(2)
        let indent3 = indent(3)
        var result = indent1 + "static func load\(funcName)(_ fromViewController: UIViewController? = nil) -> \(className) {\n"
        result += indent2 + "let storyboard = self.\(storyboard.enumName).getStoryboard(originVC: fromViewController)\n"
        var isNeedFatal = true
        if let identifier = vc.storyboardIdentifier {
            if className == "UIViewController" {
                result += indent2 + "return storyboard.instantiateViewController(withIdentifier: \"\(identifier)\")\n"
                isNeedFatal = false
            } else {
                result += indent2 + "if let result = storyboard.instantiateViewController(withIdentifier: \"\(identifier)\") as? \(className) {\n"
                result += indent3 + "return result\n"
                result += indent2 + "}\n"
            }
        } else { // initial vc
            if className == "UIViewController" {
                result += indent2 + "if let result = storyboard.instantiateInitialViewController() {\n"
            } else {
                result += indent2 + "if let result = storyboard.instantiateInitialViewController() as? \(className) {\n"
            }
            result += indent3 + "return result\n"
            result += indent2 + "}\n"
        }
        if isNeedFatal {
            result += indent2 + "fatalError(\"DEVELOP ERROR: Fail to load \\\"\(className)\\\" from storyboard \\\"\(storyboard.docName)\\\"\")\n"
        }
        result += indent1 + "}\n\n"

        return result
    }

    private func generateViewController(project: XCProject, vc: XCViewController) -> String {
        guard let className = getClassName(vc: vc), let storyboard = vc.storyboard else { return "" }
        let funcName = makeVCFunctionName(project: project, vcClass: className)
        return generateViewController(vc: vc, funcName: funcName, className: className, storyboard: storyboard)
    }

    private func generateViewController(project: XCProject, vcs: [XCViewController]) -> String {
        guard let className = getClassName(vc: vcs.first!) else { return "" }
        var storyboardsMap = [String: [XCViewController]]()
        for vc in vcs {
            guard let storyboard = vc.storyboard else { continue }
            var array = storyboardsMap[storyboard.docName] ?? []
            array.append(vc)
            storyboardsMap[storyboard.docName] = array
        }
        let keys = Array(storyboardsMap.keys).sorted()
        var result = ""
        for key in keys {
            guard let objects = storyboardsMap[key] else { continue }
            if objects.count == 1, let vc = objects.first {
                let funcName = makeVCFunctionName(project: project, vcClass: className) + "FromStoryboard" + vc.storyboard!.docName
                result += generateViewController(vc: vc, funcName: funcName, className: className, storyboard: vc.storyboard!)
            } else {
                let sortedObjects = objects.sorted(by: { (left, right) -> Bool in
                    if let idLeft = left.storyboardIdentifier, let idRight = right.storyboardIdentifier {
                        return idLeft.compare(idRight) == .orderedAscending
                    } else if left.storyboardIdentifier != nil {
                        return false
                    }
                    return true
                })
                for vc in sortedObjects {
                    let funcName: String
                    if let identifier = vc.storyboardIdentifier {
                        var idName = identifier.replacingOccurrences(of: " ", with: "")
                        idName = String(idName[idName.startIndex]).uppercased() + String(idName[idName.index(after: idName.startIndex)...])
                        funcName = makeVCFunctionName(project: project, vcClass: className) + idName + "FromStoryboard" + vc.storyboard!.docName
                    } else {
                        funcName = makeVCFunctionName(project: project, vcClass: className) + "FromStoryboard" + vc.storyboard!.docName
                    }
                    result += generateViewController(vc: vc, funcName: funcName, className: className, storyboard: vc.storyboard!)
                }
            }
        }
        return result
    }

    private func generateViewControllers(project: XCProject, resources: [String: [XCViewController]]) -> String {
        var result = ""
        let keys = Array(resources.keys).sorted()
        for key in keys {
            guard let objects = resources[key] else { continue }
            if objects.count == 1, let vc = objects.first {
                result += generateViewController(project: project, vc: vc)
            } else {
                result += generateViewController(project: project, vcs: objects)
            }
        }
        return result
    }

    private func generateEnum(name: String, values: Any) -> String {
        let indent1 = indent(1)
        let indent2 = indent(2)
        var data: [(String, String?)] = []
        if let array = values as? [String] {
            let arr = array.sorted()
            for s in arr {
                data.append((s, nil))
            }
        } else if let array = values as? [(String, String?)] {
            data = array.sorted(by: { (left, right) -> Bool in
                return left.0.compare(right.0) == .orderedAscending
            })
        }
        var result = ""
        if data.count > 0 {
            result += indent1 + "enum \(name): String {\n\n"
            for (value, customClass) in data {
                let vName = makeFuncVarName(value)
                if let cls = customClass {
                    result += indent2 + "/// " + cls + "\n"
                }
                result += indent2 + "case " + vName
                if vName != value {
                    result += " = \"\(value)\""
                }
                result += "\n"
            }
            result += "\n"
            result += indent1 + "}\n\n"
        }
        return result
    }

    private func generateConstants(project: XCProject, storyboards: [XCStoryboard]) -> String {
        var resources = [String: [XCViewController]]()
        for storyboard in storyboards {
            if let scenes = storyboard.scenes {
                for scene in scenes {
                    if let objects = scene.objects {
                        for obj in objects {
                            if let vc = obj as? XCViewController, let name = vc.customClass {
                                var array = resources[name] ?? []
                                array.append(vc)
                                resources[name] = array
                            }
                        }
                    }
                }
            }
        }
        var result = ""
        let indent1 = indent(1)
        let indent2 = indent(2)
        let indent3 = indent(3)
        var segues = [String: [String]]()
        var tableCellIds = [String: [(String, String?)]]()
        var collectionCellIds = [String: [(String, String?)]]()
        var allKeys = [String]()
        for (_, objects) in resources {
            for vc in objects {
                if let key = vc.customClass {
                    if !allKeys.contains(key) {
                        allKeys.append(key)
                    }
                    var seguesArray = segues[key] ?? []
                    seguesArray.append(contentsOf: vc.segues)
                    segues[key] = seguesArray
                    var tableCellsArray = tableCellIds[key] ?? []
                    tableCellsArray.append(contentsOf: vc.tableCells)
                    tableCellIds[key] = tableCellsArray
                    var collectionCellsArray = collectionCellIds[key] ?? []
                    collectionCellsArray.append(contentsOf: vc.collectionCells)
                    collectionCellIds[key] = collectionCellsArray
                }
            }
        }
        allKeys.sort()
        var cnt = 0
        for key in allKeys {
            let seguesArray = segues[key] ?? []
            let tableCellsArray = tableCellIds[key] ?? []
            let collectionCellsArray = collectionCellIds[key] ?? []
            if seguesArray.count > 0 || tableCellsArray.count > 0 || collectionCellsArray.count > 0 {
                cnt += 1
                result += "extension \(key) {\n\n"
                result += generateEnum(name: "SegueIdentifier", values: seguesArray)
                result += generateEnum(name: "TableCellIdentifier", values: tableCellsArray)
                result += generateEnum(name: "CollectionCellIdentifer", values: collectionCellsArray)

                if tableCellsArray.count > 0 {
                    for (cellId, customClass) in tableCellsArray {
                        guard let cls = customClass else { continue }
                        result += indent1 + "func getTableCellView\(makeKeyword(cellId))(_ tableView: UITableView) -> \(cls) {\n"
                        result += indent2 + "if let cell = tableView.dequeueReusableCell(withIdentifier: TableCellIdentifier.\(makeFuncVarName(cellId)).rawValue) as? \(cls) {\n"
                        result += indent3 + "return cell\n"
                        result += indent2 + "}\n"
                        result += indent2 + "fatalError(\"DEVELOP ERROR: Fail to dequeue cell \\\"\(cls)\\\" with identifier \\\"\(cellId)\\\"\")\n"
                        result += indent1 + "}\n\n"
                    }
                }

                if collectionCellsArray.count > 0 {
                    for (cellId, customClass) in collectionCellsArray {
                        guard let cls = customClass else { continue }
                        result += indent1 + "func getCollectionCellView\(makeKeyword(cellId))(collectionView: UICollectionView, indexPath: IndexPath) -> \(cls) {\n"
                        result += indent2 + "if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionCellIdentifer.\(makeFuncVarName(cellId)).rawValue, for: indexPath) as? \(cls) {\n"
                        result += indent3 + "return cell\n"
                        result += indent2 + "}\n"
                        result += indent2 + "fatalError(\"DEVELOP ERROR: Fail to dequeue cell \\\"\(cls)\\\" with identifier \\\"\(cellId)\\\" for IndexPath \\(indexPath.section)-\\(indexPath.row)\")\n"
                        result += indent1 + "}\n\n"
                    }
                }

                result += "}\n\n"
            }
        }
        if cnt > 0 {
            result = "\n" + result[result.startIndex..<result.index(before: result.endIndex)]
        }
        return result
    }

    private func generateContent(project: XCProject, storyboards: [XCStoryboard], xibs: [XCXib], classesMap: [String: [XCViewController]],
                                 launchScreenStoryboard: String?, isAvKitAvailable: Bool) -> Error? {
        let fullOutputPath = checkOutputFile(project: project, output: output)
        var content = project.getHeader(output) + "\nimport UIKit\n"
        if isAvKitAvailable {
            content += "import AVKit\n"
        }
        content += "\n"
        content += generateCommonFunc(xibEnum: xibs.count > 0 ? (project.prefix ?? "") + "Xib" : nil)
        content += generateEnums(project: project, storyboards: storyboards, xibs: xibs, launchScreenStoryboard: launchScreenStoryboard)
        if storyboards.count > 0 {
            content += generateViewControllers(project: project, resources: classesMap)
            content += "}\n"
        }
        content += generateConstants(project: project, storyboards: storyboards)
        let (error, change) = writeOutput(project: project, content: content, fullPath: fullOutputPath)
        if !change {
            printLog(.outputNotChange())
        }
        return error
    }

    private func findRow(xmlLine: String) -> UInt {
        var row: UInt = 0
        if let range = xmlLine.range(of: "<") {
            row = UInt(xmlLine.distance(from: xmlLine.startIndex, to: range.lowerBound))
        }
        return row + 1
    }

    private func findLine(cache: inout [String: String], storyboard: XCStoryboard, vc: XCViewController, object: XCViewController.Object?) -> (UInt, UInt) {
        let content: String
        if let data = cache[storyboard.path] {
            content = data
        } else if let str = try? String(contentsOfFile: storyboard.path) {
            content = str
            cache[storyboard.path] = str
        } else {
            return (0, 0)
        }
        let lines = content.components(separatedBy: CharacterSet.newlines)
        var isFoundVC = false
        var lineIndex: UInt = 0
        for line in lines {
            let oneLine = line.trimmingCharacters(in: CharacterSet.whitespaces)
            if !isFoundVC {
                isFoundVC = vc.isMyXMLLine(oneLine)
            } else if let obj = object {
                if obj.isMyXMLLineId(oneLine) {
                    return (lineIndex + 1, findRow(xmlLine: line))
                }
            } else {
                return (lineIndex, findRow(xmlLine: line))
            }
            lineIndex += 1
        }
        return (0, 0)
    }

    private func validatePlaceHolderVC(vc: XCViewController, storyboards: [XCStoryboard], cache: inout [String: String]) {
        if let originalStoryboard = vc.storyboard, let storyboardName = vc.attributes["storyboardName"] {
            var destStoryboard: XCStoryboard?
            for storyboard in storyboards where storyboard !== originalStoryboard && storyboard.docName == storyboardName {
                destStoryboard = storyboard
                break
            }
            if let dStoryboard = destStoryboard {
                if let refVCIdentifier = vc.attributes["referencedIdentifier"] {
                    if dStoryboard.findViewController(storyboardId: refVCIdentifier) == nil {
                        let loc = findLine(cache: &cache, storyboard: originalStoryboard, vc: vc, object: nil)
                        printLog(.placeHolderVCDestinationVCNotFound(destName: refVCIdentifier, destStroyboard: dStoryboard.docName, file: originalStoryboard.path, row: loc.1, column: loc.0))
                    }
                } else if dStoryboard.initialVC == nil {
                    let loc = findLine(cache: &cache, storyboard: originalStoryboard, vc: vc, object: nil)
                    printLog(.placeHolderVCDestinationInitialVCNotFound(destName: dStoryboard.docName, file: originalStoryboard.path, row: loc.1, column: loc.0))
                }
            } else {
                let loc = findLine(cache: &cache, storyboard: originalStoryboard, vc: vc, object: nil)
                printLog(.placeHolderVCDestinationStoryboardNotFound(destName: storyboardName, file: originalStoryboard.path, row: loc.1, column: loc.0))
            }
        }
    }

    private func validateStoryboards(_ storyboards: [XCStoryboard]) {
        var cache = [String: String]()
        for storyboard in storyboards {
            if let scenes = storyboard.scenes {
                for scene in scenes {
                    if let objects = scene.objects {
                        for obj in objects {
                            if let vc = obj as? XCViewController {
                                let invalidObjs = vc.validateDestinations()
                                for invObj in invalidObjs {
                                    let position = findLine(cache: &cache, storyboard: storyboard, vc: vc, object: invObj)
                                    var vcName = vc.customClass ?? (scene.comment ?? vc.type)
                                    if let objPName = invObj.parentName {
                                        vcName += "'.'UI" + String(objPName[objPName.startIndex]).uppercased() + String(objPName[objPName.index(after: objPName.startIndex)...])
                                    }
                                    if invObj.name == "outlet" {
                                        printLog(.invalidOutlet(propName: invObj.attributes["property"] ?? "",
                                                                vcName: vcName, file: storyboard.path,
                                                                row: position.1, column: position.0))
                                    } else {
                                        printLog(.invalidStoryboardItem(item: invObj.name, vcName: vcName,
                                                                        file: storyboard.path,
                                                                        row: position.1, column: position.0))
                                    }
                                }
                                if vc.type == XCViewController.ViewControllerType.placeholder.rawValue {
                                    validatePlaceHolderVC(vc: vc, storyboards: storyboards, cache: &cache)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func append(object: XCViewController, for key: String, storage: inout [String: [XCViewController]]) {
        var array = storage[key] ?? []
        array.append(object)
        storage[key] = array
    }

    override func run(_ project: XCProject) -> Error? {
        _ = super.run(project)
        let launchScreenStoryboard = env.infoDict?["UILaunchStoryboardName"] as? String
        let resources = project.getCopyResourcesFiles(types: [.storyboard, .xib])
        var storyboards = [XCStoryboard]()
        var xibs = [XCXib]()
        var viewClasses = [String: [XCViewController]]()
        var isAvKit = false
        for (type, items) in resources {
            switch type {
            case .storyboard:
                for item in items {
                    if let storyboard = XCStoryboard(item) {
                        storyboard.generateNames(prefix: project.prefix)
                        if let launchStoryboard = launchScreenStoryboard, storyboard.docName == launchStoryboard {
                            continue
                        }
                        printLog(.found(storyboard.docName))
                        storyboards.append(storyboard)
                        if let scenes = storyboard.scenes {
                            for scene in scenes {
                                if let objects = scene.objects {
                                    for obj in objects {
                                        if let vc = obj as? XCViewController, vc.isInitial || vc.storyboardIdentifier != nil,
                                            vc.type != XCViewController.ViewControllerType.placeholder.rawValue {
                                            if vc.type == XCViewController.ViewControllerType.avPlayerViewController.rawValue {
                                                isAvKit = true
                                            }
                                            if let customClass = vc.customClass {
                                                append(object: vc, for: customClass, storage: &viewClasses)
                                            } else {
                                                append(object: vc, for: vc.type, storage: &viewClasses)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            case .xib:
                for item in items {
                    if let xib = XCXib(item) {
                        xib.generateNames(prefix: project.prefix)
                        printLog(.found(xib.docName))
                        xibs.append(xib)
                    }
                }
            default:
                break
            }
        }

        storyboards.sort { (left, right) -> Bool in
            return left.enumName < right.enumName
        }
        xibs.sort { (left, right) -> Bool in
            return left.enumName < right.enumName
        }

        let result = generateContent(project: project, storyboards: storyboards, xibs: xibs,
                                     classesMap: viewClasses, launchScreenStoryboard: launchScreenStoryboard,
                                     isAvKitAvailable: isAvKit)
        validateStoryboards(storyboards)
        return result
    }

}
