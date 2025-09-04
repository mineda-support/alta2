require 'minitest/autorun'
require 'rack/test'
require '../app'

class APITest < Minitest::Test
    include Rack::Test::Methods
    #i_suck_and_my_tests_are_order_dependent!
# disable random test order for any TestCase
ActiveSupport::TestCase.class_eval do
  # http://docs.seattlerb.org/minitest/Minitest/Test.html#method-c-i_suck_and_my_tests_are_order_dependent-21
  i_suck_and_my_tests_are_order_dependent!
end

Minitest.remove_possible_singleton_method(:__run)
Minitest.define_singleton_method(:__run) do  |reporter, options|
  suites = Minitest::Runnable.runnables.reject { |s| s.runnable_methods.empty? }
  parallel, serial = suites.partition { |s| s.test_order == :parallel }

  # If we run the parallel tests before the serial tests, the parallel tests
  # could run in parallel with the serial tests. This would be bad because
  # the serial tests won't lock around Reporter#record. Run the serial tests
  # first, so that after they complete, the parallel tests will lock when
  # recording results.
  serial.map { |suite| suite.run reporter, options } +
    parallel.map { |suite| suite.run reporter, options }
end
    def app
      Test::API
    end
=begin
    def test_simulate_ngspice
      puts 'simulate_ngspice!'
      get '/api/ngspctl/simulate?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5Clr_noda%2F&file=NAND.sch&probes=time&variations=%7B%7D&elements_update=%7Btran%3A%27.tran%20100p%202.5u%27%2C%7D&models_update=%7B%7D'
      #get '/api/ngspctl/simulate?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5CLR_hokari%2F&file=NOR2.sch&probes=time%2C%20V(in1)%2C%20V(out)&variations=%7B%7D&models_update=%7B%7D'
      #assert_equal [], JSON.parse(last_response.body)['calculated_value']
      result = JSON.parse(last_response.body)#['keys']
      assert_equal [], [result['keys'], result['calculated_value']]
    end
=end
    def test_get_results
      puts 'get results'
      #get '/api/ngspctl/results?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5Clr_noda%2F&file=NAND.sch&probes=time%2C%20V(a)%2C%20V(b)%2C%20V(y)&equation=x.where(y%2C%202.5)%7B%7Cx%2C%20y%7C%20x%20%3E%201e-6%7D'
      get '/api/ltspctl/results?dir=C%3A%5CUsers%5Cseiji%5CSeafile%5CLSI_devel%5CLR_homework%5CLR_Furukawa%2F&file=2NAND.asc&probes=time%2C%20V(out)&equation='
      result = JSON.parse(last_response.body) #['keys']
      assert_equal [], [result['keys'], result['calculated_value']]
    end
  end