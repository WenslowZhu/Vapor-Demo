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
    let header: HTTPHeaders = ["Content-Type": "application/json"]
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
                                   username: usersUsername,
                                   on: conn)
        _ = try User.create(on: conn)

        let users = try app.getResponse(to: usersURI,
                                        decodeTo: [User.Public].self)

        XCTAssertEqual(users.count, 3)
        XCTAssertEqual(users[1].name, usersName)
        XCTAssertEqual(users[1].username, usersUsername)
        XCTAssertEqual(users[1].id, user.id)
    }

    func testUserCanBeSavedWithAPI() throws {
        let user = User(name: usersName,
                        username: usersUsername,
                        password: "password")

        let receivedUser = try app.getResponse(to: usersURI,
                                               method: .POST,
                                               headers: header,
                                               data: user,
                                               decodeTo: User.Public.self, loggedInRequest: true)

        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)

        let users = try app.getResponse(to: usersURI,
                                        decodeTo: [User.Public].self)

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[1].name, usersName)
        XCTAssertEqual(users[1].username, usersUsername)
        XCTAssertEqual(users[1].id, receivedUser.id)
    }

    func testGettingASingleUserFromTheAPI() throws {
        let user = try User.create(name: usersName,
                                   username: usersUsername,
                                   on: conn)

        let receivedUser = try app.getResponse(to: "\(usersURI)\(user.id!)",
                                                method: .GET,
                                                headers: header,
                                                data: user,
                                                decodeTo: User.Public.self)

        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }

    func testGettingAUsersAcronymsFromTheAPI() throws {
        let user = try User.create(on: conn)

        let acronymShort = "OMG"
        let acronymLong = "Oh My God"

        let acronym1 = try Acronym.create(short: acronymShort,
                                          long: acronymLong,
                                          user: user,
                                          on: conn)

        _ = try Acronym.create(short: "LOL",
                               long: "Laugh Out Loud",
                               user: user,
                               on: conn)

        let acronyms = try app.getResponse(to: "\(usersURI)\(user.id!)/acronyms",
                                           decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 2)
        XCTAssertEqual(acronyms[0].id, acronym1.id)
        XCTAssertEqual(acronyms[0].short, acronym1.short)
        XCTAssertEqual(acronyms[0].long, acronym1.long)
    }
}
