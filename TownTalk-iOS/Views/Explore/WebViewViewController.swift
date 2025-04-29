//
//  WebViewViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 07/06/2023.
//

import UIKit
import WebKit

class WebViewViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var webView: WKWebView!
    var webViewConfiguration: WKWebViewConfiguration!
    
    var checkinData: CheckIn?
    var name = ""
    var url = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        lblName.text = name
        if url == ""{
            addFile(fileName: name == "Help Center" ? "help_file": "cg_file")
            return
        }
        let url = URL(string: url)!
        
        webView.load(URLRequest(url: url))
        
        webView.allowsBackForwardNavigationGestures = true
        
        self.logPageView()
    }
    
    func addFile(fileName: String){
        if let htmlPath = Bundle.main.path(forResource: fileName, ofType: "html") {
            let htmlURL = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        }
        
        // Scroll to the bottom of the content
        let script = "window.onload = function() { window.scrollTo(0, document.body.scrollHeight); };"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
