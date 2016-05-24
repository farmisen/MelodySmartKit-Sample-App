//
//  MSOtauViewController.swift
//  MelodySmart_Example
//
//  Created by Stanislav Nikolov on 16/01/2015.
//  Copyright (c) 2015 Blue Creation. All rights reserved.
//

import UIKit
import MelodySmartKit

class MelodyRelease {
    var version: String!
    var imageFileUrl: NSURL!
    var keyFileUrl: NSURL!
    var releaseDate: NSDate!

    init() {
    }
}

class OtauViewController: UIViewController, MelodySmartDeviceListener {

    @IBOutlet var lblImage: UILabel!
    @IBOutlet var lblDeviceVersion: UILabel!
    @IBOutlet var lblProgress: UILabel!
    @IBOutlet var lblStatus: UILabel!
    @IBOutlet var btnStartOtau: UIButton!
    @IBOutlet var pvProgress: UIProgressView!

    private var imageData: NSData?
    private var keyData: NSData?

    var device: MelodySmartDevice?

    func melodySmartDidConnectDevice(device: MelodySmartDevice, inBootMode bootMode: (MelodySmartDevice.BootMode)) {
        switch bootMode {
        case .Application:
            updateUi()

        case .Bootloader:
            btnStartOtau.enabled = false
            guard let id = imageData, let kfd = keyData else {
                print("No Image data or key file data found!")
                return
            }

            device.startOtauWithImageData(id, keyFileData: kfd)

        default:
            break
        }
    }

    func melodySmartDidUpdateOtauState(otauState: MelodySmartDevice.OtauState, forDevice device: MelodySmartDevice) {
        switch otauState {
        case .Idle:
            lblStatus.text = "Idle"

        case .Starting:
            lblStatus.text = "Starting..."

        case .InProgress(let progress):
            lblStatus.text = "Update In Progress..."
            lblProgress.text = "\(progress)%"
            pvProgress.progress = Float(progress) / 100.0

        case .Complete:
            lblStatus.text = "Update successful!"

        case .Failed:
            lblStatus.text = "Update failed!"
        }
    }

    @IBAction func btnStartOtau_onTouchedUpInside() {
        lblStatus.text = "Downloading FW image..."

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.imageData = NSData(contentsOfURL: self.melodyRelease!.imageFileUrl)
            self.keyData = NSData(contentsOfURL: self.melodyRelease!.keyFileUrl)

            guard self.imageData != nil && self.keyData != nil else {
                self.lblStatus.text = "Error"
                UIAlertView(title: "Error", message: "Error downloading FW image, please try again!", delegate: nil, cancelButtonTitle: "OK").show()
                return
            }

            self.device!.rebootToOtauMode()
            
            dispatch_async(dispatch_get_main_queue(), {
                self.lblStatus.text = "Rebooting device"
            })
        })
    }

    var melodyRelease: MelodyRelease? {
        didSet { updateUi() }
    }

    func updateUi() {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        if melodyRelease != nil {
            lblImage.text = "Selected FW: \(melodyRelease!.version) @ \(formatter.stringFromDate(melodyRelease!.releaseDate))"
        }
        btnStartOtau.enabled = melodyRelease != nil
        lblDeviceVersion.text = "Device FW: \(device!.firmwareVersion ?? "Unknown")"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateUi()
    }

    override func viewWillAppear(animated: Bool) {
        device?.addListener(self)
    }

    override func viewWillDisappear(animated: Bool) {
        device?.removeListener(self)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "image_selection" {
            (segue.destinationViewController as! OtauImageSelectionTableViewController).delegate = self;
        }
    }

}
