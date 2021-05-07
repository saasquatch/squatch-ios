import SwiftUI
import UIKit

import SaaSquatch
import SaaSquatchWebView

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

class WebViewController: UIViewController  {
    var sqWebView: SaaSquatchWebView = SaaSquatchWebView()
    
    override func loadView(){
        super.loadView()
        
        do {
            let clientOptions = try ClientOptions.Builder()
                .setTenantAlias("<tenant_alias>")
                .build()
            
            let client = SaaSquatchClient(clientOptions)
            sqWebView.client = client
        } catch let error {
            print(error)
            return
        }
        
        self.view = sqWebView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let jwt = "<jwt>"
        
        do {
            let input = try WidgetUpsertInput.Builder()
                .setUserInputWithUserJwt(jwt)
                .setWidgetType(ProgramWidgetType(programId: "<program-id>", programWidgetKey: "referrerWidget"))
                .build()
            
            try sqWebView.widgetUpsert(input: input) { result in
                print(result)
            }
        } catch let error {
            print(error)
        }
    }
    
}
