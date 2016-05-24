//
//  DetailViewController.swift
//  MelodySmart2 Sample App
//
//  Created by Stanislav Nikolov on 04/05/2016.
//  Copyright © 2016 BlueCreation. All rights reserved.
//

import UIKit
import MelodySmartKit

class DetailViewController: UIViewController, MelodySmartDeviceListener {

    @IBOutlet weak var tfOutgoingData: UITextField!
    @IBOutlet weak var tfIncomingData: UITextField!

    @IBOutlet weak var btnRemoteCommands: UIButton!
    @IBOutlet weak var btnI2cControl: UIButton!
    @IBOutlet weak var btnOTAU: UIButton!

    var melodyDevice: MelodySmartDevice? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        updateConnectiongStatus()
    }

    @IBAction func btnDisconnect_TouchUpInside(sender: AnyObject) {
        melodyDevice?.disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func viewWillAppear(animated: Bool) {
        melodyDevice?.addListener(self)

        if (melodyDevice!.state == .Disconnected) {
            connectDevice()
        }
    }

    override func viewWillDisappear(animated: Bool) {
//        melodyDevice!.disconnect()
        melodyDevice?.removeListener(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func enableButtons(enable: Bool) {
        btnI2cControl?.enabled = enable
        btnRemoteCommands?.enabled = enable
        btnOTAU?.enabled = enable
    }

    func updateConnectiongStatus() {
        let buttonEnabled: Bool
        let status: String

        switch melodyDevice!.state {
        case .Connected:
            status = "Connected"
            buttonEnabled = true

        case .Connecting:
            status = "Connecting..."
            buttonEnabled = false

        case .Disconnecting:
            status = "Disconnecting..."
            buttonEnabled = false

        case .Disconnected:
            status = "Disconnected"
            buttonEnabled = false
        }

        enableButtons(buttonEnabled)
        title = "\(melodyDevice!.name ?? "<Unknown>") (\(status))"
    }

    func connectDevice() {
        melodyDevice!.connect()
        updateConnectiongStatus()
    }
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "i2c":
            let controller = segue.destinationViewController as! I2cCommandsViewController
            controller.device = melodyDevice!

        case "remoteCommands":
            let controller = segue.destinationViewController as! RemoteCommandsViewController
            controller.melodyDevice = melodyDevice!

        case "otau":
            let controller = segue.destinationViewController as! OtauViewController
            controller.device = melodyDevice!

        default:
            break
        }
    }

    // MARK: - MelodySmartDevice listener

    func melodySmartDidConnectDevice(device: MelodySmartDevice, inBootMode bootMode: (MelodySmartDevice.BootMode)) {
        updateConnectiongStatus()
    }

    func melodySmartDidDisconnectDevice(device: MelodySmartDevice) {
        updateConnectiongStatus()
    }

    func melodySmartDidReceiveData(data: [UInt8], fromDevice device: MelodySmartDevice) {
        let stringData = String(bytes: data, encoding: NSUTF8StringEncoding)
        tfIncomingData.text = stringData
    }

    func melodySmartDidReceiveCommandOutput(output: String, fromDevice device: MelodySmartDevice) {
    }

    func melodySmartDidReceiveI2cData(data: [UInt8], fromDevice device: MelodySmartDevice, success: Bool) {
    }

    // MARK: - UITextField delegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard textField === self.tfOutgoingData else {
            return false
        }

        if !melodyDevice!.sendString(textField.text!) {
            print("Send error")
        }

        textField.resignFirstResponder()

        return true
    }
}
