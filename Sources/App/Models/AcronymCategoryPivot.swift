//
//  AcronymCategoryPivot.swift
//  App
//
//  Created by tstone10 on 2019/12/25.
//

import Foundation
import FluentPostgreSQL

final class AcronymCategoryPivot: PostgreSQLUUIDPivot {
    var id: UUID?

    // 3
    var acronymID: Acronym.ID
    var categoryID: Category.ID

    // 4
    typealias Left = Acronym
    typealias Right = Category

    // 5
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID

    // 6
    init(_ acronym: Acronym, _ category: Category) throws {
        self.acronymID = try acronym.requireID()
        self.categoryID = try category.requireID()
    }
}

// 7
extension AcronymCategoryPivot: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        // 建立表
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            // 删除 acronym 时，relationship 会被自动删除
            builder.reference(from: \.acronymID, to: \Acronym.id, onDelete: ._cascade)
            builder.reference(from: \.categoryID, to: \Category.id, onDelete: ._cascade)
        }
    }
}
extension AcronymCategoryPivot: ModifiablePivot {}
