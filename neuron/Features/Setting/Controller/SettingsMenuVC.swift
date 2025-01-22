/*
 * Copyright (C) 2024 Razer Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CocoaLumberjack
import SwiftUI

let MenuViewBgWidth = CGFloat(UIScreen.main.bounds.size.width*0.343) - 70 - 10
let MenuViewWidth:CGFloat = MenuViewBgWidth//IsIpad() ? 352 : 215

class SettingsMenuVC: RZBaseVC , UITableViewDelegate , UITableViewDataSource {
    
    var selecetdIndexPath = IndexPath(row: 0, section: 0)
    var selecteView:UIView?
    
    var localNetworkAuthorization: LocalNetworkAuthorization = LocalNetworkAuthorization()
    var isShowDownloadOverlay: Bool = false
    var streamConfig: StreamConfiguration = StreamConfiguration()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //设置router的navigationController
        SettingsRouter.shared.navigationController = self.navigationController
        // Do any additional setup after loading the view.
        setupView()

        handel.reloadCallBack = { [self] in
            nextHandel = nil
            reloadContentView()
        }

        setupNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        if (nextHandel != nil) {
            menuTable.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //self.navigationController?.isNavigationBarHidden = false
        if (nextHandel != nil) {
            menuTable.reloadData()
            let menuItem = menuArray[selecetdIndexPath.section][selecetdIndexPath.row]
            menuItem.viewController.viewDidAppear(animated)
            if let vc = menuItem.viewController as? SettingsHostDevicesVC {
                vc.viewShoudResponsHandel = true
                vc.reloadContentView()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dimissDownloadOverlay()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupView() {
        //set back ground color
        view.backgroundColor = .black
        
        //add contents
        view.addSubview(menuTable)
        view.addSubview(line)
        view.addSubview(contentView)
        view.addSubview(customNavBar)

        customNavBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44.0)
            if IsIpad() {
                make.top.equalTo(20)
            } else {
                make.top.equalToSuperview()
            }
        }
        
        menuTable.snp.makeConstraints { make in
            make.left.equalTo(IsIpad() ? 25 : DeviceLeftSpace)
            make.top.equalTo(IsIpad() ? 44 : 0)
            make.width.equalTo(MenuViewWidth)
            make.bottom.equalTo(0)
        }
        
        line.snp.makeConstraints { make in
            make.bottom.equalTo(0)
            make.top.equalTo(customNavBar.snp.bottom)
            make.left.equalTo(menuTable.snp.right).offset(12)
            make.width.equalTo(1.0/ScreenScale)
        }
        
        contentView.snp.makeConstraints { make in
            make.left.equalTo(line.snp.right).offset(1)
            make.bottom.right.equalTo(0)
            make.top.equalTo(IsIpad() ? 44 : 0)
        }
        
        
        for menuList in menuArray {
            for menu in menuList {
                menu.view.isHidden = true
                contentView.addSubview(menu.view)
                menu.view.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
        
        selecteView = menuArray[safe:selecetdIndexPath.section]?[safe:selecetdIndexPath.row]?.view
        selecteView?.isHidden = false
        
    }
    
    func reloadContentView(){
        menuTable.reloadData()
        selecteView?.isHidden = true
        selecteView = menuArray[safe:selecetdIndexPath.section]?[safe:selecetdIndexPath.row]?.view
        selecteView?.isHidden = false
    }
    
    @objc func willResignActiveNotification() {
//        hideAlertView()
    }
    
    override func updateNextHandel(_ handel:RZHandleResponder?) {
        if (nextHandel == handel && nextHandel != nil) {
            return
        }
        super.updateNextHandel(handel)
        handel?.stopTracking()
        nextHandel?.startTracking()
        nextHandel?.reloadCallBack?()
        reloadContentView()
    }
    
    //MARK: - tableview delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        changeSelectedItem(indexPath: indexPath)
    }
    
    //MARK: - tableview data source
    func numberOfSections(in tableView: UITableView) -> Int {
        let sectionCount = menuArray.count
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let list = menuArray[safe: section]
        return list?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = menuArray[safe: indexPath.section]
        let item = list?[safe: indexPath.row]
        let cell = SettingsMenuCell.cell(style: item?.cellStyle ?? .roundedRectangle, isNeedSeparator: item?.isNeedSeparator ?? false)
        cell.configure(with: item?.title ?? "No Data")
        tableView.separatorStyle = .none
        var heighted = (selecetdIndexPath.section == indexPath.section && selecetdIndexPath.row == indexPath.row)
        if nextHandel != nil && (nextHandel?.shouleTracking() == true) {
            heighted = false
        }
        cell.isHeightLight(heighted)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let list = menuArray[safe: indexPath.section]
        let item = list?[safe: indexPath.row]
        return item?.height ?? 40.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: UITableViewHeaderFooterView.description())
        view?.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: UITableViewHeaderFooterView.description())
        view?.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 55.0
        }
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20.0
    }
    
    //MARK: - Lazy - UI
    
    lazy var customNavBar:CustomNavigationBar = {
        let nav = CustomNavigationBar(title: "Settings".localize(), leftButtonTitle: "Home".localize(), rightButtonTitle: nil, delegate: self)
        return nav
    }()
    
    lazy var menuTable : UITableView = {
        let table = UITableView.init(frame: CGRectZero, style: .grouped)
        table.backgroundColor = .black
        table.delegate = self
        table.dataSource = self
        table.register(SettingsMenuCell.self, forCellReuseIdentifier: SettingsMenuCell.description())
        table.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.description())
        table.showsVerticalScrollIndicator = false
        return table
    }()
    
    lazy var line : UIView = {
        let view = UIView.init()
        view.backgroundColor = Color.SettingsLine.uiColor()
        return view
    }()
    
    lazy var contentView : UIView = {
        let view = UIView.init()
        return view
    }()
    
    //用于计算cell高度
    lazy var titleLabel : UILabel = {
        let label = UILabel.init()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()
    
    lazy var menuArray : [[SettingsMenuItem]] = {
        let array = createMenuArray()
        return array
    }()
    
    func updateMenuArray() {
        menuArray = createMenuArray()
    }
    
    func createMenuArray() ->[[SettingsMenuItem]] {
        let isDebugMode = DevUtils.shared().isDebugMode
        Logger.debug("isDebugMode:\(isDebugMode)")
        
        var array:[[SettingsMenuItem]] = []
        
        
        let StreamingOptions = "Streaming Options".localize()
        let Computers = "Computers".localize()
        let About = "About".localize()
        let DevOptions = "Dev Options".localize()
        
        let devicesVC = SettingsHostDevicesVC()
        devicesVC.lastHandel = handel
        devicesVC.lastVC = self
        
        let frameSettingsVC = RZStreamFrameSettingsViewController()
        frameSettingsVC.lastHandel = handel
        frameSettingsVC.lastVC = self
        array.append([SettingsMenuItem(title: StreamingOptions, viewController: frameSettingsVC, cellStyle: .topHalfRoundedRectangle, isNeedSeparator: true , height: coutingCellHeihgt(text: StreamingOptions)), SettingsMenuItem.init(title: Computers, viewController: devicesVC, cellStyle: .bottomHalfRoundedRectangle, isNeedSeparator: false, height: coutingCellHeihgt(text: Computers))])
        
        let aboutVC = AboutVC()
        aboutVC.lastHandel = handel
        aboutVC.lastVC = self
        array.append([ SettingsMenuItem.init(title: About, viewController: aboutVC, cellStyle: .roundedRectangle, isNeedSeparator: false , height: coutingCellHeihgt(text: About)) ])
        
        if isDebugMode {
            let devOptionVC = DevOptionVC()
            devOptionVC.lastHandel = handel
            devOptionVC.lastVC = self
            array.append([ SettingsMenuItem.init(title: DevOptions, viewController: devOptionVC, cellStyle: .roundedRectangle, isNeedSeparator: false, height: coutingCellHeihgt(text: DevOptions)) ])
        }
        return array
    }
    
    func cancelHostRunningGame(_ appHost: TemporaryHost?) {
        let hMan = HttpManager.init(host: appHost)
        let quitResponse = HttpResponse();
        let quitRequest = HttpRequest(for: quitResponse, with:hMan?.newQuitAppRequest())
        hMan?.executeRequestSynchronously(quitRequest)
        print("Requesting :\(quitRequest?.request.url?.absoluteString ?? "") -- result:\(quitResponse.isStatusOk())")
    }
    
    func coutingCellHeihgt(text:String) -> CGFloat {
        // 获取文本属性
        let attributes: [NSAttributedString.Key: Any] = [
            .font: titleLabel.font!
        ]
        // 计算文本的高度
        let width: CGFloat = MenuViewWidth - 15.0 * 2.0 // 你想要的固定宽度
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let rect = text.boundingRect(with: size, options: options, attributes: attributes, context: nil)
        
        if rect.height > 40.0 {
            return 60.0
        }
        return 40.0
    }
}

//MARK: - RZHandleResponderDelegate
extension SettingsMenuVC : RZHandleResponderDelegate {
    func handleClickButton(_ action: GamePadButton) {
        switch action {
        case .B:
            SettingsRouter.shared.navigationController?.popViewController(animated: true)
        case .right , .A:
            rightAction()
        case .up:
            lastMenu()
        case .down:
            nextMenu()
        default:
            break
        }
    }
}

//MARK: - RZHandleResponderDelegate - handels actions
extension SettingsMenuVC {
    
    func  changeSelectedItem(indexPath: IndexPath) {
        if nextHandel != nil {
            nextHandel?.buttonTriggered(controlTriggered :.control(button: .B, counter: 0, state: .Up))
            nextHandel?.stopTracking()
            nextHandel = nil
            handel.startTracking()
        }
        selecetdIndexPath = indexPath
        reloadContentView()
    }
    
    func nextMenu() {
        var section = selecetdIndexPath.section
        var row = selecetdIndexPath.row
        let list = menuArray[section]
        if row + 1 < list.count {
            row = row + 1
        }else if section + 1 < menuArray.count {
            section = section + 1
            row = 0
        }
        let indexPath = IndexPath.init(row: row, section: section)
        changeSelectedItem(indexPath: indexPath)
    }
    
    func lastMenu() {
        var section = selecetdIndexPath.section
        var row = selecetdIndexPath.row
        var list = menuArray[section]
        if row - 1 >= 0 {
            row = row - 1
        }else if section - 1 >= 0 {
            section = section - 1
            list = menuArray[section]
            row = list.count - 1
        }
        let indexPath = IndexPath.init(row: row, section: section)
        changeSelectedItem(indexPath: indexPath)
    }
    
    func rightAction() {
        let item = menuArray[selecetdIndexPath.section][selecetdIndexPath.row]
        if let vc = item.viewController as? RZBaseVC {
            nextHandel = vc.handel
            nextHandel?.startTracking()
            nextHandel?.reloadCallBack?()
            reloadContentView()
        }
    }
}

extension SettingsMenuVC: CustomNavigationBarDelegate {
    func backButtonTapped() {
        SettingsRouter.shared.navigationController?.popViewController(animated: true)
    }
    
    func rightButtonTapped() {
        //do nothing
    }
}
