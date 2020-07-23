//
//  NetParamsController.swift
//  UCSample
//
//  Created by portsip on 16/6/30.
//  Copyright © 2016 PortSIP. All rights reserved.
//
import UIKit
protocol NetParamsControllerDelegate {
    func didSelectValue(_ key: String, value: Int)

//    func didEndSelectValue(key:String,value:Int)
}

class NetParamsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tbView: UITableView!
    var data: [String]! = []
    var labletitle: String!
    var delegate: AnyObject!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.setNavigationBarHidden(false, animated: false)
        // self.navigationController!.title = labletitle;
        tbView.dataSource = self
        tbView.delegate = self
    }

    @IBAction func backButtonClicked(_: AnyObject) {
        navigationController!.popToRootViewController(animated: true)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if data != nil {
            return data.count
        }
        return 0
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: data[(indexPath as NSIndexPath).row])
        cell.textLabel!.text = data[(indexPath as NSIndexPath).row]
        return cell
    }

    func itemCellHeight(_: IndexPath) -> Float {
        44.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController!.popToRootViewController(animated: true)
        let tempdelegate = delegate as! NetParamsControllerDelegate
        tempdelegate.didSelectValue(labletitle, value: (indexPath as NSIndexPath).row)
    }
}
