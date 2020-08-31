//
//  ViewController.swift
//  GeoImage
//
//  Created by Stanislav Povolotskiy on 31.08.2020.
//  Copyright © 2020 Stanislav Povolotskiy. All rights reserved.
//

import UIKit
import Photos
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!

    var imagePicker: ImagePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }

    @IBAction func showImagePicker(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
//    func addAsset(image: UIImage, location: CLLocation? = nil) {
//           PHPhotoLibrary.shared().performChanges({
//               // Request creating an asset from the image.
//               let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
//               // Set metadata location
//               if let location = location {
//                   creationRequest.location = location
//               }
//           }, completionHandler: { success, error in
//               if !success { NSLog("error creating asset: \(error)") }
//           })
//    }
}

extension ViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        self.imageView.image = image
        
        
//        var locationManager = CLLocationManager()
//        locationManager.requestWhenInUseAuthorization()
//        var currentLoc: CLLocation!
//        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
//        CLLocationManager.authorizationStatus() == .authorizedAlways) {
//           currentLoc = locationManager.location
//           print(currentLoc.coordinate.latitude)
//           print(currentLoc.coordinate.longitude)
//        }
//
//        addAsset(image: image!, location: currentLoc)
//        print("BLAA: \(image?.getExifData())")
    }
}

extension UIImage {

    func getExifData() -> CFDictionary? {
        var exifData: CFDictionary? = nil
        if let data = self.jpegData(compressionQuality: 1.0) {
            data.withUnsafeBytes {
                let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                if let cfData = CFDataCreate(kCFAllocatorDefault, bytes, data.count),
                    let source = CGImageSourceCreateWithData(cfData, nil) {
                    exifData = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                }
            }
        }
        return exifData
    }
}
