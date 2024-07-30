import Fluent
// 1
import FluentSQLiteDriver
import Vapor
// configures your application
public func configure(_ app: Application) throws {
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateAcronym())
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()
    // register routes
    try routes(app)
}
