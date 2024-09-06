import ImperialGoogle
import Vapor
import Fluent

struct ImperialController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		guard let googleCallbackURL = Environment.get("GOOGLE_CALLBACK_URL") else {
			fatalError("Google callback URL not set")
		}
		try routes.oAuth(
			from: Google.self,
			authenticate: "login-google",
			callback: googleCallbackURL,
			scope: ["profile", "email"],
			completion: processGoogleLogin)
	}
	
	
	// this will be the final callback, it executes after the Google login
	@Sendable func processGoogleLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
		try Google
			.getUser(on: request)
			.flatMap { userInfo in
				// see if the user exists, if they do just log them in, if they don't create a new one and set the username as the email and the password as an UUID, since there's no need for it, it ensures no one can login to the account via a normal password
				User
					.query(on: request.db)
					.filter(\.$username == userInfo.email)
					.first()
					.flatMap { foundUser in
						guard let existingUser = foundUser else {
							// if the user doesn't exists, create a new one and save him
							let user = User(
								name: userInfo.name,
								username: userInfo.email,
								password: UUID().uuidString)
							return user
								.save(on: request.db)
								.map {
									request.session.authenticate(user)
									return request.redirect(to: "/")
								}
						}
						// if he does, authenticate him and redirect to the login page
						request.session.authenticate(existingUser)
						return request.eventLoop.future(request.redirect(to: "/"))
					}
			}
	}
}

// the only fields you care about (the the Google API returns, since it returns more stuff)
struct GoogleUserInfo: Content {
	let email: String
	let name: String
}

extension Google {
	// this method will her a user's details from the Google API
	static func getUser(on request: Request) throws -> EventLoopFuture<GoogleUserInfo> {
		// we add an Oauth token to the authorisation
		var headers = HTTPHeaders()
		headers.bearerAuthorization = try BearerAuthorization(token: request.accessToken())
		
		// set the URL
		let googleAPIURL: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
		
		// sends a request to `Google.get` and sends an HTTP GET request, unwraps the returned future response and handles it
		return request
			.client.get(googleAPIURL, headers: headers)
			.flatMapThrowing { response in
				guard response.status == .ok else {
					if response.status == .unauthorized {
						throw Abort.redirect(to: "/login-google")
					} else {
						throw Abort(.internalServerError)
					}
				}
				return try response.content
					.decode(GoogleUserInfo.self)
			}
	}
}
