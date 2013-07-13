# start.rb

# 依存ライブラリをロードパスへ追加する
Dir.glob(File.join(File.dirname(__FILE__), 'vendor/*/')) do |path|
  $LOAD_PATH.unshift path
end

require 'ramaze'
require 'mysql'
require 'sequel'
require 'logger'

require './src/property'
require './src/fractal'
require './src/code'


log = Logger.new(STDOUT)
log.level = Logger::INFO

# invalid byte sequence in Windows-31J
Encoding.default_external = 'UTF-8'

#
Ramaze.start
