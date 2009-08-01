require 'erb'

class HTMLLayout
  def initialize(src, title, template)
    @body = src
    @title = title
    @template = template
  end
  attr_reader :body, :title

  def result
    if File.exist?(@template)
      return ERB.new(IO.read(@template)).result(binding)
    else
      return @src
    end
  end
end
