//
//  ImagePicker.swift
//  GeoImage
//
//  Created by Stanislav Povolotskiy on 31.08.2020.
//  Copyright © 2020 Stanislav Povolotskiy. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary
import CoreLocation

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?, location: CLLocation?, locationName: String?)
}

open class ImagePicker: NSObject {

    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?
    var locationManager = CLLocationManager()
    var location: CLLocation?
    var locationName: String?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
        self.pickerController.mediaTypes = ["public.image"]
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }

    public func present(from sourceView: UIView) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action = self.action(for: .camera, title: "Take photo") {
            self.locationManager.requestWhenInUseAuthorization()
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        self.presentationController?.present(alertController, animated: true)
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?, location: CLLocation?, locationName: String?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image, location: location, locationName: locationName)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil, location: nil, locationName: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil, location: nil, locationName: nil)
        }
        switch picker.sourceType {
        case .photoLibrary, .savedPhotosAlbum:
                    if let URL = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.referenceURL.rawValue)] as? URL {
                        let opts = PHFetchOptions()
                        opts.fetchLimit = 1
                        let assets = PHAsset.fetchAssets(withALAssetURLs: [URL], options: opts)
                        
                        for assetIndex in 0..<assets.count {
                            let asset = assets[assetIndex]

                            self.determineCity(location: asset.location!)
                        }
                    }
        case .camera:
            ALAssetsLibrary().writeImage(toSavedPhotosAlbum: image.cgImage!, metadata: info[UIImagePickerController.InfoKey.mediaMetadata]! as! [NSObject : AnyObject], completionBlock: { (url, error) -> Void in

                guard let URL = url else { return }
                var currentLoc: CLLocation!
                if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() == .authorizedAlways) {
                    currentLoc = self.locationManager.location
                    print(currentLoc.coordinate.latitude)
                    print(currentLoc.coordinate.longitude)
                    self.location = currentLoc
                    self.determineCity(location: currentLoc)
                }
            })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.pickerController(picker, didSelect: image, location: self.location, locationName: self.locationName)
        }
//        self.pickerController(picker, didSelect: image, location: location, locationName: locationName)
    }
    
    func determineCity(location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in //check here for asset.location nil

            if let error = error {
                print("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            if placemarks != nil && placemarks!.count > 0 {
                    print("Locality: \(placemarks![0].locality!)")
                    self.locationName = "\(placemarks?[0].locality!)"
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
