import Fluent
// 1
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
  // 2
  app.databases.use(.postgres(
    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
    username: Environment.get("DATABASE_USERNAME")
      ?? "vapor_username",
    password: Environment.get("DATABASE_PASSWORD")
      ?? "vapor_password",
    database: Environment.get("DATABASE_NAME")
      ?? "vapor_database"
  ), as: .psql)
  
  app.migrations.add(CreateAcronym())
	app.migrations.add(CreateAcronym())
  
  app.logger.logLevel = .debug
  
  try app.autoMigrate().wait()
  
  // register routes
  try routes(app)
}
