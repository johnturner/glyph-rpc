require 'rubygems'
require 'mongrel'
require 'encoder'

class GlyphRouter < Mongrel::HttpHandler
  attr_accessor :mappers

  def initialize
    @mappers = {}
  end

  def process(request, response)
    if (@default)
      response.start(303) do |head,out|
        head['Location'] = @default.uri
        head['Content-Type'] = 'text/html'
        out.write("<a href=#{@default.uri}>Go here.</a>")
      end
    else
      response.start(200) do |head,out|
        head['Content-Type'] = 'text/plain'
        out.write("RPClol\n")
      end
    end
  end

  def add item
    if item.kind_of? Symbol
      mtd = method(item)
      mapper = GlyphMethodMapper.new(mtd)
      @mappers[mtd] = mapper
      mapper
    elsif item.kind_of? Class and item < GlyphResource
      mapper = GlyphResourceMapper.new(item)
      @mappers[item] = mapper
      mapper
    end
  end

  def default item
    @default = add item
  end

  def run
    r = self
    @config = Mongrel::Configurator.new :host => '0.0.0.0' do
      listener :port => 3000 do
        uri '/', :handler => r
        r.mappers.values.each do |mapper|
          uri mapper.uri, :handler => mapper
        end
      end
      run
    end
    @config.join
  end
end

class GlyphMethodMapper < Mongrel::HttpHandler
  attr_accessor :uri

  def initialize mtd
    @method = mtd
    @uri = "/#{@method.name}"
  end

  def process(request, response)
    response.start(200) do |head,out|
      head['Content-Type'] = 'text/plain'
      result = @method.call()
      out.write("#{result}\n")
    end
  end
end

class GlyphResourceMapper < Mongrel::HttpHandler
  attr_accessor :uri
  
  def initialize resource
    @resource = resource
    @uri = "/#{resource.name.gsub('::', '/')}"
  end
  
  def process(request, response)
    args = Mongrel::HttpRequest.query_parse request.params['QUERY_STRING']

    response.start(200) do |head,out|
      head['Content-Type'] = 'text/plain'
      out.write("Resource: #{@resource.name}\n")
      out.write("Params: #{args.inspect}\n")
    end
  end
end

class GlyphResource
end
