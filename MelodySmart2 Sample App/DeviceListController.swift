//
//  MasterViewController.swift
//  MelodySmart2 Sample App
//
//  Created by Stanislav Nikolov on 04/05/2016.
//  Copyright © 2016 BlueCreation. All rights reserved.
//

import UIKit
import MelodySmartKit


class MasterViewController: UITableViewController, MelodySmartManagerListener {  

    struct DiscoveredDevice {
        var device: MelodySmartDevice
        var RSSI: NSNumber
    }

    var detailViewController: DetailViewController? = nil
    var objects = [DiscoveredDevice]()

    var melodyManager: MelodySmartManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        melodyManager = MelodySmartManager()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(startScan(_:)))

        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        melodyManager!.addListener(self)

        if (melodyManager!.state == .PoweredOn) {
            melodyManager!.scan()
        }

        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed

        self.tableView.reloadData()
    }

    override func viewWillDisappear(animated: Bool) {
        print("viewWillDisappear")

        melodyManager!.stopScan()
        melodyManager!.removeListener(self)

        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func startScan(sender: AnyObject) {
        print("starting scanning")

        let indexPaths = (0..<objects.count).map({ NSIndexPath(forRow: $0, inSection: 0) })

        objects.removeAll()

        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)

        melodyManager?.scan()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                if indexPath.row != objects.count {
                    let object = objects[indexPath.row]
                    controller.melodyDevice = object.device
                }
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count + 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if indexPath.row == objects.count {
            cell.textLabel!.text = "Virtual Device"
            cell.detailTextLabel!.text = "0"
        } else {
            let object = objects[indexPath.row]
            cell.textLabel!.text = (object.device.name ?? "<Unkown>") + ((object.device.state == .Connected) ? " (Connected)" : "")
            cell.detailTextLabel!.text = "\(object.RSSI)"
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }

    // MelodySmartManagerListener

    func melodySmartManager(manager: MelodySmartManager, didUpdateState state: MelodySmartManager.State) {
        print("new state \(state)")

        if (state == .PoweredOn) {
        }
    }
    
    func melodySmartManager(manager: MelodySmartManager, didConnectDevice device: MelodySmartDevice) {
    }
    
    func melodySmartManager(manager: MelodySmartManager, didDisconnectDevice device: MelodySmartDevice) {
    }
    
    func melodySmartManager(manager: MelodySmartManager, didDiscoverDevice device: MelodySmartDevice, advertisementData: MelodySmartManager.AdvertisementData) {
        let RSSI = advertisementData.RSSI

        if let knownDeviceIndex = try! objects.indexOf({ $0.device === device }) {
            objects[knownDeviceIndex].RSSI = RSSI
            tableView.reloadRowsAtIndexPaths([ NSIndexPath(forRow: knownDeviceIndex, inSection: 0) ], withRowAnimation: .None)
        } else {
            let newDevice = DiscoveredDevice(device: device, RSSI: RSSI)
            objects.append(newDevice)
            tableView.insertRowsAtIndexPaths([ NSIndexPath(forRow: objects.count - 1, inSection: 0) ], withRowAnimation: .Automatic)
        }
    }


}

