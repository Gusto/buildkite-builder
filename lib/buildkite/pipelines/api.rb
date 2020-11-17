# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'

module Buildkite
  module Pipelines
    class Api
      BASE_URI = URI('https://api.buildkite.com/v2').freeze
      URI_PARTS = {
        organization: 'organizations',
        pipeline: 'pipelines',
        pipelines: 'pipelines',
        build: 'builds',
        builds: 'builds',
        access_token: 'access-token',
      }.freeze

      def initialize(token)
        @token = token
      end

      def get_access_token
        uri = uri_for(access_token: nil)
        JSON.parse(get_request(uri).body)
      end

      def list_pipelines(organization)
        raise NotImplementedError
      end

      def get_pipeline(organization, pipeline)
        response = get_request(
          uri_for(
            organization: organization,
            pipeline: pipeline
          )
        )
        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        end
      end

      def create_pipeline(organization, params)
        uri = uri_for(
          organization: organization,
          pipelines: nil
        )
        JSON.parse(post_request(uri, params).body)
      end

      def get_pipeline_builds(organization, pipeline, **params)
        uri = uri_for(params.merge(
          organization: organization,
          pipeline: pipeline,
          builds: nil
        ))
        JSON.parse(get_request(uri).body)
      end

      def get_build(organization, pipeline, build)
        uri = uri_for(
          organization: organization,
          pipeline: pipeline,
          build: build
        )
        JSON.parse(get_request(uri).body)
      end

      def create_build(organization, pipeline)
        raise NotImplementedError
      end

      def cancel_build(organization, pipeline, build)
        raise NotImplementedError
      end

      def rebuild_build(organization, pipeline, build)
        raise NotImplementedError
      end

      private

      def get_request(uri)
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          request = prepare_request(Net::HTTP::Get.new(uri))
          http.request(request)
        end
      end

      def post_request(uri, data)
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          request = prepare_request(Net::HTTP::Post.new(uri))
          request.content_type = 'application/json'
          request.body = data.to_json
          http.request(request)
        end
      end

      def uri_for(options)
        uri_parts = URI_PARTS.each_with_object([]) do |(resource, path), parts|
          if options.key?(resource)
            parts << [path, options.delete(resource)].compact
          end
        end
        uri = URI(uri_parts.flatten.unshift(BASE_URI).join('/'))
        uri.query = URI.encode_www_form(options) if options.any?
        uri
      end

      def prepare_request(request)
        request['Authorization'] = "Bearer #{@token}"
        request['Accept'] = 'application/json'
        request
      end
    end
  end
end
