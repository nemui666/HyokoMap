//
//  ViewController.swift
//  HyokouMap
//
//  Created by SawakiRyusuke on 2015/11/07.
//  Copyright © 2015年 SawakiRyusuke. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SwiftyJSON
import CoreData
import Social

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UISearchBarDelegate,SelectTableViewControllerDelegate,NADViewDelegate,NADInterstitialDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var lbElevetion: UILabel!
    //@IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var lbAddress: UILabel!
    @IBOutlet weak var dummyView: UIView!
    var locationManager: CLLocationManager!
    var userLocation: CLLocationCoordinate2D!
    var userLocAnnotation: GMSMarker!
    var prevElevation: String!
    var annotations: [MKAnnotation] = []
    var mapView: GMSMapView!
    var focusImg:UIImageView!
    var zoomLevel:Float!
    
    // グラフ用
    var dataSource:[Double] = []
    
    // 距離計測用
    var distancePath:GMSMutablePath!
    var distanceMarker:[GMSMarker] = []
    var distancePolyline:[GMSPolyline] = []
    
    // 国土地理院
    var kokudoLayer:GMSURLTileLayer!
    var kokudoAltLayer:GMSURLTileLayer!
    
    // 広告
    var nadView:NADView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        lbElevetion.text = ""
        lbAddress.text = ""
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        zoomLevel = 14
        let camera:GMSCameraPosition = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0, width: self.view.bounds.width+10, height: self.view.bounds.height-44), camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        mapView.isUserInteractionEnabled = true
        //mapView.settings.myLocationButton = true
        
        self.dummyView.addSubview(mapView)
        
        searchBar.delegate = self
        
        // 位置情報取得の許可状況を確認
        let status = CLLocationManager.authorizationStatus()
        
        // 許可が場合は確認ダイアログを表示
        if(status == CLAuthorizationStatus.notDetermined) {
            print("didChangeAuthorizationStatus:\(status)");
            self.locationManager.requestAlwaysAuthorization()
        }
        //位置情報の精度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //位置情報取得間隔(m)
        locationManager.distanceFilter = 300
        locationManager.startUpdatingLocation()
        
        // 検索用品
        //userLocAnnotation = MKPointAnnotation()
        userLocAnnotation = GMSMarker()
        
        // 地図上に線を描く
        distancePath = GMSMutablePath()
        
        // フォーカス画像セット
        let image = UIImage(named:"reticle")
        focusImg = UIImageView(image: image)
        focusImg.alpha = 0.6
        focusImg.isHidden = true
        self.mapView.addSubview(focusImg)
        
        // ナビゲーションバー非表示
        self.navigationController?.isNavigationBarHidden = true
        
        // 古い標高MAP読み込み
        oldHyokoMapLoad()
        
        // slidingView
        self.view.addGestureRecognizer(self.slidingViewController().panGesture)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // 距離ライン再表示
        for (ii in 0 ..< distanceMarker.count) {
            distanceMarker[ii].map = mapView
            distancePolyline[ii].map = mapView
        }
        
        // ピンを再表示
        readData()
        
        // フォーカス画像の設定
        let point = self.mapView.projection.point(for: self.mapView.projection.coordinate(for: mapView.center))
        //let image = UIImage(named:"reticle")
        //let imageView = UIImageView(image: image)
        focusImg.isHidden = false
        focusImg.center = point

        // キーボードが出てたら閉じる
        searchBar.resignFirstResponder()
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            //println("iPhone")
            showNend2()
        }else if UIDevice.current.userInterfaceIdiom == .pad{
            //println("iPad")
            showNend()
        }else{
            //println("Unspecified")
            showNend()
        }
        
        // 国土地理院たいる読み込み
        let urls = { (x: UInt, y: UInt, zoom: UInt) -> URL in
            let url = String(format:"http://cyberjapandata.gsi.go.jp/xyz/std/%d/%d/%d.png",zoom,x,y)
            //print(url)
            return URL(string: url)!
        }
        
        // Create the GMSTileLayer
        kokudoLayer = GMSURLTileLayer(urlConstructor: urls)
        
        // Display on the map at a specific zIndex
        kokudoLayer.zIndex = 100
        kokudoLayer.map = nil
        
        // 国土地理院たいる読み込み
        let urls2 = { (x: UInt, y: UInt, zoom: UInt) -> URL in
            let url = String(format:"http://cyberjapandata.gsi.go.jp/xyz/relief/%d/%d/%d.png",zoom,x,y)
            //print(url)
            return URL(string: url)!
        }
        
        // Create the GMSTileLayer
        kokudoAltLayer = GMSURLTileLayer(urlConstructor: urls2)
        kokudoAltLayer.zIndex = 100
        kokudoAltLayer.map = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 位置情報取得に成功したときに呼び出されるデリゲート.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        userLocation = CLLocationCoordinate2DMake(manager.location!.coordinate.latitude, manager.location!.coordinate.longitude)
        
        //let userLocAnnotation: MKPointAnnotation = MKPointAnnotation()
        //userLocAnnotation.coordinate = userLocation
        //userLocAnnotation.title = "現在地"
        //mapView.addAnnotation(userLocAnnotation)
        
        let now :GMSCameraPosition = GMSCameraPosition.camera(withLatitude: manager.location!.coordinate.latitude,longitude: manager.location!.coordinate.longitude,zoom:zoomLevel)
        
        mapView.camera = now
        
        getElevation()
        
        locationManager.stopUpdatingLocation()

    }
    
    // 位置情報取得に失敗した時に呼び出されるデリゲート.
    func locationManager(_ manager: CLLocationManager,didFailWithError error: Error){
        print("locationManager error")
    }
    /*
    func mapView(mapView: YMKMapView!, regionWillChangeAnimated animated: Bool) {

        print("regionWillChangeAnimated:");
    }
    */
    
    // 中心を取得
    func getCenterLocation()->CLLocationCoordinate2D{
        //TODO:マップの中心位置を取得
        let centerCoordinate = self.mapView.projection.coordinate(for: mapView.center)

        return centerCoordinate;
    }
    
    // 指定場所に移動
    func setCoordinate(_ coordinate:CLLocationCoordinate2D,zoom:Float){
        let now :GMSCameraPosition = GMSCameraPosition.camera(withLatitude: coordinate.latitude,longitude: coordinate.longitude,zoom:zoom)
        mapView.camera = now
    }
    
    func getElevation(){
        let strURL = NSString(
            format:"http://maps.googleapis.com/maps/api/elevation/json?locations=%f,%f&sensor=false"
            ,self.getCenterLocation().latitude
            ,self.getCenterLocation().longitude)
        
        let URL = Foundation.URL(string: strURL as String)
        
        let req = URLRequest(url: URL!)
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate:nil, delegateQueue:OperationQueue.main)
        
        let task = session.dataTask(with: req, completionHandler: {
            (data, response, error) -> Void in
            
            let json = JSON(data: data!)
            let elevation = json["results"][0]["elevation"].doubleValue
            self.lbElevetion.text = String(format: "%.1fm", elevation)
            self.prevElevation = String(format: "%.1f", elevation)
            
        })
        
        task.resume()
        
        // ジオコード
        self.lbAddress.text = ""
        let location = CLLocation(latitude: self.getCenterLocation().latitude, longitude: self.getCenterLocation().longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: {
            (placemarks, error) -> Void in
            if (error == nil && placemarks!.count > 0) {
                let placemark = placemarks![0] as CLPlacemark
                /*
                print("Country = \(placemark.country)")
                print("Postal Code = \(placemark.postalCode)")
                print("Administrative Area = \(placemark.administrativeArea)")
                print("Sub Administrative Area = \(placemark.subAdministrativeArea)")
                print("Locality = \(placemark.locality)")
                print("Sub Locality = \(placemark.subLocality)")
                print("Throughfare = \(placemark.thoroughfare)")
                */
                if (placemark.administrativeArea != nil) {
                    self.lbAddress.text = String(format: "%@"
                        , placemark.administrativeArea!)
                }
                if (placemark.locality != nil) {
                    self.lbAddress.text = String(format: "%@%@周辺"
                        , self.lbAddress.text!
                        , placemark.locality!)
                }
                /*
                if (placemark.thoroughfare != nil) {
                    self.lbAddress.text = String(format: "%@%@"
                        , self.lbAddress.text!
                        , placemark.thoroughfare!)
                }
*/
                
            } else if (error == nil && placemarks!.count == 0) {
                print("No results were returned.")
            } else if (error != nil) {
                print("An error occured = \(error!.localizedDescription)")
            }
        })
    }
    
    func mapView(_ mapView: GMSMapView!, didChange position: GMSCameraPosition!) {

        //print("regionDidChangeAnimated:")
        self.slidingViewController().resetTopView(animated: true)
        
        
    }
    func mapView(_ mapView: GMSMapView!, idleAt position: GMSCameraPosition!) {
        getElevation()
        searchBar.resignFirstResponder()
        self.slidingViewController().resetTopView(animated: true)
    }

    @IBAction func mapTap(_ sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.slidingViewController().resetTopView(animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        let strURL = NSString(format:"http://maps.google.com/maps/api/geocode/json?address=%@&sensor=false"
            ,self.searchBar.text!)
        
        let URL = Foundation.URL(string: strURL.addingPercentEscapes(using: String.Encoding.utf8.rawValue)! as String)
        
        let req = URLRequest(url: URL!)
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate:nil, delegateQueue:OperationQueue.main)
        
        let task = session.dataTask(with: req, completionHandler: {
            (data, response, error) -> Void in

            let json = JSON(data: data!)
            
            //print(json["results"][0]["geometry"]["location"]["lat"])
            
            let searchLocation = CLLocationCoordinate2DMake(json["results"][0]["geometry"]["location"]["lat"].doubleValue, json["results"][0]["geometry"]["location"]["lng"].doubleValue)
    
            self.setCoordinate(searchLocation, zoom: self.zoomLevel)
            
        })

        task.resume()
        searchBar.resignFirstResponder()
    }
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        performSegue(withIdentifier: "SegSelectTableView", sender: nil)
    }
    @IBAction func btnAddHyokoPoint(_ sender: AnyObject) {
        writeData()
    }
    // タップイベント.
    func tapAddHyokoPoint(_ sender: UITapGestureRecognizer){
        writeData()
    }
    // 書き込み処理（writeBtnのアクション）
    func writeData() {
        let alertController = UIAlertController(title: "保存します。", message: "メモ", preferredStyle: .alert)
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
                
                // 近くにいるか判定
                let yodobashiUmedaPoint = self.mapView.myLocation.coordinate // 中心緯度経度
                let yodobashiUmedaRadius:CLLocationDistance = 100.0; // 半径100m
                let yodobashiUmedaArea = MKCircle(center: yodobashiUmedaPoint, radius: yodobashiUmedaRadius)
                
                // ユーザーの座標
                let userCoordinate:CLLocationCoordinate2D = self.getCenterLocation()
                let userLocationMapPoint:MKMapPoint = MKMapPointForCoordinate(userCoordinate)
                
                // パスをオフスクリーン描画
                let yodobashiUmedaRenderer = MKCircleRenderer.init(circle: yodobashiUmedaArea)
                yodobashiUmedaRenderer.createPath()
                
                // ユーザーの座標を CGPoint に変換
                let userLocationPoint:CGPoint = yodobashiUmedaRenderer.point(for: userLocationMapPoint)
                
                // ユーザーの座標がパスに含まれるかを判定
                if (CGPathContainsPoint(yodobashiUmedaRenderer.path, nil, userLocationPoint, false)) {
                    print("近くにいるよ")
                }
                else {
                    print("いないよ")
                }
                
                let textFields:Array<UITextField>? =  alertController.textFields as Array<UITextField>?
                if textFields != nil {
                    for textField:UITextField in textFields! {
                        //各textにアクセス
                        //println(textField.text)
                        self.insertHyokoPoint(
                              String(format: "%f", self.getCenterLocation().latitude)
                            , longitude: String(format: "%f", self.getCenterLocation().longitude)
                            , elevation: self.prevElevation
                            , address: self.lbAddress.text!
                            , memo: textField.text!
                            , regist_dt: Date()
                        )
                        self.readData()
                    }
                }
        })
        
        alertController.addAction(defaultAction)
        alertController.addTextField(configurationHandler: {(text:UITextField!) -> Void in
        })
        present(alertController, animated: true, completion: nil)
    }
    func insertHyokoPoint(_ latitude:String,longitude:String,elevation:String,address:String,memo:String,regist_dt:Date){
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        let entity: NSEntityDescription! = NSEntityDescription.entity(forEntityName: "HyokoPoint", in: context)
        let newData = HyokoPoint(entity: entity, insertInto: context)
        newData.latitude = latitude
        newData.longitude = longitude
        newData.elevation = elevation
        newData.address = address
        newData.memo = memo
        newData.regist_dt = regist_dt
        do {
            try context.save()
        } catch {
            print("保存失敗")
        }
    }
    // 読み込み処理（readBtnのアクション）
    func readData() {
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        let request: NSFetchRequest = NSFetchRequest(entityName: "HyokoPoint")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            //lef results: NSArray! = context.executeFetchRequest(request)
            
            //memos = []
            //dates = []
            
            annotations = []
        
            //mapView.clear()
            
            for data in results {
                //memos.append(data.memo)
                //dates.append(data.date)
                // コンソールに表示
                //print(data)
                let hyokoPoint = data as! HyokoPoint
                
                
                let latitude:NSString = hyokoPoint.latitude! as NSString
                let longitude:NSString = hyokoPoint.longitude! as NSString
                
                let marker = GMSMarker()
                //marker.title = "標高：" + hyokoPoint.elevation! + "m"
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .short
                dateFormatter.dateStyle = .short
                marker.title = dateFormatter.string(from: hyokoPoint.regist_dt! as Date)
                marker.snippet = hyokoPoint.memo
                marker.position = CLLocationCoordinate2DMake(latitude.doubleValue,longitude.doubleValue)
                //marker.icon = UIImage(named: "map_pin_bookmark")
                marker.map = self.mapView;
                //marker.userData = [NSNumber numberWithInteger:markerIdYodobashi];
            }
            
            // 距離ライン再表示
            for (ii in 0 ..< distanceMarker.count) {
                distanceMarker[ii].map = mapView
                distancePolyline[ii].map = mapView
            }
            //mapView.addAnnotations(annotations)
        } catch {
            return
        }
    }
    
    func SelectTableViewControllerDidFinished(_ hyokoPoint: HyokoPoint) {
        let latitude:NSString = hyokoPoint.latitude! as NSString
        let longitude:NSString = hyokoPoint.longitude! as NSString
        let coordinate = CLLocationCoordinate2DMake(latitude.doubleValue,longitude.doubleValue)
        self.setCoordinate(coordinate,zoom: zoomLevel)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! SelectTableViewController
        vc.delegate = self
    }
    @IBAction func btnHome(_ sender: AnyObject) {
        locationManager.startUpdatingLocation()
    }
    @IBAction func longPressGestuer(_ sender: AnyObject) {
        //let annotation: MKPointAnnotation = MKPointAnnotation()
        //let gesture = sender as! UILongPressGestureRecognizer
        //let coord = self.mapView.convertPoint(sender.locationInView(self.view), toCoordinateFromView: self.mapView)
        //annotation.coordinate = coord
        //mapView.addAnnotation(annotation)
        //distance.append(annotation)
    }
    @IBAction func btnAction(_ sender: AnyObject) {
        self.slidingViewController().anchorTopViewToRight(animated: true)
    }
    internal func sharHyokoMap() {
        // 共有する項目
        let shareText = "この場所の標高：" + lbElevetion.text!
        let strUrl = String(format:"http://maps.google.co.jp/maps?q=%f,%f",self.getCenterLocation().latitude,self.getCenterLocation().longitude)
        let shareWebsite = URL(string: strUrl)!
        
        let activityItems = [shareText, shareWebsite] as [Any]
        
        // 初期化処理
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // 使用しないアクティビティタイプ
        let excludedActivityTypes = [
            UIActivityType.postToWeibo,
            UIActivityType.saveToCameraRoll,
            UIActivityType.print
        ]
        
        activityVC.excludedActivityTypes = excludedActivityTypes
        
        // UIActivityViewControllerを表示
        activityVC.popoverPresentationController?.sourceView = self.view; // 追加
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func btnZoomUp(_ sender: AnyObject) {
        zoomLevel = zoomLevel + 1
        setCoordinate(getCenterLocation(),zoom: zoomLevel)
    }
    @IBAction func btnZoomDown(_ sender: AnyObject) {
        zoomLevel = zoomLevel - 1
        setCoordinate(getCenterLocation(),zoom: zoomLevel)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //getElevation()
    }
    @IBAction func btnDistanceRedo(_ sender: AnyObject) {
        if (distanceMarker.count == 0) {
           return
        }
        // ラインの削除
        distancePath.removeLastCoordinate()
        distancePolyline[distancePolyline.count-1].map = nil
        distancePolyline.removeLast()
        // マーカーの削除
        distanceMarker[distanceMarker.count-1].map = nil
        distanceMarker.removeLast()
        
        dataSource = []
        //plot.reloadData()
        //distanceLoad()
        //graphLoad()
        
    }
    @IBAction func btnDistanceRemove(_ sender: AnyObject) {
        for marker in distanceMarker {
            marker.map = nil
        }
        for porylyne in distancePolyline {
            porylyne.map = nil
        }
        distancePath.removeAllCoordinates()
        dataSource = []
    }
    @IBAction func btnDistance(_ sender: AnyObject) {
        distancePath.add(getCenterLocation())
        distanceLoad()
        //graphLoad()
    }
    
    func distanceLoad(){
        let porylyne = GMSPolyline(path: distancePath)
        porylyne?.strokeWidth = 2
        porylyne?.strokeColor = UIColor.blue
        porylyne?.zIndex = 200
        porylyne.map = mapView
        distancePolyline.append(porylyne!)
    
        var totalDistance:Double = 0
        for (ii:UInt in 1 ..< distancePath.count()) {
            let 現在地の緯度: Double = distancePath.coordinate(at: ii-1).latitude
            let 現在地の経度: Double = distancePath.coordinate(at: ii-1).longitude
            let 行き先の緯度: Double = distancePath.coordinate(at: ii).latitude
            let 行き先の経度: Double = distancePath.coordinate(at: ii).longitude
            let 現在地の位置情報: CLLocation = CLLocation(latitude: 現在地の緯度, longitude: 現在地の経度)
            let 行き先の位置情報: CLLocation = CLLocation(latitude: 行き先の緯度, longitude: 行き先の経度)
            let distance:Double = 行き先の位置情報.distance(from: 現在地の位置情報)
            totalDistance = totalDistance + distance
        }
        
        let marker = GMSMarker()
        //marker.title = "標高：" + hyokoPoint.elevation! + "m"
        //marker.snippet = hyokoPoint.memo
        marker.icon = getDistanceMarker(totalDistance)
        marker.position = CLLocationCoordinate2DMake(getCenterLocation().latitude,getCenterLocation().longitude)
        marker.map = self.mapView;
        distanceMarker.append(marker)
    }
    
    func graphLoad(){
        
        var totalDistance:Double = 0
        var maxElevation:Double = 0
        self.dataSource = []
        for (ii:UInt in 1 ..< distancePath.count()) {
            let 現在地の緯度: Double = distancePath.coordinate(at: ii-1).latitude
            let 現在地の経度: Double = distancePath.coordinate(at: ii-1).longitude
            let 行き先の緯度: Double = distancePath.coordinate(at: ii).latitude
            let 行き先の経度: Double = distancePath.coordinate(at: ii).longitude
            let 現在地の位置情報: CLLocation = CLLocation(latitude: 現在地の緯度, longitude: 現在地の経度)
            let 行き先の位置情報: CLLocation = CLLocation(latitude: 行き先の緯度, longitude: 行き先の経度)
            let distance:Double = 行き先の位置情報.distance(from: 現在地の位置情報)
            totalDistance = totalDistance + distance
            
            // ---------------------------------------------------
            // 高度表の作成
            var samples = 2
            if (ceil(distance/100) == 1) {
                samples = 2
            } else {
                samples = Int(ceil(distance/100))
            }
            let strURL = NSString(format:"http://maps.googleapis.com/maps/api/elevation/json?path=%f,%f|%f,%f&samples=%d"
                ,distancePath.coordinate(at: ii-1).latitude
                ,distancePath.coordinate(at: ii-1).longitude
                ,distancePath.coordinate(at: ii).latitude
                ,distancePath.coordinate(at: ii).longitude
                ,samples
            )
            let URL = Foundation.URL(string: strURL.addingPercentEscapes(using: String.Encoding.utf8.rawValue)! as String)
            
            let req = URLRequest(url: URL!)
            var res:URLResponse?
            do {
                let data = try NSURLConnection.sendSynchronousRequest(req, returning: &res)
                let json = JSON(data: data)
                //print(strURL)
                //print(json["results"])
                
                for var jj = 0;jj < json["results"].count;jj += 1 {
                    if (json["results"][jj]["location"]["lat"] != 0){
                        self.dataSource.append(json["results"][jj]["elevation"].doubleValue)
                        
                        //print(json["results"][jj]["elevation"].doubleValue)
                        
                        // 最大標高を取得
                        if (maxElevation < json["results"][jj]["elevation"].doubleValue){
                            maxElevation = json["results"][jj]["elevation"].doubleValue
                        }
                    }
                }
            }catch{
                
            }
            
        }

    }
    
    func getDistanceMarker(_ distance:Double)->UIImage{
        
        let strDistance:NSString = NSString(format: "%.0fm", distance)
        let textFontAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 13),
            NSBackgroundColorAttributeName: UIColor.clear,
            NSForegroundColorAttributeName: UIColor.white];
        
        let size = strDistance.size(attributes: textFontAttributes)
        //let space:CGFloat = 5
        let width = size.width+10
        let height = size.height+10
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0);
        //let context = UIGraphicsGetCurrentContext();
        //let rect = CGRectMake(0, 0, 30, 20);
        //CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor);
        //CGContextFillRect(context, rect);
        
        let path_triangle = UIBezierPath();
        path_triangle.move(to: CGPoint(x: 2, y: 2));//始点
        path_triangle.addLine(to: CGPoint(x: width-2, y: 2));//次の点
        path_triangle.addLine(to: CGPoint(x: width-2, y: height-5));//次の点
        path_triangle.addLine(to: CGPoint(x: (width/2)+3, y: height-5));//次の点
        path_triangle.addLine(to: CGPoint(x: width/2, y: height-2));
        path_triangle.addLine(to: CGPoint(x: (width/2)-3, y: height-5));
        path_triangle.addLine(to: CGPoint(x: 2, y: height-5));//終点（最初の点）
        path_triangle.addLine(to: CGPoint(x: 2, y: 2));//終点（最初の点）
        
        // 塗りつぶし色の設定
        UIColor.red.setFill()
        // 内側の塗りつぶし
        path_triangle.fill()
        
        // stroke 色の設定
        UIColor.white.setStroke()
        // ライン幅
        path_triangle.lineWidth = 1
        // 描画
        path_triangle.stroke()
        
        //let image:UIImage = UIImage(named: "mk_distance")!
        //image.drawInRect(CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 30, height: 30)))
        
        strDistance.draw(at: CGPoint(x: 3,y: 2), withAttributes: textFontAttributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func showNend() {
        NADInterstitial.sharedInstance().loadAd(withApiKey: "6e007e415e88cc09117669a745d788ee74798e9b", spotId: "492795")
        //NADInterstitial.sharedInstance().loadAdWithApiKey("308c2499c75c4a192f03c02b2fcebd16dcb45cc9", spotId: "213208")
        NADInterstitial.sharedInstance().delegate = self
    //}
    //func didFinishLoadInterstitialAdWithStatus(status: NADInterstitialStatusCode) {
        var showResult: NADInterstitialShowResult
        showResult = NADInterstitial.sharedInstance().showAd()
        
        switch(showResult.rawValue){
        case AD_SHOW_SUCCESS.rawValue:
            print("広告の表示に成功しました。")
            break
        case AD_SHOW_ALREADY.rawValue:
            print("既に広告が表示されています。")
            break
        case AD_FREQUENCY_NOT_REACHABLE.rawValue:
            print("広告のフリークエンシーカウントに達していません。")
            break
        case AD_LOAD_INCOMPLETE.rawValue:
            print("抽選リクエストが実行されていない、もしくは実行中です。")
            break
        case AD_REQUEST_INCOMPLETE.rawValue:
            print("抽選リクエストに失敗しています。")
            showNend3()
            break
        case AD_DOWNLOAD_INCOMPLETE.rawValue:
            print("広告のダウンロードが完了していません。")
            break
        default:
            break
        }
    }
    
    func showNend2(){
        nadView = NADView(frame: CGRect(x: 0, y: 44, width: 320, height: 50), isAdjustAdSize: true)
        // 広告枠のapikey/spotidを設定(必須)
        nadView.setNendID("70832fb49e0aa3266dfaeec42fd2abebfdc70b10", spotID: "73723")
        //nadView.setNendID("a6eca9dd074372c898dd1df549301f277c53f2b9", spotID: "3172")
        // nendSDKログ出力の設定(任意)
        nadView.isOutputLog = false
        // delegateを受けるオブジェクトを指定(必須)
        nadView.delegate = self
        // 読み込み開始(必須)
        nadView.load()
        // 通知有無にかかわらずViewに乗せる場合
        self.view.addSubview(nadView)
    }
    func showNend3(){
        nadView = NADView(frame: CGRect(x: 0, y: 44, width: 728, height: 90), isAdjustAdSize: true)
        // 広告枠のapikey/spotidを設定(必須)
        nadView.setNendID("adb1c4a74d1c359d3df71ae8a8f6223ff8590747", spotID: "516932")
        //nadView.setNendID("a6eca9dd074372c898dd1df549301f277c53f2b9", spotID: "3172")
        // nendSDKログ出力の設定(任意)
        nadView.isOutputLog = false
        // delegateを受けるオブジェクトを指定(必須)
        nadView.delegate = self
        // 読み込み開始(必須)
        nadView.load()
        // 通知有無にかかわらずViewに乗せる場合
        self.view.addSubview(nadView)
    }
    func nadViewDidFinishLoad(_ adView: NADView!) {
        print("delegate nadViewDidFinishLoad:")
        self.view.addSubview(nadView) // ロードが完了してから NADView を表示する場合
    }
    func oldHyokoMapLoad(){
        let ud = UserDefaults.standard
        let oldData:AnyObject? = ud.object(forKey: "old_data_read") as AnyObject?
        
        if (oldData == nil) {
            //let filePath = NSBundle.mainBundle().pathForResource(BMK_FIL_NAM, ofType:nil )!
            let paths1 = NSSearchPathForDirectoriesInDomains(
                .documentDirectory,
                .userDomainMask, true)
            let filePath = paths1[0] + "/" + BMK_FIL_NAM
            print(filePath)
            if (FileManager.default.fileExists(atPath: filePath)){
                let plists = NSMutableArray(contentsOfFile: filePath)
                for plist in plists! {
                    let dic = plist as! NSDictionary
                    //print(dic.objectForKey("latitude"))
                    //print(dic.objectForKey("longitude"))
                    print(dic.object(forKey: "dateTime"))
                    //print(dic.objectForKey("altitude"))
                    let fmt = DateFormatter()
                    fmt.dateFormat = "yyyy-MM-dd(EEE) HH:mm:ss"
                    let date = fmt.date(from: dic.object(forKey: "dateTime") as! String)
                    self.insertHyokoPoint(
                        dic.object(forKey: "latitude") as! String
                        , longitude: dic.object(forKey: "longitude") as! String
                        , elevation: dic.object(forKey: "altitude") as! String
                        , address: dic.object(forKey: "addressName") as! String
                        , memo: ""
                        , regist_dt: date!
                    )
                }
            }
            ud.set("old_data_readed", forKey: "old_data_read")
            self.readData()
        }
    }
}


