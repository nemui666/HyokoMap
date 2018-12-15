//
//  SelectTableViewController.swift
//  HyokouMap
//
//  Created by SawakiRyusuke on 2015/11/07.
//  Copyright © 2015年 SawakiRyusuke. All rights reserved.
//

import UIKit
import ECSlidingViewController

protocol MenuTableViewControllerDelegate{
    func MenuTableViewControllerDidFinished(_ hyokoPoint: HyokoPoint)
}

class MenuTableViewController: UITableViewController {
    
    var delegate: SelectTableViewControllerDelegate! = nil
    var mapvc:ViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        let nc = self.slidingViewController().topViewController as! UINavigationController
        mapvc = nc.topViewController as! ViewController
        
        self.tableView.backgroundColor = UIColor.white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func submit(){
        /*
        let index = self.tableView.indexPathForSelectedRow?.row
        self.delegate.SelectTableViewControllerDidFinished(self.dataSoruce[index!])
        //self.dismissViewControllerAnimated(true, completion: {});
        self.navigationController?.popViewControllerAnimated(true)
*/
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.section {
        case 0:
            //mapvc.kokudoLayer.map = nil
            mapvc.mapView.clear()
            switch indexPath.row {
            case 0:
                mapvc.mapView.mapType = kGMSTypeNormal
            case 1:
                mapvc.mapView.mapType = kGMSTypeHybrid
            case 2:
                mapvc.mapView.mapType = kGMSTypeSatellite
            case 3:
                mapvc.mapView.mapType = kGMSTypeTerrain
            case 4:
                mapvc.kokudoLayer.map = mapvc.mapView
            case 5:
                mapvc.kokudoAltLayer.map = mapvc.mapView
            default:
                break // do nothing
            }
            mapvc.readData()
            self.slidingViewController().resetTopView(animated: true)
        case 1:
            switch indexPath.row {
            case 0:
                mapvc.sharHyokoMap()
            default:
                break // do nothing
            }
        default:
            break // do nothing
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    @IBAction func btnBack(_ sender: AnyObject) {
        self.slidingViewController().resetTopView(animated: true)
    }
}
