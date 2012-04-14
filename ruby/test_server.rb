require 'server'
r = GlyphRouter.new

def foo
  'wut'
end
r.default(:foo)

class Foo < GlyphResource
end
r.add(Foo)

r.run
