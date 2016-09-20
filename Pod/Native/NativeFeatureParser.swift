//
//  NativeFeatureParser.swift
//  Pods
//
//  Created by Marcin Raburski on 05/09/2016.
//
//

import Foundation

struct NativeFeatureParser {
    let path: NSURL
    
    func parsedFeatures() -> [NativeFeature]? {
        let manager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = ObjCBool(false)
        guard manager.fileExistsAtPath(path.path!, isDirectory: &isDirectory) else {
            return nil
        }
        
        if isDirectory {
            // Get the files from that folder
            if let files = manager.enumeratorAtURL(path, includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
                return self.parseFeatureFiles(files)
            } else {
                return nil
            }
            
        } else {
            if let feature = self.parseFeatureFile(path) {
                return [feature]
            }
        }
        return nil
    }
    
    private func parseFeatureFiles(files: NSDirectoryEnumerator) -> [NativeFeature] {
        return files.map({ return self.parseFeatureFile($0 as! NSURL)!})
    }
    
    private func parseFeatureFile(file: NSURL) -> NativeFeature? {
        guard let feature = NativeFeature(contentsOfURL:file) else {
            return nil
        }
        return feature
    }
    
}
