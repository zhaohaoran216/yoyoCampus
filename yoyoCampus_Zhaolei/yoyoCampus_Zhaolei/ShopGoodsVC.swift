//
//  ShopGoodsVC.swift
//  yoyoCampus_Zhaolei
//
//  Created by 浩然 on 15/11/16.
//  Copyright © 2015年 赵磊. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MJRefresh

class ShopGoodsVC: UIViewController,UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate ,APIDelegate{
  
    var isSingleView = Bool()
    var groupURL = String()
    
    //两种咨询方式
    var popMenu = PopMenu()
    
    //打电话发短信
    var app = UIApplication.sharedApplication()
    
    var api = YoYoAPI()
    
    var shopIsCollected:Bool = false
    
    var shopPhoneNum = ""
    
    var shopDetailURL:String = ""
    
    var collectShopURL:String = ""
    
    var cancelCollectShopURL:String = ""
    
    var collectBtn = UIButton()
    
    var consultBtn = UIButton()
    
    internal var shopID:String = ""
    
    var shopTitleName = String()
    
    var navBtnView = UIView(frame: CGRectMake(windowWidth*0.9, 20, windowWidth*0.2, 64))

    var pageView = UIPageControl()
    var scrollBtnView = UIScrollView()
    var scrollIndicator = UIScrollView()
    var viewCount = Int()
    var viewArray = NSMutableArray()
    var tableViewArray = NSMutableArray()
    var groupArray = NSMutableArray()
    var btnArray = NSMutableArray()
    var rootView = UIScrollView()
    var resultData = NSMutableArray()
    
    var pageArray = [Int]()
    var dataNum = 0
    
    var oldPage = 0
    
    var moreX = CGFloat()
    var lessX : CGFloat = 0
    var btnLeftX : CGFloat = 0
    var btnWidth  = CGFloat()
    
    var oldBtnTag:Int = 0
    var newBtnTag:Int = 0
    
