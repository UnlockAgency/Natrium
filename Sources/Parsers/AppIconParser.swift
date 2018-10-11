//
//  AppIconParser.swift
//  CommandLineKit
//
//  Created by Bas van Kuijck on 20/10/2017.
//

import Foundation
import Yaml
import AppKit
import Francium

class AppIconParser: Parser {
    let natrium: Natrium
    var isRequired: Bool {
        return false
    }
    fileprivate var appIconSet: String!
    fileprivate var original: String!
    fileprivate var ribbon: String!
    fileprivate var idioms: [String] = []
    fileprivate let tmpFile = "tmp_file.png"

    var yamlKey: String {
        return "appicon"
    }

    required init(natrium: Natrium) {
        self.natrium = natrium
    }

    func parse(_ yaml: [NatriumKey: Yaml]) {
        for object in yaml {
            switch object.key.string {
            case "appiconset":
                appIconSet = object.value.stringValue
            case "idioms":
                if let array = object.value.array {
                    idioms = array.compactMap { $0.string }
                } else if let string = object.value.string {
                    idioms = string.components(separatedBy: ",")
                }
            case "original":
                original = object.value.string

            case "ribbon":
                ribbon = object.value.string

            default:
                Logger.warning("Invalid key: '\(object.key.string)'")
            }
        }
        if appIconSet == nil {
            Logger.fatalError("Missing 'appiconset' in [appicon]")

        } else {
            appIconSet = Dir(path: natrium.projectDir + "/" + appIconSet!).absolutePath
            if !File(path: appIconSet).isExisting {
                Logger.fatalError("Cannot find app icon set \(appIconSet!)")
            }
        }

        if original == nil {
            Logger.fatalError("Missing 'original' in [appicon]")
        } else {
            original = Dir(path: natrium.projectDir + "/" + original!).absolutePath
            if !File(path: original).isExisting {
                Logger.fatalError("Cannot find original \(original!)")
            }
        }

        if ribbon == nil {
            Logger.fatalError("Missing 'ribbon' in [appicon]")
        }
        _runIdioms()
    }

    private func _runIdioms() {
        if idioms.isEmpty {
            idioms = [ "iphone" ]
        }

        if idioms.contains("iphone") || idioms.contains("ipad") {
            idioms.append("ios-marketing")
        }

        let availableIdioms = [ "iphone", "ipad", "ios-marketing", "mac", "watch" ]
        for idiom in idioms {
            if !availableIdioms.contains(idiom) {
                Logger.warning("Invalid idiom: '\(idiom)'")
            }
        }

        natrium.lock.appIconPath = original
        if !natrium.lock.needsAppIconUpdate {
            Logger.warning("No app-icon update needed")
            return
        }
        
        _run()
    }

    fileprivate typealias AssetValue = (Double, [Int], [String: String]?)

    fileprivate func _getAssets() -> [String: [AssetValue]] {
        return [
            "iphone": [
                (29, [2, 3], nil),
                (40, [2, 3], nil),
                (60, [2, 3], nil),
                (20, [2, 3], nil)
            ],
            "ipad": [
                (29, [1, 2], nil),
                (40, [1, 2], nil),
                (76, [1, 2], nil),
                (83.5, [2], nil),
                (20, [1, 2], nil)
            ],
            "car": [
                (60, [2, 3], nil)
            ],
            "ios-marketing": [
                (1024, [1], nil)
            ],
            "watch": [
                (24, [2], [ "subtype": "38mm", "role": "notificationCenter" ]),
                (27.5, [2], [ "subtype": "42mm", "role": "notificationCenter" ]),
                (29, [2, 3], [ "role": "companionSettings" ]),
                (40, [2], [ "subtype": "38mm", "rol": "appLauncher" ]),
                (86, [2], [ "subtype": "38mm", "rol": "quickLook" ]),
                (98, [2], [ "subtype": "42mm", "rol": "quickLook" ])
            ],
            "mac": [
                (16, [1, 2], nil),
                (32, [1, 2], nil),
                (128, [1, 2], nil),
                (256, [1, 2], nil),
                (512, [1, 2], nil)
            ]
        ]
    }

