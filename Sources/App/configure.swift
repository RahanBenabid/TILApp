import Fluent
import FluentPostgresDriver
import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) throws {

	
	// this enables serving files
	app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	// using the session middleware, as a global middleware
	app.middleware.use(app.sessions.middleware)
	
	let databaseName: String
	let databasePort: Int
	
	// depending on the environment we will use a different database name and port
	if (app.environment == .testing) {
		databaseName = "vapor-test"
		databasePort = 5433
	} else {
		databaseName = "vapor_database"
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
	app.migrations.add(CreateToken())
	
	// create an admin
	app.migrations.add(CreateAdminUser())
  
  app.logger.logLevel = .debug
  
  try app.autoMigrate().wait()
  
  // to use Leaf when rendering
  app.views.use(.leaf)
  
  // register routes
  try routes(app)
}
