//
//  IMDriverSentenceContainerView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2017/11/21.
//

import UIKit

public protocol IMDriverSentenceContainerViewDelegate: class {
    func sentenceContainerView(_ view: IMDriverSentenceContainerView, didSelect message: String)
    func sentenceContainerView(_ view: IMDriverSentenceContainerView, didAddTapped btn: UIButton)
}

final public class IMDriverSentenceContainerView: UIView {

    //可被记录高度管理
    private var recordable = RecordableHeight(normal: 200)
    public weak var delegate: IMDriverSentenceContainerViewDelegate?
   
    public var commonMessage = CommonManager()
    
    private lazy var bgView: UIView = { [unowned self] in
        let view = UIView(frame: self.bounds)
        view.backgroundColor = .black
        let tap = UITapGestureRecognizer(target: self, action: #selector(hide))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    public lazy var tableView: UITableView = { [unowned self] in
        let view = UITableView(frame: .zero, style: .plain)
        view.delegate = self
        view.dataSource = self
        view.separatorColor = UIColor(hexString: "#d6d6d6")
        view.separatorInset = .zero
        view.backgroundColor = UIColor(hexString: "#f6f6f6")
        view.register(CommomMessageCell.self, forCellReuseIdentifier: "CommomMessageCellKey")
        view.tableFooterView = UIView(frame: .zero)
        return view
    }()
    
    private lazy var titleView: UIView = { [unowned self] in
        let tempView = UIView(frame: .zero)
        let label = UILabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor(hexString:"#333333")
        label.text = "常用语列表"
        tempView.addSubview(label)
        tempView.backgroundColor = UIColor(hexString: "#f6f6f6")
        
        let dot = UIView()
        dot.backgroundColor = UIColor(hexString:"#FF7801")
        tempView.addSubview(dot)
        
        dot.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize(width: 3, height: 15))
            m.left.centerY.equalToSuperview()
        })
        
        label.snp.makeConstraints({ (m) in
            m.left.equalTo(15)
            m.centerY.equalToSuperview()
        })
        
        let line = UIView()
        line.backgroundColor = UIColor(hexString: "#d6d6d6")
        tempView.addSubview(line)
        
        line.snp.makeConstraints({ (m) in
            m.left.right.bottom.equalToSuperview()
            m.height.equalTo(0.5)
        })
        
        let tap = UIPanGestureRecognizer(target: self, action: #selector(doMoveAction))
        tempView.addGestureRecognizer(tap)
        
        return tempView
    }()

    private lazy var btnTopBorder: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString:"#e7e6e6")
        return view
    }()
    
    private lazy var menuToolBar: UIView = { [unowned self] in
        let rect = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: 44)
        let view = UIView(frame: rect)
        view.backgroundColor = .white
        view.layer.shadowOpacity = 0.3
        view.layer.shadowColor = UIColor(hexString:"#DDDDDD").cgColor
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 1, height: -1)
        
        let line = UIView(frame: CGRect(x: rect.midX, y: 12, width: 0.5, height: rect.size.height - 24))
        line.backgroundColor = UIColor(hexString:"#d9d9d9")
        view.addSubview(line)
        
        let addBtn = UIButton(type: .system)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        addBtn.setTitle("新增", for: .normal)
        addBtn.setTitleColor(UIColor(hexString:"#7b7e81"), for: .normal)
        addBtn.addTarget(self, action: #selector(addSentence), for: .touchUpInside)
        view.addSubview(addBtn)
        
        let cancelBtn = UIButton(type: .system)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(UIColor(hexString:"#7b7e81"), for: .normal)
        cancelBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        view.addSubview(cancelBtn)
        
        cancelBtn.frame = CGRect(x: 10, y: 0, width: rect.size.width/2 - 20, height: rect.size.height)
        addBtn.frame = CGRect(x: rect.size.width/2 + 10, y: 0, width: rect.size.width/2 - 20, height: rect.size.height)
        
        return view
    }()
    
    @objc
    func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.alpha = 0
            self.tableView.transform = CGAffineTransform(translationX: 0, y: 60)
            self.titleView.alpha = 0
            self.titleView.transform = CGAffineTransform(translationX: 0, y: 60)
            self.bgView.alpha = 0
            self.menuToolBar.alpha = 0
        }) { (isFinished) in
            self.removeSubViews()
        }
        
        endEditing(true)
    }
    
    public func show() {
        commonMessage.prepare()
        addSubviews()
        guard tableView.alpha == 0 else { return }
        tableView.transform = CGAffineTransform(translationX: 0, y: 60)
        titleView.transform = CGAffineTransform(translationX: 0, y: 60)
        UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseInOut, animations: {
            self.tableView.alpha = 1
            self.tableView.transform = CGAffineTransform(translationX: 0, y: 0)
            self.titleView.alpha = 1
            self.titleView.transform = CGAffineTransform(translationX: 0, y: 0)
            self.bgView.alpha = 0.2
            self.menuToolBar.alpha = 1
        }, completion: nil)
    }
    
    init(frame: CGRect, type:IMChatRole) {
        super.init(frame: frame)
        commonMessage.type = type
        isHidden = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        guard subviews.isEmpty else { return }
        isHidden = false
        [bgView, tableView, menuToolBar, titleView].forEach {
            $0.alpha = 0
            addSubview($0)
        }
    }
    
    //新增常用短语按钮点击
    @objc private func addSentence(sender: UIButton) {
        delegate?.sentenceContainerView(self, didAddTapped: sender)
    }
    
    //收回tableView
    func hideTableView() {
        let contentHeight = CGFloat(recordable.value)
        UIView.animate(withDuration: 0.3) {
            self.tableView.transform = CGAffineTransform(translationX: 0, y: contentHeight)
            self.titleView.transform = CGAffineTransform(translationX: 0, y: contentHeight)
        }
    }
    
    func showTableView() {
        UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseInOut, animations: {
            self.tableView.transform = CGAffineTransform(translationX: 0, y: 0)
            self.titleView.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: nil)
    }
    
    
    @objc
    private func doMoveAction(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        let value = translation.y
        recordable.update(Float(value))
        if recognizer.state == .ended {
            recordable.record()
        }
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    private func removeSubViews() {
        isHidden = true
        [tableView, bgView, menuToolBar, titleView].forEach{
            $0.removeFromSuperview()
        }
        recordable.save()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let contentHeight = CGFloat(recordable.value)
        var rect = CGRect.zero
        rect.size = CGSize(width: bounds.size.width, height: contentHeight)
        tableView.bounds = rect
        tableView.center.y = -contentHeight / 2 + bounds.size.height - 44
        tableView.center.x = bounds.midX
        menuToolBar.frame.offsetMaxY(bounds.size.height)
        titleView.bounds = CGRect(x: 0, y: 0, width: rect.size.width, height: 44)
        titleView.center.y = tableView.frame.minY - 22
        titleView.center.x = bounds.midX
    }
}

