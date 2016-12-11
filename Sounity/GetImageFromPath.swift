//
//  GetImageFromPath.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 10/12/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import Photos

func GetImageFromPath(path: NSURL) -> UIImage {
    print("path -> \(path)")

    let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [path.absoluteURL!], options: nil)
    if let photo = fetchResult.firstObject {
        PHImageManager.default().requestImage(for: photo, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) {
            image, info in
            
        }
    }
    
    return UIImage(named: "empty")!
}
