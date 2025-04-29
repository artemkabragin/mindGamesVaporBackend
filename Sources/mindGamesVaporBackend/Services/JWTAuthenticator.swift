import Vapor

struct JWTAuthenticator: AsyncMiddleware {
    func respond(
        to request: Request,
        chainingTo next: any AsyncResponder
    ) async throws -> Response {
        let user = try await request.getUser()
        request.auth.login(user)
        return try await next.respond(to: request)
    }
}
