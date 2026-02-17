import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .unauthorized:
            return "Non autorisé"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Erreur de décodage"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: APIErrorResponse?
}

struct APIErrorResponse: Decodable {
    let code: String
    let message: String
}

class APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession
    private var token: String?

    private init() {
        #if DEBUG
        self.baseURL = "https://bryant-tinniest-shaunta.ngrok-free.dev/api/v1"
        #else
        self.baseURL = "https://api.tindersoiree.com/api/v1"
        #endif
        self.session = URLSession.shared
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Skip ngrok browser warning
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Debug: print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response [\(endpoint)]: \(jsonString.prefix(500))")
            }

            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)

            if let error = apiResponse.error {
                throw APIError.serverError(error.message)
            }

            guard let responseData = apiResponse.data else {
                throw APIError.invalidResponse
            }

            return responseData
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            print("Decoding error detail: \(error)")
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func requestOptional<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Skip ngrok browser warning
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)

            if let error = apiResponse.error {
                throw APIError.serverError(error.message)
            }

            return apiResponse.data
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func getOptional<T: Decodable>(_ endpoint: String) async throws -> T? {
        try await requestOptional(endpoint: endpoint, method: "GET")
    }

    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        try await request(endpoint: endpoint, method: "GET")
    }

    func post<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        try await request(endpoint: endpoint, method: "POST", body: body)
    }

    func patch<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        try await request(endpoint: endpoint, method: "PATCH", body: body)
    }

    func delete<T: Decodable>(_ endpoint: String) async throws -> T {
        try await request(endpoint: endpoint, method: "DELETE")
    }
}
