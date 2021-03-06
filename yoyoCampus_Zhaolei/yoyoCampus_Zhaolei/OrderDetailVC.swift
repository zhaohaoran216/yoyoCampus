//
//  OrderDetailVC.swift
//  yoyoCampus_Zhaolei
//
//  Created by 赵磊 on 15/10/24.
//  Copyright © 2015年 赵磊. All rights reserved.
//

import UIKit
import SwiftyJSON
import MJRefresh

class OrderDetailVC: UIViewController,APIDelegate,UITableViewDelegate,UITableViewDataSource{

    @IBOutlet var table: UITableView!
    
    internal var order_ID:String = ""
    
    var api = YoYoAPI()
    
    var orderDetailViewURL:String = ""
    
    var refundURL:String = ""
    
    var orderStatus:Int = 0
    
    var orderDetailJSON:JSON = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.setUpNavigationBar()
        
        self.setUpActions()
        
        self.setUpInitialLooking()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpNavigationBar(){
        Consts.setUpNavigationBarWithBackButton(self, title: "订单详情", backTitle: "<")
    }
    
    func setUpInitialLooking(){
        self.view.backgroundColor = Consts.grayView
        self.table.showsVerticalScrollIndicator = false
        self.table.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: "headerRefreshing")
        setUpOnlineData("orderDetailView")
    }
    
    func setUpActions(){
        self.api.delegate = self
        
//        注册所有cell
        let nib1 = UINib(nibName: "shopNameCell", bundle: nil)
        let nib2 = UINib(nibName: "orderDetailInfoCell", bundle: nil)
        let nib3 = UINib(nibName: "moreOrderInfoCell", bundle: nil)
        let nib4 = UINib(nibName: "OneBtnCell", bundle: nil)
        let nib5 = UINib(nibName: "OneLabelCell", bundle: nil)
        let nib6 = UINib(nibName: "payCodeCell", bundle: nil)
        let nib7 = UINib(nibName: "myRemarkCell", bundle: nil)
        
        self.table.registerNib(nib1, forCellReuseIdentifier: "shopNameCell")
        self.table.registerNib(nib2, forCellReuseIdentifier: "orderDetailInfoCell")
        self.table.registerNib(nib3, forCellReuseIdentifier: "moreOrderInfoCell")
        self.table.registerNib(nib4, forCellReuseIdentifier: "OneBtnCell")
        self.table.registerNib(nib5, forCellReuseIdentifier: "OneLabelCell")
        self.table.registerNib(nib6, forCellReuseIdentifier: "payCodeCell")
        self.table.registerNib(nib7, forCellReuseIdentifier: "myRemarkCell")
        
    }
    func headerRefreshing(){
        setUpOnlineData("orderDetailView")
    }
    func setUpOnlineData(tag:String){
        
        switch(tag){
            case "orderDetailView":
                orderDetailViewURL = "\(Consts.mainUrl)/v1.0/user/order/\(order_ID)/"
                api.httpRequest("GET", url: orderDetailViewURL, params: nil, tag: "orderDetailView")
            break
            
            case "refund":
                refundURL = "\(Consts.mainUrl)/v1.0/user/order/\(order_ID)/"
                api.httpRequest("DELETE", url: refundURL, params: nil, tag: "refund")
            break
            
        default:
            break
            
        }
    }
    
    func goBack(){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    ///有关tableView
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if(orderStatus == 4){
            return 4
        }else{
            return 3
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section){
        
        case 0://详情
            if(orderStatus == 2){
               return 3
            }else {
                return 2
            }
            break
        
        case 1://店铺名称
            return 1
            break
            
        case 2://更多详情
            return 1
            break
            
        case 3://评论
            return 1
            break
            
        default:
            return 1
            break
        }
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 0){
            return 0
        }else{
            return 25 * Consts.ratio
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch(indexPath.section){
        case 0:
            switch(indexPath.row){
            case 0://orderDetailInfoCell
                return 174 * Consts.ratio
                break
                
            case 1://分情况
                if(orderStatus == 2){
                    //payCode
                    return 512 * Consts.ratio
                }else{
                    //btn/label cell
                    return UITableViewCell().frame.height
                }
                break
                
            case 2://只有orderStatue == "unUsed"会有
                return UITableViewCell().frame.height
                break
                
            default:
                return UITableViewCell().frame.height
                break
            }
            break
            
        case 1://shopName
            return UITableViewCell().frame.height
            break
            
        case 2://moreDetail
            return tableView.fd_heightForCellWithIdentifier("moreOrderInfoCell", cacheByIndexPath: indexPath, configuration: { (cell) -> Void in
                self.setUpMoreOrderInfoCell(cell as! moreOrderInfoCell, atIndexPath: indexPath)
            })
            break
            
        case 3://status == "remarked"
            return tableView.fd_heightForCellWithIdentifier("myRemarkCell", cacheByIndexPath: indexPath, configuration: { (cell) -> Void in
                self.setUpmyRemarkCell(cell as! myRemarkCell, atIndexPath: indexPath)
            })
            break
            
        default:
            return UITableViewCell().frame.height
            break
        }

    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if(!orderDetailJSON.isEmpty){
        switch(indexPath.section){
//            section 0:
        case 0:
            switch(indexPath.row){
            case 0://orderDetailInfoCell
                
                let cell = self.table.dequeueReusableCellWithIdentifier("orderDetailInfoCell", forIndexPath: indexPath) as! orderDetailInfoCell
                cell.photoImg.sd_setImageWithURL(orderDetailJSON["good","image"].URL!, placeholderImage: UIImage.init(named: "Commodity editor_btn_picture"))
                let orderName = orderDetailJSON["good","name"].string!
                let originPrice = Float(orderDetailJSON["good","original_price"].int!)/100.00
                let price = Float(orderDetailJSON["good","price"].int!)/100.00
                cell.goodNameLabel?.text = "\(orderName)"
                let attributedText = NSAttributedString(string: "¥ \(originPrice)", attributes: [NSStrikethroughStyleAttributeName: 1])
                cell.oldPriceLabel?.attributedText = attributedText
                cell.presentPriceLabel?.text = "¥ \(price)"
                cell.presentPriceLabel.textColor = UIColor.redColor()
                cell.presentPriceLabel.sizeToFit()
                return cell
                break
                
            case 1://分情况
                if(orderStatus == 1 || orderStatus == 3){
                let cell = self.table.dequeueReusableCellWithIdentifier("OneBtnCell", forIndexPath: indexPath) as! OneBtnCell
                    if(orderStatus == 1){
                        cell.btn_operation.setTitle("付款", forState: .Normal)
                    }else{
                        cell.btn_operation.setTitle("评价", forState: .Normal)
                    }
                    cell.btn_operation.addTarget(self, action: "btnClicked:", forControlEvents: .TouchUpInside)
                    return cell
                }else if(orderStatus == 2){
                    let cell = self.table.dequeueReusableCellWithIdentifier("payCodeCell", forIndexPath: indexPath) as! payCodeCell
                    let code = orderDetailJSON["code"].string!
                    cell.payPwdLabel?.text = "\(code)"
//                    根据接收到的字符串生成二维码：
                    cell.payCodeView.image = QRCodeGenerator.qrImageForString(code, imageSize: cell.payCodeView.bounds.size.width)
                    
                    return cell
                }else{//已退款／已评价
                    let cell = self.table.dequeueReusableCellWithIdentifier("OneLabelCell", forIndexPath: indexPath) as! OneLabelCell
                    cell.label_status.textColor = Consts.lightGray
                    if(orderStatus == 0){
                        cell.label_status?.text = "已退款"
                    }else if(orderStatus == -1){
                        cell.label_status?.text = "退款中"
                    }else if(orderStatus == 4){
                        cell.label_status?.text = "已评价"
                    }
                    return cell
                }
                break
                
            case 2://只有orderstatus == "unUsed"会有
                let cell = self.table.dequeueReusableCellWithIdentifier("OneBtnCell", forIndexPath: indexPath) as! OneBtnCell
                cell.btn_operation.setTitle("申请退款", forState: .Normal)
                cell.btn_operation.sizeToFit()
                cell.btn_operation.addTarget(self, action: "btnClicked:", forControlEvents: .TouchUpInside)
                return cell
                break
                
            default:
                return UITableViewCell()
                break
            }
            break
//            section 1:
        case 1:
            let cell = self.table.dequeueReusableCellWithIdentifier("shopNameCell", forIndexPath: indexPath) as! shopNameCell
            cell.shopImage.layer.cornerRadius = cell.shopImage.frame.width/2
            cell.shopImage.sd_setImageWithURL(orderDetailJSON["shop","shop_image"].URL!, placeholderImage: UIImage.init(named: "bear_icon_register"))
            cell.shopNameLabel?.text = orderDetailJSON["shop","name"].string!
            return cell
            break
//            section 2:
        case 2:
            let cell = self.table.dequeueReusableCellWithIdentifier("moreOrderInfoCell", forIndexPath: indexPath) as! moreOrderInfoCell
            self.setUpMoreOrderInfoCell(cell, atIndexPath: indexPath)
            return cell
            break
//            section 3:
//            orderstatus == "remarked"时有
        case 3:
            let cell = self.table.dequeueReusableCellWithIdentifier("myRemarkCell", forIndexPath: indexPath) as! myRemarkCell
            setUpmyRemarkCell(cell, atIndexPath: indexPath)
            return cell
            break
            
        default:
            return UITableViewCell()
        break
        }
        }else{
            return UITableViewCell()
        }
    }
    
    func setUpMoreOrderInfoCell(cell:moreOrderInfoCell,atIndexPath indexPath:NSIndexPath){
        if(!orderDetailJSON.isEmpty){
        cell.label_orderNo?.text = orderDetailJSON["_id"].string!
        cell.label_time?.text = orderDetailJSON["time"].string!
        cell.label_phone_num?.text = orderDetailJSON["buyer","phone_num"].string!
        cell.label_campus?.text = orderDetailJSON["buyer","location"].string!
        cell.label_remark?.text = orderDetailJSON["remark"].string!
        let discount = Float(orderDetailJSON["good","discount"].int!)/100.00//优惠卡金额
        let quantity = orderDetailJSON["quantity"].int!
        let totalPrice = Float(orderDetailJSON["total_price"].int!)/100.00
        cell.label_count?.text = "\(quantity)"
        if(orderDetailJSON["use_card"].bool!){
            cell.label_discount?.text = "¥ \(Float(quantity) * discount)"
        }else{
            cell.label_discount?.text = "¥ 0"
        }
        cell.label_totalPrice?.text = "¥ \(totalPrice)"
            
        }
    }
    
    func setUpmyRemarkCell(cell:myRemarkCell,atIndexPath indexPath:NSIndexPath){
        cell.label_name?.text = "宇宙无敌小可爱"
        cell.label_remarkTime?.text = "2016-01-19"
        
        cell.label_remark.lineBreakMode = .ByCharWrapping
        cell.label_remark.numberOfLines = 0
        cell.label_remark.sizeToFit()
        cell.label_remark?.text = "很不错的地方，班级游一块儿去的吧啦吧啦吧啦吧啦吧啦吧啦吧啦吧啦吧啦吧啦吧啦吧。"
        
        cell.label_likeCount?.text = "( 15 )"
        cell.setStars(5)//星数
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.table.deselectRowAtIndexPath(indexPath, animated: false)
        switch(indexPath.section){
        
        case 0:
            if(indexPath.row == 0){//商品详情
                let vc = ShopGoodViewController()
                let goods_id = orderDetailJSON["good","_id"].string!
                vc.goods_ID = goods_id
                self.navigationController?.pushViewController(vc, animated: true)
            }
            break
        
        case 1:
            //店铺详情
            let vc = ShopGoodsVC()
            vc.shopID = orderDetailJSON["shop","shop_id"].string!
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        default:
            break
            
        }
    }

    func btnClicked(sender:UIButton){
        if(sender.titleLabel?.text == "付款"){
            let vc = OrderPayVC()
            vc.order_ID = orderDetailJSON["_id"].string!
            self.navigationController?.pushViewController(vc, animated: true)
        }else if(sender.titleLabel?.text == "申请退款"){
            setUpOnlineData("refund")
        }else if(sender.titleLabel?.text == "评价"){
            let vc = remarkVC()
            vc.order_id = orderDetailJSON["_id"].string!
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func didReceiveJsonResults(json: JSON, tag: String) {
        switch(tag){
            case "orderDetailView":
                orderDetailJSON = json
                self.orderStatus = json["status"].int!
                self.table.reloadData()
                self.table.mj_header.endRefreshing()
            break
            
            case "refund":
                Tool.showSuccessHUD("退款会在3-5个工作日返回您的支付账户")
                setUpOnlineData("orderDetailView")
            break
            
        default:
            break
        }
    }

}