    override func viewWillAppear(animated: Bool) {

        self.scrollBtnView.contentOffset.x = self.lessX
        self.scrollIndicator.contentOffset.x = -self.btnLeftX - self.lessX
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = Consts.grayView
        super.viewDidLoad()
        self.httpGetGroup()
        Consts.setUpNavigationBarWithBackButton(self, title: self.shopTitleName , backTitle: "<")
        
        api.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func httpGetGroup(){
        
        self.groupURL = "http://api2.hloli.me:9001/v1.0/shop/\(shopID)/group/"
        
        Alamofire.request(.GET, self.groupURL, headers: httpHeader).responseJSON(options: NSJSONReadingOptions.MutableContainers){
            response in
            let json = JSON(response.result.value!)
            var responseJson = json["group"]
            for(var num = 0 ; num < responseJson.count ; num++){
                self.groupArray.addObject(responseJson.arrayObject![num])
            }
            if(responseJson.count == 0){
                self.isSingleView = true
                self.viewCount = 1
                self.httpSingleGroupGetGoods()
            }
            if(responseJson.count != 0){
                self.isSingleView = false
                self.viewCount = responseJson.count
                self.httpMutableGroupGetGoods(0)
            }
            
        }
    }
    func httpSingleGroupGetGoods(){
        Alamofire.request(.GET, "http://api2.hloli.me:9001/v1.0/goods/search/", parameters: ["page":"1","location":"东南大学九龙湖校区","shop_id":self.shopID], headers: httpHeader).responseJSON(options: NSJSONReadingOptions.MutableContainers){
            response in
            let json = JSON(response.result.value!)
            var responseJson = json["result"]
            self.pageArray.append(1)
            for(var num = 0 ; num < responseJson.count ; num++){
                self.resultData.addObject(responseJson.arrayObject![num])
            }
            self.setView()
        }
        setUpOnlineData("shopDetail")
    }
    func httpMutableGroupGetGoods(nextData : Int){
        Alamofire.request(.GET, "http://api2.hloli.me:9001/v1.0/goods/search/",headers:httpHeader,parameters:["page":"1","location":"东南大学九龙湖校区","shop_id":self.shopID,"group":self.groupArray[nextData]]).responseJSON(options: NSJSONReadingOptions.MutableContainers){
            response in
            let json = JSON(response.result.value!)
            var responseJson = json["result"]
            self.didReceiveOneGroupData(responseJson.arrayObject!)
        }
    }
    func didReceiveOneGroupData(data : AnyObject){
        self.resultData.addObject(data)
        self.pageArray.append(1)
        self.dataNum++
        if(self.dataNum == self.viewCount){
            self.setView()
        }
        if(self.dataNum != self.viewCount){
            self.httpMutableGroupGetGoods(self.dataNum)
        }
        
        
    }
    
    func setView(){
        //根scrollview
        let scrollRootVC = UIScrollView(frame: CGRectMake(0, 0, windowWidth, windowHeight))
        scrollRootVC.delegate = self
        scrollRootVC.directionalLockEnabled = true
        scrollRootVC.showsHorizontalScrollIndicator = true
        scrollRootVC.showsVerticalScrollIndicator = false
        scrollRootVC.contentSize = CGSizeMake(windowWidth*CGFloat(self.viewCount), windowHeight-100)
        scrollRootVC.pagingEnabled = true
        self.rootView = scrollRootVC
        self.view.addSubview(scrollRootVC)
        
        //pageControl
        let pageCtl = UIPageControl(frame: CGRectMake(100, windowHeight-50, 50, 20))
        pageCtl.numberOfPages = Int(self.viewCount)
        pageCtl.currentPage = 0
        self.pageView = pageCtl
        self.view .addSubview(pageCtl)
        
        //btnView
        if(self.isSingleView == false){
            let scrollBtnView = UIScrollView(frame: CGRectMake(0,0,windowWidth,40))
            scrollBtnView.backgroundColor = UIColor.whiteColor()
            scrollBtnView.delegate = self
            scrollBtnView.directionalLockEnabled = true
            scrollBtnView.showsHorizontalScrollIndicator = false
            self.scrollBtnView = scrollBtnView
            scrollBtnView.contentSize = CGSizeMake(windowWidth, 40)
            if(self.viewCount > 4){
                self.moreX = CGFloat(80 * self.viewCount) - windowWidth
            }
            if(self.viewCount <= 4){
                self.moreX = 0
            }
            self.view.addSubview(scrollBtnView)
            
            //小绿条
            let scrollIndicator = UIScrollView()
            let indicatorView = UIView()
            scrollIndicator.frame = CGRectMake(0, 37, windowWidth, 3)
            scrollIndicator.contentSize = CGSize(width: windowWidth, height: 3)
            indicatorView.frame = CGRect(x: 0, y: 0, width: windowWidth/CGFloat(self.viewCount), height: 3)
            self.scrollBtnView.addSubview(scrollIndicator)
            self.scrollIndicator = scrollIndicator
            indicatorView.backgroundColor = UIColor(red: 73/255, green: 185/255, blue: 162/255, alpha: 1)
            scrollIndicator.addSubview(indicatorView)
            
            //btn
            var btnX:CGFloat = 0
            var btnWidth = CGFloat()
            if(self.viewCount > 4){
                btnWidth = 80
                self.btnWidth = 80
            }
            if(self.viewCount <= 4){
                btnWidth = windowWidth / CGFloat(self.viewCount)
                self.btnWidth = btnWidth
            }
            
            for(var num = 0 ; num < self.viewCount ; num++){
                let btn = UIButton(frame: CGRectMake(btnX ,0, btnWidth, 37))
                btn.setTitleColor(UIColor(red: 90/255, green: 90/255, blue: 90/255, alpha: 1), forState: UIControlState.Normal)
                btn.titleLabel?.font = UIFont.systemFontOfSize(16)
                self.scrollBtnView.addSubview(btn)
                //还不知道有分组的店铺里面是什么样的
                btn.setTitle( (self.groupArray[num] as! String), forState: UIControlState.Normal)
                btn.tag = num
                btn.addTarget(self, action: Selector("pageTurn:"), forControlEvents: UIControlEvents.TouchUpInside)
                btnX += btnWidth
                self.btnArray.addObject(btn)
           }
            self.btnColorChange(0)
       
       }
        //放table的view
        var viewX : CGFloat = 0
        for(var num = 0 ; num < self.viewCount ; num++){
            let view = UIView(frame: CGRectMake(viewX, 0, windowWidth, windowHeight))
            view.backgroundColor = UIColor(red: 235/255, green: 234/255, blue: 234/255, alpha: 1)
            self.rootView.addSubview(view)
            self.viewArray.addObject(view)
            viewX += windowWidth
        }
        
        //tableView
        for(var num = 0 ; num < self.viewCount ; num++){
            var tableView = UITableView()
            self.setExtraCellLineHidden(tableView)
            if(self.isSingleView == true){
                 tableView.frame = CGRectMake(0, 0, windowWidth, windowHeight-100)
            }
            if(self.isSingleView == false){
                 tableView.frame = CGRectMake(0, 43, windowWidth, windowHeight-100)
            }
            self.viewArray[num].addSubview(tableView)
            self.tableViewArray.addObject(tableView)
            tableView.tag = num
            tableView.backgroundColor = UIColor.whiteColor()
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = (windowHeight+100)/6
            tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: "footerRefreshing:")
            tableView.mj_footer.tag = num
            tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: "headerRefreshing:")
            tableView.mj_header.tag = num
        }
        
