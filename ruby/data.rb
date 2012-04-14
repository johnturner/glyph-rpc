class Node
  def initialise name, attributes, content
    @_name = name
    @_attributes = attributes
    @_content = content
  end

  def _get_state
    return @_name, @_attributes, @_content
  end

  def _set_state state
    @_name, @_attributes, @_content = state
  end

  #def method_missing method
    # TODO: What?
    #@_attributes[method]
    
  #end
end

class Extension < Node
  def resolve
  end
end

class Form < Extension
  def resolve
    @_attributes['url'] = yield @_attributes['url']
  end
end


