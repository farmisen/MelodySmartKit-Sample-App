//
//  MSI2cCommandsViewController.swift
//  MelodySmart Example v2
//
//  Created by Stanislav Nikolov on 14/01/2015.
//  Copyright (c) 2015 Blue Creation. All rights reserved.
//

import UIKit
import MelodySmartKit

extension String {
    func dataFromHexadecimalString() -> [UInt8]? {
        let hexString = self.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> "))
                            .stringByReplacingOccurrencesOfString(" ", withString: "")
        
        // make sure the cleaned up string consists solely of hex digits, and that we have even number of them
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .CaseInsensitive)
        let length = hexString.characters.count

        let found = regex.firstMatchInString(hexString, options: [], range: NSMakeRange(0, length))
        guard found != nil && found!.range.location != NSNotFound && length % 2 == 0 else {
            return nil
        }

        var result = [UInt8]()
        let startIndex = hexString.startIndex
        
        for index in 0 ..< length / 2 {
            let range = startIndex.advancedBy(2 * index) ..< startIndex.advancedBy(2 * index + 2)
            let byteString = hexString.substringWithRange(range)
            let byte = UInt8(byteString, radix: 16)!
            result.append(byte)
        }
        
        return result
    }
}

class I2cCommandsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var tfDeviceAddress: UITextField!
    @IBOutlet var tfRegisterAddress: UITextField!
    @IBOutlet var tfOutgoingData: UITextField!
    @IBOutlet var tfIncomingData: UITextField!
    @IBOutlet var lblStatus: UILabel!

    var device: MelodySmartDevice?

    func didReceiveI2CReplyWithSuccess(success: Bool, data: NSData) {
        lblStatus.text = "Operation " + (success ? "successful" : "failed")
        tfIncomingData.text = data.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnRead_TouchUpInside() {
        lblStatus.text = ""
        tfIncomingData.text = ""

        if let ret = validateDeviceAddress() {
            lblStatus.text = "Reading...";
            
            let length = UInt8(16)

            device!.readI2cDataFromDeviceAddress(ret.deviceAddress, writePortion: ret.registerAddress, length: length)
        }
    }
    
    @IBAction func btnWrite_TouchUpInside() {
        lblStatus.text = "";

        guard let (deviceAddress, registerAddress) = validateDeviceAddress() else {
            return
        }

        guard let payload = tfOutgoingData.text!.dataFromHexadecimalString()
            where registerAddress.count + payload.count <= 19 else {
            let alert = UIAlertController(
                    title: "Error",
                    message:  "The outgoing data should consist of an even number of hex digits and be no more than 16 bytes!",
                    preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)

            return
        }

        let data = registerAddress + payload

        lblStatus.text = "Writing...";
        
        device!.writeI2cData(data, toDeviceAddress: deviceAddress)
    }

    func validateDeviceAddress() -> (deviceAddress: UInt8, registerAddress: [UInt8])? {
        guard tfDeviceAddress.text!.characters.count == 2 else {
            UIAlertView(title: "Error", message: "The device address should consit of 2 hex digits!", delegate: nil, cancelButtonTitle: "OK").show()
            return nil;
        }

        guard let regAddr = tfRegisterAddress.text!.dataFromHexadecimalString() else {
            UIAlertView(title: "Error", message: "The register address should consist of an even number of hex digits!", delegate: nil, cancelButtonTitle: "OK").show()
            return nil
        }

        var deviceAddr: UInt32 = 0
        let scanner = NSScanner(string: tfDeviceAddress.text!)
        scanner.scanHexInt(&deviceAddr)

        return (UInt8(deviceAddr), regAddr)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
}
