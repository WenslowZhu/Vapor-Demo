import FluentPostgreSQL
import Vapor
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // 文件存储
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // 配置测试数据库环境
    let databaseName: String
    let databasePort: Int
    if (env == .testing) {
        databaseName = "vapor-test"
        databasePort = 5433
    } else {
        databaseName = "vapor"
        databasePort = 5432
    }

    // Configure a SQLite database
    let databaseConfig = PostgreSQLDatabaseConfig(hostname: "localhost",
                                                  port: databasePort,
                                                  username: "vapor",
                                                  database: databaseName,
                                                  password: "password")

    let database = PostgreSQLDatabase(config: databaseConfig)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()

    databases.add(database: database, as: .psql)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)
    services.register(migrations)

    // 允许手动 Migration
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)

    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}