    private func _createRibbonLabel() -> NSTextField {
        let ribbonLabel = NSTextField()
        ribbonLabel.isBezeled = false
        ribbonLabel.isEditable = false
        ribbonLabel.isSelectable = false
        ribbonLabel.drawsBackground = false
        ribbonLabel.textColor = NSColor.white
        ribbonLabel.alignment = .center
        return ribbonLabel
    }

    fileprivate func _run() {
        try? Dir(path: appIconSet).empty(recursively: true)

        let assets: [String: [AssetValue]] = _getAssets()

        var images: [[String: String]] = []
        let maxSize: CGFloat = 1024

        guard var image = NSImage(contentsOfFile: original!) else {
            return
        }

        let frame = NSRect(x: 0, y: 0, width: maxSize, height: maxSize)
        let imageView = NSImageView(frame: frame)
        imageView.layer = CALayer()
        imageView.layer?.contentsGravity = .resize
        imageView.layer?.contents = image

        if ribbon != nil && !ribbon.isEmpty {
            let containerView = NSView(frame: frame)
            containerView.addSubview(imageView)
            let ribbonHeight = maxSize / 5
            let ribbonFrame = NSRect(x: 0, y: 0, width: maxSize, height: ribbonHeight)

            let ribbonView = NSView(frame: ribbonFrame)
            ribbonView.wantsLayer = true
            ribbonView.layer?.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.5).cgColor
            containerView.addSubview(ribbonView)

            let ribbonLabel = _createRibbonLabel()
            ribbonLabel.frame = NSRect(x: 0, y: 0, width: maxSize, height: ribbonHeight - 20)
            ribbonLabel.font = NSFont.systemFont(ofSize: maxSize / 7.5)
            ribbonLabel.stringValue = ribbon!
            ribbonView.addSubview(ribbonLabel)

            if let captureImage = containerView.capturedImage() {
                image = captureImage
            }
        }

        Logger.info("Generating icons:")
        Logger.insets += 1
        let idiomAssets = assets.filter { idioms.contains($0.key) }
        for asset in idiomAssets {
            for assetValue in asset.value {
                for scale in assetValue.1 {
                    images.append(_createAsset(originalImage: image,
                                               idiom: asset.key,
                                               size: assetValue.0,
                                               scale: scale,
                                               additional: assetValue.2))
                }
            }
        }
        _generateContentsJSON(images: images)
    }

    private func _generateContentsJSON(images: [[String: String]]) {
        let json: [String: Any] = [
            "images": images,
            "info": [
                "author": "xcode",
                "version": 1
            ],
            "properties": [
                "pre-rendered": true
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
            let jsonString = String(data: data, encoding: .utf8) else {
                return
        }

        let filePath = "\(appIconSet!)/Contents.json"
        do {
            let file = File(path: filePath)
            if file.isExisting {
                file.chmod(0o7777)
            }
            try file.write(string: jsonString)

        } catch { }
    }
    
    fileprivate func _createAsset(originalImage: NSImage,
                                  idiom: String,
                                  size: Double,
                                  scale: Int,
                                  additional: [String: String]?) -> [String: String] {
        
        var rSizeString = "\(size)"
        if Double(Int(size)) == size {
            rSizeString = "\(Int(size))"
        }
        var sizeString = "\(rSizeString)x\(rSizeString)"
        var filename = "\(rSizeString)@x\(scale).png"
        if scale == 1 {
            filename = "\(rSizeString).png"
        }
        var dic = [
            "filename": filename,
            "size": sizeString,
            "idiom": idiom,
            "scale": "\(scale)x"
        ]

        for assetValue in (additional ?? [:]) {
            dic[assetValue.key] = assetValue.value
        }

        rSizeString = "\(size * Double(scale))"
        if Double(Int(size)) == size {
            rSizeString = "\(Int(size) * scale)"
        }
        sizeString = "\(rSizeString)x\(rSizeString)"
        let widhtHeight = CGFloat(size * Double(scale))
        Logger.log("\(sizeString) ▸ \(filename)")

        let image = originalImage.resize(to: CGSize(width: widhtHeight, height: widhtHeight))
        image.writePNG(toFilePath: "\(appIconSet!)/\(filename)")

        return dic
    }
}
