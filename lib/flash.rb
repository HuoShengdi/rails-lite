require 'json'

class Flash
  attr_accessor :now
  def initialize(req)
    if req.cookies['_rails_lite_app_flash']
      @now = JSON.parse(req.cookies['_rails_lite_app_flash'])
    end
    @now ||= {}
    @flash = {}
  end

  def [](key)
    @flash[key] || @now[key]
  end

  def []=(key, val)
    @flash[key] = val
  end


  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_flash(res)
    cookie = @flash.to_json
    res.set_cookie('_rails_lite_app_flash', cookie)
  end
end
