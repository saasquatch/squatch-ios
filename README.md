# SaaSquatch for IOS

## Description

This project projects an API wrapper for SaaSquatch and a simple to use WKWebView subclass which makes it easy to render referral widgets in your iOS Swift application.

## Installation

Add this to your project using Swift Package Manager. In Xcode that is simply: File > Swift Packages > Add Package Dependency... and you're done. 

## Example

The easiest way to render a widget in your application is to use the `SaaSquatchWebView` in your `UIViewController`.

Import the packages:

```
import SaaSquatch
import SaaSquatchWebView
```

Create a `SaaSquatchClient` using your tenant alias:

```            
let clientOptions = try ClientOptions.Builder()
   .setTenantAlias("<tenant_alias>")
   .build()
let client = SaaSquatchClient(clientOptions)
```

Create a `SaaSquatchWebView`, give it the client and set it as the view of your `UIViewController`:

```
var sqWebView = SaaSquatchWebView()
sqWebView.client = client
self.view = sqWebView
```

In your `viewDidLoad` or some other relevant place, perform a widget upsert:

```        
let jwt = "<user jwt>" 

do {
    let input = try WidgetUpsertInput.Builder()
        .setUserInputWithUserJwt(jwt)
        .setWidgetType(ProgramWidgetType(programId: "<program-id>", programWidgetKey: "referrerWidget"))
        .build()
    
    try sqWebView.widgetUpsert(input: input)
} catch let error {
    print(error)
}
```

Here's a full example:
```
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
```

## Security

To produce a user JWT, you will need to sign it with your Tenant API key. We do NOT recommend that you include this key in your application, but rather produce the JWT server-side.

For more information about creating valid JWT's, see [the SaaSquatch documentation](https://docs.saasquatch.com/topics/json-web-tokens/).

## License

squatch-ios is available under the MIT license. See [the LICENSE file](LICENSE) for more information.
