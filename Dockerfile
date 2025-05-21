FROM ruby:3.3 as gem
WORKDIR /workspace
COPY . ./
RUN --mount=type=secret,id=gem-host-api-key \
    gem build buildkite-builder.gemspec && \
    GEM_HOST_API_KEY=$(cat /run/secrets/gem-host-api-key) gem push buildkite-builder-*.gem

FROM ruby:3.3 as release
COPY .buildkite/docker/bootstrap /tmp/bootstrap
ARG version
RUN /tmp/bootstrap
CMD ["buildkite-builder", "run"]
