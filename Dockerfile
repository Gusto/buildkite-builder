FROM ruby:3.0-alpine
ARG version

RUN apk add git                                       \
    && if [ -z ${version} ]; then                     \
      gem install buildkite-builder;                  \
    else                                              \
      gem install buildkite-builder -v ${version};    \
    fi

CMD bundle exec buildkite-builder run
