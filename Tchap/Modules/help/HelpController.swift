// 
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

class HelpController: UIViewController, WKUIDelegate {
    
    lazy var webview: WKWebView = { [unowned self] in
        let conf = WKWebViewConfiguration()
        conf.preferences.javaScriptEnabled = true
        let wb = WKWebView(frame: .zero, configuration: conf)
        wb.translatesAutoresizingMaskIntoConstraints = false
        wb.navigationDelegate = self
        return wb
    }()
    
    lazy var loadingSpinner: UIActivityIndicatorView = { [unowned self] in
        let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    var closeButtonIsHidden = true {
        didSet {
            if self.closeButtonIsHidden {
                self.view.removeFromSuperview()
            } else {
                self.view.addSubview(self.buttonClose)
                self.view.bringSubviewToFront(self.buttonClose)
                self.updateCloseButtonConstraints()
            }
        }
    }
    
    lazy var buttonClose: UIButton = { [unowned self] in
        let btn = UIButton(type: .close)
        btn.backgroundColor = .black
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(close(sender:)), for: .touchUpInside)
        return btn
    }()
    
    func updateCloseButtonConstraints() {
        guard !self.closeButtonIsHidden else { return }
        
        self.buttonClose.centerXAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -32.0).isActive = true
        self.buttonClose.centerYAnchor.constraint(equalTo: self.view.topAnchor, constant: 32.0).isActive = true
        self.buttonClose.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
        self.buttonClose.heightAnchor.constraint(equalTo: self.buttonClose.widthAnchor, multiplier: 1.0).isActive = true
    }
    
    var targetUrl: URL?
    
    private func _configure() {
        self.closeButtonIsHidden = false
    }
    
    convenience init(targetUrl: URL) {
        self.init()
        // set targetUrl before configuring else viewDidLoad will be called with an empty targetUrl.
        self.targetUrl = targetUrl
        self._configure()
        self.displayLoading(true)
    }

    func displayLoading(_ show: Bool) {
        if show && self.loadingSpinner.superview != self.view {
            self.webview.addSubview(self.loadingSpinner)
            self.loadingSpinner.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -32.0).isActive = true
            self.loadingSpinner.heightAnchor.constraint(equalTo: self.view.heightAnchor, constant: -32.0).isActive = true
            self.loadingSpinner.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            self.loadingSpinner.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            self.loadingSpinner.startAnimating()
        } else if !show && self.loadingSpinner.superview != nil {
            self.loadingSpinner.stopAnimating()
            self.loadingSpinner.removeFromSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.webview)
        self.setConstraints()
        self.webview.navigationDelegate = self
        
        self.closeButtonIsHidden = false
        
        if let targetUrl = targetUrl {
            self.webview.load(URLRequest(url: targetUrl))
        }
    }
    
    func setConstraints() {
        let constraints = [
            self.webview.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.webview.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.webview.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.webview.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func close(sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension HelpController: WKNavigationDelegate {
    /*
     webView decidePolicyFor navigationAction:
     webView didStartProvisionalNavigation:
     
     if Redirection:
        webView decidePolicyFor navigationAction:
     
        if .cancel:
            webView didFailProvisionalNavigation:
            FINISHED
        if .allow
            webView didReceiveServerRedirectForProvisionalNavigation:
            webView decidePolicyFor navigationResponse:
            webView didCommit navigation:
            webView didFinish navigation:
            FINISHED
     */
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Decides whether to allow or cancel a navigation.
//        print("webView decidePolicyFor navigationAction: " + (webView.url?.absoluteString ?? "???"))
        
        // Test if target is _blank
        if navigationAction.targetFrame == nil {
            // If target is _blank, open page in external navigator
            if let targetUrl = navigationAction.request.url {
                UIApplication.shared.openURL(targetUrl)
            }
            decisionHandler(.cancel)
        } else {
            // allow navigation to any page.
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Called when an error occurs while the web view is loading content or if decidePolicyForNavigationAction did answer .cancel.
    }
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // Called when a web view receives a server redirect, and after decidePolicyForNavigationAction did answer .allow.
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Called when web content begins to load in a web view.
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Called when the web view needs to respond to an authentication challenge.
        completionHandler(.performDefaultHandling, nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // Decides whether to allow or cancel a navigation after its response is known.
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // Called when the web view begins to receive web content.
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Called when the navigation is complete.
        self.displayLoading(false)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Called when an error occurs during navigation.
        self.displayLoading(false)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // Called when the web view’s web content process is terminated.
    }
}
