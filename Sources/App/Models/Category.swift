//
//  Category.swift
//  App
//
//  Created by tstone10 on 2019/12/25.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Category: Codable {
    var id: Int?
    var name: String

    init(name: String) {
        self.name = name
    }
}

extension Category: PostgreSQLModel {}
extension Category: Content {}
extension Category: Migration {}
extension Category: Parameter {}

extension Category {
    var acronyms: Siblings<Category, Acronym, AcronymCategoryPivot> {
        return siblings()
    }
}
