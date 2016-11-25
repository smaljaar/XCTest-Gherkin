//
//  NativeFeature.swift
//  Pods
//
//  Created by Sam Dean on 06/11/2015.
//
//

import Foundation

struct FileTags {
    static let Tag = "@"
    static let Feature = "Feature:"
    static let Background = "Background:"
    static let Scenario = "Scenario:"
    static let Outline = "Scenario Outline:"
    static let Examples = "Examples:"
    static let ExampleLine = "|"
    static let Given = "Given"
    static let When = "When"
    static let Then = "Then"
    static let And = "And"
}

class NativeFeature : CustomStringConvertible {
    let featureDescription: String
    let scenarios: [NativeScenario]
    let background: NativeBackground?
    
    required init(description: String, scenarios:[NativeScenario], background: NativeBackground?) {
        self.featureDescription = description
        self.scenarios = scenarios
        self.background = background
    }
    
    var description: String {
        get {
            var backgroundDescription = "No background"
            if let myBackground = self.background {
                backgroundDescription = myBackground.description
            }
            return "<\(type(of: self)) \(self.featureDescription) Background: \(backgroundDescription). \(self.scenarios.count) scenario(s)>"
        }
    }
}

extension NativeFeature {
    
    class func featureFrom(contents: String) -> (background: NativeBackground?, scenarios: [NativeScenario], featureDescription: String) {
        
        // Replace new line character that is sometimes used if the Gherkin files have been written on a Windows machine.
        let contentsFixedWindowsNewLineCharacters = contents.replacingOccurrences(of: "\r\n", with: "\n")
        
        // Get all the lines in the file
        var lines = contentsFixedWindowsNewLineCharacters.components(separatedBy: "\n").map { $0.trimmingCharacters(in: whitespace) }
        
        // Filter comments (#), also filter white lines
        lines = lines.filter { $0.characters.first != "#" && $0.characters.count > 0}
        guard !lines.isEmpty else {
            fatalError("no lines found in feature file")
        }
        
        let lineWithFeatureTag = lines.first { $0.contains(FileTags.Feature) }
        guard let myLine = lineWithFeatureTag else {
            fatalError("could not find Feature: tag")
        }
        
        let (_,suffixOption) = myLine.componentsWithPrefix(FileTags.Feature)
        guard let featureDescription = suffixOption else {
            fatalError("Feature: tag was found but description is missing")
        }
        
        return (NativeFeature.parseLines(lines).background, NativeFeature.parseLines(lines).scenarios, featureDescription)
    }
    
    convenience init?(contentsOfURL url: URL) {
        // Read in the file
        let contents = try! String(contentsOf: url, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        
        let feature = NativeFeature.featureFrom(contents: contents)
        
        self.init(description: feature.featureDescription, scenarios: feature.scenarios, background: feature.background)
    }
    
    fileprivate class func parseLines(_ lines: [String]) -> (background: NativeBackground?, scenarios:[NativeScenario]) {
        
        var state = ParseState()
        var scenarios = Array<NativeScenario>()
        var background: NativeBackground?
        var featureTag: String?
        var scenarioTag: String?
        var startedParsingScenario = false
        var startedParsingFeature = false
        
        func updateState(newTag: String?, lineSuffix: String, parsingBackground: Bool = false){
            
            if let aBackground = state.background() {
                background = aBackground
            } else if let newScenarios = state.scenarios() {
                scenarios.append(contentsOf: newScenarios)
            }
            state = ParseState(tag: newTag, description: lineSuffix, parsingBackground: parsingBackground)
        }
        
        // Go through each line in turn
        for (lineIndex,line) in lines.enumerated() {
            
            if !line.isEmpty {
                // What kind of line is it?
                if let (linePrefix, lineSuffix) = line.lineComponents() {
                    
                    switch(linePrefix) {
                        
                    case FileTags.Background :
                        updateState(newTag: scenarioTag, lineSuffix: lineSuffix, parsingBackground: true)
                        
                    case FileTags.Scenario :
                        
                        startedParsingScenario = true

                        if let featureTag = featureTag {
                            updateState(newTag: featureTag, lineSuffix: lineSuffix)
                        } else {
                            updateState(newTag: scenarioTag, lineSuffix: lineSuffix)
                            scenarioTag = nil
                        }
                        
                    case FileTags.Given, FileTags.When, FileTags.Then, FileTags.And:
                        state.steps.append(lineSuffix)
                        
                    case FileTags.Outline:
                        startedParsingScenario = true
                        
                        if let featureTag = featureTag {
                            updateState(newTag: featureTag, lineSuffix: lineSuffix)
                        } else {
                            updateState(newTag: scenarioTag, lineSuffix: lineSuffix)
                        }
                        
                    case FileTags.Examples:
                        // Prep the examples array for examples
                        state.exampleLines = []

                    case FileTags.ExampleLine:
                        state.exampleLines.append( (lineIndex+1, lineSuffix) )
                        
                    case FileTags.Feature:
                        startedParsingFeature = true
                        break
                        
                    case FileTags.Tag:

                        if startedParsingScenario {
                            if let newScenarios = state.scenarios() {
                                scenarios.append(contentsOf: newScenarios)
                            }
                            
                            scenarioTag = "@\(lineSuffix)"
                            print("scenario tag saved with suffix \(lineSuffix)")
                            startedParsingScenario = false
                        } else if !startedParsingFeature {
                            featureTag = "@\(lineSuffix)"
                            print("feature tag saved with suffix \(lineSuffix)")
                        } else {
                            scenarioTag = "@\(lineSuffix)"
                            print("scenario tag saved with suffix \(lineSuffix)")
                        }
                        
                    default:
                        // Just ignore lines we don't recognise yet
                        break
                    }
                    
                }
            }

        }
        
        // If we hit the end of the file, we need to make sure we have dealt with
        // the last scenarios
        if let newScenarios = state.scenarios() {
            scenarios.append(contentsOf: newScenarios)
        }
        
        return (background, scenarios)
    }

}

private let whitespace = CharacterSet.whitespaces

extension String {
    
    func componentsWithPrefix(_ prefix: String) -> (String, String?) {
        guard self.hasPrefix(prefix) else { return (self,nil) }
        
        let index = (prefix as NSString).length
        let suffix = (self as NSString).substring(from: index).trimmingCharacters(in: whitespace)
        return (prefix, suffix)
    }
    
    func lineComponents() -> (String, String)? {
        let prefixes = [ FileTags.Tag, FileTags.Feature, FileTags.Scenario, FileTags.Background, FileTags.Given, FileTags.When, FileTags.Then, FileTags.And, FileTags.Outline, FileTags.Examples, FileTags.ExampleLine ]
        
        func first(_ a: [String]) -> (String, String)? {
            if a.count == 0 { return nil }
            let string = a.first!
            let (prefix, suffix) = self.componentsWithPrefix(string)
            if let suffix = suffix {
                return (prefix, suffix)
            } else {
                return first(Array(a.dropFirst(1)))
            }
        }
        
        return first(prefixes)
    }
}
