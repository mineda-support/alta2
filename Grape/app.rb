require 'grape'
#$:.unshift File.join(ENV['HOME'].gsub(/\\/, '/'), '/work/alb2/lib')
$:.unshift File.join('..', '..', 'j_pack')
$:.unshift File.join('..', '..', '..', 'j_pack')
$:.unshift '..'
$:.unshift '.'
puts "hello world from ruby"
puts Dir.pwd
#puts $:
require 'j_pack'
#require 'byebug'
require 'csv_read'
require 'xls_read'
require 'exec_proc'

def coordinates probe
  offset = @vars.index(probe)
  raise "Probe '#{probe}' is not valid for @vars=#{@vars}" if offset.nil?
  plotdata = @plot_data[@index + offset]
  x = Array_with_interpolation.new plotdata[:x]
  y = Array_with_interpolation.new plotdata[:y]
  [x, y]
end

def eval_equation vars, plot_data, equation
  puts "vars=#{vars} at eval_equation for equation", equation, '----' 
  @vars = vars
  @plot_data = plot_data
  # if plot_data && plot_data.size > 0
  results = []
  if equation =~ /coordinates/
    for i in 0..(plot_data.length / vars.length)-1
      @index = i * vars.length
      results <<eval(equation)
      puts "vars=#{vars} i=#{i} @index=#{@index} results: #{results}"
    end
  else 
    $stderr.puts "plot_data.size = #{plot_data.size}"
    plot_data.each{|plotdata|
      x = Array_with_interpolation.new plotdata[:x]
      y = Array_with_interpolation.new plotdata[:y]
      begin
        results << eval(equation)
      rescue
        results << nil
      end
    }
  end
  results
end

def eval_db_ph_equation db_traces, ph_traces, equation
  results = []
  db_traces.each_with_index{|db_data, index|
    x = Array_with_interpolation.new db_data[:x]
    db = Array_with_interpolation.new db_data[:y]
    ph_data = ph_traces[index]
    ph = Array_with_interpolation.new ph_data[:y]
    # puts "db=#{db}"
    begin
      results << eval(equation)
      #puts "results === #{results}"
    rescue
      results << nil
    end
  }
  results
end

def return_results probes, traces, params, vars, keys, results
  if probes.start_with? 'frequency'
    db_traces = traces.map{|trace| {name: trace[:name], x: trace[:x], y: trace[:y].map{|a| 20.0*Math.log10(a.abs)}}}
    phase_traces = traces.map{|trace| {name: trace[:name], x: trace[:x], y: trace[:y].map{|a| Utils::shift360(a.phase*(180.0/Math::PI))}}}
    if (equation = params[:equation]) != ''
      results = eval_db_ph_equation db_traces, phase_traces, equation
      {"vars" => vars, "db" => db_traces, "phase" => phase_traces, "calculated_value" => results}
    else
      {"vars" => vars, "db" => db_traces, "phase" => phase_traces, "keys" => keys, "calculated_value" => results}
    end
  else
    # $stderr.puts "params[:equation]=#{params[:equation].inspect}"
    if (equation = params[:equation]) != ''
      results = eval_equation vars, traces, equation
      {"vars" => vars, "traces" => traces, "calculated_value" => results}
    else
      {"vars" => vars, "traces" => traces, "keys" => keys, "calculated_value" => results}
    end
  end 
end

