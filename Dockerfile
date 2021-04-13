FROM ruby:3.0-alpine
ARG version

RUN if [ -z ${version} ]; then                                                                                                                \
      apk add --no-cache --virtual ruby-dev build-base && gem install buildkite-builder && apk del --purge ruby-dev build-base;               \
    else                                                                                                                                      \
      apk add --no-cache --virtual ruby-dev build-base && gem install buildkite-builder -v ${version} && apk del --purge ruby-dev build-base; \
    fi

CMD buildkite-builder run
