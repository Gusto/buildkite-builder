FROM ruby:2.7-slim
ARG version

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    if [ -z ${version} ]; then                     \
      gem install buildkite-builder;                   \
    else                                               \
      gem install buildkite-builder -v ${version}; \
    fi

CMD buildkite-builder run
