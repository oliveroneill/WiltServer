# Wilt - What I Listen To
This is a GraphQL server for querying a user's play history.

The server uses [Hexaville](https://github.com/noppoMan/Hexaville) to deploy
to Lambda and uses API Gateway for making HTTP requests. GraphQL is used for
making queries.

# Installation
1. Install Hexaville as specified in [it's README](https://github.com/noppoMan/Hexaville)
2. Create a `Hexavillefile.yml` to deploy the server to your AWS account. This
is also described in their README.
3. Modify the Dockerfile installed in `~/.hexaville`. This is an unfortunate
step to get Swift NIO building for AWS Lambda. Specifically it requires a newer
version of GCC due to requiring `stdatomic.h`. Hopefully this will get merged
into Hexaville soon. The changes needed are:
    - `RUN apt-get install -y software-properties-common`
    - `RUN add-apt-repository ppa:ubuntu-toolchain-r/test`
    - `RUN apt-get install -y clang-3.8`
    - `RUN apt-get install -y gcc-7 g++-7`
