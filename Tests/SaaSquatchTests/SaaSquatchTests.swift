    import XCTest
    @testable import SaaSquatch
    import SwiftyJSON
    
    final class SaaSquatchTests: XCTestCase {
        
        var client : SaaSquatchClient?
        
        let testQuery = """
            query renderWidget(
                $user: UserIdInput
                $widgetType: WidgetType
                $engagementMedium: UserEngagementMedium
                $locale: RSLocale
            ) {
                renderWidget(
                    user: $user
                    widgetType: $widgetType
                    engagementMedium: $engagementMedium
                    locale: $locale
                ) {
                    template
                }
            }
        """
        
        let tenantAlias = "CHANGEME"
        let appDomain = "CHANGEME"
        let programId = "CHANGEME"
        let userid = "CHANGEME"
        let accountid = "CHANGEME"
        let jwt = "CHANGEME"
        
        override func setUp() {
            super.setUp()
            
            do{
                let options = try ClientOptions.Builder()
                    .setTenantAlias(tenantAlias)
                    .setAppDomain(appDomain)
                    .build()
                self.client = SaaSquatchClient(options)
            } catch let error {
                XCTFail("\(error)")
            }
            
        }
        
        override func tearDown() {
            super.tearDown()
        }
        
        func testClientOptionsBuildWithDomain() {
            XCTAssertNoThrow(try ClientOptions.Builder()
                                .setTenantAlias(tenantAlias)
                                .setAppDomain(appDomain)
                                .build())
        }
        
        func testClientOptionsBuildWithoutDomain() {
            XCTAssertNoThrow(try ClientOptions.Builder()
                                .setTenantAlias(tenantAlias)
                                .build())
        }
        
        func testClientOptionsBuildWithoutAlias() {
            XCTAssertThrowsError(try ClientOptions.Builder()
                                    .setAppDomain(appDomain)
                                    .build())
            
        }
        
        func testValidAppDomain() {
            XCTAssertThrowsError(try ClientOptions.Builder()
                                    .setTenantAlias(tenantAlias)
                                    .setAppDomain("")
                                    .build())
            
            XCTAssertThrowsError(try ClientOptions.Builder()
                                    .setTenantAlias(tenantAlias)
                                    .setAppDomain("\(appDomain)/")
                                    .build())
            
            XCTAssertThrowsError(try ClientOptions.Builder()
                                    .setTenantAlias(tenantAlias)
                                    .setAppDomain("/\(appDomain)")
                                    .build())
            
            XCTAssertThrowsError(try ClientOptions.Builder()
                                    .setTenantAlias(tenantAlias)
                                    .setAppDomain("https://\(appDomain)")
                                    .build())
        }
        
        func testValidTenantAlias() {
            XCTAssertThrowsError(try ClientOptions.Builder().build())
            
            XCTAssertThrowsError(try ClientOptions.Builder()
                                    .setTenantAlias("")
                                    .build())
        }
        
        func testClientOptionsAssignment() {
            do {
                let options = try ClientOptions.Builder()
                    .setTenantAlias(tenantAlias)
                    .setAppDomain(appDomain)
                    .build()
                
                XCTAssertEqual(options.appDomain, appDomain)
                XCTAssertEqual(options.tenantAlias, tenantAlias)
            }
            catch let error{
                XCTFail("\(error)")
            }
            
        }
        
        
        func testSuccessfulClientBuild() {
            do {
                let options = try ClientOptions.Builder()
                    .setTenantAlias(tenantAlias)
                    .setAppDomain(appDomain)
                    .build()
                
                XCTAssertNoThrow(SaaSquatchClient(options))
            }
            catch let error{
                XCTFail("\(error)")
            }
        }
        
        func testBlankQuery() {
            XCTAssertThrowsError(try GraphQLInput.Builder()
                                    .withQuery("")
                                    .withOperatioName("TestOperation")
                                    .withVariables("{}").build())
        }
        
        func testBlankOperationName() {
            XCTAssertThrowsError(try GraphQLInput.Builder()
                                    .withQuery(self.testQuery)
                                    .withOperatioName("")
                                    .withVariables("{}").build())
        }
        
        func testBuildWithOperationAndVariables(){
            XCTAssertNoThrow(try GraphQLInput.Builder()
                                .withQuery(self.testQuery)
                                .withOperatioName("TestOperation")
                                .withVariables("{}").build())
            
        }
        
        func testBuildWithQueryOnly() {
            XCTAssertNoThrow(try GraphQLInput.Builder()
                                .withQuery(self.testQuery)
                                .build())
        }
        
        func testBuildGraphQLWithCorrectData() {
            do{
                let gqlInput = try GraphQLInput.Builder()
                    .withQuery(self.testQuery)
                    .withOperatioName("TestOperation")
                    .withVariables("{}").build()
                
                XCTAssertEqual(gqlInput.query, self.testQuery)
                XCTAssertEqual(gqlInput.operationName, "TestOperation")
                XCTAssertEqual(gqlInput.variables, "{}")
                
            } catch let error {
                XCTFail("Failed with error \(error)")
            }
        }
        
        func testGraphQLWithBadJWT() {
            do{
                let gqlInput = try GraphQLInput.Builder()
                    .withQuery(self.testQuery)
                    .withOperatioName("TestOperation")
                    .withVariables("{}").build()
                
                XCTAssertNoThrow(try client?.graphQL(input: gqlInput, userJwt: self.jwt + "123"){
                    result in
                    switch result {
                    case .success(let result):
                        XCTAssert(result.exists())
                    case .failure(let error):
                        XCTAssert(!error.description.isEmpty)
                    }
                })
                
            } catch let error {
                XCTFail("Failed with error \(error)")
            }
            
        }
        
        func testValidGraphQLRequest() {
            do{
                let gqlInput = try GraphQLInput.Builder()
                    .withQuery(self.testQuery)
                    .withOperatioName("TestOperation")
                    .withVariables("{}").build()
                
                XCTAssertNoThrow(try client?.graphQL(input: gqlInput, userJwt: self.jwt){
                    result in
                    switch result {
                    case .success(let result):
                        XCTAssert(result.exists())
                    case .failure(let error):
                        XCTFail("Failed with error \(error)")
                    }
                })
                
            } catch let error {
                XCTFail("Failed with error \(error)")
            }
            
        }
        
        func testUpsertUserNoAccount() {
            let userinput : JSON = ["id":"\(self.userid)"]
            
            XCTAssertThrowsError(try client?.userUpsert(userInput: userinput, userJwt: self.jwt){
                result in
                switch result {
                case .success(let result):
                    XCTFail("Failed, received server response \(result)")
                case .failure(let error):
                    XCTFail("Failed, reqest executed with error \(error.description)")
                }
            })
            
        }
        
        func testUpsertUserNoID() {
            let userinput : JSON = ["accountId":"\(self.accountid)"]
            
            XCTAssertThrowsError(try client?.userUpsert(userInput: userinput, userJwt: self.jwt){
                result in
                switch result {
                case .success(let result):
                    XCTFail("Failed, received server response \(result)")
                case .failure(let error):
                    XCTFail("Failed, request executed with error \(error.description)")
                }
            })
        }
        
        func testUpsertUserWithBadJWT() {
            let userinput : JSON = ["id":"\(self.userid)", "accountId":"\(self.accountid)"]
            
            XCTAssertNoThrow(try client?.userUpsert(userInput: userinput, userJwt: self.jwt + "123"){
                result in
                switch result {
                case .success(let result):
                    XCTFail("Failed, received server response \(result)")
                case .failure(let error):
                    XCTAssert(!error.description.isEmpty)
                }
            })
            
        }
        
        func testUpsertUserWithJWTBadJWT(){
            XCTAssertNoThrow(try client?.userUpsertWithUserJwt(self.jwt + "123"){
                result in
                switch result {
                case .success(let result):
                    XCTFail("Failed, received server response \(result)")
                case .failure(let error):
                    XCTAssert(!error.description.isEmpty)
                }
            })
        }
        
        func testUpsertUserWithJWT() {
            XCTAssertNoThrow(try client?.userUpsertWithUserJwt(self.jwt){
                result in
                switch result {
                case .success(let result):
                    XCTAssert(result.exists())
                case .failure(let error):
                    XCTFail("Failed with error \(error.description)")
                }
            })
        }
        
        func testUpsertUser() {
            let userinput : JSON = ["id":"\(self.userid)", "accountId":"\(self.accountid)"]
            
            XCTAssertNoThrow(try client?.userUpsert(userInput: userinput, userJwt: self.jwt){
                result in
                switch result {
                case .success(let result):
                    XCTAssert(result.exists())
                case .failure(let error):
                    XCTFail("Failed with error \(error.description)")
                }
            })
        }
        
        func testLogEventBadJWT() {
            let usereventinput : JSON = ["userId":"\(self.userid)", "accountId":"\(self.accountid)"]
            
            XCTAssertNoThrow(try client?.logUserEvent(userEventInput: JSON(usereventinput), userJwt: self.jwt + "123"){
                result in
                switch result {
                case .success(let result):
                    XCTFail("Failed, received server response \(result)")
                case .failure(let error):
                    XCTAssert(!error.description.isEmpty)
                }
            })
        }
        
        func testLogEventNoAccount() {
            let usereventinput : JSON = ["userId":"\(self.userid)"]
            
            XCTAssertThrowsError(try client?.logUserEvent(userEventInput: usereventinput, userJwt: self.jwt){
                result in
                switch result {
                case .success(let result):
                    XCTFail("Failed, received server response \(result)")
                case .failure(let error):
                    XCTFail("Failed, reqest executed with error \(error.description)")
                }
            })
        }
        
        func testLogEventNoID() {
            let usereventinput : JSON = ["accountId":"\(self.accountid)"]
            
            XCTAssertThrowsError(try client?.logUserEvent(userEventInput: usereventinput, userJwt: self.jwt){
                result in
                switch result {
                case .success(let result):
                    XCTFail("Failed, received server response \(result)")
                case .failure(let error):
                    XCTFail("Failed, request executed with error \(error.description)")
                }
            })
        }
        
        func testLogEvent() {
            let usereventinput : JSON = ["userId":"\(self.userid)", "accountId":"\(self.accountid)"]
            
            XCTAssertNoThrow(try client?.logUserEvent(userEventInput: usereventinput, userJwt: self.jwt){
                result in
                switch result {
                case .success(let result):
                    XCTAssert(result.exists())
                case .failure(let error):
                    XCTFail("Failed with error \(error.description)")
                }
            })
            
        }
        
        func testAnalyticsEventBadJWT(){
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            do{
                let analyticsInput = try PushWidgetAnalyticsEventInput.Builder()
                    .setUser(userinput)
                    .setUserJwt(self.jwt + "123")
                    .build()
                
                try client?.pushWidgetLoadedAnalyticsEvent(analyticsInput){
                    result in
                    switch result {
                    case .success(let result):
                        XCTFail("Failed, received server response \(result)")
                    case .failure(let error):
                        XCTAssert(!error.description.isEmpty)
                    }
                }
            } catch let error {
                XCTFail("Request failed with error \(error)")
            }
            
        }
        
        
        func testLoadedAnalyticsEvent() {
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            do{
                let analyticsInput = try PushWidgetAnalyticsEventInput.Builder()
                    .setUser(userinput)
                    .setUserJwt(self.jwt)
                    .build()
                
                try client?.pushWidgetLoadedAnalyticsEvent(analyticsInput){
                    result in
                    switch result {
                    case .success(let result):
                        //XCTAssert(result.exists())
                        break
                    case .failure(let error):
                        XCTFail("Failed, request executed with error \(error)")
                    }
                }
            } catch let error {
                XCTFail("Request failed with error \(error)")
            }
        }
        
        func testSharedAnalyticsEvent() {
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            do{
                let analyticsInput = try PushWidgetAnalyticsEventInput.Builder()
                    .setUser(userinput)
                    .setUserJwt(self.jwt)
                    .build()
                
                try client?.pushWidgetSharedAnalyticsEvent(analyticsInput){
                    result in
                    switch result {
                    case .success(let result):
                        //XCTAssert(result.exists())
                        break
                    case .failure(let error):
                        XCTFail("Failed, request executed with error \(error)")
                    }
                }
            } catch let error {
                XCTFail("Request failed with error \(error)")
            }
        }
        
        func testLoadedEventWithShareMedium() {
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            do{
                let analyticsInput = try PushWidgetAnalyticsEventInput.Builder()
                    .setUser(userinput)
                    .setUserJwt(self.jwt)
                    .setShareMedium("EMAIL")
                    .build()
                
                
                XCTAssertThrowsError(try client?.pushWidgetLoadedAnalyticsEvent(analyticsInput){
                    result in
                    switch result {
                    case .success(let result):
                        //XCTAssert(result.exists())
                        break
                    case .failure(let error):
                        XCTFail("Failed, request executed with error \(error)")
                    }
                })
            } catch let error {
                XCTFail("Request failed with error \(error)")
            }
        }
        
        func testAnalyticsEventMissingUser(){
            XCTAssertThrowsError(try PushWidgetAnalyticsEventInput.Builder()
                                    .setUserJwt(self.jwt)
                                    .build())
        }
        
        func testAnalyticsEventMissingJWT(){
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            XCTAssertThrowsError(try PushWidgetAnalyticsEventInput.Builder()
                                    .setUser(userinput)
                                    .build())
        }
        
        func testMinimalAnalyticsEventData(){
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            XCTAssertNoThrow(try PushWidgetAnalyticsEventInput.Builder()
                                .setUser(userinput)
                                .setUserJwt(self.jwt)
                                .build())
        }
        
        func testFullAnalyticsEventData(){
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            XCTAssertNoThrow(try PushWidgetAnalyticsEventInput.Builder()
                                .setUser(userinput)
                                .setUserJwt(self.jwt)
                                .setShareMedium("EMAIL")
                                .setProgramId(programId)
                                .setEngagementMedium("MOBILE")
                                .build())
        }
        
        func testAnalyticsInputBuildsWithCorrectData(){
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            do{
                let analyticsInput = try PushWidgetAnalyticsEventInput.Builder()
                    .setUser(userinput)
                    .setUserJwt(self.jwt)
                    .setShareMedium("EMAIL")
                    .setProgramId(programId)
                    .setEngagementMedium("MOBILE")
                    .build()
                
                XCTAssertEqual(analyticsInput.user.userId, self.userid)
                XCTAssertEqual(analyticsInput.user.accountId, self.accountid)
                XCTAssertEqual(analyticsInput.userJwt, self.jwt)
                XCTAssertEqual(analyticsInput.shareMedium, "EMAIL")
                XCTAssertEqual(analyticsInput.programId, programId)
                XCTAssertEqual(analyticsInput.engagementMedium, "MOBILE")
                
            } catch let error {
                XCTFail("Failed to build analytics input with error \(error)")
            }
        }
        
        func testAnaylticsEventEmptyProgramId(){
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            XCTAssertThrowsError(try PushWidgetAnalyticsEventInput.Builder()
                                    .setUser(userinput)
                                    .setUserJwt(self.jwt)
                                    .setShareMedium("EMAIL")
                                    .setProgramId("")
                                    .setEngagementMedium("MOBILE")
                                    .build())
        }
        
        func testAnalyticsEventEmptyEngagementMedium(){
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            XCTAssertThrowsError(try PushWidgetAnalyticsEventInput.Builder()
                                    .setUser(userinput)
                                    .setUserJwt(self.jwt)
                                    .setShareMedium("EMAIL")
                                    .setProgramId(programId)
                                    .setEngagementMedium("")
                                    .build())
            
        }
        
        func testAnalyticsEventEmptyShareMedium() {
            let userinput = UserIdInput(accountId: self.accountid, userId: self.userid)
            
            XCTAssertThrowsError(try PushWidgetAnalyticsEventInput.Builder()
                                    .setUser(userinput)
                                    .setUserJwt(self.jwt)
                                    .setShareMedium("")
                                    .setProgramId(programId)
                                    .setEngagementMedium("MOBILE")
                                    .build())
        }
        
        
        func testWidgetUpsertInputNoUser() {
            let userinput : JSON = ["accountId":self.accountid]
            
            XCTAssertThrowsError(try WidgetUpsertInput.Builder()
                                    .setUserInput(userinput)
                                    .setUserJwt(self.jwt)
                                    .build())
        }
        
        func testWidgetUpsertInputNoAccount() {
            let userinput : JSON = ["id":self.userid]
            
            XCTAssertThrowsError(try WidgetUpsertInput.Builder()
                                    .setUserInput(userinput)
                                    .setUserJwt(self.jwt)
                                    .build())
        }
        
        func testMinimalWidgetUpsertInputData() {
            let userinput : JSON = ["id":self.userid, "accountId":self.accountid]
            
            XCTAssertNoThrow(try WidgetUpsertInput.Builder()
                                .setUserInput(userinput)
                                .setUserJwt(self.jwt)
                                .build())
        }
        
        func testFullWidgetUpsertInputData(){
            let userinput : JSON = ["id":self.userid, "accountId":self.accountid]
            
            XCTAssertNoThrow(try WidgetUpsertInput.Builder()
                                .setUserInput(userinput)
                                .setUserJwt(self.jwt)
                                .setEngagementMedium("MOBILE")
                                .setWidgetType(ProgramWidgetType(programId: programId, programWidgetKey: "referrerWidget"))
                                .build())
        }
        
        func testWidgetUpsertInputBuildsWithCorrectData() {
            let userinput : JSON = ["id":self.userid, "accountId":self.accountid]
            
            do{
                let input = try WidgetUpsertInput.Builder()
                    .setUserInput(userinput)
                    .setUserJwt(self.jwt)
                    .setEngagementMedium("MOBILE")
                    .setWidgetType(ProgramWidgetType(programId: programId, programWidgetKey: "referrerWidget"))
                    .build()
                
                XCTAssertEqual(input.userInput, userinput)
                XCTAssertEqual(input.accountId, self.accountid)
                XCTAssertEqual(input.userId, self.userid)
                XCTAssertEqual(input.userJwt, self.jwt)
                XCTAssertEqual(input.engagementMedium, "MOBILE")
                XCTAssertEqual(input.widgetType?.widgetType, "p/\(programId)/w/referrerWidget")
            } catch let error {
                XCTFail("Failed with error \(error)")
            }
        }
        
        func testUpsertWidgetBadJWT() {
            let userinput : JSON = ["id":self.userid, "accountId":self.accountid]
            
            do{
                let input = try WidgetUpsertInput.Builder()
                    .setUserInput(userinput)
                    .setUserJwt(self.jwt + "123")
                    .setEngagementMedium("MOBILE")
                    .setWidgetType(ProgramWidgetType(programId: programId, programWidgetKey: "referrerWidget"))
                    .build()
                
                try client?.widgetUpsert(input){
                    result in
                    switch result {
                    case .success(let result):
                        XCTFail("Request executed with response \(result)")
                        break
                    case .failure(let error):
                        XCTAssert(!error.description.isEmpty)
                    }
                }
                
            } catch let error {
                XCTFail("Failed with erro \(error)")
            }
        }
        
        func testUpsertWidget() {
            let userinput : JSON = ["id":self.userid, "accountId":self.accountid]
            
            do{
                let input = try WidgetUpsertInput.Builder()
                    .setUserInput(userinput)
                    .setUserJwt(self.jwt + "123")
                    .setEngagementMedium("MOBILE")
                    .setWidgetType(ProgramWidgetType(programId: programId, programWidgetKey: "referrerWidget"))
                    .build()
                
                try client?.widgetUpsert(input){
                    result in
                    switch result {
                    case .success(let result):
                        XCTAssert(result.exists())
                        break
                    case .failure(let error):
                        XCTFail("Failed with error \(error)")
                    }
                }
                
            } catch let error {
                XCTFail("Failed with erro \(error)")
            }
        }
        
    }