extension IMDriverSentenceContainerView: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commonMessage.dataSource.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommomMessageCellKey") as! CommomMessageCell
        cell.messageLabel.text = commonMessage.dataSource[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.sentenceContainerView(self, didSelect: commonMessage.dataSource[indexPath.row])
        hide()
    }
    
    public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "删除"
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        commonMessage.dataSource.remove(at: indexPath.row)
        tableView.reloadData()
    }
}

extension IMDriverSentenceContainerView: CommomMessageCellDelegate {
    func commomMessageCell(_ cell: CommomMessageCell, didTapped text:String) {
        delegate?.sentenceContainerView(self, didSelect: text)
        hide()
    }
}


extension CGRect {
    fileprivate mutating func offsetMaxY(_ value: CGFloat) {
        origin.y = value - size.height
    }
}


//可被记录的高度类
fileprivate struct RecordableHeight {
    
    //最大的移动距离
    public var maxDistance: Float = 200
    private(set) var value: Float = 0
    
    private let normal: Float
    private var last: Float = 0
    private let key: String = "DriverSenntenceLocationKey"
    
    //初始化的高度
    init(normal: Float) {
        let localHeight = UserDefaults.standard.float(forKey: key)
        self.value = max(normal, localHeight)
        self.last = value
        self.normal = normal
    }
    
    //改变值
    mutating func update(_ v: Float) {
        
        var isBusy = true
        
        if normal >= value {
            if v > 0 {
                isBusy = false
                last = value + v
            }
            else {
                isBusy = true
            }
            
            value = normal
        }
        
        if value >= normal + maxDistance {
            if v < 0 {
                isBusy = false
                last = value + v
            }
            else {
                isBusy = true
            }
            
            value = normal + maxDistance
        }
        
        
        if isBusy {
            value = last - v
        }
        
    }
    
    //记录值
    mutating func record() {
        if normal > value || value > normal + maxDistance {
            return
        }
        last = value
    }
    
    // 保存值
    func save() {
        UserDefaults.standard.set(last, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
}
