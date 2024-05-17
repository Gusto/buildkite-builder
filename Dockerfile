FROM ruby:3.3
ARG version

RUN if [ -z ${version} ]; then                        \
      gem install buildkite-builder;                  \
    else                                              \
      gem install buildkite-builder -v ${version};    \
    fi

RUN git config --global --add safe.directory /workdir

CMD buildkite-builder run
