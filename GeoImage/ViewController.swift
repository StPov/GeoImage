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
    @IBOutlet var loc: UILabel!
    @IBOutlet var locName: UILabel!

    var imagePicker: ImagePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }

    @IBAction func showImagePicker(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
}

extension ViewController: ImagePickerDelegate {

//    func didSelect(image: UIImage?) {
//        self.imageView.image = image
//    }
    func didSelect(image: UIImage?, location: CLLocation?, locationName: String?) {
        self.imageView.image = image
        loc.text = "\(location)"
        locName.text = locationName
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
