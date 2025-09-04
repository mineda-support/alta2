require 'minitest/autorun'
require 'rack/test'
require '../app'

class APITest < Minitest::Test
    include Rack::Test::Methods

    def app
      Test::API
    end

    def test_open_LTspice
      puts 'open LTspice!'
      get '/api/ltspctl/open?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5CLR_Furukawa%2F&file=2NAND.asc'
      assert_equal [], JSON.parse(last_response.body)
    end
end