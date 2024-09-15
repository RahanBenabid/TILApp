import Vapor
import Leaf
import SendGrid

struct WebsiteController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		// we use this to make the user available for these pages
		let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
		
		authSessionsRoutes.get("login", use: loginHandler)
		let credentialsRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
		credentialsRoutes.post("login", use: loginPostHandler)
		authSessionsRoutes.get(use: indexHandler)
		authSessionsRoutes.get("acronyms", ":acronymID", use: acronymHandler)
		authSessionsRoutes.get("users", ":userID", use: userHandler)
		authSessionsRoutes.get("users", use: allUserHandler)
		authSessionsRoutes.get("categories", use: allCategoriesHandler)
		authSessionsRoutes.get("categories", ":categoryID", use: categoryHandler)
		authSessionsRoutes.post("logout", use: logoutHandler)
		authSessionsRoutes.get("register", use: registerHandler)
		authSessionsRoutes.post("register", use: registerPostHandler)
		authSessionsRoutes.get("forgottenPassword", use: forgottenPasswordHandler)
		authSessionsRoutes.post("forgottenPassword", use: forgottenPasswordPostHandler)
		authSessionsRoutes.get("resetPassword", use: resetPasswordHandler)
		authSessionsRoutes.post("resetPassword", use: resetPasswordPostHandler)
		
		let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
		protectedRoutes.get("acronyms", "create", use: createAcronymHandler)
		protectedRoutes.post("acronyms", "create", use: createAcronymPostHandler)
		protectedRoutes.get("acronyms", ":acronymID", "edit", use: editAcronymHandler)
		protectedRoutes.post("acronyms", ":acronymID", "edit", use: editAcronymPostHandler)
		protectedRoutes.post("acronyms", ":acronymID", "delete", use: deleteAcronymHandler)
	}
	
	@Sendable func indexHandler(_ req: Request) -> EventLoopFuture<View> {
		Acronym.query(on: req.db).all().flatMap { acronyms in
			// create an Encodable IndexTitle containing the title we want
			let userLoggedIn = req.auth.has(User.self)
			let showCookieMessage = req.cookies["cookies-accepted"] == nil
			let context = IndexContext(
				title: "Home page",
				acronyms: acronyms,
				userLoggedIn: userLoggedIn,
				showCookieMessage: showCookieMessage)
			// pass it as a second parameter
			return req.view.render("index", context)
		}
	}
	
	@Sendable func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				let userFuture = acronym.$user.get(on: req.db)
				let categoriesFuture = acronym.$categories.query(on: req.db).all()
				return userFuture.and(categoriesFuture)
					.flatMap { user, categories in
						let context = AcronymContext(
							title: acronym.short,
							acronym: acronym,
							user: user,
							categories: categories)
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
			let token = [UInt8].random(count: 16).base64
			print("\n\n token: ", token, "\n\n")
			let context = CreateAcronymContext(csrfToken: token)
			req.session.data["CSRF_TOKEN"] = token
			return req.view.render("createAcronym", context)
		}
	}
	
	@Sendable func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
		let data = try req.content.decode(CreateAcronymFormData.self)
		let user = try req.auth.require(User.self)
		let expectedToken = req.session.data["CSRF_TOKEN"]
		req.session.data["CSRF_TOKEN"] = nil
		guard
			let csrfToken = data.csrfToken,
			expectedToken == csrfToken
		else {
			throw Abort(.badRequest)
		}
		print("\n\n authentication succeeded using: ", csrfToken, "\n\n")
		let acronym = try Acronym(
			short: data.short,
			long: data.long,
			userID: user.requireID())
		
		return acronym.save(on: req.db).flatMap {
			// ensures the ID is set or else throws a server error
			guard let id = acronym.id else {
				return req.eventLoop.future(error: Abort(.internalServerError))
			}
			var categySaves: [EventLoopFuture<Void>] = []
			for category in data.categories ?? [] {
				categySaves.append(
					Category.addCategory(category, to: acronym, on: req))
			}
			let redirect = req.redirect(to: "/acronyms/\(id)")
			return categySaves.flatten(on: req.eventLoop)
				.transform(to: redirect)
		}
	}
	
	@Sendable func editAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
		return Acronym
			.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.$categories.get(on: req.db)
					.flatMap { categories in
						let context = EditAcronymContext(
							acronym: acronym,
							categories: categories)
						return req.view.render("createAcronym", context)
					}
			}
	}
	
	@Sendable func editAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
		// now the request decodes a CreateAcronymFormData
		let updateData = try req.content.decode(CreateAcronymFormData.self)
		let user = try req.auth.require(User.self)
		let userID = try user.requireID()
		return Acronym
			.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound)).flatMap { acronym in
				acronym.short = updateData.short
				acronym.long = updateData.long
				acronym.$user.id = userID
				guard let id = acronym.id else {
					return req.eventLoop
						.future(error: Abort(.internalServerError))
				}
				// chaining futures, this returns all the acronym's categories
				return acronym.save(on: req.db).flatMap {
					// get the categories from the db
					acronym.$categories.get(on: req.db)
				}.flatMap { existingCategories in
					// creates an array of categories
					let existingStringArray = existingCategories.map {
						$0.name
					}
					// creates a Set for the categories and the categories supplied with the request
					let existingSet = Set<String>(existingStringArray)
					let newSet = Set<String>(updateData.categories ?? [])
					// calculates the categories to add and to remove to the acronym
					let categoriesToAdd = newSet.subtracting(existingSet)
					let categoriesToRemove = existingSet
						.subtracting(newSet)
					// creates an array of category operation results
					var categoryResults: [EventLoopFuture<Void>] = []
					// loop through the cats and sets up the relationship
					for newCategory in categoriesToAdd {
						categoryResults.append(
							Category.addCategory(
								newCategory,
								to: acronym,
								on: req))
					}
					// loops though the category names to remove from the acronym
					for categoryNameToRemove in categoriesToRemove {
						// Get the Category object from the name of the category to remove
						let categoryToRemove = existingCategories.first {
							$0.name == categoryNameToRemove
						}
						// if the cat object exists, use detach to remove the relationship
						if let category = categoryToRemove {
							categoryResults.append(
								acronym.$categories.detach(category, on: req.db))
						}
					}
					let redirect = req.redirect(to: "/acronyms/\(id)")
					// Flatten all the future category results. Transform the result to redirect to the updated acronym’s page
					return categoryResults.flatten(on: req.eventLoop)
						.transform(to: redirect)
				}
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
	
	// Handles GET requests to the login page
	@Sendable func loginHandler(_ req: Request) -> EventLoopFuture<View> {
		let context: LoginContext
		// Checks if there is an "error" query parameter; if true, sets loginError to true in the context
		if let error = req.query[Bool.self, at: "error"], error {
			context = LoginContext(loginError: true)
		} else {
			context = LoginContext()
		}
		// Renders the "login" view with the context
		return req.view.render("login", context)
	}
	
	// Handles POST requests for login form submissions
	@Sendable func loginPostHandler(_ req: Request) -> EventLoopFuture<Response> {
		// Checks if the user is already authenticated
		if req.auth.has(User.self) {
			// If authenticated, redirects to the homepage
			return req.eventLoop.future(req.redirect(to: "/"))
		} else {
			// If not authenticated, renders the login page with an error context
			let context = LoginContext(loginError: true)
			return req
				.view
				.render("login", context)
				.encodeResponse(for: req)
		}
	}
	
	@Sendable func logoutHandler(_ req: Request) -> Response {
		req.auth.logout(User.self)
		return req.redirect(to: "/")
	}
	
	@Sendable func registerHandler(_ req: Request) -> EventLoopFuture<View> {
		let context: RegisterContext
		// if the message exists, then include it when rendering the page
		if let message = req.query[String.self, at: "message"] {
			context = RegisterContext(message: message)
		} else {
			context = RegisterContext()
		}
		return req.view.render("register", context)
	}
	
	@Sendable func registerPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
		// calls validate content, to make sure it conforms to the rules we made
		do {
			try RegisterData.validate(content: req)
		} catch let error as ValidationsError {
			let message = error
				.description
				.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
			let redirect = req.redirect(to: "/register?message=\(message)")
			return req.eventLoop.future(redirect)
		}
		
		let data = try req.content.decode(RegisterData.self)
		let password = try Bcrypt.hash(data.password)
		let user = User(
			name: data.name,
			username: data.username,
			password: password,
			email: data.emailAddress)
		return user.save(on: req.db).map {
			req.auth.login(user)
			return req.redirect(to: "/")
		}
	}
	
	@Sendable func forgottenPasswordHandler(_ req: Request) -> EventLoopFuture<View> {
		req.view.render("forgottenPassword", ["title": "Reset your password"])
	}
	
	@Sendable func forgottenPasswordPostHandler(_ req: Request) throws -> EventLoopFuture<View> {
		let email = try req.content.get(String.self, at: "email")
		return User.query(on: req.db)
			.filter(\.$email, .equal, email)
			.first()
			.flatMap { user in
				guard let user = user else {
					return req.view.render("forgottenPasswordConfirmed", ["title": "Password Reset Email Sent"])
				}
				let resetTokenString = Data([UInt8].random(count: 32)).base32EncodedString()
				let resetToken: ResetPasswordToken
				do {
					resetToken = try ResetPasswordToken(
						token: resetTokenString,
						userID: user.requireID())
				} catch {
					return req.eventLoop.future(error: error)
				}
				return resetToken.save(on: req.db).flatMap {
					let emailContent = """
					<p> You've requested to reset your password. 
					<a href="http://localhost:8080/resetPassword?\token=\(resetTokenString)"> 
						Click here
					</a>
					to reset your password.
					</p>
					"""
					let emailAddress = EmailAddress(email: user.email, name: user.username)
					let fromEmail = EmailAddress(email: "<SENDGRID SENDER EMAIL>", name: "Vapor TIL")
					let emailConfig = Personalization(to: [emailAddress], subject: "Reset Your Password")
					let email = SendGridEmail(personalizations: [emailConfig], from: fromEmail, content: [
						["type" : "text/html",
						 "value": emailContent]
					])
					let emailSend: EventLoopFuture<Void>
					do {
						emailSend = try req.application
							.sendgrid
							.client
							.send(email: email, on: req.eventLoop)
					} catch {
						return req.eventLoop.future(error: error)
					}
					return emailSend.flatMap {
						return req.view.render("forgottenPasswordConfirmed", ["title": "Password Reset Email Sent"])
					}
				}
			}
	}
	
	@Sendable func resetPasswordHandler(_ req: Request) -> EventLoopFuture<View> {
		guard let token = try? req.query.get(String.self, at: "token") else {
			return req.view.render("resetPassword", ResetPasswordContext(error: true))
		}
		return ResetPasswordToken.query(on: req.db)
			.filter(\.$token, .equal, token)
			.first()
			.unwrap(or: Abort.redirect(to: "/"))
			.flatMap { token in
				token.$user.get(on: req.db).flatMap { user in
					do {
						try req.session.set("ResetPasswordUser", to: user)
					} catch {
						return req.eventLoop.future(error: error)
					}
					return token.delete(on: req.db)
				}
			}.flatMap {
				req.view.render("resetPassword", ResetPasswordContext())
			}
	}
	
	@Sendable func resetPasswordPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
		let data = try req.content.decode(ResetPasswordData.self)
		guard data.password == data.confirmPassword else {
			return req.view
				.render("resetPassword", ResetPasswordContext(error: true))
				.encodeResponse(for: req)
		}
		let resetPasswordUser = try req.session.get("ResetPasswordUser", as: User.self)
		req.session.data["ResetPasswordUser"] = nil
		let newPassword = try Bcrypt.hash(data.password)
		return try User.query(on: req.db)
			.filter(\.$id, .equal, resetPasswordUser.requireID())
			.set(\.$password, to: newPassword)
			.update()
			.transform(to: req.redirect(to: "/login"))
	}
	
	// end of WebsiteController function ( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)
	// ( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)
	// ( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)( ͡❛ ᴗ ͡❛)
	// doing this to be able to locate the end of the function cuz its is so damn big
}

