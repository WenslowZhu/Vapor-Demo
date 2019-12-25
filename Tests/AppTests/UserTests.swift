//
//  UserTests.swift
//  App
//
//  Created by tstone10 on 2019/12/25.
//

import Vapor
import XCTest
import FluentPostgreSQL
@testable import App

final class UserTests: XCTestCase {
    let usersName = "Alice"
    let usersUsername = "alicea"
    let usersURI = "/api/users/"
    var app: Application!
    var conn: PostgreSQLConnection!

    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }

    override func tearDown() {
        conn.close()
        try? app.syncShutdownGracefully()
    }

    func testUsersCanBeRetrievedFromAPI() throws {
        let user = try User.create(name: usersName,
                                   userName: usersUsername,
                                   on: conn)
        _ = user.create(on: conn)

        let users = try app.getResponse(to: usersURI,
                                        decodeTo: [User].self)

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].userName, usersUsername)
        XCTAssertEqual(users[0].id, user.id)
    }
}
