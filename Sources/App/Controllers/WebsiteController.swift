import Vapor
import Leaf

struct WebsiteController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		routes.get(use: indexHandler)
		routes.get("acronyms", ":acronymID", use: acronymHandler)
		routes.get("users", ":userID", use: userHandler)
		routes.get("users", use: allUserHandler)
	}
	
	@Sendable func indexHandler(_ req: Request) -> EventLoopFuture<View> {
		Acronym.query(on: req.db).all().flatMap { acronyms in
			// create an Encodable IndexTitle containing the title we want
			let context = IndexContext(title: "Home Page", acronyms: acronyms)
			// pass it as a second parameter
			return req.view.render("index", context)
		}
	}
	
	@Sendable func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.$user.get(on: req.db).flatMap { user in
					let context = AcronymContext(title: acronym.short,
																			 acronym: acronym,
																			 user: user)
					return req.view.render("acronym", context)
				}
			}
	}
	
	@Sendable func userHandler(_ req: Request) -> EventLoopFuture<View> {
		User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { user in
				user.$acronyms.get(on: req.db).flatMap { acronyms in
					let context = userContext(title: "user.name",
																		user: user,
																		acronyms: acronyms)
					return req.view.render("user", context)
				}
			}
	}
	
	@Sendable func allUserHandler(_ req: Request) -> EventLoopFuture<View> {
		User.query(on: req.db)
			.all()
			.flatMap { users in
			let context = allUsersContext(title: "All Users", users: users)
			return req.view.render("allUsers", context)
		}
	}
}

struct IndexContext: Encodable {
	let title: String
	let acronyms: [Acronym]
}

struct AcronymContext: Encodable {
	let title: String
	let acronym: Acronym
	let user: User
}

struct userContext: Encodable {
	let title: String
	let user: User
	let acronyms: [Acronym]
}

struct allUsersContext: Encodable {
	let title: String
	let users: [User]
}
