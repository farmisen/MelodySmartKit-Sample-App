//
//  DetailViewController.swift
//  MelodySmart2 Sample App
//
//  Created by Stanislav Nikolov on 04/05/2016.
//  Copyright © 2016 BlueCreation. All rights reserved.
//

import UIKit
import MelodySmartKit
//import SwiftString
import Foundation
import SwiftCSV
import Chronos

//import SwiftWebSocket

import Starscream


class DetailViewController: UIViewController, UITextFieldDelegate, MelodySmartDeviceListener, WebSocketDelegate, WebSocketPongDelegate {
    var ws: WebSocket?
    var buffer = ""
    var discardedCount = 0
    var timer: DispatchTimer?
    var index = 0

    @IBOutlet weak var serverURLTextField: UITextField!
    @IBOutlet weak var tfIncomingData: UITextField!
    @IBOutlet weak var transmitSwitch: UISwitch!
    @IBOutlet var fakeDataSwitch: UISwitch!
    @IBOutlet weak var calibrateSwitch: UISwitch!

    @IBOutlet weak var connectingSwitch: UISwitch!

    @IBAction func onResetTouched(sender: AnyObject) {
        self.ws?.writeString("RST")
        self.index = 1
        self.calibrateSwitch.on = false 
    }
    
    @IBAction func onConnectingSwitchValueChanged(sender: AnyObject) {
        if self.connectingSwitch.on {
            self.connectingSwitch.enabled = false
            self.initSocket()
        } else {
            self.ws?.writeString("CAL_OFF")
            self.ws?.disconnect()
            self.transmitSwitch.on = false
            self.calibrateSwitch.on = false            
        }
        
    }
    
    @IBAction func onTransmitSwitchValueChanged(sender: AnyObject) {
    }


    @IBAction func onFakeDataSwitchValueChanged(sender: AnyObject) {
    }


    @IBAction func onCalibrateSwitchValueChanged(sender: AnyObject) {
        if self.calibrateSwitch.on {
            self.ws?.writeString("CAL_ON")
        } else {
            self.ws?.writeString("CAL_OFF")
        }
    }

//    @IBOutlet weak var transmitSwitch: UISwitch!
//    @IBOutlet weak var fakeDataSwitch: UISwitch!
//

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
        updateConnectiongStatus()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
//        self.initSocket()
        self.setupSampleData()
        self.transmitSwitch.on = false
        self.fakeDataSwitch.on = false
        self.calibrateSwitch.on = false
        self.transmitSwitch.enabled = false
        self.fakeDataSwitch.enabled = false
        self.calibrateSwitch.enabled = false
        self.connectingSwitch.on = false
        self.serverURLTextField.text = "ws://lim-dashboard.herokuapp.com"
//        self.serverURLTextField.text = "ws://lim.ngrok.io"
        self.serverURLTextField.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        melodyDevice?.addListener(self)
        
        if let device = melodyDevice {
            if (device.state == .Disconnected) {
                connectDevice()
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        melodyDevice?.disconnect()
        melodyDevice?.removeListener(self)
        self.ws?.writeString("CAL_OFF")
        self.ws?.disconnect()
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

        
        if let device = melodyDevice {
            switch device.state {
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
            title = "\(device.name ?? "<Unknown>") (\(status))"
        }
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

    // MARK: - UITextField delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
        print("RCV:\(stringData!)")

        self.buffer = self.buffer + stringData!
        while (self.buffer.containsString("!")) {
            var chunks = self.buffer.componentsSeparatedByString("!")
            let chunk = chunks[0]
            chunks.removeAtIndex(0)
            self.buffer = chunks.joinWithSeparator("!")
            let tokens = chunk.componentsSeparatedByString("/")

            if (tokens.count != 14) {
                self.discardedCount += 1

            } else {
                if (self.transmitSwitch.on && !self.fakeDataSwitch.on) {
                    self.ws?.writeString(chunk)
                    print("rcv:\(stringData!) - snt:\(chunk) - buf:\(self.buffer) - dis:\(self.discardedCount)")
                }
            }
        }
    }

    func melodySmartDidReceiveCommandOutput(output: String, fromDevice device: MelodySmartDevice) {
        print("CMD:\(output)")
    }

    func melodySmartDidReceiveI2cData(data: [UInt8], fromDevice device: MelodySmartDevice, success: Bool) {
    }


    // MARK: - Networking
    func initSocket() {
//        self.ws = WebSocket(url: NSURL(string: "ws://192.168.1.235:3000/")!)
        self.ws = WebSocket(url: NSURL(string: self.serverURLTextField.text!)!)
        self.ws?.delegate = self
        self.ws?.pongDelegate = self
        self.ws?.connect()
    }

    func websocketDidConnect(ws: WebSocket) {
        print("websocket is connected")
        self.connectingSwitch.enabled = true
        self.transmitSwitch.enabled = true
        self.fakeDataSwitch.enabled = true
        self.calibrateSwitch.enabled = true
    }

    func websocketDidDisconnect(ws: WebSocket, error: NSError?) {
        self.transmitSwitch.on = false
        self.calibrateSwitch.on = false
        self.connectingSwitch.on = false
        self.transmitSwitch.enabled = false
        self.fakeDataSwitch.enabled = false
        self.calibrateSwitch.enabled = false
        self.connectingSwitch.enabled = true
        self.calibrateSwitch.on = false
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
        }
    }

    func websocketDidReceiveMessage(ws: WebSocket, text: String) {
        print("Received text: \(text)")
    }

    func websocketDidReceiveData(ws: WebSocket, data: NSData) {
        print("Received data: \(data.length)")
    }

    func websocketDidReceivePong(ws: WebSocket) {
        print("Got pong!")
    }

    func setupSampleData() {
        do {
            let fileLocation = NSBundle.mainBundle().pathForResource("sample3", ofType: "csv")!
            let csv = try CSV(name: fileLocation)
            self.index = 1
            print("Sample data loaded")
            self.timer = DispatchTimer(interval: 0.25, closure: {
                (timer: RepeatingTimer, count: Int) in
                if (self.transmitSwitch.on && self.fakeDataSwitch.on) {
                    let row = csv.rows[self.index]

                    let ts = row["ts"]!
                    let ax = row["ax"]!
                    let ay = row["ay"]!
                    let az = row["az"]!
                    let rvx = row["rvx"]!
                    let rvy = row["rvy"]!
                    let rvz = row["rvz"]!
                    let pr1 = row["pr1"]!
                    let pr2 = row["pr2"]!
                    let pr3 = row["pr3"]!
                    let pr4 = row["pr4"]!
                    let pr5 = row["pr5"]!
                    let pr6 = row["pr6"]!
                    let tmp = row["tmp"]!
                    
                    let payload = "\(ts)/\(ax)/\(ay)/\(az)/\(rvx)/\(rvy)/\(rvz)/\(pr1)/\(pr2)/\(pr3)/\(pr4)/\(pr5)/\(pr6)/\(tmp)"
                    self.ws?.writeString(payload)
                    print( "smpl:\(payload)" )
                    self.index = (self.index + 1) % csv.rows.count
                }

            })
            self.timer?.start(true)
        } catch {
            print("Something bad happened: \(error)")
        }


    }

}

