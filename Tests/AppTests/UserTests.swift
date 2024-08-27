@testable import App
import XCTVapor

final class UserTests: XCTestCase {
	let usersName = "Alice"
	let usersUsername = "alicea"
	let usersURI = "/api/users/"
	var app: Application!
	
	// creates the application for the test and resets the database
	override func setUpWithError() throws {
		app = try Application.testable()
	}
	
	// this to shut down the application
	override func tearDownWithError() throws {
		app.shutdown()
	}
	
	func testUsersCanBeRetrievedFromAPI() throws {
		let user = try User.create(
			name: usersName,
			username: usersUsername,
			on: app.db)
		_ = try User.create(on: app.db)
		
		try app.test(.GET, usersURI, afterResponse: { response in
			XCTAssertEqual(response.status, .ok)
			let users = try response.content.decode([User].self)
			
			XCTAssertEqual(users.count, 2)
			XCTAssertEqual(users[0].name, usersName)
			XCTAssertEqual(users[0].username, usersUsername)
			XCTAssertEqual(users[0].id, user.id)
		})
	}
	
	// test the POST request
	func testUserCanBeSavedWithAPI() throws {
		let user = User(name: usersName, username: usersUsername, password: "password")
		
		// we use (_:_:beforeRequest:afterResponse:), we post the user, then check the response
		try app.test(.POST, usersURI, beforeRequest: { req in
			try req.content.encode(user)
		}, afterResponse: { response in
			let receivedUser = try response.content.decode(User.self)
			XCTAssertEqual(receivedUser.name, usersName)
			XCTAssertEqual(receivedUser.username, usersUsername)
			XCTAssertNotNil(receivedUser.id)
			try app.test(.GET, usersURI, afterResponse: { secondResponse in
				let users =
				try secondResponse.content.decode([User].self)
				XCTAssertEqual(users.count, 1)
				XCTAssertEqual(users[0].name, usersName)
				XCTAssertEqual(users[0].username, usersUsername)
				XCTAssertEqual(users[0].id, receivedUser.id)
			})
		})
	}
	
	// test getting one user
	func testGettingASingleUserFromTheAPI() throws {
		let user = try User.create(
			name: usersName,
			username: usersUsername,
			on: app.db)
		try app.test(.GET, "\(usersURI)\(user.id!)", afterResponse: { response in
			let receivedUser = try response.content.decode(User.self)
			XCTAssertEqual(receivedUser.name, usersName)
			XCTAssertEqual(receivedUser.username, usersUsername)
			XCTAssertEqual(receivedUser.id, user.id)
		})
	}
	
	func testGettingAUserAcronymFromTheAPI() throws {
		// we create a user for the acronym
		let user = try User.create(on: app.db)
		
		// define the expected values
		let acronymShort: String = "OMG"
		let acronymLong: String = "Oh My God"
		
		// create 2 acronyms in the DB, using the created user to fill the
		let acronym1 = try Acronym.create(
			short: acronymShort,
			long: acronymLong,
			user: user,
			on: app.db)
		_ = try Acronym.create(
			short: "LOL",
			long: "Laugh Out Loud",
			user: user,
			on: app.db)
		
		// send a GET request to the API
		try app.test(.GET, "\(usersURI)\(user.id!)/acronyms", afterResponse: { response in
			let acronyms = try response.content.decode([Acronym].self)
			
			// finally test the response
			XCTAssertEqual(acronyms.count, 2)
			XCTAssertEqual(acronyms[0].id, acronym1.id)
			XCTAssertEqual(acronyms[0].short, acronymShort)
			XCTAssertEqual(acronyms[0].long, acronymLong)
		})
	}
	
}
