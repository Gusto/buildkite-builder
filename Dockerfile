FROM ruby:3.3
ARG version

RUN gem update --system --no-document && \
    if [ -z "$version" ]; then                        \
      gem install buildkite-builder;                  \
    else                                              \
      gem install buildkite-builder -v "$version";    \
    fi

CMD ["buildkite-builder", "run"]
