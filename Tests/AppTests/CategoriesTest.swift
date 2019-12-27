//
//  CategoriesTest.swift
//  AppTests
//
//  Created by tstone10 on 2019/12/25.
//

import Vapor
import XCTest
import FluentPostgreSQL
@testable import App

final class CategoriesTest: XCTestCase {
    let categoryName = "AAAAA"
    let categoriesURI = "/api/categories/"
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

    func testCreateAndGetAllAPI() throws {
        let category = App.Category(name: categoryName)

        _ = try app.sendRequest(to: categoriesURI,
                                method: .POST,
                                headers: header,
                                body: category,
                                loggedInRequest: true)

        let result = try app.getResponse(to: categoriesURI,
                                         decodeTo: [App.Category].self)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, category.name)
    }

    func testGetSingleAPI() throws {
        let category = try App.Category.create(on: conn)

        let result = try app.getResponse(to: "\(categoriesURI)\(category.id!)",
                                            decodeTo: App.Category.self)

        XCTAssertEqual(result.id!, category.id!)
    }

    func testGetAcronymsAPI() throws {
        let acronym = try Acronym.create(on: conn)
        let category = try App.Category.create(on: conn)
        let acronymsURI = "/api/acronyms/"

        _ = try app.sendRequest(to: "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)", method: .POST,loggedInRequest: true)

        let result = try app.getResponse(to: "\(categoriesURI)\(category.id!)/acronyms",
            method: .GET,
            headers: header,
            decodeTo: [Acronym].self)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id!, acronym.id!)
    }
}
