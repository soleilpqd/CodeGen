//
//  XCValidator.swift
//  CodeGen
//
//  Created by DươngPQ on 24/04/2018.
//  Copyright © 2018 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

class XCValidator {

    static let shared = XCValidator()

    var projectFile: XCProject?

    var shouldCheckImageUsage = false

    private var usageKeywords = [String: [String]]()
    private var imageNames = [String: [(String, Int, Int)]]()

    func addKeywordForCheckUsage(category: String, keyword: String) {
        var keywords = usageKeywords[category] ?? []
        if !keywords.contains(keyword) {
            keywords.append(keyword)
            usageKeywords[category] = keywords
        }
    }

    func removeKeywordForCheckUsage(category: String, keyword: String) {
        guard var keywords = usageKeywords[category] else { return }
        var index = 0
        for kwd in keywords {
            if kwd == keyword {
                keywords.remove(at: index)
                usageKeywords[category] = keywords
                break
            }
            index += 1
        }
    }

    static func checkUsageUsingRegex(pattern: String, content: String, commentRanges: [NSRange]) -> Bool {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            var count = 0
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
            for item in matches where XCValidator.checkRangeInCommentedRange(range: item.range, commentRanges: commentRanges) {
                count += 1
            }
            return count > 0
        }
        return false
    }

    // Return true if given range is not inside commented ranges
    static private func checkRangeInCommentedRange(range: NSRange, commentRanges: [NSRange]) -> Bool {
        var isValid = true
        for cmtRange in commentRanges {
            if range.location >= cmtRange.location && range.location < cmtRange.location + cmtRange.length {
                isValid = false
                break
            }
        }
        return isValid
    }

    private func collectImageNameWithRegex(_ pattern: String, file: String, content: String, offset: Int, commentsRange: [NSRange]) {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
            for item in matches where XCValidator.checkRangeInCommentedRange(range: item.range, commentRanges: commentsRange) {
                var word = (content as NSString).substring(with: NSMakeRange(item.range.location + offset, item.range.length - offset - 2))
                if word.lowercased().hasSuffix(".jpg") || word.lowercased().hasSuffix(".png") {
                    word = (word as NSString).deletingPathExtension
                }
                let preResult = (content as NSString).substring(to: item.range.location)
                let components = preResult.components(separatedBy: CharacterSet.newlines)
                let row = components.count
                let column = components.last?.count ?? 0
                var array = imageNames[word] ?? []
                array.append((file, row, column))
                imageNames[word] = array
            }
        }
    }

    private func collectImageName(content: String, file: String, commentsRange: [NSRange]) {
        collectImageNameWithRegex("#imageLiteral\\(resourceName: \\\".+\\\"\\)", file: file, content: content, offset: 29, commentsRange: commentsRange)
        collectImageNameWithRegex("UIImage\\(named: \\\".+\\\"\\)", file: file, content: content, offset: 16, commentsRange: commentsRange)
    }

    static private func getCommentedRanges(content: String, pattern: String, store: inout [NSRange]) {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
            for item in matches {
                store.append(item.range)
            }
        }
    }

    static func commentedRanges(_ content: String) -> [NSRange] {
        var result = [NSRange]()
        getCommentedRanges(content: content, pattern: "\\/\\/.*\\n", store: &result)
        getCommentedRanges(content: content, pattern: "\\/\\*.*\\*\\/", store: &result)
        return result
    }

    func checkUsageInSwiftFiles() {
        guard let project = projectFile else { return }
        let sources = project.getSwiftFiles()
        for path in sources {
            guard let content = try? String(contentsOfFile: path) else { continue }
            let comments = XCValidator.commentedRanges(content)
            for (category, keywords) in usageKeywords {
                var tmpKeywords = keywords
                for keyword in keywords {
                    let pattern = "\\.\(keyword)(.|\\n|\\)|\\]|\\})?"
                    if XCValidator.checkUsageUsingRegex(pattern: pattern, content: content, commentRanges: comments) {
                        var index = 0
                        for item in tmpKeywords {
                            if item == keyword {
                                tmpKeywords.remove(at: index)
                                break
                            }
                            index += 1
                        }
                    }
                }
                usageKeywords[category] = tmpKeywords
            }
            collectImageName(content: content, file: path, commentsRange: comments)
        }
        for (category, keywords) in usageKeywords where keywords.count > 0 {
            var list = ""
            for kwd in keywords {
                list += "\(kwd), "
            }
            list = cropTail(input: list, length: 2)
            print(String.notUsed(list, category))
        }
    }

    private func getAssetsImage(folder: XCAssetFoler, store: inout [XCAssetImage]) {
        if let children = folder.children {
            for child in children {
                if let subFolder = child as? XCAssetFoler {
                    getAssetsImage(folder: subFolder, store: &store)
                } else if let image = child as? XCAssetImage {
                    store.append(image)
                }
            }
        }
    }

    func checkImagesUsage() -> Bool {
        if !shouldCheckImageUsage { return true }
        guard let project = projectFile else { return true }
        let copiedResources = project.getCopyResourcesFiles(types: [.assets, .png, .jpg])
        var assetsImages = [XCAssetImage]()
        var fileImages = [String: String]()
        var allAssets = [XCAssets]() // keep assets alive
        for (key, values) in copiedResources {
            switch key {
            case .assets:
                for path in values {
                    if let fItem = project.getItem(with: path) as? XCFileReference {
                        let assets = XCAssets(fileReference: fItem, path: path)
                        allAssets.append(assets)
                        getAssetsImage(folder: assets, store: &assetsImages)
                    }
                }
            case .png, .jpg:
                for path in values {
                    fileImages[((path as NSString).lastPathComponent as NSString).deletingPathExtension] = path
                }
            default:
                break
            }
        }

        let removeArrayItem: (String, inout [String]) -> Void = { (item, array) in
            var index = 0
            var found = true
            for itm in array {
                if item == itm {
                    found = true
                    break
                }
                index += 1
            }
            if found {
                array.remove(at: index)
            }
        }

        var notFoundImages = Array(imageNames.keys)
        var notUsedFileImages = Array(fileImages.keys)
        var notUsedAssetsImages = assetsImages
        for (name, _) in imageNames {
            for (fileImage, _) in fileImages where name == fileImage {
                removeArrayItem(name, &notFoundImages)
                removeArrayItem(name, &notUsedFileImages)
            }
            for assetsImage in assetsImages where assetsImage.name == name {
                removeArrayItem(name, &notFoundImages)
                var index = 0
                var found = true
                for itm in notUsedAssetsImages {
                    if assetsImage === itm {
                        found = true
                        break
                    }
                    index += 1
                }
                if found {
                    notUsedAssetsImages.remove(at: index)
                }
            }
        }
        for item in notUsedFileImages {
            if let path = fileImages[item] {
                print(String.imageNotUsed(path))
            }
        }
        for item in notUsedAssetsImages {
            if let _ = item as? XCAssetAppIcon {
                continue
            }
            var tmp = item.parent
            while tmp != nil {
                if let _ = tmp as? XCAssets {
                    break
                }
                tmp = tmp?.parent
            }
            if let assets = tmp as? XCAssets {
                print(String.notUsed(item.name, assets.name + ".xcassets"))
            }
        }
        for item in notFoundImages {
            if let positions = imageNames[item] {
                for (file, row, column) in positions {
                    print(String.imageNotFound(str: item, file: file, row: row, column: column))
                }
            }
        }
        return notFoundImages.count == 0
    }
    

}
