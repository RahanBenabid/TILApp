import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
	let databaseName: String
	let databasePort: Int
	
	// depending on the environment we will use a different database name and port
	if (app.environment == .testing) {
		databaseName = "vapor-test"
		databasePort = 5433
	} else {
		databaseName = "vapor-database"
		databasePort = 5432
	}
	
	// modify these to use the properties we defined earlier
  app.databases.use(.postgres(
    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
		port: databasePort,
    username: Environment.get("DATABASE_USERNAME")
      ?? "vapor_username",
    password: Environment.get("DATABASE_PASSWORD")
      ?? "vapor_password",
    database: Environment.get("DATABASE_NAME")
		?? databaseName
  ), as: .psql)
  
	app.migrations.add(CreateUser())
  app.migrations.add(CreateAcronym())
	app.migrations.add(CreateCategory())
	app.migrations.add(CreateAcronymCategoryPivot())
  
  app.logger.logLevel = .debug
  
  try app.autoMigrate().wait()
  
  // register routes
  try routes(app)
}
