import Vapor
import Leaf

struct WebsiteController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		routes.get(use: indexHandler)
		routes.get("acronyms", ":acronymID", use: acronymHandler)
		routes.get("users", ":userID", use: userHandler)
		routes.get("users", use: allUserHandler)
		routes.get("categories", use: allCategoriesHandler)
		routes.get("categories", ":categoryID", use: categoryHandler)
		routes.get("acronyms", "create", use: createAcronymHandler)
		routes.post("acronyms", "create", use: createAcronymPostHandler)
		routes.get("acronyms", ":acronymID", "edit", use: editAcronymHandler)
		routes.post("acronyms", ":acronymID", "edit", use: editAcronymPostHandler)
		routes.post("acronyms", ":acronymID", "delete", use: deleteAcronymHandler)
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
					let context = UserContext(title: "user.name",
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
			let context = AllUsersContext(title: "All Users", users: users)
			return req.view.render("allUsers", context)
		}
	}
	
	@Sendable func allCategoriesHandler(_ req: Request) -> EventLoopFuture<View> {
		Category.query(on: req.db).all().flatMap { categories in
			let context = AllCategoriesContext(categories: categories)
			return req.view.render("allCategories", context)
		}
	}
	
	@Sendable func categoryHandler(_ req: Request) -> EventLoopFuture<View> {
		Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { category in
				category.$acronyms.get(on: req.db).flatMap { acronyms in
					let context = CategoryContext(title: category.name,
																				category: category,
																				acronyms: acronyms)
					return req.view.render("category", context)
				}
			}
	}
	
	@Sendable func createAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
		User.query(on: req.db).all().flatMap { users in
			let context = CreateAcronymContext(users: users)
			return req.view.render("createAcronym", context)
		}
	}
	
	@Sendable func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
		let data = try req.content.decode(CreateAcronymData.self)
		let acronym = Acronym(
			short: data.short,
			long: data.long,
			userID: data.userID)
		
		return acronym.save(on: req.db).flatMapThrowing {
			// ensures the ID is set or else throws a server error
			guard let id = acronym.id else {
				throw Abort(.internalServerError)
			}
			return req.redirect(to: "/acronyms/\(id)")
		}
	}
	
	@Sendable func editAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
		let acronymFuture = Acronym
			.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		
		let userQuery = User.query(on: req.db).all()
		
		return acronymFuture.and(userQuery)
			.flatMap { acronym, users in
				let context = EditAcronymContext(
					acronym: acronym,
					users: users)
				return req.view.render("createAcronym", context)
			}
	}
	
	@Sendable func editAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
		let updateData = try req.content.decode(CreateAcronymData.self)
		
		return Acronym
			.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound)).flatMap { acronym in
				acronym.short = updateData.short
				acronym.long = updateData.long
				acronym.$user.id = updateData.userID
				guard let id = acronym.id else {
					let error = Abort(.internalServerError)
					return req.eventLoop.future(error: error)
				}
				let redirect = req.redirect(to: "/acronyms/\(id)")
				return acronym.save(on: req.db).transform(to: redirect)
			}
	}
	
	@Sendable func deleteAcronymHandler(_ req: Request) -> EventLoopFuture<Response> {
		Acronym
			.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.delete(on: req.db)
					.transform(to: req.redirect(to: "/"))
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

struct UserContext: Encodable {
	let title: String
	let user: User
	let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
	let title: String
	let users: [User]
}

struct AllCategoriesContext: Encodable {
	let title = "All Categories"
	let categories: [Category]
}

struct CategoryContext: Encodable {
	let title: String
	let category: Category
	let acronyms: [Acronym]
}

struct CreateAcronymContext: Encodable {
	let title = "Create an acronym" // static because the title doesn't change
	let users: [User]
}

struct EditAcronymContext: Encodable {
	let title = "Edit Acronym"
	let acronym: Acronym
	let users: [User]
	let editing = true
}
