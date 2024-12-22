require './app'
require 'rack/cors'
#disable Rack::method_override
#use Rack::RewindableInput::Middleware
#use Rack::MethodOverride
run 1
use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
    end
  end
Test::API.compile!
run Test::API