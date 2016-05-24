//
//  MelodySmartListenerExtensions.swift
//  MelodySmart2 Sample App
//
//  Created by Stanislav Nikolov on 13/05/2016.
//  Copyright © 2016 BlueCreation. All rights reserved.
//

import Foundation
import MelodySmartKit

// These are used as default implementations of the MelodySmartDeviceLister, so that we don't have
// to reimplement all methods in all listeners
extension MelodySmartDeviceListener {
    func melodySmartDidConnectDevice(device: MelodySmartDevice, inBootMode bootMode: (MelodySmartDevice.BootMode)) {
    }

    func melodySmartDidDisconnectDevice(device: MelodySmartDevice) {
    }

    func melodySmartDidReceiveData(data: [UInt8], fromDevice device:MelodySmartDevice) {
    }

    func melodySmartDidReceiveCommandOutput(output: String, fromDevice device:MelodySmartDevice) {
    }

    func melodySmartDidReceiveI2cData(data: [UInt8], fromDevice device:MelodySmartDevice, success: Bool) {
    }

    func melodySmartDidUpdateOtauState(otauState: MelodySmartDevice.OtauState, forDevice device: MelodySmartDevice) {
    }
}