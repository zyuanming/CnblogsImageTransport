//
//  ViewController.swift
//  cnblogs
//
//  Created by Zhang Yuanming on 11/4/17.
//  Copyright © 2017 None. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var imageNamesTemp: [String: Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let pathURL = Bundle.main.resourceURL!.appendingPathComponent("Blogs")

        let fileManager = FileManager.default
        let keys = [URLResourceKey.isDirectoryKey, URLResourceKey.localizedNameKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsSubdirectoryDescendants, .skipsHiddenFiles]

        let enumerator = fileManager.enumerator(
            at: pathURL,
            includingPropertiesForKeys: keys,
            options: options,
            errorHandler: {(url, error) -> Bool in
                return true
        })

        if enumerator != nil {
            while let file = enumerator!.nextObject() {
                let abstring = (file as! URL).absoluteString
                let path = URL(fileURLWithPath: abstring, relativeTo: pathURL)
                if path.path.hasSuffix(".md") {
                    let content = try! String(contentsOf: file as! URL)
                    var newContent = content
                    let imgs = content.regex(regex: "(http[^\\s]+(jpg|jpeg|png|tiff)\\b)")
                    let blogName = path.lastPathComponent.removingPercentEncoding!
                    let monthAndDay = getImageMonthAndDay(file: file as! URL)
                    let year = getImageYear(file: file as! URL)

                    createDirectory(name: year)
                    for imgStr in imgs {
                        let currentIndex = getImageIndex(monthAndDay: monthAndDay, year: year)

                        let imageNewName = "\(monthAndDay)-\(currentIndex)"
                        imageNamesTemp["\(year)-\(monthAndDay)"] = currentIndex

                        let imageType = URL(string: imgStr)!.pathExtension
                        let imageData = try! Data(contentsOf: URL(string: imgStr)!)
                        saveImage(imageData, directory: year, name: imageNewName, type: imageType)
                        let newName = "/assets/images/\(year)/\(imageNewName).\(imageType)"
                        newContent = newContent.replacingOccurrences(of: imgStr, with: newName)
                    }

                    saveContent(name: blogName, content: newContent)
                }
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func saveContent(name: String, content: String) {
        let path = NSHomeDirectory().appending("/Documents/blogs/")
        try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)

        let blogPath = NSHomeDirectory().appending("/Documents/blogs/\(name)")
        try! content.write(toFile: blogPath, atomically: true, encoding: .utf8)
    }

    private func createDirectory(name: String) {
        let path = NSHomeDirectory().appending("/Documents/images/\(name)/")
        try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }

    private func saveImage(_ data: Data, directory: String, name: String, type: String) {
        let path = NSHomeDirectory().appending("/Documents/images/\(directory)/\(name).\(type)")
        try! data.write(to: URL(fileURLWithPath: path))
    }

    private func getImageYear(file: URL) -> String {
        let fileName = file.pathComponents.last!
//        return fileName.substring(to: fileName.index(fileName.startIndex, offsetBy: 4))
        let startIndex = fileName.index(fileName.startIndex, offsetBy: 4)
        return String(fileName[startIndex...])
    }

    private func getImageMonthAndDay(file: URL) -> String {
        let fileName = file.pathComponents.last!
        let startIndex = fileName.index(fileName.startIndex, offsetBy: 5)
        let endIndex = fileName.index(fileName.startIndex, offsetBy: 10)
        let range = startIndex..<endIndex
//        return fileName.substring(with: range)
        return String(fileName[range])
    }

    private func getImageIndex(monthAndDay: String, year: String) -> Int {
        if let oldIndex = imageNamesTemp["\(year)-\(monthAndDay)"] {
            return oldIndex + 1
        } else {
            return 1
        }
    }

}


extension String {
    func regex(regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}





