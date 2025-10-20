//
//  NatriumParser.swift
//  CommandLineKit
//
//  Created by Bas van Kuijck on 16/01/2019.
//

import Foundation
import Yaml
import Francium

class NatriumParser {
    let natrium: Natrium
    let configurations: [String]
    let infoPlistPath: String
    let buildSettings: [String: Any]?

    lazy var environmentVariables = EnvironmentVariables.get(from: natrium.projectDirPath)

    lazy var parsers: [Parseable] = {
        return [
            SettingsParser(),
            XcconfigParser(),
            SwiftVariablesParser(),
            FilesParser(),
            AppIconParser(),
            PlistParser(),
            LaunchScreenParser(buildSettings: buildSettings)
        ]
    }()

    init(natrium: Natrium, infoPlistPath: String, configurations: [String], buildSettings: [String: Any]?) {
        self.configurations = configurations
        self.natrium = natrium
        self.infoPlistPath = infoPlistPath
        self.buildSettings = buildSettings
    }

    /// This is the 'main' function that tries to parse the .natrium.yml file.
    /// Within several steps.
    func run() throws {

        /// -- Read the .natrium.yml file and create a `YAML` instance of it
        guard let contents = File(path: natrium.yamlFile).contents else {
            throw NatriumError("Error reading \(natrium.yamlFile)")
        }
        var yaml = try Yaml.load(contents)

        /// -- Check if `environments is filled in in .natrium.yml
        guard let environments = (yaml["environments"].array?.compactMap { $0.string }) else {
            throw NatriumError("Missing environments in .natrium.yml")
        }

        try checkEnvironment(in: environments)
        Logger.debug("[environments]")
        for environment in environments {
            Logger.log("  - \(environment)")
        }

        /// -- Auto fill keys (empty values) in the yaml
        autoGenerateKeys(for: &yaml)

        /// -- Parse the natrium variables and extend them with target_specific natrium_variables
        var natriumVariables = try parse(yaml, key: "natrium_variables")

        Logger.log(key: "natrium_variables", natriumVariables)
        var targetSpecific: [String: [String: Yaml]] = [:]
        if let targetSpecificDictionary = try parseValue(yaml["target_specific"][Yaml.string(natrium.targetName)]).dictionary {
            Logger.debug("[target_specific]")
            Logger.insets += 1
            Logger.log(Logger.colorWrap(text: natrium.targetName, in: "4;1"))
            Logger.insets += 1
            for targetSpecificObj in targetSpecificDictionary {
                guard let targetSpecificKey = targetSpecificObj.key.string else {
                    continue
                }

                targetSpecific[targetSpecificKey] = try parse(Yaml.dictionary(targetSpecificDictionary), key: targetSpecificKey)
                Logger.log(key: targetSpecificKey, targetSpecific[targetSpecificKey]!)
            }
            Logger.insets -= 1
            if let natriumVariablesTargetSpecific = targetSpecific["natrium_variables"] {
                natriumVariables.merge(natriumVariablesTargetSpecific) { _, new in new }
            }
        }

        /// Set NatriumParserData to be used in `Parseable` instances
        NatriumParserData.instance = NatriumParserData {
            $0.projectDir = self.natrium.projectDirPath
            $0.configurations = self.configurations
            $0.environments = environments
            $0.infoPlistPath = self.infoPlistPath
            $0.target = self.natrium.targetName
            $0.configuration = self.natrium.configuration
            $0.environment = self.natrium.environment
            $0.dryRun = self.natrium.dryRun
        }

        /// -- Parse each individual entry for the YAML obejct
        for parser in parsers {
            let convertedValue = try _convert(yaml: yaml, key: parser.yamlKey, natriumVariables: natriumVariables, targetSpecific: targetSpecific)
            if !convertedValue.keys.isEmpty || parser.isRequired {
                try parser.parse(convertedValue)
            }
        }
    }

    /// Transform a dictionary or string by using the `natrium_variables` and `target_specific` entries
    ///
    /// - parameters:
    ///   - yaml: `YAML` The main yaml object (.natrium.yml)
    ///   - key: `String` The key of the yaml to parse (e.g. "xcconfig")
    ///   - natriumVariables: `[String: Yaml]` A dictionary containing all the available `natrium_variables`
    ///   - targetSpecific: `[String: [String: Yaml]]` Target specific values
    ///
    /// - throws:
    ///   - Parse errors -> @see parse(_, key:)
    ///
    /// - returns:
    ///   - `[String: Yaml]`
    private func _convert(yaml: Yaml,
                          key: String,
                          natriumVariables: [String: Yaml],
                          targetSpecific: [String: [String: Yaml]]) throws -> [String: Yaml] {
        var items = try parse(yaml, key: key).merging(targetSpecific[key] ?? [:]) { _, new in new }
        for item in items {
            if var stringValue = item.value.string {
                stringValue = try _replaceEnvironmentVariables(in: _replaceNatriumVariables(in: stringValue, natriumVariables))
                try _errorCheck(for: stringValue, key: "\(key).\(item.key)")
                items[item.key] = Yaml.string(stringValue)

            } else if var dic = item.value.dictionary {
                for dicValue in dic {
                    if var dicStringValue = dicValue.value.string {
                        dicStringValue = try _replaceEnvironmentVariables(in: _replaceNatriumVariables(in: dicStringValue, natriumVariables))
                        try _errorCheck(for: dicStringValue, key: "\(key).\(dicValue.key.stringValue)")
                        dic[dicValue.key] = Yaml.string(dicStringValue)
                    } else if var array = dicValue.value.array {
                        for (index, arrayStringValue) in array.enumerated() {
                            let stringValue = try _replaceEnvironmentVariables(in: _replaceNatriumVariables(in: arrayStringValue.stringValue, natriumVariables))
                            try _errorCheck(for: stringValue, key: "\(key)[\(index)]")
                            array[index] = Yaml.string(stringValue)
                        }
                        dic[dicValue.key] = Yaml.array(array)
                    }
                }
                items[item.key] = Yaml.dictionary(dic)
            } else if var array = item.value.array {
                for (index, stringValue) in array.enumerated() {
                    guard var arrayStringValue = stringValue.string else {
                        continue
                    }
                    arrayStringValue = try _replaceEnvironmentVariables(in: _replaceNatriumVariables(in: arrayStringValue, natriumVariables))
                    try _errorCheck(for: arrayStringValue, key: "\(key).\(item.key)")
                    array[index] = Yaml.string(arrayStringValue)
                }
                items[item.key] = Yaml.array(array)
            } else {
                try _errorCheck(for: item.value.stringValue, key: "\(key).\(item.key)")
                items[item.key] = item.value
            }
        }
        Logger.log(key: key, items)
        return items
    }

