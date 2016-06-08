class Static
  attr_accessor :app
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.path.match(/^\/public/)
      serve_file(req)
    else
      app.call(env)
    end
  end

  def serve_file(req)
    url = "." + req.path
    res = Rack::Response.new
    begin
      file = File.read(url)
    rescue
      res.status = 404
      res['Content-Type'] = 'text/html'
      res.write('404 - File Not Found')
      return res.finish
    end
    extension = req.path.match(/(?<ext>\.\w*$)/)
    res['Content-Type'] = Rack::Mime.mime_type(extension[:ext])
    res.write(file)
    res.finish
  end
end
