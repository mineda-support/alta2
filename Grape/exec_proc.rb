#require 'bsim3_fit'
#load '../j_pack/j_pack.rb'
#Dir.chdir '../j_pack'
#load 'c:/Users/seiji/work/SvelteKit/new_alta/Grape/bsim3fit/bsim3_fit.rb'
#require 'debug'
require 'json'
def exec_proc params
  puts "model=#{params[:model]}"
  mf = Bsim3Fit.new params[:model]
  puts "mf=#{mf}.inspect"
  mf.jtable = [params[:settings], params[:jtable]] 
  puts 'jtable=', mf.jtable.inspect
  debugger
  puts "procedure: #{params[:procedure]}"
  params[:procedure].each_line{|l|
    puts "exec_proc: #{l}"
    mf.send(l.chomp)
  }
  { 'plotdata' => mf.jtable[1] }
end

if $0 == __FILE__
  Dir.chdir 'c:/Users/seiji/work/SvelteKit/new_alta/Grape/bsim3fit'
  params = {
    wdir: 'c:/Users/seiji/work/SvelteKit/new_alta/Grape/bsim3fit',
    model: 'test.lib',
    model_org: "C:/Users/seiji/KLayout/salt/PTS06/Technology/tech/models/MinedaPTS06_TT",
    jtable: 'json/test0325_with_condition.json'
  }
  mf = Bsim3Fit.new params[:model], params[:model_org]
  mf.imitate_measdata File.join(params[:wdir], params[:jtable])
  mf.calculate_vth_vbs_relation flg: false, vgs: 0.0, vds: 0.05, vbs: [0.0, -0.5 , -1.0, -1.5,-2.0], lw: [[30e-6,30e-6]], mode: "lines",
  name: ["vbs=0.0","vbs=-0.5","vbs=-1.0","vbs=-1.5","vbs=-2.0"]
  mf.estimate_vth_k1_k2
  mf.step1_calc_vth_vbs
  #  mf.plot_graph 'measdata' # "vthdata"
  mf.plot_graph "vthdata"
  p
end