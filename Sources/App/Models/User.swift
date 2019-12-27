import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String

    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }

    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String

        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            // 用户名唯一
            builder.unique(on: \.username)
        }
    }
}
extension User: Parameter {}

extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID)
    }

    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

extension User.Public: Content {}

extension Future where T : User {
    // 类型转换
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.username
    static let passwordKey: PasswordKey = \User.password
}

// 配置 Token 类型
extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

// Admin 用户
struct AdminUser: Migration {
    // 使用何种数据库
    typealias Database = PostgreSQLDatabase

    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
      let password = try? BCrypt.hash("password")
      guard let hashedPassword = password else {
        fatalError("Failed to create admin user")
      }
      let user = User(name: "Admin", username: "admin", password: hashedPassword)
      return user.save(on: connection).transform(to: ())
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
      return .done(on: connection)
    }
}
