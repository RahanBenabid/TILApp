import Fluent
import Vapor

func routes(_ app: Application) throws {
	
		
	/// better orgnanise routes
	
	// create a new AcronymController
	let acronymsController = AcronymsController()
	// create UsersController instance
	let usersController = UsersController()
	let categoriesController = CategoriesController()
	
	// to ensure the route gets regitered
	try app.register(collection: acronymsController)
	// Register the new controller instance with the router to hook up the routes
	try app.register(collection: usersController)
	try app.register(collection: categoriesController)
  
  // Leaf
  let websiteController = WebsiteController()
  try app.register(collection: websiteController)
	
	//imperial
	let imperialController = ImperialController()
	try app.register(collection: imperialController)
}
