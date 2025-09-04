require 'minitest/autorun'
require 'rack/test'
require '../app'

class APITest < Minitest::Test
    include Rack::Test::Methods

    def app
      Test::API
    end

    def test_simulate_LTspice
      puts 'LTspice simulateion!'
      get '/api/ltspctl/simulate?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5CLR_Furukawa%2F&file=2NAND.asc&probes=time%2C%20V(out)&variations=%7B%7D&models_update=%7B%7D'
      result = JSON.parse(last_response.body) #['keys']
      assert_equal [], [result['keys'], result['calculated_value']] # result
    end
end