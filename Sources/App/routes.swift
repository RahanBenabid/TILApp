import Fluent
import Vapor

func routes(_ app: Application) throws {
	
	app.get("hello") { req async -> String in
		"Hello, world!"
	}
	
	/// better orgnanise routes
	
	// create a new AcronymController
	let acronymsController = AcronymsController()
	
	// to ensure the route gets regitered
	try app.register(collection: acronymsController)
	
	
}
