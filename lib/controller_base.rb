require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'

class ControllerBase
  attr_reader :req, :res, :params

  def initialize(req, res, params={})
    @req = req
    @res = res
    @params = params.merge(req.params)
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    raise 'ArgumentError', @already_built_response if @already_built_response
    @res["Location"] = url
    @res.status = 302
    @already_built_response = "Double-render error"
    session.store_session(@res)
    flash.store_flash(@res)
    @res
  end

  def render_content(content, content_type)
    raise 'ArgumentError', @already_built_response if @already_built_response
    @res["Content-Type"] = content_type
    @res.write(content)
    @already_built_response = "Double-render error"
    session.store_session(@res)
    flash.store_flash(@res)
    @res
  end

  def render(template_name)
    template_file = "views/#{self.class.to_s.underscore}/#{template_name.to_s}.html.erb"
    contents = File.read(template_file)
    erb = ERB.new(contents)
    html_content = erb.result(binding)
    render_content(html_content, 'text/html')
  end

  def session
    @session ||= Session.new(@req)
  end
  
  def flash
    @flash ||= Flash.new(@req)
  end

  def invoke_action(name)
    self.send(name)
    render(name) unless @already_built_response
  end
end
