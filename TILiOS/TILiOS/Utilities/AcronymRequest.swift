import Foundation

struct AcronymRequest {
	let resource: URL
	
	// sets the resource prop to the URL for that acronym
	init(acronymID: UUID) {
		let resourceString = "http://localhost:8080/api/acronyms/\(acronymID)"
		guard let resourceURL = URL(string: resourceString) else {
			fatalError("unable to create URL")
		}
		self.resource = resourceURL
	}
	
	// get the acronym's user
	func getUser(
		completion: @escaping (
			Result<User, ResourceRequestError>
		) -> Void
	) {
		// to get the acronym's user
		let url = resource.appendingPathComponent("user")
		
		// create a URLSessionDataTask to fetch the data
		let dataTask = URLSession.shared
			.dataTask(with: url) { data, _, _ in
				// check if the data is not nil
				guard let jsonData = data else {
					completion(.failure(.noData))
					return
				}
				do {
					// decode the data into a User object
					let user  = try JSONDecoder()
						.decode(User.self, from: jsonData)
					completion(.success(user))
				} catch {
					// handle decoding error
					completion(.failure(.decodingError))
				}
			}
		// start the network task
		dataTask.resume()
	}
	
	// get the acronym's category
	func getCategories(
		completion: @escaping (
			Result<[Category], ResourceRequestError>
			) -> Void
	) {
		let url = resource.appendingPathComponent("categories")
		let dataTask = URLSession.shared
			.dataTask(with: url) { data, _,  _ in
				guard let jsonData = data else {
					completion(.failure(.noData))
					return
				}
				do {
					let categories = try JSONDecoder()
						.decode([Category].self, from: jsonData)
					completion(.success(categories))
				} catch {
					completion(.failure(.decodingError))
				}
			}
		dataTask.resume()
	}
}
