module HTTParty
  class Request
    def auth_headers
      credentials[:headers]
    end
    def setup_digest_auth
      if auth_headers
        @raw_request.digest_auth(username, password, {'www-authenticate' => auth_headers})
      end
    end    
  end
end