    private func _errorCheck(for string: String, key: String) throws {
        if string == "#error" {
            throw NatriumError("#error in \(key)")
        }
    }

    private func _replaceNatriumVariables(in string: String, _ natriumVariables: [String: Yaml]) -> String {
        var string = string
        
        for natriumVariable in natriumVariables {
            string = string.replacingOccurrences(of: "#{\(natriumVariable.key)}", with: natriumVariable.value.stringValue)
        }

        return string
    }

    private func _replaceEnvironmentVariables(in string: String) throws -> String {
        let matches = string.capturedGroups(withRegex: "#env\\((.+?)\\)")

        var string = string
        try matches.forEach { _, matchString in
            guard let value = self.environmentVariables[matchString] else {
                throw NatriumError("Cannot find environment variable: '\(matchString)'")
            }
            string = string.replacingOccurrences(of: "#env(\(matchString))", with: value)
        }

        return string
    }

    func checkEnvironment(in environments: [String]) throws {
        for environment in environments {
            guard environment =~ "^[A-za-z-_]+$" else {
                throw NatriumError("Environment names can only contain A-Z, a-z, - or _")
            }
        }
        let environment = natrium.environment
        if environments.filter({ $0 == environment }).isEmpty {
            throw NatriumError("Environment '\(environment)' not available. Available environments: \(environments)")
        }
    }

    func autoGenerateKeys(for yaml: inout Yaml) {
        for parser in parsers where parser.isRequired {
            let yamlKey = Yaml.string(parser.yamlKey)
            if yaml[yamlKey] == nil {
                yaml[yamlKey] = Yaml.dictionary([:])
            }
        }
    }
    
    private func parseValue(_ yaml: Yaml) throws -> Yaml {
        guard yaml.stringValue.hasPrefix("!include") else {
            return yaml
        }
        var path = yaml.stringValue
        path.removeFirst(9)
        path = "\(natrium.projectDirPath)/\(path)"
        
        guard let contents = File(path: path).contents else {
            throw NatriumError("Error reading !include \(path)")
        }
        
        Logger.info("!include \(path)")
        return try Yaml.load(contents)
    }

    /// Convert a yaml entry (for a specific key) into a dictionary
    ///
    /// - parameters:
    ///   - yaml: `YAML`
    ///   - key: `String`
    ///
    /// - throws:
    ///   - Array values are not allowed directly after a main key (e.g. natrium_variables)
    ///
    /// - returns: `[String: Yaml]`
    func parse(_ yaml: Yaml, key yamlKey: String) throws -> [String: Yaml] {
        guard yaml != .null else {
            return [:]
        }
        
        var dictionary: [Yaml: Yaml] = [:]
        if let readDictionary = yaml[Yaml.string(yamlKey)].dictionary {
            dictionary = readDictionary
        } else {
            if yaml[Yaml.string(yamlKey)].string != nil {
                let parsedYaml = try parseValue(yaml[Yaml.string(yamlKey)])
                dictionary = parsedYaml.dictionary ?? [:]
            }
        }

        if yamlKey == "plists" {
            let sequence = try dictionary.map { key, _ -> (String, Yaml) in
                let plistValue = try parse(Yaml.dictionary(dictionary), key: key.stringValue)
                return (key.stringValue, plistValue.toYaml())
            }

            return Dictionary(uniqueKeysWithValues: sequence)
        }
        
        var returnDictionary: [String: Yaml] = [:]
        // Global
        for globalObj in dictionary {
            guard let key = globalObj.key.string else {
                continue
            }

            if globalObj.value.array != nil && yamlKey != "appicon" {
                returnDictionary[key] = try parseValue(globalObj.value)
                continue
            }

            guard let globalObjDictionary = globalObj.value.dictionary else {
                returnDictionary[key] = try parseValue(globalObj.value)
                continue
            }

            // Environment
            for environmentObj in globalObjDictionary {
                let environmentKey = environmentObj.key.string ?? ""
                guard environmentKey.components(separatedBy: ",")
                    .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                    .contains(natrium.environment) || environmentKey == "*" else {
                    continue
                }
                
                guard let environmentObjDictionary = environmentObj.value.dictionary else {
                    returnDictionary[key] = try parseValue(environmentObj.value)
                    continue
                }

                // Configuration
                for configurationObj in environmentObjDictionary {
                    let configurationKey = configurationObj.key.string ?? ""
                    guard configurationKey.components(separatedBy: ",")
                        .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                        .contains(natrium.configuration) else {
                        continue
                    }
                    if yamlKey == "xcconfig" {
                        returnDictionary[key] = try parseValue(environmentObj.value)
                        break
                    }
                    returnDictionary[key] = try parseValue(configurationObj.value)
                } // :Configuration
            } // :Environment
        } // :Global

        return returnDictionary
    }
}
