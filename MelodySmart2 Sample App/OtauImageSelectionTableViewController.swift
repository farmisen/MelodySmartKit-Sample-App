//
//  MSOtauImageSelectionTableViewController.swift
//  MelodySmart_Example
//
//  Created by Stanislav Nikolov on 16/01/2015.
//  Copyright (c) 2015 Blue Creation. All rights reserved.
//

import UIKit

class OtauImageSelectionTableViewController: UITableViewController {

    var delegate: OtauViewController!

    private let BASE_URL = NSURL(string: "https://bluecreation.com/stan/melody_smart_otau/")!

    private var availableImages = [MelodyRelease]()

    private var loadingDialog: UIAlertView?

    override func viewDidLoad() {
        super.viewDidLoad()

        loadingDialog = UIAlertView(title: "Loading FW versions", message: "Please wait...", delegate: nil, cancelButtonTitle: nil)
        loadingDialog?.show()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            guard let manifestData = NSData(contentsOfURL: self.BASE_URL.URLByAppendingPathComponent("manifest.json")) else {
                self.loadingDialog?.dismissWithClickedButtonIndex(0, animated: true)
                return;
            }

            let jsonObject: AnyObject!
            do {
                jsonObject = try NSJSONSerialization.JSONObjectWithData(manifestData, options: [])
            } catch _ {
                jsonObject = nil
            }

            guard let topObject = jsonObject as? NSDictionary else {
                self.loadingDialog?.dismissWithClickedButtonIndex(0, animated: true)
                return;
            }

            let defaultKeyfile: String = topObject["default_keyfile"] as! String
            
            let releases: NSArray = topObject["releases"] as! NSArray

            for release in releases {
                let melodyRelease = MelodyRelease()
                melodyRelease.version = release["version"] as! String
                melodyRelease.imageFileUrl = self.BASE_URL.URLByAppendingPathComponent(release["file_name"] as! String)

                let keyfile = release["keyfile"] as! String?
                melodyRelease.keyFileUrl = self.BASE_URL.URLByAppendingPathComponent(keyfile != nil ? keyfile! : defaultKeyfile)
                melodyRelease.releaseDate = formatter.dateFromString(release["release_date"] as! String)!

                self.availableImages.append(melodyRelease)
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.loadingDialog?.dismissWithClickedButtonIndex(0, animated: true)
                self.tableView.reloadData()
            })
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableImages.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) 

        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle

        cell.textLabel?.text = availableImages[indexPath.row].version
        cell.detailTextLabel?.text = formatter.stringFromDate(availableImages[indexPath.row].releaseDate)

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate.melodyRelease = availableImages[indexPath.row]
        navigationController?.popViewControllerAnimated(true)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
}
