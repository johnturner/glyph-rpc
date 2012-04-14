#!/usr/bin/ruby
require 'server'
$r = GlyphRouter.new


class Bar
  def self.foo
    ['hello', 'yes', {'what' => 1, 2 => 3.4}, 'things', 4, 5, 6]
  end
  $r.default(method(:foo))

  def self.bar
    method(:foo)
  end
  $r.redirect(method(:bar))
end

class Foo < GlyphResource
end
$r.add(Foo)

$r.run