module Test
  class Utils
    def self.get_params params
      work_dir = params[:dir] || ENV['HOMEPATH'] + '/Seafile/PTS06_2022_8/BGR_TEG/'
      work_dir.sub!('%HOMEPATH%', ENV['HOMEPATH'] || ENV['HOME'])
      ckt_name = File.join(work_dir, params[:file] || 'tsd_TEG_tb.asc')
      [work_dir, ckt_name] 
    end
    def self.shift360 p
      if p > 30
        p = p -360
      end
      p
    end
  end
  class API < Grape::API
    @@ngspice_ckt = {}
    @@ngspice_mtime = {}
    format :json
    prefix :api
    resource :misc do
      desc 'Load program'
      get :load do
        dir, file = Utils::get_params(params)
        load File.join(dir, file)
        {}
      end
      desc 'execute procedure'      
      post :exec_proc do
        result = exec_proc params
       end
      desc 'read json file'
      get :read_json do
        dir, json_file = Utils::get_params(params)
        if FileTest.exist?(json_file)
          table = JSON.load(File.read(json_file));
          { json: table}
        else
          {}
        end
      end
      desc 'Convert_circuit_data'
      post :convert_circuit_data do
        # puts params
        # puts params.keys
   
        load 'ltspice.rb'
        load 'qucs.rb'
        load 'xschem.rb'
        load 'eeschema.rb'
        load 'alta.rb'
        load 'ltspctl.rb'
        load 'ngspice.rb'
        load 'ngspctl.rb'
        load 'qucsctl.rb'
        work_dir, ckt_name = Utils::get_params(params)
        Dir.chdir(work_dir){
          puts 'execute under' + work_dir
          puts params[:program]
          eval params[:program]
        }
      end
      desc 'Get models file'
      get :get_models do
        cm = CompactModel.new params[:file]
        {'models' => cm.models}
      end
      desc 'Get measured data'
      get :measured_data do
        measfile = params[:file]
        # puts "Get measured data measfile=#{measfile} selection = #{params[:selection]}"
        select_list = [0, 1]
        if (selection = params[:selection]) && selection != ''
          puts "selection=#{selection.inspect}"
          select_list = selection.gsub(/[, ] +/, ',').split(/[, ]/).map{|a| a.to_i}
        end
        puts "Get measured data from #{measfile}; selection:#{selection.inspect} => #{select_list.inspect}"
        case File.extname(measfile).downcase
        when '.csv'
          c = CSV.read(measfile)
          puts "params[:invert_x/y] = #{params[:invert_x].inspect}/#{params[:invert_y].inspect}"
          d = valid_data c, select_list, (params[:invert_x] == 'true') ? -1.0 : 1.0, (params[:invert_y] == 'true') ? -1.0 : 1.0
        when '.xls'
          d = xls_read(measfile, select_list, (params[:invert_x] == 'true') ? -1.0 : 1.0, (params[:invert_y] == 'true') ? -1.0 : 1.0)
        end
        {"traces" => d}
      end      
    end

    helpers do 
      def open
        work_dir, ckt_name = Utils::get_params(params)

        Dir.chdir(work_dir){
          begin
            yield ckt_name
          rescue => error
            $stderr.puts "Error at open: #{error}"
            $stderr.puts error.backtrace.join("\n")
            error!("#{error}\n\n#{error.backtrace.join("\n")}", 404)
          end
        }              
      end

      def ckt_is_latest file
        return nil unless ckt = @@ngspice_ckt[file]
        return nil unless File.exist?(file)
        mtime = File.mtime file
        return nil if @@ngspice_mtime[file] && (mtime > @@ngspice_mtime[file])
        @@ngspice_mtime[file] = mtime
        ckt
      end
    end
    
    resource :ngspctl do
      desc 'Open Xschem'
      get :open do
        open{|ckt_name|
        unless ckt = ckt_is_latest(ckt_name)
          ckt = NgspiceControl.new(File.basename(ckt_name), true, true)
          puts "ckt.file@:open = #{ckt.file}"
          @@ngspice_ckt[ckt_name] = ckt
        end
        ckt.open(File.basename(ckt_name), true, true) if params[:showup]
          {"elements" => ckt.elements, "info" => nil, "models" => ckt.models}
        }
      end
      desc 'Simulate'
      get :simulate do
        work_dir, ckt_name = Utils::get_params(params)
        probes = params[:probes] 
        Dir.chdir(work_dir){
          unless ckt = @@ngspice_ckt[ckt_name]
            ckt = NgspiceControl.new(File.basename(ckt_name), true, true)
            @@ngspice_ckt[ckt_name] = ckt
          end
          puts "ckt.file@:simulate = #{ckt.file}"
          if params[:elements_update]
            updates = eval params[:elements_update]
            puts "updates: #{updates}"
            ckt.set updates
          end
          puts "models_update: #{params[:models_update]}"
          puts "variations: #{params[:variations]}"
          variations = params[:variations] ? eval(params[:variations].gsub('null', 'nil')) : {}
          models_update = params[:models_update] ? eval(params[:models_update]) : {}
          begin
            keys, results = ckt.simulate models_update: models_update, variations: variations, probes: probes.split(',')
          rescue => error
            $stderr.puts "Error at simulate: #{error}"
            $stderr.puts error.backtrace.join("\n")
            error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
          end
          puts "probes=#{probes}"
          if probes && probes.strip != ''
            begin
              vars, traces = ckt.get_traces *(probes.split(','))
            rescue => error
              $stderr.puts "Error at get_traces: #{error}"
              $stderr.puts error.backtrace.join("\n")
              error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
            end
            begin
              return_results probes, traces, params, vars, keys, results
            rescue => error
              $stderr.puts "Error at 'get :simulate': #{error}"
              $stderr.puts error.backtrace.join("\n")
              error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
            end 
          else
            {"log" => ckt.sim_log, "updates" => ckt.elements, "info" => ckt.info}          
          end
          }
        end
      desc 'Results'
      get :results do
        work_dir, ckt_name = Utils::get_params(params)
        #probes = params[:probes] ? URI.decode_www_form_component(params[:probes]): nil
        probes = params[:probes] 
        # require 'debug'
        # debugger
        Dir.chdir(work_dir){
          unless ckt = @@ngspice_ckt[ckt_name]
            ckt = NgspiceControl.new(File.basename(ckt_name), true, true)
            @@ngspice_ckt[ckt_name] = ckt
          end
          puts "ckt.file@:results = #{ckt.file}"
          if probes && probes.strip != ''
            vars, traces = ckt.get_traces *(probes.split(','))
            begin
              return_results probes, traces, params, vars, ckt.step_results[3], ckt.step_results[2]
            rescue => error
              $stderr.puts "Error at 'get :results': #{error}"
              $stderr.puts error.backtrace.join("\n")
              error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
            end
          else
            {"log" => ckt.sim_log}
          end
        }
      end
      desc 'Updates' # no longer used
      get :update do
        work_dir, ckt_name = Utils::get_params(params)
        updates = eval params[:updates]
        puts "updates: #{updates}"
        Dir.chdir(work_dir){
          ckt = @@ngspice_ckt[ckt_name]
          #unless ckt = @@ngspice_ckt[ckt_name]
          #  ckt = NgspiceControl.new(File.basename(ckt_name), true, true)
          #  @@ngspice_ckt[ckt_name] = ckt
          #end          
          ckt.set updates
          {"elements" => ckt.elements, "info" => ckt.info}
        }
      end
      desc 'Info'
      get :info do
        work_dir, ckt_name = Utils::get_params(params)
        Dir.chdir(work_dir){
          ckt = @@ngspice_ckt[ckt_name]
          {"info" => ckt.info}
        }
      end   
      desc 'Measurement'
      post :measure do
        require 'json'
        # puts params.keys
        # puts params
        work_dir, ckt_name = Utils::get_params(params)
        results = []
        Dir.chdir(work_dir){
          puts "equation for measurement:\n#{params[:equation]}"
          ckt = @@ngspice_ckt[ckt_name]
          # '#{params[:plotdata].inspect}', size=#{params[:plotdata].size}"
          if params[:plotdata] && params[:plotdata].size > 0
            vars = params[:probes].split(',')[1..-1].map{|a| a.strip}
            begin
              results = eval_equation vars, params[:plotdata], params[:equation]
            rescue => error
              $stderr.puts "Error at measure: #{error}"
              $stderr.puts error.backtrace.join("\n")
              error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
            end
          else # db and phase
            puts params[:db_data].size
            if params[:db_data] && params[:db_data].size > 0
              params[:db_data].each_index{|i|
                db_data = params[:db_data][i]
                ph_data = params[:ph_data][i]
                x = Array_with_interpolation.new db_data[:x]
                db = Array_with_interpolation.new db_data[:y]
                ph = Array_with_interpolation.new ph_data[:y]
                # puts "db=#{db}"
                begin
                  results << eval(params[:equation])
                  #puts "results === #{results}"
                rescue
                  results << nil
                end
              }
            end
          end
          {"calculated_value" => results}
        }
      end
    end
    resource :ltspctl do      
      desc 'Open LTspice'
      get :open do
        open{|ckt_name|
          ckt = LTspiceControl.new(File.basename(ckt_name), true)
          ckt.open(File.basename(ckt_name), true) if params[:showup]
          puts ckt.elements
          {"elements" => ckt.elements, "info" => ckt.info, "models" => ckt.models}
        }
      end

      desc 'Convert EDIF to LTspice'
      get :convert_edif do
        require 'edif2cdraw'
        work_dir, edif_file = Utils::get_params(params)
        Dir.chdir(work_dir){
          desc = SXP.read(File.read(edif_file).encode('UTF-8'))
          $resistor_with_bulk = true
          e = Edif_in.new desc
          FileUtils.rm_rf 'pictures/*'
          e.edif2cdraw
          [Dir.glob('pictures/**/*.asc') + Dir.glob('pictures/**/*.asy')].each{|file|
            FileUtils.cp file, '.'
          }
        }
      end

      desc 'Simulate'
      get :simulate do
        work_dir, ckt_name = Utils::get_params(params)
        probes = params[:probes] 
        Dir.chdir(work_dir){
          ckt = LTspiceControl.new(File.basename ckt_name)
          if params[:elements_update]
            updates = eval params[:elements_update]
            puts "updates: #{updates}"
            ckt.set updates
          end
          puts "models_update: #{params[:models_update]}"
          puts "variations: #{params[:variations]}"
          variations = params[:variations] ? eval(params[:variations].gsub('null', 'nil')) : {}
          models_update = params[:models_update] ? eval(params[:models_update]) : {}
          begin
            ckt.simulate models_update: models_update, variations: variations
          rescue  => error
              $stderr.puts "Error at simulate: #{error}"
              $stderr.puts error.backtrace.join("\n")
              error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
          end
          puts "probes=#{probes}"
          if probes && probes.strip != ''
            begin
              vars, traces = ckt.get_traces *(probes.split(','))
            rescue => error
              $stderr.puts "Error at get_traces: #{error}"
              $stderr.puts error.backtrace.join("\n")
              error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
            end
            begin
              if probes.start_with? 'frequency'
                db_traces = traces.map{|trace| {name: trace[:name], x: trace[:x], y: trace[:y].map{|a| 20.0*Math.log10(a.abs)}}}
                phase_traces = traces.map{|trace| {name: trace[:name], x: trace[:x], y: trace[:y].map{|a| Utils::shift360(a.phase*(180.0/Math::PI))}}}
                if (equation = params[:equation]) != ''
                  results = eval_db_ph_equation db_traces, phase_traces, equation
                end
                {"vars" => vars, "db" => db_traces, "phase" => phase_traces, "calculated_value" => results, "updates" => ckt.elements, "info" => ckt.info}
              else
                if (equation = params[:equation]) != ''
                  results = eval_equation vars, traces, equation
                end
                {"vars" => vars, "traces" => traces, "calculated_value" => results, "updates" => ckt.elements, "info" => ckt.info}
              end
            rescue => error
              $stderr.puts "Error at simulate: #{error}"
              $stderr.puts error.backtrace.join("\n")
              error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
            end 
          else
            {"log" => ckt.sim_log, "updates" => ckt.elements, "info" => ckt.info}
          end
          }
        end
      desc 'Results'
      get :results do
        work_dir, ckt_name = Utils::get_params(params)
        #probes = params[:probes] ? URI.decode_www_form_component(params[:probes]): nil
        probes = params[:probes] 
        Dir.chdir(work_dir){
          ckt = LTspiceControl.new(File.basename ckt_name)
          if probes && probes.strip != ''
            vars, traces = ckt.get_traces *(probes.split(','))
            begin
              if probes.start_with? 'frequency'
                db_traces = traces.map{|trace| {name: trace[:name], x: trace[:x], y: trace[:y].map{|a| 20.0*Math.log10(a.abs)}}}
                phase_traces = traces.map{|trace| {name: trace[:name], x: trace[:x], y: trace[:y].map{|a| Utils::shift360(a.phase*(180.0/Math::PI))}}}
                if equation = params[:equation]
                  results = eval_db_ph_equation db_traces, phase_traces, equation
                end
                {"vars" => vars, "db" => db_traces, "phase" => phase_traces, "calculated_value" => results}
              else
                if equation = params[:equation]
                  results = eval_equation vars, traces, equation
                end
                {"vars" => vars, "traces" => traces, "calculated_value" => results}
              end 
            rescue => error
              $stderr.puts "Error at results: #{error}"
              $stderr.puts error.backtrace.join("\n")
              error!("#{error}\n\n#{error.backtrace.join("\n")}", 500)
            end 
          else
            {"log" => ckt.sim_log}
          end
        }
      end
      desc 'Updates'  # no longer used
      get :update do
        work_dir, ckt_name = Utils::get_params(params)
        updates = eval params[:updates]
        puts "updates: #{updates}"
        Dir.chdir(work_dir){
          ckt = LTspiceControl.new(File.basename ckt_name)
          ckt.set updates
          {"elements" => ckt.elements, "info" => ckt.info}
        }
      end
      desc 'Info'
      get :info do
        work_dir, ckt_name = Utils::get_params(params)
        Dir.chdir(work_dir){
          ckt = LTspiceControl.new(File.basename ckt_name)
          {"info" => ckt.info}
        }
      end
      desc 'Execute program'
      post :execute do
        # puts params.keys
        # puts params
        work_dir, ckt_name = Utils::get_params(params)
        Dir.chdir(work_dir){
          puts params[:program]
          ckt = LTspiceControl.new(File.basename ckt_name)
          new_traces = eval params[:program]
          {"traces" => new_traces}
        }
      end
      desc 'Measurement'
      post :measure do
        require 'json'
        # puts params.keys
        # puts params
        work_dir, ckt_name = Utils::get_params(params)
        results = []
        Dir.chdir(work_dir){
          equation = params[:equation]
          equation = "[#{equation}]" unless equation.start_with? '['
          puts "equation for measurement: #{equation}"
          ckt = LTspiceControl.new(File.basename ckt_name)
          # puts "plotdata: '#{params[:plotdata].inspect}', size=#{params[:plotdata].size}"
          if params[:plotdata] && params[:plotdata].size > 0
            params[:plotdata].each{|plotdata|
              # debugger
              # puts plotdata[:x]
              # puts plotdata[:y]
              x = Array_with_interpolation.new plotdata[:x]
              y = Array_with_interpolation.new plotdata[:y]
              begin
                results << eval(equation)
              rescue
                results << nil
              end
            }
          else # db and phase
            puts params[:db_data].size
            if params[:db_data] && params[:db_data].size > 0
              params[:db_data].each_index{|i|
                db_data = params[:db_data][i]
                ph_data = params[:ph_data][i]
                x = Array_with_interpolation.new db_data[:x]
                db = Array_with_interpolation.new db_data[:y]
                ph = Array_with_interpolation.new ph_data[:y]
                # puts "db=#{db}"
                begin
                  results << eval(equation)
                  #puts "results === #{results}"
                rescue
                  results << nil
                end
              }
            end
          end
          {"calculated_value" => results}
        }
      end
    end
  end
end