struct IndexContext: Encodable {
	let title: String
	let acronyms: [Acronym]
	let userLoggedIn: Bool
	let showCookieMessage: Bool
}

struct AcronymContext: Encodable {
	let title: String
	let acronym: Acronym
	let user: User
	let categories: [Category]
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
	// for session
	let csrfToken: String
}

struct EditAcronymContext: Encodable {
	let title = "Edit Acronym"
	let acronym: Acronym
	let editing = true
	let categories: [Category]
}

struct CreateAcronymFormData: Content {
	let short: String
	let long: String
	let categories: [String]?
	let csrfToken: String?
}

struct LoginContext: Encodable {
	let title = "Log In"
	let loginError: Bool
	
	init(loginError: Bool = false) {
		self.loginError = loginError
	}
}

struct RegisterContext: Encodable {
	let title = "Register"
	let message: String?
	
	init(message: String? = nil) {
		self.message = message
	}
}

struct RegisterData: Content {
	let name: String
	let username: String
	let password: String
	let confirmPassword: String
	let emailAddress: String
}

extension RegisterData: Validatable {
	static func validations(_ validations: inout Validations) {
		validations.add("name", as: String.self, is: .ascii)
		validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
		validations.add("password", as: String.self, is: .count(8...))
		validations.add("zipCode", as: String.self, is: .zipCode, required: false)
		validations.add("email", as: String.self, is: .email)
	}
}

extension ValidatorResults {
	struct ZipCode {
		let isValidZipCode: Bool
	}
}

extension ValidatorResults.ZipCode: ValidatorResult {
	var isFailure: Bool {
		!isValidZipCode
	}
	var successDescription: String? {
		"is a valid zip code"
	}
	var failureDescription: String? {
		"is not a valid zip code"
	}
}

extension Validator where T == String {
	private static var zipCodeRegex: String {
		"^\\d{5}(?:[-\\s]\\d{4})?$"
	}
	
	public static var zipCode: Validator<T> {
		Validator { input -> ValidatorResult in
			guard
				let range = input.range(
					of: zipCodeRegex,
					options: [.regularExpression]),
				range.lowerBound == input.startIndex && range.upperBound == input.endIndex
			else {
				return ValidatorResults.ZipCode(isValidZipCode: false)
			}
			return ValidatorResults.ZipCode(isValidZipCode: true)
		}
	}
}

struct ResetPasswordContext: Encodable {
	let title = "Reset Password"
	let error: Bool?
	
	init(error: Bool? = false) {
		self.error = error
	}
}

struct ResetPasswordData: Content {
	let password: String
	let confirmPassword: String
}
