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
            if (info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.imageURL.rawValue)] as? URL) != nil {
                let opts = PHFetchOptions()
                opts.fetchLimit = 1
                let asset = info[UIImagePickerController.InfoKey.phAsset] as! PHAsset
                guard let location = asset.location else {
                    self.setCurrentLocationToImage(image: image) { (location) in
                        guard let location = location else {
                            return self.pickerController(picker, didSelect: image, location: nil, locationName: "None")
                        }
                        self.determineCity(location: location) { (cityName) in
                            self.pickerController(picker, didSelect: image, location: location, locationName: cityName)
                        }
                    }
                    return self.pickerController(picker, didSelect: image, location: nil, locationName: "None")
                }
                self.determineCity(location: location) { (cityName) in
                    self.pickerController(picker, didSelect: image, location: location, locationName: cityName)
                }
            }
        case .camera:
            setCurrentLocationToImage(image: image) { (location) in
                guard let location = location else {
                    return self.pickerController(picker, didSelect: image, location: nil, locationName: "None")
                }
                self.determineCity(location: location) { (cityName) in
                    self.pickerController(picker, didSelect: image, location: location, locationName: cityName)
                }
            }
            
        @unknown default:
            fatalError()
        }
    }
    
    func determineCity(location: CLLocation, completion: @escaping (_ city: String) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in

            if let error = error {
                print("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            if placemarks != nil && placemarks!.count > 0 {
                guard let cityName = placemarks?[0].locality else { return }
                completion(cityName)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    func setCurrentLocationToImage(_ picker: UIImagePickerController = UIImagePickerController(), image: UIImage, completion: @escaping (_ location: CLLocation?) -> Void) {
        var currentLoc: CLLocation!
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways) {
            currentLoc = self.locationManager.location
            completion(currentLoc)
        } else {
            completion(nil)
        }
    }

}

extension ImagePicker: UINavigationControllerDelegate {

}
