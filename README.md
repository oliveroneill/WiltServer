# Wilt - What I Listen To

[![Build Status](https://travis-ci.org/oliveroneill/WiltServer.svg?branch=master)](https://travis-ci.org/oliveroneill/WiltServer)
[![Platform](https://img.shields.io/badge/Swift-4.1-orange.svg)](https://img.shields.io/badge/Swift-4.1-orange.svg)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)

This is a GraphQL server for querying a user's play history.

The server uses [Hexaville](https://github.com/noppoMan/Hexaville) to deploy
to Lambda and uses API Gateway for making HTTP requests. GraphQL is used for
making queries.

# Status
The master branch is no longer up to date with
[WiltCollector](https://github.com/oliveroneill/WiltCollector)
as it has now moved to Google Cloud's BigQuery. There is a branch called
`bigquery` that is almost working, however in the end I decided not to use
Swift and AWS due to dependency issues. There's a new project called
[wilt-cloud-functions](https://github.com/oliveroneill/wilt-cloud-functions)
that supersedes this one.

# Dependencies
- [Hexaville](https://github.com/noppoMan/Hexaville)

# Installation
Unfortunately there were a few changes to Hexaville to get this program
to deploy. I've made pull requests for each of these:
- [Hexaville changes](https://github.com/noppoMan/Hexaville/pull/102)
- [HexavilleFramework changes](https://github.com/noppoMan/HexavilleFramework/pull/18)

You can either make these changes yourself manually on your installed version
of Hexaville or use my forks in the meantime.

Specifically, the issues were:
1. GraphQL requires URL encoded parameters when using GET requests and
the encoding was getting undone by API Gateway
2. Graphiti uses Swift NIO which required a newer version of gcc

# Deployment
```bash
hexaville deploy WiltServer
```

# Usage
```bash
curl -i -G -H "Content-Type: application/graphql" https://<ID>.execute-api.<REGION>.amazonaws.com/staging/ --data-urlencode 'query={ history(userId: "<USER-ID>") { userId date primaryArtist name artists trackId } }'
```

# DynamoDB
This server will make queries to a table called `SpotifyHistory`. It's
columns are:
- user_id
- date
- artists
- name
- primary_artist
- track_id
