//
//  PlainTextMessageViewController.swift
//  littleprinter
//
//  Created by Michael Colville on 11/01/2018.
//  Copyright © 2018 Nord Projects Ltd. All rights reserved.
//

import UIKit
import SnapKit

class PlainTextMessageViewController: UIViewController {
    
    var recipient: Printer?
    
    lazy var textField = UITextView()
    lazy var sendButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.black.cgColor
        view.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(20)
            make.width.equalTo(view).offset(-40)
            make.height.equalTo(200)
            make.centerX.equalTo(view)
        }
        
        sendButton.addTarget(self, action: #selector(sendPressed), for: .touchUpInside)
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(.black, for: .normal)
        view.addSubview(sendButton)
        sendButton.snp.makeConstraints { (make) in
            make.top.equalTo(textField.snp.bottom).offset(10)
            make.right.equalTo(textField)
            make.width.equalTo(120)
            make.height.equalTo(40)
        }
        if let printer = recipient {
            self.title = printer.info.owner
        }
    }
    
    @objc func sendPressed() {
        if let printer = recipient {
            SiriusServer.shared.sendPlainText(textField.text, from: "TODO", to: printer.key, completion: { (error) in
                if let error = error {
                    let alert = UIAlertController(title: "Unable to send message to: \(printer.info.owner)", error: error)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                let alert = UIAlertController(title: "Message Sent", message: "🙌")
                self.present(alert, animated: true, completion: {
                    self.navigationController?.popViewController(animated: true)
                })
            })
        }
    }
}
