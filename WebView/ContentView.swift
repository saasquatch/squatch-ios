//
//  ContentView.swift
//  WebView
//
//  Created by Noah on 4/21/21.
//

import SwiftUI
import WebKit
import UIKit
import MaterialComponents.MaterialSnackbar
import FBSDKShareKit

struct ContentView: View {
    var body: some View {
        WebView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct WebView: UIViewControllerRepresentable{
    typealias UIViewControllerType = WebViewController
    
    func makeUIViewController(context: Context) -> WebViewController {
        let webview = WebViewController()
        return webview
    }
    
    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        
    }
}

class WebViewController: UIViewController, WKScriptMessageHandler{
    @IBOutlet var containerView: UIView? = nil
    
    var webView: WKWebView?
    
    override func loadView(){
        super.loadView()
        
        let contentController = WKUserContentController()
        contentController.add(self, name: "snackbarMessage")
        contentController.add(self, name: "facebookShare")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        self.webView = WKWebView (frame: self.containerView?.bounds ?? .zero, configuration: config)
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // let request = URLRequest(url: URL(string: "https://example.com")!)
        
        let url = Bundle.main.url(forResource: "index", withExtension: "html")!
        webView?.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)

        webView?.load(request)
        webView?.allowsBackForwardNavigationGestures = true
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage){
        if(message.name == "snackbarMessage"){
            let content = MDCSnackbarMessage(text: "\(message.body)")
            MDCSnackbarManager.default.show(content)
        } else if (message.name == "facebookShare"){
            guard let url = URL(string: "\(message.body)") else { return } // https://developers.facebook.com/docs/apps/review/prefill/
            let linkContent = ShareLinkContent()
            linkContent.contentURL = url
            ShareDialog(fromViewController: self, content: linkContent, delegate: nil)
        }
    }
}
