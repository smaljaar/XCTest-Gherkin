//
//  AfterTagTests.swift
//  AfterTagTests
//
//  Created by Samuël Maljaars on 24/11/2016.
//  Copyright © 2016 ABN Amro. All rights reserved.
//

import XCTest
@testable import XCTest_Gherkin

class AfterTagTests: XCTestCase {
    
    func testIfTagComesBeforeFeatureDescriptionThenAppendTagToEveryScenario(){
        let nativeFeature = NativeFeature(featureFileName: "feature_tag")
        
        nativeFeature?.scenarios.forEach { scenario in
            XCTAssertEqual(scenario.tag, "@samuelsTag")
        }
    }
    
    func testNoTag() {
        let nativeFeature = NativeFeature(featureFileName: "no_tag")
        
        XCTAssertEqual(nativeFeature?.background!.tag, nil)
        nativeFeature?.scenarios.forEach { scenario in
            XCTAssertEqual(scenario.tag, nil)
        }
    }
    
    func testTagForOnlyOneScenario() {
        let nativeFeature = NativeFeature(featureFileName: "one_scenario_tag")
        let scenariosToTest = nativeFeature?.scenarios
        
        XCTAssertEqual(nativeFeature?.background!.tag, nil)
        XCTAssertEqual(scenariosToTest?[0].tag, "@cleanupTask")
        
        let remainingScenariosToTest = scenariosToTest?.dropFirst()
        remainingScenariosToTest?.forEach { scenario in
            XCTAssertEqual(scenario.tag, nil)
        }
    }
    
    func testTwoDifferentTagsInOneFeature() {
        let nativeFeature = NativeFeature(featureFileName: "two_scenarios_tagged")
        let scenariosToTest = nativeFeature?.scenarios
        
        XCTAssertEqual(nativeFeature?.background!.tag, nil)
        XCTAssertEqual(scenariosToTest?[0].tag, "@cleanupTask")
        XCTAssertEqual(scenariosToTest?[1].tag, nil)
        XCTAssertEqual(scenariosToTest?[2].tag, "@anotherTag")
    }
    
    func testNoBackgroundAndExamples() {
        let nativeFeature = NativeFeature(featureFileName: "no_background_outline_tag")
        let scenariosToTest = nativeFeature?.scenarios
        
        XCTAssertNil(nativeFeature?.background)
        XCTAssertEqual(scenariosToTest?[0].tag, nil)
        XCTAssertEqual(scenariosToTest?[1].tag, nil)
        XCTAssertEqual(scenariosToTest?[2].tag, "@tapTransferButton")
        XCTAssertEqual(scenariosToTest?[3].tag, nil)
    }
    
    
}

extension NativeFeature {
    
    class func contentsOfFile(fileName: String) -> String {
        guard let path = Bundle(for: AfterTagTests.self).path(forResource: fileName, ofType: "feature") else {
            fatalError("could not find file with name \(fileName)")
        }
        
        return try! String(contentsOfFile:path, encoding: String.Encoding.utf8)
        
    }
    
    convenience init?(featureFileName: String) {
        let contents = NativeFeature.contentsOfFile(fileName: featureFileName)
        
        let feature = NativeFeature.featureFrom(contents: contents)
        
        self.init(description: feature.featureDescription, scenarios: feature.scenarios, background: feature.background)
    }
    
}
