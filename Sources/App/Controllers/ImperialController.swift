import ImperialGoogle
import ImperialGitHub
import Vapor
import Fluent

struct ImperialController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		
		// GOOGLE
		guard let googleCallbackURL = Environment.get("GOOGLE_CALLBACK_URL") else {
			fatalError("Google callback URL not set")
		}
		try routes.oAuth(
			from: Google.self,
			authenticate: "login-google",
			callback: googleCallbackURL,
			scope: ["profile", "email"],
			completion: processGoogleLogin)
		
		// GITHUB
		guard let githubCallbackURL = Environment.get("GITHUB_CALLBACK_URL") else {
			fatalError("GitHub callback URL not set")
		}
		try routes.oAuth(
			from: GitHub.self,
			authenticate: "login-github",
			callback: githubCallbackURL,
			completion: processGitHubLogin)
		
		// iOS
		routes.get("iOS", "login-google", use: iOSGoogleLogin)
		routes.get("iOS", "login-github", use: iOSGitHubLogin)
	}
	
	// GOOGLE
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
								.flatMap {
									request.session.authenticate(user)
									return generateRedirect(on: request, for: user)
								}
						}
						// if he does, authenticate him and redirect to the login page
						request.session.authenticate(existingUser)
						return generateRedirect(on: request, for: existingUser)					}
			}
	}
	
	//GITHUB
	@Sendable func processGitHubLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
		return try GitHub
			.getUser(on: request)
			.flatMap { userInfo in
				User
					.query(on: request.db)
					.filter(\.$username == userInfo.login)
					.first()
					.flatMap { foundUser in
						guard let existingUser = foundUser else {
							let user = User(
								name: userInfo.name,
								username: userInfo.login,
								password: UUID().uuidString)
							return user
								.save(on: request.db)
								.flatMap {
									request.session.authenticate(user)
									return generateRedirect(on: request, for: user)
								}
						}
						request.session.authenticate(existingUser)
						return generateRedirect(on: request, for: existingUser)
					}
			}
	}
	
	// iOS
	
	@Sendable func iOSGoogleLogin(_ req: Request) -> Response {
		req.session.data["oauth_login"] = "iOS"
		return req.redirect(to: "/login-google")
	}
	@Sendable func iOSGitHubLogin(_ req: Request) -> Response {
		req.session.data["oauth_login"] = "iOS"
		return req.redirect(to: "/login-github")
	}
	
	@Sendable func generateRedirect(on req: Request, for user: User) -> EventLoopFuture<ResponseEncodable> {
		let redirectURL: EventLoopFuture<String>
		if req.session.data["ouath_login"] == "iOS" {
			do {
				let token = try Token.generate(for: user)
				redirectURL = token.save(on: req.db).map {
					"tilapp://auth?token=\(token.value)"
				}
			} catch {
				return req.eventLoop.future(error: error)
			}
		} else {
			redirectURL = req.eventLoop.future("/")
		}
		req.session.data["oauth_login"] = nil
		return redirectURL.map { url in
			req.redirect(to: url)
		}
	}
	
	
}

// GOOGLE
// the data we'll get from the Google API, the only fields you care about (the the Google API returns, since it returns more stuff)
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

// GITHUB
struct GithubUserInfo: Content {
	let name: String
	let login: String
}

extension GitHub {
	// Fetch user info from GitHub API, returning GithubUserInfo
	static func getUser(on request: Request) throws -> EventLoopFuture<GithubUserInfo> {
		// Setup HTTP headers
		var headers = HTTPHeaders()
		// Add Authorization header
		try headers.add(name: .authorization, value: "token \(request.accessToken())")
		// Add User-Agent header
		headers.add(name: .userAgent, value: "vapor")
		// GitHub user API URL
		let githubUserAPIURL: URI = "https://api.github.com/user"
		// Make GET request
		return request.client.get(githubUserAPIURL, headers: headers)
		// Handle response
			.flatMapThrowing { response in
				// Check status code
				guard response.status == .ok else {
					if response.status == .unauthorized {
						// Redirect if unauthorized
						throw Abort.redirect(to: "/login-github")
					} else {
						// Throw 500 error for other cases
						throw Abort(.internalServerError)
					}
				}
				// Decode response to GithubUserInfo
				return try response.content.decode(GithubUserInfo.self)
			}
	}
}
