//
//  Natrium.swift
//  CommandLineKit
//
//  Created by Bas van Kuijck on 20/10/2017.
//

import Foundation
import XcodeEdit
import Yaml
import Francium

class Natrium {
    static var version: String = "8.4.0"

    let projectDirPath: String
    let targetName: String
    let configuration: String
    let environment: String
    let dryRun: Bool

    var yamlFile: String {
        return "\(projectDirPath)/.natrium.yml"
    }

    init(projectDirPath: String, targetName: String, configuration: String, environment: String, dryRun: Bool = false) {
        self.projectDirPath = projectDirPath
        self.targetName = targetName
        self.configuration = configuration
        self.environment = environment
        self.dryRun = dryRun
    }

    func run() {
        Logger.clearLogFile()
        
        Logger.log(Logger.colorWrap(text: "Running Natrium installer (v\(Natrium.version))", in: "1"))
        Logger.log("")

        Logger.info("Configuration:")
        Logger.log(" - Project path: \(projectDirPath)")
        Logger.log(" - Working directory: \(FileManager.default.currentDirectoryPath)")
        Logger.log(" - CocoaPods: \(isCocoaPods)")
        Logger.log(" - Target name: \(targetName)")
        Logger.log(" - Configuration: \(configuration)")
        Logger.log(" - Environment: \(environment)")
        Logger.info("")

        do {
            try preconditionChecks()

            let xcodeTarget = try _getXcodeProjectTarget()
            let infoPlistPath = try _getInfoPlistFile(from: xcodeTarget)
            let configurations = _getXcodeConfigurations(from: xcodeTarget)
            let buildSettings = _getBuildSettings(from: xcodeTarget, configuration: configuration)
            
            Logger.info("Project configuration:")
            Logger.log(" - Xcode target name: \(xcodeTarget.name)")
            Logger.log(" - Info.plist path: \(infoPlistPath)")
            Logger.log(" - Build configurations: \(configurations.joined(separator: ", "))")
            Logger.info("")
            Logger.info("Parsing \(yamlFile)...")
            let parser = NatriumParser(natrium: self, infoPlistPath: infoPlistPath, configurations: configurations, buildSettings: buildSettings)
            try parser.run()

        } catch let error {
            Logger.fatalError("\(error)")
        }
    }

    func preconditionChecks() throws {
        if !File(path: yamlFile).isExisting {
            throw NatriumError("Cannot find \(yamlFile)")
        }
    }
}

extension Natrium {
    /// Get the Xcode project
    ///
    /// - throws:
    ///   - Not able to find a project in the specific `projectDirPath`s
    ///   - Cannot find a target with the name `targetName`
    ///
    /// - returns: `PBXNativeTarget`
    fileprivate func _getXcodeProjectTarget() throws -> PBXNativeTarget {
        guard let xcodeProjectPath = Dir(path: projectDirPath).glob("*.xcodeproj").first?.path else {
            throw NatriumError("Cannot find xcodeproj in folder '\(projectDirPath)'")
        }
        let xcodeproj = URL(fileURLWithPath: xcodeProjectPath)
        let xcProjectFile = try XCProjectFile(xcodeprojURL: xcodeproj)
        guard let target = xcProjectFile.project.targets.first(where: { $0.name == self.targetName }) else {
            throw NatriumError("Cannot find target '\(targetName)' in '\(xcodeProjectPath)'")
        }

        return target
    }

    /// Get the build configurations available for a specific xcode target
    ///
    /// - parameters:
    ///   - xcTarget: `PBXNativeTarget` The Xcode target retrieved from `_getXcodeProjectTarget()`
    ///
    /// - returns: `[String]` An array of build configuration names
    fileprivate func _getXcodeConfigurations(from xcTarget: PBXNativeTarget) -> [String] {
        return xcTarget.buildConfigurationList.buildConfigurations.map { $0.name }
    }

    fileprivate func _getBuildSettings(from xcTarget: PBXNativeTarget, configuration: String) -> [String: Any]? {
        return xcTarget.buildConfigurationList.buildConfigurations.first { $0.name == configuration }?.buildSettings
    }

    /// Get the Info.plist file location for a specific Xcode Target
    ///
    /// - parameters:
    ///   - xcTarget: `PBXNativeTarget` The Xcode target retrieved from `_getXcodeProjectTarget()`
    ///
    /// - throws:
    ///   - Not able to find a specific confifuration with the name `configuration`
    ///   - Cannot find the INFOPLIST_FILE key in the Info.plist file
    ///   - The actual Info.plist file does not exist at the INFOPLIST_FILE location
    ///
    /// - returns: `String`. The absolute file location of the Info.plist file
    fileprivate func _getInfoPlistFile(from xcTarget: PBXNativeTarget) throws -> String {
        guard let buildConfiguration = xcTarget.buildConfigurationList.buildConfigurations.first(where: { $0.name == self.configuration }) else {
            throw NatriumError("Cannot find configuration '\(configuration)' in '\(xcTarget.name)'")
        }

        guard let infoPlist = buildConfiguration.buildSettings?["INFOPLIST_FILE"] as? String else {
            throw NatriumError("Cannot find INFOPLIST_FILE in '\(xcTarget.name)'")
        }

        let infoPlistPath = _replaceSettingsReferences(infoPlist)

        if !File(path: infoPlistPath).isExisting {
            throw NatriumError("Cannot find \(String(describing: infoPlistPath))")
        }

        return infoPlistPath
    }

    /// This would replace xcode specific variables (like SCROOT)
    ///
    /// - parameters:
    ///   - string: `Stringa` Actual string
    ///
    /// - returns: `String`
    private func _replaceSettingsReferences(_ string: String) -> String {
        let mapping = [
            "SRCROOT": projectDirPath,
            "PROJECT_DIR": projectDirPath
        ]

        var string = string
        for (key, value) in mapping {
            string = string
                .replacingOccurrences(of: "$(\(key))", with: value)
                .replacingOccurrences(of: "${\(key)}", with: value)
                .replacingOccurrences(of: "$\(key)", with: value)
        }
        if !string.hasPrefix(projectDirPath) {
            string = "\(projectDirPath)/\(string)"
        }
        return string
    }
}
