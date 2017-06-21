//
//  ViewController.swift
//  CoreMLAppDemo
//
//  Created by vijay vikram singh on 6/21/17.
//  Copyright © 2017 vijay vikram singh. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var imagePickerController:UIImagePickerController?
    
    @IBOutlet weak var scene: UILabel!
    var predictor = GoogLeNetPlaces()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerController = UIImagePickerController.init()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func selectImage(_ sender: Any) {
        imagePickerController?.sourceType = .photoLibrary
        imagePickerController?.allowsEditing = false
        imagePickerController?.delegate = self;
        self.present(imagePickerController!, animated: true, completion: nil)
    }
    
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    let image:UIImage? = info[UIImagePickerControllerOriginalImage] as? UIImage
    imagePickerController?.dismiss(animated: true, completion: nil)
    
    guard let prediction =  try? predictor.prediction(sceneImage: self.pixelBuffer(image: image!)!) else {
        print("found error")
        return
     }
    imageView.image = image
    scene.text = prediction.sceneLabel
    }
    
    func pixelBuffer(image:UIImage) -> CVPixelBuffer? {
        // As image needed is 224x224
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 224, height: 224), true, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 224, height: 224))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Converting to CVPixelBuffer
        let width = resizedImage.size.width
        let height = resizedImage.size.height
        var pixelBuffer: CVPixelBuffer?
        let result = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_32ARGB,
                                         [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                                          kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary,
                                         &pixelBuffer)
        
        guard let resultPixelBuffer = pixelBuffer, result == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                                        return nil
        }
        
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        resizedImage.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return resultPixelBuffer
    }
}

