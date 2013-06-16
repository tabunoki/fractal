Ramaze.middleware(:dev) do
  use Rack::Lint
  use Rack::CommonLogger, Ramaze::Log
  use Rack::ShowExceptions
  use Rack::ShowStatus
  use Rack::RouteExceptions
  use Rack::ConditionalGet
  use Rack::ETag, 'public'
  use Rack::Head
  use Ramaze::Reloader

  run Ramaze.core
end

Ramaze.middleware(:live) do
  use Rack::CommonLogger, Ramaze::Log
  use Rack::RouteExceptions
  use Rack::ShowStatus
  use Rack::ConditionalGet
  use Rack::ETag, 'public'
  use Rack::Head

  run Ramaze.core
end
