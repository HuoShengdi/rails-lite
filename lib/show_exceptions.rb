require 'erb'
require 'byebug'

class ShowExceptions
  attr_accessor :app

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      app.call(env)
    rescue StandardError => e
      render_exception(e)
    end
  end

  private

  def render_exception(e)
    @res = Rack::Response.new
    @res.status = '500'
    path = "lib/templates/rescue.html.erb"
    template = ERB.new(File.read(path))
    result = template.result(binding)
    render_content(result, 'text/html')
    debugger
  end

  def render_content(content, content_type)
    @res['Content-Type'] = content_type
    @res.write(content)
    @res.finish
  end
end
