import Vapor

struct UsersController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		
		let usersRoute = routes.grouped("api", "users")
		
		
		usersRoute.post(use: createHandler)
		usersRoute.get(use: getAllHandler)
		usersRoute.get(":userID", use: getHandler)
		usersRoute.get(":userID", "acronyms", use: getAcronymsHandler)
	}
	
	// define the functions
	
	// now this function will use the extension EventLoopFuture<[User]> for the return type
	@Sendable func getAllHandler(_ req: Request) -> EventLoopFuture<[User.Public]> {
		User.query(on: req.db).all().convertToPublic()
	}
	
	@Sendable func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
		let user = try req.content.decode(User.self)
		user.password = try Bcrypt.hash(user.password)
		return user.save(on: req.db).map { user.convertToPublic() }
	}
	
	@Sendable func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
		User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.convertToPublic()
	}
	
	@Sendable func getAcronymsHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { user in
				user.$acronyms.get(on: req.db)
			}
	}
}
