class Node
  def initialize name, attributes, content = nil
    @_name = name
    @_attributes = attributes
    @_content = content
  end

  def _state
    return @_name, @_attributes, @_content
  end

  def _state= state
    @_name, @_attributes, @_content = state
  end

  def method_missing method, *args, &block
    attrib = @_attributes[method]
    return attrib.call(*args, &block) if attrib and attrib.respond_to? :call
    raise NoMethodError(method)
  end

  def [] item
    return @_content[item]
  end
end

class Extension < Node
  def resolve
  end
end

class Form < Extension
  def initialize url, method="POST", values=nil
    unless values
      if url.respond_to? :call
        values = url.parameters.map{|p| p[1]}.compact
        p values
      elsif Class === url
        values = url.instance_method(:initialize).parameters.map{|p| p[1]}.compact
      end
    end
    
    attribs = {:method => method, :url => url}
    super('form', attribs, values)
  end

  def resolve
    @_attributes['url'] = yield @_attributes['url']
  end

  #TODO: Make method_missing make a call to the correct url for the client.
end


