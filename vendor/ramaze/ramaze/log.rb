#          Copyright (c) 2009 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the MIT license.
require 'ramaze/log/logging'
require 'ramaze/log/informer'

begin
  require 'win32console' if RUBY_PLATFORM =~ /win32/i && RUBY_VERSION < '1.9'
rescue LoadError => ex
  puts ex
  puts "For nice colors on windows, please `gem install win32console`"
  Ramaze::Logger::Informer.trait[:colorize] = false
end

module Ramaze
  Log = Innate::Log

  ##
  # Module used as the base namespace for all loggers that ship with Ramaze.
  #
  # @author Michael Fellinger
  # @since  11-08-2009
  #
  module Logger
    autoload :LogHub          , 'ramaze/log/hub'
    autoload :RotatingInformer, 'ramaze/log/rotatinginformer'
    autoload :Syslog          , 'ramaze/log/syslog'
    autoload :Logger          , 'ramaze/log/logger'
  end
end
