//
//  ExampleNativeFeatureTest.swift
//  XCTest-Gherkin
//
//  Created by Marcin Raburski on 30/06/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import XCTest_Gherkin

private let bundle = NSBundle.allBundles()[1]

class RunSingleFeatureFileTest: NativeTestCase {
    override class func path() -> NSURL? {

        let resourceURL = bundle.resourceURL
        let fullURL = resourceURL?.URLByAppendingPathComponent("NativeFeatures/native_example_simple.feature")
        
        return  fullURL
    }
}

class RunMultipleFeatureFilesTest: NativeTestCase {
    override class func path() -> NSURL? {
        return bundle.resourceURL?.URLByAppendingPathComponent("NativeFeatures/")
    }
}