        //商家详情按钮
        let btnDetail = UIButton(frame: CGRectMake(windowWidth*0.09+20, 23, 20, 20))
        btnDetail.setBackgroundImage(UIImage(named: "shopDetail.png"), forState:UIControlState.Normal)
        btnDetail.addTarget(self, action: Selector("intoDetail"), forControlEvents: UIControlEvents.TouchUpInside)
        self.navBtnView.addSubview(btnDetail)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navBtnView)

        //bottomView
        let newWidth = self.view.frame.width
        let newHeight = self.view.frame.height
        let bottomView = UIView(frame: CGRect(x: 0, y: newHeight - 55, width: newWidth, height: 55))
        bottomView.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 234/255, alpha: 1.0)
        self.view.addSubview(bottomView)
        
        collectBtn = UIButton(type: .System)
        collectBtn.frame = CGRect(x: 150*Consts.ratio, y: 20 * Consts.ratio, width: 25, height: 38)
        if(self.shopIsCollected == true){
            collectBtn.setBackgroundImage(UIImage.init(named: "homepage_btn_collection_n"), forState: .Normal)
            collectBtn.tag = 11
        }else if(self.shopIsCollected == false){
            collectBtn.setBackgroundImage(UIImage.init(named: "homepage_btn_collection_p"), forState: .Normal)
            collectBtn.tag = 10
        }
        collectBtn.tintColor = Consts.tintGreen
        bottomView.addSubview(collectBtn)
        
        consultBtn = UIButton(type: .System)
        consultBtn.frame = CGRect(x: newWidth - 150 * Consts.ratio - 25, y: 20 * Consts.ratio, width: 25, height: 38)
        consultBtn.setBackgroundImage(UIImage.init(named: "homepage_btn_consult"), forState: .Normal)
        consultBtn.tintColor = Consts.tintGreen
        bottomView.addSubview(consultBtn)
        
        let bottomLine = UIView(frame: CGRect(x: 0, y: bottomView.frame.minY, width: newWidth, height: 1))
        bottomLine.backgroundColor = UIColor.lightGrayColor()
        self.view.addSubview(bottomLine)
        
        collectBtn.addTarget(self, action: "collectBtnClicked:", forControlEvents: .TouchUpInside)
        consultBtn.addTarget(self, action: "showMenu", forControlEvents: .TouchUpInside)
    }

    func setExtraCellLineHidden(tableView:UITableView){
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = view
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if(self.isSingleView == true){
            let viewCell = ViewCell()
            viewCell.setData(self.resultData[indexPath.row])
            viewCell.selectionStyle = UITableViewCellSelectionStyle.None
            viewCell.isIdleCell = false
            return viewCell
        }
        if(self.isSingleView == false){
            for(var num = 0 ; num < self.viewCount ; num++){
                if(tableView == self.tableViewArray[num] as! NSObject){
                    let viewCell = ViewCell()
                    viewCell.setData(self.resultData[num].objectAtIndex(indexPath.row))
                    viewCell.selectionStyle = UITableViewCellSelectionStyle.None
                    viewCell.isIdleCell = false
                    return viewCell
                }
            }
        }
        let defaultCell = UITableViewCell()
        return defaultCell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.isSingleView == true){
            return self.resultData.count
        }
        if(self.isSingleView == false){
            for(var num = 0 ; num < self.viewCount ; num++){
                if(tableView == self.tableViewArray[num] as! NSObject){
                    return self.resultData[num].count
                }
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let tempCell = tableView.cellForRowAtIndexPath(indexPath)as! ViewCell
        let vc = ShopGoodViewController()
        vc.goods_ID = tempCell.dataCell.objectForKey("goods_id")as!String
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
        
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if(scrollView == self.rootView){
            pageView.currentPage = Int(Float(rootView.contentOffset.x) / Float(windowWidth))
            scrollPageTurn(self.pageView.currentPage)
            if(pageView.currentPage > oldPage){
                self.btnLeftX += self.btnWidth
                if(self.btnLeftX > windowWidth/2 && self.moreX != 0){
                    var moveTemp = self.btnLeftX - windowWidth/2 + 40
                    if(self.moreX - moveTemp <= 0){
                        self.scrollBtnView.setContentOffset(CGPoint(x: self.scrollBtnView.contentOffset.x + self.moreX,y: self.scrollBtnView.contentOffset.y), animated: true)
                        self.lessX += self.moreX
                        self.btnLeftX -= self.moreX
                        self.moreX = 0
                    }
                    if(self.moreX - moveTemp > 0){
                        self.scrollBtnView.setContentOffset(CGPoint(x: self.scrollBtnView.contentOffset.x + moveTemp,y: self.scrollBtnView.contentOffset.y), animated: true)
                        self.lessX += moveTemp
                        self.btnLeftX -= moveTemp
                        self.moreX -= moveTemp
                    }
                    oldPage = pageView.currentPage
                }
                oldPage = pageView.currentPage
            }
            if(pageView.currentPage < oldPage){
                self.btnLeftX -= self.btnWidth
                if(self.btnLeftX < windowWidth/2-80 && self.lessX != 0){
                    var moveTemp = windowWidth/2 - 40 - self.btnLeftX
                    if(self.lessX - moveTemp <= 0){
                        self.scrollBtnView.setContentOffset(CGPoint(x: self.scrollBtnView.contentOffset.x - self.lessX,y: self.scrollBtnView.contentOffset.y), animated: true)
                        self.moreX += self.lessX
                        self.btnLeftX += self.lessX
                        self.lessX = 0
                    }
                    if(self.lessX - moveTemp > 0){
                        self.scrollBtnView.setContentOffset(CGPoint(x: self.scrollBtnView.contentOffset.x - moveTemp,y: self.scrollBtnView.contentOffset.y), animated: true)
                        self.lessX -= moveTemp
                        self.moreX += moveTemp
                        self.btnLeftX += moveTemp
                    }
                    oldPage = pageView.currentPage
                }
                oldPage = pageView.currentPage
            }
        }
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if(scrollView == self.rootView){
            let offset : CGPoint = scrollView.contentOffset
            if(self.viewCount > 4){
                self.scrollIndicator.contentOffset = CGPoint(x:( -offset.x * 80)/windowWidth , y: offset.y)
            }
            else{
                self.scrollIndicator.contentOffset = CGPoint(x: -offset.x / CGFloat(self.viewCount), y: offset.y)
            }
        }
        
    }
    
    
    func pageTurn(sender : UIButton){
        self.rootView.setContentOffset(CGPoint(x: CGFloat(sender.tag) * windowWidth, y: 0), animated: true)
        pageView.currentPage = sender.tag
        self.scrollBtnView(sender.tag)
        btnColorChange(sender.tag)
        self.tableViewArray[sender.tag].reloadData()
    }
    func scrollPageTurn(sender : Int){
        self.rootView.contentOffset = CGPoint(x: CGFloat(sender) * windowWidth, y: 0)
        pageView.currentPage = sender
        btnColorChange(sender)
        self.tableViewArray[sender].reloadData()
        
    }
    func scrollBtnView(newTag : Int){
        let jumpNum = newTag - self.oldPage
        if(pageView.currentPage > self.oldPage){
            self.btnLeftX += CGFloat(jumpNum)*self.btnWidth
            if(self.btnLeftX > windowWidth/2 && self.moreX != 0){
                let moveTemp = self.btnLeftX - windowWidth/2 + 40
                if(self.moreX - moveTemp <= 0){
                    self.scrollBtnView.setContentOffset(CGPoint(x: self.scrollBtnView.contentOffset.x + self.moreX,y: self.scrollBtnView.contentOffset.y), animated: true)
                    self.lessX += self.moreX
                    self.btnLeftX -= self.moreX
                    self.moreX = 0
                }
                if(self.moreX - moveTemp > 0){
                    self.scrollBtnView.setContentOffset(CGPoint(x: self.scrollBtnView.contentOffset.x + moveTemp,y: self.scrollBtnView.contentOffset.y), animated: true)
                    self.lessX += moveTemp
                    self.btnLeftX -= moveTemp
                    self.moreX -= moveTemp
                }
                oldPage = pageView.currentPage
            }
            oldPage = pageView.currentPage
        }
        if(pageView.currentPage < self.oldPage){
            self.btnLeftX = self.btnLeftX + CGFloat(jumpNum)*self.btnWidth
            if(self.btnLeftX < windowWidth/2-80 && self.lessX != 0){
                let moveTemp = windowWidth/2 - 40 - self.btnLeftX
                if(self.lessX - moveTemp <= 0){
                    self.scrollBtnView.setContentOffset(CGPoint(x: self.scrollBtnView.contentOffset.x - self.lessX,y: self.scrollBtnView.contentOffset.y), animated: true)
                    self.moreX += self.lessX
                    self.btnLeftX += self.lessX
                    self.lessX = 0
                }
                if(self.lessX - moveTemp > 0){
                    self.scrollBtnView.setContentOffset(CGPoint(x: self.scrollBtnView.contentOffset.x - moveTemp,y: self.scrollBtnView.contentOffset.y), animated: true)
                    self.lessX -= moveTemp
                    self.moreX += moveTemp
                    self.btnLeftX += moveTemp
                }
                oldPage = pageView.currentPage
            }
            oldPage = pageView.currentPage
        }
        oldPage = pageView.currentPage
    }
    
    func btnColorChange(which : Int ){
        for(var num = 0 ; num < Int(self.viewCount) ; num++){
            if(num != which){
                self.btnArray[num].setTitleColor(UIColor(red: 90/255, green: 90/255, blue: 90/255, alpha: 1), forState: UIControlState.Normal)
            }
            else{
                self.btnArray[num].setTitleColor(UIColor(red: 73/255, green: 185/255, blue: 162/255, alpha: 1), forState: UIControlState.Normal)
            }
        }
    }
    
    func footerRefreshing(sender : AnyObject){
        if(self.isSingleView == true){
            self.pageArray[sender.tag]++
            Alamofire.request(.GET, "http://api2.hloli.me:9001/v1.0/goods/search/",parameters: ["page":self.pageArray[sender.tag],"location":"东南大学九龙湖校区","shop_id":self.shopID],headers:httpHeader).responseJSON(options: NSJSONReadingOptions.MutableContainers){
                response in
                let json = JSON(response.result.value!)
                var responseJson = json["result"]
                if(responseJson.count != 0 ){
                    for(var num = 0 ; num < responseJson.count ; num++){
                        self.resultData.addObject(responseJson.arrayObject![num])
                    }
                    self.tableViewArray[sender.tag].reloadData()
                    (self.tableViewArray[sender.tag]as! UITableView).mj_footer!.endRefreshing()
                }
                if(responseJson.count == 0){
                    self.pageArray[sender.tag]--
                    (self.tableViewArray[sender.tag]as! UITableView).mj_footer!.endRefreshing()
                }
                
            }
        }
        if(self.isSingleView == false){
            self.pageArray[sender.tag]++
            Alamofire.request(.GET, "http://api2.hloli.me:9001/v1.0/goods/search/",parameters: ["page":self.pageArray[sender.tag],"location":"东南大学九龙湖校区","shop_id":self.shopID,"group":self.groupArray[sender.tag]],headers:httpHeader).responseJSON(options: NSJSONReadingOptions.MutableContainers){
                response in
                let json = JSON(response.result.value!)
                var responseJson = json["result"]
                if(responseJson.count != 0){
                    var tempArray =  self.resultData[sender.tag].mutableCopy()
                    for(var num = 0 ; num < responseJson.count ; num++){
                        tempArray.addObject(responseJson.arrayObject![num])
                    }
                    self.resultData.replaceObjectAtIndex(sender.tag, withObject: tempArray)
                    self.tableViewArray[sender.tag].reloadData()
                    (self.tableViewArray[sender.tag]as! UITableView).mj_footer!.endRefreshing()
                }
                if(responseJson.count == 0){
                    self.pageArray[sender.tag]--
                    (self.tableViewArray[sender.tag]as! UITableView).mj_footer!.endRefreshing()
                }
            }
            
        }
        
    }
    
    func headerRefreshing(sender : AnyObject){
        if(self.isSingleView == true){
            Alamofire.request(.GET, "http://api2.hloli.me:9001/v1.0/goods/search/",parameters: ["page":"1","location":"东南大学九龙湖校区","shop_id":self.shopID],headers:httpHeader).responseJSON(options: NSJSONReadingOptions.MutableContainers){
                response in
                let json = JSON(response.result.value!)
                var responseJson = json["result"]
                self.resultData.removeAllObjects()
                for(var num = 0 ; num < responseJson.count ; num++){
                    self.resultData.addObject(responseJson.arrayObject![num])
                }
                self.tableViewArray[sender.tag].reloadData()
                (self.tableViewArray[sender.tag]as! UITableView).mj_header!.endRefreshing()
            }
        }
        if(self.isSingleView == false){
            Alamofire.request(.GET, "http://api2.hloli.me:9001/v1.0/goods/search/",parameters: ["page":1,"location":"东南大学九龙湖校区","shop_id":self.shopID,"group":self.groupArray[sender.tag]],headers:httpHeader).responseJSON(options: NSJSONReadingOptions.MutableContainers){
                response in
                var json = JSON(response.result.value!)
                var responseJson = json["result"]
                self.resultData[self.pageView.currentPage] = responseJson.arrayObject!
                self.tableViewArray[sender.tag].reloadData
                (self.tableViewArray[sender.tag]as! UITableView).mj_header!.endRefreshing()
            }
        }
    }
    
    func intoDetail(){
        let shopDetail = ShopDetailVC()
        shopDetail.shopID = self.shopID
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(shopDetail, animated: true)
    }
    func goBack(){
        self.navigationController?.popViewControllerAnimated(true)
    }

    func setUpOnlineData(tag:String){
        if(tag == "shopDetail"){
            self.shopDetailURL = "http://api2.hloli.me:9001/v1.0/shop/\(shopID)"
            api.httpRequest("GET", url: shopDetailURL, params: nil, tag: "shopDetail")
        }else if(tag == "collectShop"){
            self.collectShopURL = "http://api2.hloli.me:9001/v1.0/shop/collection/\(shopID)"
            api.httpRequest("POST", url: collectShopURL, params: nil, tag: "collectShop")
        }else if(tag == "cancelCollectShop"){
            self.cancelCollectShopURL = "http://api2.hloli.me:9001/v1.0/shop/collection/\(shopID)"
            api.httpRequest("DELETE", url: cancelCollectShopURL, params: nil, tag: "cancelCollectShop")
        }
    }
    
    
    func didReceiveJsonResults(json: JSON, tag: String) {
        if(tag == "shopDetail"){
            if(json["is_collected"] == 1){
                collectBtn.setBackgroundImage(UIImage.init(named: "homepage_btn_collection_n"), forState: .Normal)
                shopIsCollected = true
                collectBtn.tag = 11
//                self.setView()
            }else{
                collectBtn.setBackgroundImage(UIImage.init(named: "homepage_btn_collection_p"), forState: .Normal)
                shopIsCollected = false
                collectBtn.tag = 10
            }
        }else if(tag == "collectShop"){
            collectBtn.setBackgroundImage(UIImage.init(named: "homepage_btn_collection_n"), forState: .Normal)
            shopIsCollected = true
            collectBtn.tag = 11
        }else if(tag == "cancelCollectShop"){
            collectBtn.setBackgroundImage(UIImage.init(named: "homepage_btn_collection_p"), forState: .Normal)
            shopIsCollected = false
            collectBtn.tag = 10
        }
    }
    
    func collectBtnClicked(sender:UIButton){
        if(sender.tag == 10){//未收藏
            setUpOnlineData("collectShop")
        }else if(sender.tag == 11){//已收藏
            setUpOnlineData("cancelCollectShop")
        }
    }
    
    //咨询跳出两个选择
    func showMenu(){
        //注意空数组的定义.MenuItem为元素类型
        var items = [MenuItem]()
        var menuItem = MenuItem(title: "sms", iconName: "xiangqing_btn_message")//短信
        items.append(menuItem)
        menuItem = MenuItem(title: "tel", iconName: "xiangqing_btn_call")//电话
        items.append(menuItem)
        
        popMenu = PopMenu(frame: self.view.bounds, items: items)
        popMenu.menuAnimationType = PopMenuAnimationType.NetEase
        
        if(popMenu.isShowed == true){
            return
        }
        
        popMenu.didSelectedItemCompletion = { (selectedItem) in
            //点击事件
            if(selectedItem.title == "sms"){
                self.app.openURL(NSURL(string: "sms:\(self.shopPhoneNum)")!)
            }else if(selectedItem.title == "tel"){
                self.self.webViewCallPhone()
            }
        };
        
        popMenu.showMenuAtView(self.view)
    }
    
    func  webViewCallPhone(){
        //        此种方法打完电话可以回到本应用
        let callWebview = UIWebView()
        let teleURL = NSURL(string: "tel:\(self.shopPhoneNum)")
        callWebview.loadRequest(NSURLRequest(URL: teleURL!))
        //        将uiwebview添加到view
        self.view.addSubview(callWebview)
    }

}
