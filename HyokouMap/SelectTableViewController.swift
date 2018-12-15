//
//  SelectTableViewController.swift
//  HyokouMap
//
//  Created by SawakiRyusuke on 2015/11/07.
//  Copyright © 2015年 SawakiRyusuke. All rights reserved.
//

import UIKit
import CoreData

protocol SelectTableViewControllerDelegate{
    func SelectTableViewControllerDidFinished(_ hyokoPoint: HyokoPoint)
}

class SelectTableViewController: UITableViewController {
    
    var delegate: SelectTableViewControllerDelegate! = nil
    var dataSoruce: [HyokoPoint] = []
    var mylist:Array<AnyObject>=[]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        //self.editButtonItem().title = "編集"
        
        readData()
        
        self.tableView.reloadData()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
/*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
*/
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataSoruce.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Configure the cell...
        let data = dataSoruce[indexPath.row]
        
        let memo = cell.viewWithTag(1) as! UILabel
        memo.text = data.memo
        
        let address = cell.viewWithTag(2) as! UILabel
        address.text = data.address
        
        let regist_dt = cell.viewWithTag(3) as! UILabel
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        regist_dt.text = dateFormatter.string(from: data.regist_dt! as Date)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        submit()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //remove(indexPath)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    func remove(_ indexPath: IndexPath){
        // Delete the row from the data source
        dataSoruce.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        context.delete(mylist[indexPath.row] as! NSManagedObject)
        mylist.remove(at: indexPath.row)
        
        // Save the context.
        do {
            try context.save()
        }catch{
            print("Unresolved error")
            abort()
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        self.editButtonItem.title = "キャンセル"
        
        // 編集
        let edit = UITableViewRowAction(style: .normal, title: "編集") {
            (action, indexPath) in
            
            //self.itemArray[indexPath.row] += "!!"
            //self.swipeTable.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            self.updateData(indexPath)
        }
        
        edit.backgroundColor = UIColor.lightGray
        
        // 削除
        let del = UITableViewRowAction(style: .default, title: "削除") {
            (action, indexPath) in
            //self.itemArray.removeAtIndex(indexPath.row)
            //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self.remove(indexPath)
        }
        
        del.backgroundColor = UIColor.red
        
        return [edit, del]
    }
    
    func updateData(_ indexPath: IndexPath) {
        let alertController = UIAlertController(title: "更新します。", message: "メモ", preferredStyle: .alert)
        let cancelAction:UIAlertAction = UIAlertAction(title: "Cancel",
            style: UIAlertActionStyle.cancel,
            handler:{
                (action:UIAlertAction!) -> Void in
                //println("Cancel")
        })
        alertController.addAction(cancelAction)
        let defaultAction:UIAlertAction = UIAlertAction(title: "OK",
            style: UIAlertActionStyle.default,
            handler:{
                (action:UIAlertAction!) -> Void in
                let textFields:Array<UITextField>? =  alertController.textFields as Array<UITextField>?
                if textFields != nil {
                    for textField:UITextField in textFields! {
                        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                        let context: NSManagedObjectContext = appDel.managedObjectContext
                        
                        let hyokoPoint = self.mylist[indexPath.row] as! HyokoPoint
                        hyokoPoint.memo = textField.text
                        
                        // Save the context.
                        do {
                            try context.save()
                        }catch{
                            print("Unresolved error")
                            abort()
                        }
                        self.tableView.reloadData()
                    }
                }
        })
        
        alertController.addAction(defaultAction)
        alertController.addTextField(configurationHandler: {(text:UITextField!) -> Void in
        })
        present(alertController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // 読み込み処理（readBtnのアクション）
    func readData() {
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        let request: NSFetchRequest = NSFetchRequest(entityName: "HyokoPoint")
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = [NSSortDescriptor(key: "regist_dt", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            //lef results: NSArray! = context.executeFetchRequest(request)
            mylist = results as Array<AnyObject>
            
            //memos = []
            //dates = []
            dataSoruce = []
            
            for data in results {
                //memos.append(data.memo)
                //dates.append(data.date)
                // コンソールに表示
                //print(data)
                dataSoruce.append(data as! HyokoPoint)
                
                //dataSoruce.addObject(data)
            }
        } catch {
            
        }
        // ナビゲーションバー表示
        self.navigationController?.isNavigationBarHidden = false
        
    }

    @IBAction func btnBack(_ sender: AnyObject) {
        //self.dismissViewControllerAnimated(true, completion: {});
        self.navigationController?.popViewController(animated: true)
    }
    
    func submit(){
        let index = self.tableView.indexPathForSelectedRow?.row
        self.delegate.SelectTableViewControllerDidFinished(self.dataSoruce[index!])
        //self.dismissViewControllerAnimated(true, completion: {});
        self.navigationController?.popViewController(animated: true)
    }
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
