require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params = {})
    @req = req
    @res = res
    @params = params
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response ||= false
  end

  # Set the response status code and header
  def redirect_to(url)
    @res['Location'] = url
    @res.status = 302
    session.store_session(@res)
    raise "already rendered" if @already_built_response
    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    @res['Content-Type'] = content_type
    form_authenticity_token
    @res.write(content)
    session.store_session(@res)
    raise "already rendered" if @already_built_response
    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    path = "views/" + self.class.name.underscore + "/#{template_name.to_s}.html.erb"
    template = ERB.new(File.read(path))
    result = template.result(binding)
    render_content(result, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    unless @already_built_response
      render(name)
    end
  end

  def form_authenticity_token
    @token ||= SecureRandom.urlsafe_base64(16)
    @res.set_cookie('authenticity_token', @token)
    @token
  end

  def self.protect_from_forgery
    define_method(:invoke_action) do |name|
      self.send(name)
      unless @req.request_method == "GET"
        check_authenticity_token
      end
      unless @already_built_response
          render(name)
      end
    end
  end

  def check_authenticity_token
    if (@params['authenticity_token'] != @req.cookies['authenticity_token']) || (
      @params['authenticity_token'] == nil)
      raise "Invalid authenticity token"
    end
  end
end
