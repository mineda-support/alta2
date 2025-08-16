require 'minitest/autorun'
require 'rack/test'
require '../app'

class APITest < Minitest::Test
    include Rack::Test::Methods

    def app
      Test::API
    end

    def test_simulate_ngspice
      puts 'simulate_ngspice!'
      get '/api/ngspctl/simulate?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5CLR_hokari%2F&file=NOR2.sch&probes=time%2C%20V(in1)%2C%20V(out)&variations=%7B%7D&models_update=%7B%7D'
      assert_equal [], JSON.parse(last_response.body)
    end

    def test_ruby2
      puts 'test_ruby!'
      assert_equal 1, 1 + 1
    end
end