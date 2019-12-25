//
//  AcronymTest.swift
//  App
//
//  Created by tstone10 on 2019/12/25.
//

import Vapor
import XCTest
import FluentPostgreSQL
@testable import App

final class AcronymTest: XCTestCase {
    let acronymShort = "OMG"
    let acronymLong = "Oh My God"
    let acronymsURI = "/api/acronyms/"
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

    func testAcronymCanBeRetrievedFromAPI() throws {
        let acronym = try Acronym.create(short: acronymShort,
                                         long: acronymLong,
                                         on: conn)

        let acronyms = try app.getResponse(to: acronymsURI,
                                           decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 1)
        XCTAssertEqual(acronyms[0].short, acronym.short)
        XCTAssertEqual(acronyms[0].long, acronym.long)
        XCTAssertEqual(acronyms[0].id, acronym.id)
        XCTAssertEqual(acronyms[0].userID, acronym.userID)
        XCTAssertEqual(acronyms[0].user.parentID, acronym.user.parentID)
    }

    func testAcronymCanBeSavedWithAPI() throws {
        let user = try User.create(name: "123",
                                   username: "456",
                                   on: conn)
        let acronym = Acronym(short: acronymShort,
                              long: acronymLong,
                              userID: user.id!)

        let receivedAcronym = try app.getResponse(to: acronymsURI,
                                                  method: .POST,
                                                  headers: header,
                                                  data: acronym,
                                                  decodeTo: Acronym.self)

        XCTAssertEqual(receivedAcronym.short, acronym.short)
        XCTAssertEqual(receivedAcronym.long, acronym.long)
        XCTAssertEqual(receivedAcronym.userID, user.id)
    }

    func testGettingASingleAcronymFromTheAPI() throws {
        let acronym = try Acronym.create(short: acronymShort,
                                         long: acronymLong,
                                         on: conn)

        let receivedAcronym = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)",
                                                  method: .GET,
                                                  headers: header,
                                                  decodeTo: Acronym.self)

        XCTAssertEqual(receivedAcronym.short, acronym.short)
        XCTAssertEqual(receivedAcronym.long, acronym.long)
        XCTAssertEqual(receivedAcronym.id, acronym.id)
        XCTAssertEqual(receivedAcronym.userID, acronym.userID)
    }

    func testUpdateAPI() throws {
        let acronym = try Acronym.create(short: acronymShort,
                                         long: acronymLong,
                                         on: conn)

        let user = try User.create(name: "123",
                                   username: "456",
                                   on: conn)

        let acronym2 = Acronym(short: "acronymShort",
                               long: "acronymLong",
                               userID: user.id!)

        let updatedAcronym = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)",
                                                method: .PUT,
                                                headers: header,
                                                data: acronym2,
                                                decodeTo: Acronym.self)

        XCTAssertEqual(updatedAcronym.short, acronym2.short)
        XCTAssertEqual(updatedAcronym.long, acronym2.long)
        XCTAssertEqual(updatedAcronym.userID, acronym2.userID)
    }

    func testDeleteAPI() throws {
        let acronym = try Acronym.create(on: conn)

        _ = try app.sendRequest(to: "\(acronymsURI)\(acronym.id!)", method: .DELETE)

        let acronyms = try app.getResponse(to: acronymsURI,
                                           method: .GET,
                                           headers: header,
                                           decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 0)
    }

    func testSearchAPI() throws {
        let acronym = try Acronym.create(on: conn)

        let acronyms = try app.getResponse(to: "\(acronymsURI)search?term=TIL",
                                            method: .GET,
                                            headers: header,
                                            decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 1)
        XCTAssertEqual(acronyms[0].id, acronym.id)
    }

    func testFirstAPI() throws {
        let acronym1 = try Acronym.create(on: conn)
        let acronym2 = try Acronym.create(short: acronymShort,
                                          long: acronymLong,
                                          on: conn)

        let acronym = try app.getResponse(to: "\(acronymsURI)first",
                                            method: .GET,
                                            headers: header,
                                            decodeTo: Acronym.self)

        XCTAssertEqual(acronym.id, acronym1.id)
        XCTAssertNotEqual(acronym.id, acronym2.id)
    }

    func testSortedAPI() throws {
        let acronym1 = try Acronym.create(short: "ZZZ",
                                          long: "XXX",
                                          on: conn)
        let acronym2 = try Acronym.create(short: acronymShort,
                                          long: acronymLong,
                                          on: conn)

        let acronyms = try app.getResponse(to: "\(acronymsURI)sorted",
                                            method: .GET,
                                            headers: header,
                                            decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms[0].id!, acronym2.id!)
        XCTAssertEqual(acronyms[1].id!, acronym1.id!)
    }

    func testGetUserAPI() throws {
        let user = try User.create(on: conn)
        let acronym = try Acronym.create(short: acronymShort,
                                         long: acronymLong,
                                         user: user,
                                         on: conn)

        let result = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)/user",
            method: .GET,
            headers: header,
            decodeTo: User.self)

        XCTAssertEqual(result.id!, user.id!)
    }

    func testAddCategoriesAPI() throws {
        let acronym = try Acronym.create(on: conn)
        let category = try App.Category.create(on: conn)

        _ = try app.sendRequest(to: "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)", method: .POST)

        let result = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)/categories",
            method: .GET,
            headers: header,
            decodeTo: [App.Category].self)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id!, category.id!)
    }

    func testRemoveCategoriesAPI() throws {
        let acronym = try Acronym.create(on: conn)
        let category = try App.Category.create(on: conn)

        _ = try app.sendRequest(to: "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)", method: .POST)

        _ = try app.sendRequest(to: "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)", method: .DELETE)

        let result = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)/categories",
            method: .GET,
            headers: header,
            decodeTo: [App.Category].self)

        XCTAssertEqual(result.count, 0)
    }
}
