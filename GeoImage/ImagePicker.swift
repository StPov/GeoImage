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
    func didSelect(image: UIImage?)
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

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        switch picker.sourceType {
        case .photoLibrary, .savedPhotosAlbum:
                    print("1")
                    if let URL = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.referenceURL.rawValue)] as? URL {
//                        print("We got the URL as \(URL)")
                        let opts = PHFetchOptions()
                        opts.fetchLimit = 1
                        let assets = PHAsset.fetchAssets(withALAssetURLs: [URL], options: opts)
                        for assetIndex in 0..<assets.count {
                            let asset = assets[assetIndex]
                            
                            CLGeocoder().reverseGeocodeLocation(asset.location!, completionHandler: {(placemarks, error) -> Void in
                                print(asset.location)
                                
                                if let error = error {
                                    print("Reverse geocoder failed with error" + error.localizedDescription)
                                    return
                                }
                                if placemarks != nil && placemarks!.count > 0 {
                                    DispatchQueue.main.async {
                                        print("Locality: \(placemarks![0].locality!)")
                                    }
                                } else {
                                    print("Problem with the data received from geocoder")
                                }
                            })
                        }
                    }
        case .camera:
            ALAssetsLibrary().writeImage(toSavedPhotosAlbum: image.cgImage!, metadata: info[UIImagePickerController.InfoKey.mediaMetadata]! as! [NSObject : AnyObject], completionBlock: { (url, error) -> Void in
                                    print("2")
                                    guard let URL = url else { return }
//                                    print("photo saved to asset")
//                                    print(url)
                            
                            let assetLibrary = ALAssetsLibrary()
                                        assetLibrary.asset(for: url,
                                                        resultBlock: { (asset) -> Void in
                                                            if let asset = asset {
                                                                print("Asset: \(asset.description)")
                            //                                    print(asset.image)
                            //                                    print(asset.location)
                                                                let assetImage =  UIImage(cgImage:  asset.defaultRepresentation().fullResolutionImage().takeUnretainedValue())
                                                                print("Asset image: \(assetImage.getExifData())")
                                                            }
                                                        }, failureBlock: { (error) -> Void in
                                                            if let error = error { print(error.localizedDescription) }
                                                    })
                                            
                                                
                                //                 you can load your UIImage that was just saved to your asset as follow
            //                        let assetLibrary = ALAssetsLibrary()
            //                        assetLibrary.asset(for: url,
            //                                        resultBlock: { (asset) -> Void in
            //                                            if let asset = asset {
            //                                                print(asset)
            //            //                                    print(asset.image)
            //            //                                    print(asset.location)
            //                                                let assetImage =  UIImage(cgImage:  asset.defaultRepresentation().fullResolutionImage().takeUnretainedValue())
            //                                                print(assetImage)
            //                                            }
            //                                        }, failureBlock: { (error) -> Void in
            //                                            if let error = error { print(error.localizedDescription) }
            //                                    })
                            
                            var currentLoc: CLLocation!
                            if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                            CLLocationManager.authorizationStatus() == .authorizedAlways) {
                                currentLoc = self.locationManager.location
                               print(currentLoc.coordinate.latitude)
                               print(currentLoc.coordinate.longitude)
                            }
                            
                            
                            
                                    let opts = PHFetchOptions()
                                    opts.fetchLimit = 1
                                    let assets = PHAsset.fetchAssets(withALAssetURLs: [URL], options: opts)
                                                for assetIndex in 0..<assets.count {
                                                    let asset = assets[assetIndex]
                                                    // print("Location: \(asset.location?.description) Taken: \(asset.creationDate)")
                                    //                location = String(describing: asset.location!)
                                    //                timeTaken = asset.creationDate!.description
                                                    
            //                                        CLGeocoder().reverseGeocodeLocation(asset.location!, completionHandler: {(placemarks, error) -> Void in
            //                                            print(asset.location)
            //
            //                                            if let error = error {
            //                                                print("Reverse geocoder failed with error" + error.localizedDescription)
            //                                                return
            //                                            }
            //
            //                                            if placemarks != nil && placemarks!.count > 0 {
            //                                                DispatchQueue.main.async {
            //                                                    print("Locality: \(placemarks![0].locality!)")
            //                                                }
            //
            //                                            }
            //                                            else {
            //                                                print("Problem with the data received from geocoder")
            //                                            }
            //                                        })
                                                }
                                            })
        }
        self.pickerController(picker, didSelect: image)
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
