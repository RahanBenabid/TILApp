import Vapor

struct UsersController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		
		let usersRoute = routes.grouped("api", "users")
		usersRoute.get(use: getAllHandler)
		usersRoute.get(":userID", use: getHandler)
		usersRoute.get(":userID", "acronyms", use: getAcronymsHandler)
		
		let basicAuthMiddleware = User.authenticator()
		let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
		basicAuthGroup.post("login", use: loginHandler)
		
		let tokenAuthMiddleware = Token.authenticator()
		let gaurdAuthMiddleware = User.guardMiddleware()
		let tokenAuthGroup = usersRoute.grouped(
			tokenAuthMiddleware,
			gaurdAuthMiddleware
		)
		tokenAuthGroup.post(use: createHandler)
		
		let usersV2Route = routes.grouped("api", "v2", "users")
		usersV2Route.get(":userID", use: getV2Handler)
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
	
	@Sendable func getV2Handler(_ req: Request) -> EventLoopFuture<User.PublicV2> {
		User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.convertToPublicV2()
	}
	
	@Sendable func getAcronymsHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { user in
				user.$acronyms.get(on: req.db)
			}
	}
	
	@Sendable func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
			// Extract the authenticated user from the request
			// If the user is not authenticated, this will throw an error
			let user = try req.auth.require(User.self)
			// Generate a new token for the authenticated user
			let token = try Token.generate(for: user)
			// Save the newly generated token to the database
			// This returns an EventLoopFuture, which resolves once the token is saved
			return token.save(on: req.db).map { token }
	}
}
