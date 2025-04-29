//
//  HelpCenterViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 02/07/2023.
//

import UIKit
import WebKit

class HTMLViewController: UIViewController {

    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.logPageView()
        // Create a WKWebView instance
        webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        // Load HTML content from file
        if let htmlPath = Bundle.main.path(forResource: "help_file", ofType: "html") {
            let htmlURL = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        }

        // Scroll to the bottom of the content
        let script = "window.onload = function() { window.scrollTo(0, document.body.scrollHeight); };"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}

