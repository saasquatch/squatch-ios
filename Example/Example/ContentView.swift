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
                .setTenantAlias("test_aisnwipcdkk5k")
                .setAppDomain("staging.referralsaasquatch.com")
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
        
        let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7ImlkIjoibndjIiwiYWNjb3VudElkIjoibndjIiwiZW1haWwiOiJud2NAZXhhbXBsZS5jb20ifX0.vF4kJpgabt9heJDP8D5VBWXkQK2dVpHvhDCCJK7mEVc"

        
        do {
            let input = try WidgetUpsertInput.Builder()
                .setUserInputWithUserJwt(jwt)
                .setWidgetType(ProgramWidgetType(programId: "qa-program", programWidgetKey: "referrerWidget"))
                .build()
            
            try sqWebView.widgetUpsert(input: input) { result in
                print(result)
            }
        } catch let error {
            print(error)
        }
    }
    
}
