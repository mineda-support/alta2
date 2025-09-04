require 'minitest/autorun'
require 'rack/test'
require '../app'

class APITest < Minitest::Test
    include Rack::Test::Methods

    def app
      Test::API
    end

    def test_get_meas_results_LTspice
      puts 'open LTspice!'
      get '/api/ltspctl/results?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5CLR_Furukawa%2F&file=2NAND.asc&probes=time%2C%20V(out)&equation='
      result = JSON.parse(last_response.body) #['keys']
      assert_equal [], [result['keys'], result['calculated_value']] # result
    end
end