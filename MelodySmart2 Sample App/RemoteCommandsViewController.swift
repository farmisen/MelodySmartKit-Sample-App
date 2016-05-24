//
//  MSRemoteCommandsViewController.swift
//  MelodySmart_Example
//
//  Created by Stanislav Nikolov on 15/01/2015.
//  Copyright (c) 2015 Blue Creation. All rights reserved.
//

import UIKit
import MelodySmartKit

class RemoteCommandsViewController: UIViewController, UITextFieldDelegate, MelodySmartDeviceListener {
    @IBOutlet var tfCommand: UITextField!
    @IBOutlet var tvOutput: UITextView!

    internal var melodyDevice: MelodySmartDevice?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        melodyDevice?.addListener(self)
    }

    override func viewDidDisappear(animated: Bool) {
        melodyDevice?.removeListener(self)

        super.viewWillDisappear(animated)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        melodyDevice!.sendCommand(tfCommand.text!)

        textField.resignFirstResponder()

        return true
    }

    func melodySmartDidConnectDevice(device: MelodySmartDevice, inBootMode bootMode: (MelodySmartDevice.BootMode)) {
    }
    
    func melodySmartDidConnectDevice(device: MelodySmartDevice) {
    }

    func melodySmartDidDisconnectDevice(device: MelodySmartDevice) {
    }

    func melodySmartDidReceiveData(data: [UInt8], fromDevice device: MelodySmartDevice) {
    }

    func melodySmartDidReceiveCommandOutput(output: String, fromDevice device: MelodySmartDevice) {
        tvOutput.text? += output

        tvOutput.scrollRangeToVisible(NSRange(location: tvOutput.text.characters.count, length: 1))
    }

    func melodySmartDidReceiveI2cData(data: [UInt8], fromDevice device: MelodySmartDevice, success: Bool) {
    }
}
