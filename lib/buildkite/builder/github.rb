# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Buildkite
  module Builder
    class Github
      BASE_URI = URI('https://api.github.com').freeze
      ACCEPT_HEADER = 'application/vnd.github.v3+json'
      LINK_HEADER = 'link'
      NEXT_LINK_REGEX = /<(?<uri>.+)>; rel="next"/.freeze
      REPO_REGEX = /github\.com(?::|\/)(.*)\.git\z/.freeze
      PER_PAGE = 100

      def self.pull_request_files
        new.pull_request_files
      end

      def initialize(env = ENV)
        @env = env
      end

      def pull_request_files
        files = []
        next_uri = URI.join(BASE_URI, "repos/#{repo}/pulls/#{pull_request_number}/files?per_page=#{PER_PAGE}")

        while next_uri
          response = request(next_uri)
          files.concat(JSON.parse(response.body))
          next_uri = parse_next_uri(response)
        end

        files
      end

      private

      def repo
        Buildkite.env.repo[REPO_REGEX, 1]
      end

      def token
        @env.fetch('GITHUB_API_TOKEN')
      end

      def pull_request_number
        Buildkite.env.pull_request
      end

      def request(uri)
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(uri)
          request['Authorization'] = "token #{token}"
          request['Accept'] = ACCEPT_HEADER

          http.request(request)
        end
      end

      def parse_next_uri(response)
        links = response[LINK_HEADER]
        return unless links

        matches = links.match(NEXT_LINK_REGEX)
        URI.parse(matches[:uri]) if matches
      end
    end
  end
end
