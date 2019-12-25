//
//  Models+Testable.swift
//  AppTests
//
//  Created by tstone10 on 2019/12/25.
//

@testable import App
import FluentPostgreSQL

extension User {
    // 创建测试模型
    static func create(name: String = "Luke", userName: String = "lukes", on connection: PostgreSQLConnection) throws -> User {
        let user = User(name: name, userName: userName)
        return try user.save(on: connection).wait()
    }
}
