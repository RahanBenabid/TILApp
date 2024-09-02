@testable import App
@testable import XCTVapor
import Fluent
// to be able to see the Bcrypt function
import Vapor

// a function that saves a user, with a default value, so no need to be obliged to provide one
extension User {
	// the username is optional in case it's already supplied, if not create one using UUID, to make sure it's unique
	static func create(
		name: String = "Luke",
		username: String? = nil,
		on database: Database
	) throws -> User {
		let createUsername: String
		if let suppliedUsername = username {
			createUsername = suppliedUsername
		} else {
			createUsername = UUID().uuidString
		}
		
		// hash the password then create a user
		let password = try Bcrypt.hash("password")
		let user = User(name: name,
										username: createUsername,
										password: "password")
		try user.save(on: database).wait()
		return user
	}
}

extension Acronym {
	static func create(
		short: String = "TIL",
		long: String = "Today I Learned",
		user: User? = nil,
		on database: Database
	) throws -> Acronym {
		var acronymUser = user
		
		if acronymUser == nil {
			acronymUser = try User.create(on: database)
		}
		
		let acronym = Acronym(short: short, long: long, userID: acronymUser!.id!)
		try acronym.save(on: database).wait()
		return acronym
	}
}

extension App.Category {
	static func create(
		name: String = "Random",
		on database: Database
	) throws -> App.Category {
		let category = Category(name: name)
		try category.save(on: database).wait()
		return category
	}
}

extension XCTApplicationTester {
	// perform a login operation using the provided User object and returns a Token.
	public func login(
		user: User
	) throws -> Token {
		// Create an HTTP POST request to the "/api/users/login" endpoint.
		var request = XCTHTTPRequest(
			method: .POST,
			url: .init(path: "/api/users/login"),
			headers: [:],
			// Initialize an empty request body using ByteBufferAllocator.
			body: ByteBufferAllocator().buffer(capacity: 0)
		)
		// Add basic authentication to the request headers using the user's username and password.
		request.headers.basicAuthorization =
			.init(username: user.username, password: "password")
		// Perform the request and capture the response.
		let response = try performTest(request: request)
		// Decode the response content into a Token object and return it.
		return try response.content.decode(Token.self)
	}
	
	@discardableResult
	public func test(
	_ method: HTTPMethod,
	_ path: String,
	headers: HTTPHeaders = [:],
	body: ByteBuffer? = nil,
	loggedInRequest: Bool = false,
	loggedInUser: User? = nil,
	file: StaticString = #file,
	line: UInt = #line,
	beforeRequest: (inout XCTHTTPRequest) throws -> () = { _ in },
	afterResponse: (XCTHTTPResponse) throws -> () = { _ in }
	) throws -> XCTApplicationTester {
		var request = XCTHTTPRequest(
			method: method,
			url: .init(path: path),
			headers: headers,
			body: body ?? ByteBufferAllocator().buffer(capacity: 0)
		)
		
		if (loggedInRequest || loggedInUser != nil) {
			let userToLogin: User
			if let user = loggedInUser {
				userToLogin = user
			} else {
				userToLogin = User(
					name: "Admin",
					username: "admin",
					password: "password")
			}
			let token = try login(user: userToLogin)
			request.headers.bearerAuthorization = .init(token: token.value)
		}
		
		try beforeRequest(&request)
		
		do {
			let response = try performTest(request: request)
			try afterResponse(response)
		} catch {
			XCTFail("\(error)", file: (file), line: line)
			throw error
		}
		return self
	}
}
