require 'bsim3_fit'
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