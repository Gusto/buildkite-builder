FROM ruby:2.7-slim

ARG gem_version
RUN if [ -z ${gem_version} ]; then                     \
      gem install buildkite-builder;                   \
    else                                               \
      gem install buildkite-builder -v ${gem_version}; \
    fi

CMD buildkite-builder run
