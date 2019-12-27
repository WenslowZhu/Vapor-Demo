//
//  Application+Testable.swift
//  AppTests
//
//  Created by tstone10 on 2019/12/25.
//

import Vapor
@testable import App
import FluentPostgreSQL
import Authentication

extension Application {
    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }
        try App.configure(&config, &env, &services)
        let app = try Application(config: config,
                                  environment: env,
                                  services: services)
        try App.boot(app)
        return app
    }

    // 在每次测试之后， revert 数据库，migrate数据库
    static func reset() throws {
        let revertEnvironment = ["vapor", "revert", "--all", "-y"]
        try Application.testable(envArgs: revertEnvironment)
            .asyncRun()
            .wait()
        let migrateEnvironment = ["vapor", "migrate", "-y"]
        try Application.testable(envArgs: migrateEnvironment)
            .asyncRun()
            .wait()
    }

    // 1
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: T? = nil, loggedInRequest: Bool = false, loggedInUser: User? = nil) throws -> Response where T: Content {
        var headers = headers
        if (loggedInRequest || loggedInUser != nil) {
          let username: String
          if let user = loggedInUser {
            username = user.username
          } else {
            username = "admin"
          }
          let credentials = BasicAuthorization(username: username, password: "password")

          var tokenHeaders = HTTPHeaders()
          tokenHeaders.basicAuthorization = credentials

          let tokenResponse = try self.sendRequest(to: "/api/users/login", method: .POST, headers: tokenHeaders)
          let token = try tokenResponse.content.syncDecode(Token.self)
          headers.add(name: .authorization, value: "Bearer \(token.token)")
        }

        let responder = try self.make(Responder.self)
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: request, using: self)
        if let body = body {
          try wrappedRequest.content.encode(body)
        }
        return try responder.respond(to: wrappedRequest).wait()
    }

    // body 为空
    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), loggedInRequest: Bool = false, loggedInUser: User? = nil) throws -> Response {
        // 6
        let emptyContent: EmptyContent? = nil
        // 7
        return try sendRequest(to: path,
                               method: method,
                               headers: headers,
                               body: emptyContent,
                               loggedInRequest: loggedInRequest,
                               loggedInUser: loggedInUser)
    }

    // 无需关心 response 的测试方法
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders, data: T, loggedInRequest: Bool = false, loggedInUser: User? = nil) throws where T: Content {
        // 9
        _ = try self.sendRequest(to: path,
                                 method: method,
                                 headers: headers,
                                 body: data,
                                 loggedInRequest: loggedInRequest,
                                 loggedInUser: loggedInUser)
    }

    // 1
    func getResponse<C, T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: C? = nil, decodeTo type: T.Type, loggedInRequest: Bool = false, loggedInUser: User? = nil) throws -> T where C: Content, T: Decodable {
        // 2
        let response = try self.sendRequest(to: path,
                                            method: method,
                                            headers: headers,
                                            body: data,
                                            loggedInRequest: loggedInRequest,
                                            loggedInUser: loggedInUser)
        // 3
        return try response.content.decode(type).wait()
    }

    // body 为空
    func getResponse<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), decodeTo type: T.Type, loggedInRequest: Bool = false, loggedInUser: User? = nil) throws -> T where T: Decodable {
        // 5
        let emptyContent: EmptyContent? = nil
        // 6
        return try self.getResponse(to: path,
                                    method: method,
                                    headers: headers,
                                    data: emptyContent,
                                    decodeTo: type,
                                    loggedInRequest: loggedInRequest,
                                    loggedInUser: loggedInUser)
    }
}

// 用来发送空 body 的类型
struct EmptyContent: Content {}
