import Vapor
import Fluent

struct CreateAdminUser: Migration {
	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		let passwordHash: String
		do {
			// in normal cases, you shouldn't hard code it, either read from an environment variable or randomly generate and print it
			passwordHash = try Bcrypt.hash("password")
		} catch {
			return database.eventLoop.future(error: error)
		}
		
		let user = User(
			name: "Admin",
			username: "admin",
			password: passwordHash)
		return user.save(on: database)
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		User.query(on: database)
			.filter(\.$username == "admin")
			.delete()
	}
}
