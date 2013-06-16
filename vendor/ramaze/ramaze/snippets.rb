#          Copyright (c) 2009 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the MIT license.

require 'ramaze/snippets/blankslate'
require 'ramaze/snippets/object/__dir__'
require 'ramaze/snippets/ramaze/deprecated'
require 'ramaze/snippets/string/camel_case'
require 'ramaze/snippets/string/color'
require 'ramaze/snippets/string/esc'
require 'ramaze/snippets/string/snake_case'
require 'ramaze/snippets/string/unindent'

Ramaze::CoreExtensions.constants.each do |const|
  ext = Ramaze::CoreExtensions.const_get(const)
  into = Module.const_get(const)

  collisions = ext.instance_methods & into.instance_methods

  if collisions.empty?
    into.__send__(:include, ext)
  else
    warn "Won't include %p with %p, %p exists" % [into, ext, collisions]
  end
end
