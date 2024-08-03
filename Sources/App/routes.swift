import Fluent
import Vapor

func routes(_ app: Application) throws {
	
	app.get("hello") { req async -> String in
		"Hello, world!"
	}
	
	/// better orgnanise routes
	
	// create a new AcronymController
	let acronymsController = AcronymsController()
	// create UsersController instance
	let userController = UsersController()
	
	// to ensure the route gets regitered
	try app.register(collection: acronymsController)
	// Register the new controller instance with the router to hook up the routes
	try app.register(collection: userController)
	
	
}
