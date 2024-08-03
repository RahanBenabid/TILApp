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
	@Sendable func getAllHandler(_ req: Request) -> EventLoopFuture<[User]> {
		User.query(on: req.db).all()
	}
	
	@Sendable func createHandler(_ req: Request) throws -> EventLoopFuture<User> {
		let user = try req.content.decode(User.self)
		return user.save(on: req.db).map { user }
	}
	
	@Sendable func getHandler(_ req: Request) -> EventLoopFuture<User> {
		User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
	}
	
	@Sendable func getAcronymsHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { user in
				user.$acronyms.get(on: req.db)
			}
	}
}
