import Foundation
import SwiftyJSON
import WebKit
import SaaSquatch

public class SaaSquatchWebView: WKWebView {
    public var client: SaaSquatchClient?
    
    /**
     Render a SaaSquatch widget to the web view.
     
     - Parameters:
        - input: The render widget input.
        - completion: A completion callback for the response to check if the render was successful.
    */
    public func renderWidget(input: RenderWidgetInput, completion: ResultHandler<Void>?) throws {
        try client?.renderWidget(input) { result in
            switch result {
            case .failure(let error):
                self.setWebViewErrorContent()
                if let completion = completion {
                    completion(.failure(error))
                }
            case .success(let template):
                self.setWebViewContent(html: template)
                
                var programId: String? = nil
                if let widgetType = input.widgetType as? ProgramWidgetType {
                    programId = widgetType.programId
                }
                
                try? self.recordWidgetLoadedAnalytic(
                    user: input.user,
                    userJwt: input.userJwt,
                    programId: programId
                )

                if let completion = completion {
                    completion(.success(()))
                }
            }
        }
    }
    
    /**
     Perform a widget upsert operation which upserts a user and renders their widget in the web view.
     
     - Parameters:
        - input: The widget upsert input.
        - completion: A completion callback for the response that receives the JSON response of the widget upsert, which contains the user and the rendered widget HTML.
     
     - Throws: `SaaSquatchClientError`if there is a failure making the request.
    */
    public func widgetUpsert(input: WidgetUpsertInput, completion: ResultHandler<JSON>?) throws {
        try client?.widgetUpsert(input) { result in
            switch result {
            case .failure(let error):
                self.setWebViewErrorContent()
                if let completion = completion {
                    completion(.failure(error))
                }
            case .success(let json):
                if let template = json["template"].string {
                    self.setWebViewContent(html: template)
                    
                    var programId: String? = nil
                    if let widgetType = input.widgetType as? ProgramWidgetType {
                        programId = widgetType.programId
                    }
                    
                    try? self.recordWidgetLoadedAnalytic(
                        user: UserIdInput(accountId: input.accountId, userId: input.userId),
                        userJwt: input.userJwt,
                        programId: programId
                    )
                    
                    if let completion = completion {
                        completion(.success(json))
                    }
                    return
                }
            }
        }
    }
    
    private func setWebViewContent(html: String) {
        DispatchQueue.main.async {
            let htmlWithMeta = html.replacingOccurrences(of: "</head>", with: "<meta name=\"viewport\" content=\"initial-scale=1.0\" /></head>")
            self.loadHTMLString(htmlWithMeta, baseURL: URL(string: "https://fast.ssqt.io"))
        }
    }
    
    private func setWebViewErrorContent() {
        DispatchQueue.main.async {
            // TODO: Err number
            self.loadHTMLString(ERROR_HTML_TEMPLATE, baseURL: URL(string: "https://fast.ssqt.io"))
        }
    }
    
    private func recordWidgetLoadedAnalytic(user: UserIdInput, userJwt: String, programId: String?) throws {
        let analyticsInput = try PushWidgetAnalyticsEventInput.Builder()
            .setUser(user)
            .setUserJwt(userJwt)
            .setEngagementMedium("MOBILE")
        if let programId = programId {
            try analyticsInput.setProgramId(programId)
        }
        try client?.pushWidgetLoadedAnalyticsEvent(analyticsInput.build()) { result in
            switch result {
            case .failure(let error):
                print("Failed to push widget loaded analytic event: \(error)")
            case .success():
                return
            }
        }
    }
}

let ERROR_HTML_TEMPLATE = """
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="initial-scale=1.0" />
        <link
          rel="stylesheet"
          media="all"
          href="https://fast.ssqt.io/assets/css/widget/errorpage.css"
        />
      </head>
      <body>
        <div class="squatch-container embed" style="width: 100%">
          <div class="errorbody">
            <div class="sadface">
              <img src="https://fast.ssqt.io/assets/images/face.png" />
            </div>
            <h4>Our referral program is temporarily unavailable.</h4>
            <br />
            <p>Please reload the page or check back later.</p>
            <p>If the persists please contact our support team.</p>
            <br />
            <br />
            <!-- div class="right-align errtxt">Error Code: {0}</div -->
          </div>
        </div>
      </body>
    </html>
"""
