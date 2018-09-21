// Disable print buffering for better AWS Lambda debugging
#if os(Linux)
import Glibc
#else
import Darwin
#endif
setbuf(stdout, nil)
setbuf(stderr, nil)

import Foundation
import HexavilleFramework
import WiltLib

let app = HexavilleFramework()

var router = Router()

router.use(.get, "/") { request, context in
    let handler = PlayHistoryGraphQLHandler()
    let result = try handler.handle(queryItems: request.queryItems)
    return Response(
        headers: [
            "Content-Type": "application/graphql",
            "Access-Control-Allow-Origin": "*"
        ],
        body: result
    )
}
app.use(router)

app.catch { error in
    print(error)
    return Response(status: .internalServerError, body: "\(error)".data)
}

try app.run()
