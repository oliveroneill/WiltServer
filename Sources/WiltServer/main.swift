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

// Check that environment variable has been set
guard let projectId = ProcessInfo.processInfo.environment["BIGQUERY_PROJECT_ID"] else {
    fatalError("Project ID not set")
}

let app = HexavilleFramework()

var router = Router()

router.use(.GET, "/") { request, context in
    let db = try BigQueryAccess(projectId: projectId)
    let handler = PlayHistoryGraphQLHandler(dao: db)
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
