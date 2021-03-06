require 'json'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    if req.cookies['_rails_lite_app']
      @hash = JSON.parse(req.cookies['_rails_lite_app'])
    end
    @hash ||= {}
  end

  def [](key)
    @hash[key]
  end

  def []=(key, val)
    @hash[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    cookie = @hash.to_json
    res.set_cookie('_rails_lite_app', cookie)
  end
end
