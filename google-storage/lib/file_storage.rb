# Copyright 2013 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'
require 'signet/oauth_2/client'

# Adapted from https://github.com/google/google-api-ruby-client/blob/master/lib/google/api_client/auth/file_storage.rb
# Added the capability to store the project id in the file so an auth pertains not just
# to a user but to a specific project

    ##
    # Represents cached OAuth 2 tokens stored on local disk in a
    # JSON serialized file. Meant to resemble the serialized format
    # http://google-api-python-client.googlecode.com/hg/docs/epy/oauth2client.file.Storage-class.html
    #
    class FileStorage
      # @return [String] Path to the credentials file.
      attr_accessor :path

      # @return [Signet::OAuth2::Client] Path to the credentials file.
      attr_reader :authorization

      # @return [String] Project id
      attr_reader :project

      ##
      # Initializes the FileStorage object.
      #
      # @param [String] path
      #    Path to the credentials file.
      def initialize(dir, acct)
        unless File.directory?(dir)
          Dir.mkdir(dir)
        end

        @path = File.join(dir, acct)
        self.load_credentials
      end

      ##
      # Attempt to read in credentials from the specified file.
      def load_credentials
        if File.exist? self.path
          File.open(self.path, 'r') do |file|
            cached_credentials = JSON.load(file)
            @project = cached_credentials.delete('project')
            @authorization = Signet::OAuth2::Client.new(cached_credentials)
            @authorization.issued_at = Time.at(cached_credentials['issued_at'])
            if @authorization.expired?
              @authorization.fetch_access_token!
              self.write_credentials
            end
          end
        end
      end

      ##
      # Write the credentials to the specified file.
      #
      # @param [Signet::OAuth2::Client] authorization
      #    Optional authorization instance. If not provided, the authorization
      #    already associated with this instance will be written.
      # @param [String] project
      #    Optional project name. If not provided, the project already associated
      #    with this instance will be written
      def write_credentials(authorization=nil, project=nil)
        @authorization = authorization unless authorization.nil?
        @project = project unless project.nil?

        unless @authorization.refresh_token.nil?
          hash = {}
          %w'access_token
           authorization_uri
           client_id
           client_secret
           expires_in
           refresh_token
           token_credential_uri'.each do |var|
            hash[var] = @authorization.instance_variable_get("@#{var}")
          end
          hash['issued_at'] = @authorization.issued_at.to_i
          hash['project'] = @project

          File.open(self.path, 'w', 0600) do |file|
            file.write(hash.to_json)
          end
        end
      end
    end
