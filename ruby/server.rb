require 'rubygems'
require 'mongrel'
require 'encoder'

class GlyphRouter < Mongrel::HttpHandler
  attr_reader :mappers

  def initialize
    @mappers = {}
    @encoder = Encoder.new
  end

  def dump obj
    @encoder.dump obj
  end

  def process(request, response)
    if (@default)
      response.start(303) do |head,out|
        head['Location'] = @default.url
        head['Content-Type'] = 'text/html'
        out.write("<a href=#{@default.url}>Go here.</a>")
      end
    else
      response.start(200) do |head,out|
        head['Content-Type'] = 'text/plain'
        out.write("RPClol (no default)\n")
      end
    end
  end

  def add item
    if item.kind_of? Symbol
      mtd = method(item)
      mapper = GlyphMethodMapper.new(mtd, self)
      @mappers[item] = mapper
      mapper
    elsif item.kind_of? Method
      mapper = GlyphMethodMapper.new(item, self)
      @mappers[item.name.intern] = mapper
      mapper
    elsif item.kind_of? Class and item < GlyphResource
      mapper = GlyphResourceMapper.new(item, self)
      @mappers[item] = mapper
      mapper
    end
  end

  def default item
    @default = add item
  end

  def redirect item, code=303
    handler = add item
    handler.redirect=code
  end

  def run
    r = self
    @config = Mongrel::Configurator.new :host => '0.0.0.0' do
      listener :port => 3000 do
        uri '/', :handler => r
        r.mappers.values.each do |mapper|
          uri mapper.url, :handler => mapper
        end
      end
      run
    end
    @config.join
  end
end

class GlyphMapper < Mongrel::HttpHandler
  attr_accessor :redirect
  
  def initialize router
    @router = router
  end

  def get_args request
    Mongrel::HttpRequest.query_parse request.params['QUERY_STRING']
  end
end

class GlyphMethodMapper < GlyphMapper
  attr_reader :url

  def initialize mtd, router
    super router
    @method = mtd
    @url = "/#{@method.name}"
  end

  def process(request, response)
    result = @method.call()
    if @redirect
      response.start(@redirect) do |head,out|
        result = result.name.intern if result.kind_of? Method
        url = @router.mappers[result].url
        head['Location'] = url
        head['Content-Type'] = 'text/html'
        out.write("<a href=#{url}>Go here.</a>")
      end
    else
      response.start(200) do |head,out|
        head['Content-Type'] = Encoder::CONTENT_TYPE
        out.write @router.dump(result)
      end
    end
  end
end

class GlyphResourceMapper < GlyphMapper
  attr_accessor :url
  
  def initialize resource, router
    super router
    @resource = resource
    @url = "/#{resource.name.gsub('::', '/')}"
  end
  
  def process(request, response)
    args = get_args request

    response.start(200) do |head,out|
      head['Content-Type'] = Encoder::CONTENT_TYPE
      out.write "Resource: #{@resource.name}\n"
      out.write "Params: #{args.inspect}\n"
    end
  end
end

class GlyphResource
end
