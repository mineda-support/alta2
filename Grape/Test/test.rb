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
      #get '/api/ngspctl/simulate?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5Clr_noda%2F&file=NAND.sch&probes=time&variations=%7B%7D&elements_update=%7Btran%3A%27.tran%20100p%202.5u%27%2C%7D&models_update=%7B%7D'
      #get '/api/ngspctl/simulate?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5Clr_noda%2F&file=NAND.sch&probes=&variations=%7B%7D&models_update=%7B%7D'
      get '/api/ngspctl/simulate?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5Clr_noda%2F&file=NAND.sch&probes=time%2C%20V(a)%2C%20V(b)%2C%20V(y)&variations=%7B%7D&models_update=%7B%7D'
      #get '/api/ngspctl/simulate?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5CLR_hokari%2F&file=NOR2.sch&probes=time%2C%20V(in1)%2C%20V(out)&variations=%7B%7D&models_update=%7B%7D'
      #assert_equal [], JSON.parse(last_response.body)['calculated_value']
      result = JSON.parse(last_response.body)#['keys']
      assert_equal [], [result['keys'], result['calculated_value']]
    end

    def test_ruby2
      puts 'test_ruby!'
      assert_equal 1, 1 + 1
    end
end