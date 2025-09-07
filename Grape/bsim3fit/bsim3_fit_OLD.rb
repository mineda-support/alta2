['alta2', 'jpack'].each{|f| a_path = File.join(ENV['HOMEPATH'], f)
  $:.unshift a_path if File.exist?(a_path) && !$:.include?(a_path)
}
if File.exist?('../j_pack/')
  Dir.chdir'../j_pack/' 
  load 'j_pack.rb'
end
p "PWD = " + Dir.pwd

require 'csv'
require 'matrix'
require 'json'
require 'compact_model'

Q = 1.6e-19 unless defined? Q
ESi = 12 unless defined? ESi
Eox = 3.9 unless defined? Eox
E0 = 8.854e-12 unless defined? E0
T = 300.0 unless defined? T
K = 1.38e-23 unless defined? K
Ni = 1.5e+10 unless defined? Ni
Vt = K*T/Q unless defined? Vt  


J_data = {"x" => [],"y" =>[],"z" =>[],"vgs"=> 0.0,"vds"=>0.0,"vbs" =>0.0,"vth" =>0.0,"l"=>0.0,"w"=>0.0,"gmax"=>[],"name" =>"","mode" =>"lines"} unless defined? J_data

J_vth_list = {"vgs"=>0.0,"vds"=>0.0,"vbs" =>0.0,"vth" =>0.0,"l"=>0.0,"w"=>0.0,"memo" =>""} unless defined? J_vth_list


class ModelFit
  attr_accessor :model, :model_org, :jtable
  def initialize model="models/test.lib", model_org="models/MinedaPTS06_TT"
    @model     = CompactModel::new model
    @model_org = CompactModel::new model_org
    @jtable =  [{"plot_number"=>0,"title"=>[],"title_x"=>[],"title_y"=>[],"day" => "","basename"=>"","filename"=>"","ver"=>0.99,"act"=>" ","device"=>"","dir"=>"","ext"=>"","step"=>"","plotdata"=>[]},{"measdata"=>[],"plotdata"=>[]}] unless defined? J_table
  end

  # read csv file to table(like json type)
  def read_csv csv_file = './csv/test1.csv'
    table = CSV.table(csv_file).by_col!
  end
  private :read_csv

  def read_measdata ctable, basename='json/vgid'

    meas = []
    for j in 0..ctable.headers.size - 2 do
      
      meas[j] = J_data.dup
      meas[j]["name"] =ctable.headers[j+1]
      p [j,ctable.size,meas[j]["name"]]
      for i in 0..ctable.size - 2 do
        meas[j]["x"][i] = ctable[0][i].round(5)
        meas[j]["y"][i] = ctable[j+1][i]
      end
    end
    @jtable[1]["measdata"] = meas
    @jtable[0]["basename"]= basename
    @jtable[0]["act"] = "csv to json,"
    @jtable
  end
  # read json file to table

  def read_json json_file
    if !(FileTest.exist?(json_file)) then
      p json_file + "does not exist!!"
      return
    end
    File.open(json_file,mode = "r") do |f|
      table = JSON.load(f)
    end
  end

#  private :read_json

  #write data to json_file

  def write_json data=@jtable
    dir  = data[0]["dir"]
    name = data[0]["basename"]
    ext  = data[0]["ext"]
    step = [data[0]["step"],"STEP0"].max
    ver  = (data[0]["ver"]+0.01).round(3)
    if data[0]["device"].empty? then
      device = ""
    else
      device = "_" + data[0]["device"]
    end
      new_file = dir + name + "_" + step + device + ".ver" + ver.to_s + "." + ext
    data[0]["filename"]=new_file
    data[0]["day"] = Time.now.to_s
    data[0]["ver"] = ver
    p "convert file =" + new_file

    File.open(new_file, 'w') do |file|
      JSON.dump(data, file)
    end
  end

end

class Bsim3Fit < ModelFit

  def print_condition
    p "filename = " + @jtable[0]["filename"]
    meas =@jtable[1]["measdata"]
    datas =["name","vbs","vgs","vds","vth","l","w","mode"]
    datas.each{|a| 
      tmp =format("%-8s,",a)
      for i in 0..meas.size - 1 do
        if a == "vth" then
          tmp += format("%-8.4f,",meas[i][a].to_f)
        else
          tmp += format("%-8s,",meas[i][a].to_s)
        end
      end
      p tmp
    }
    true
  end

  def set_condition vgs:nil,vds:nil,vbs:nil,name:nil,l:nil,w:nil#,mode:nil
    meas =@jtable[1]["measdata"]
    ii = meas.size

    # 'name' set
    if name.nil? then
    elsif name.instance_of?(Array) then
      jj =name.size
      for i in 0..[ii,jj].min - 1 do
        meas[i]["name"] =name[i].to_s
      end
      strs ="name  "
      for i in 0..ii - 1 do
        strs += ( ", " + meas[i]["name"])
      end
      p strs
    else
      strs ="name  "
      for i in 0..ii - 1 do
        meas[i]["name"]=name
        strs += ( ", " + meas[i]["name"])
      end
      p strs
    end

    # 'vgs' set
    if vgs.nil? then
    elsif vgs.instance_of?(Array) then
      jj = vgs.size
      for i in 0..[ii,jj].min - 1 do
        meas[i]["vgs"] =vgs[i]
      end
      strs ="vgs   "
      for i in 0..ii - 1 do
        strs += ( ", " + meas[i]["vgs"].to_s)
      end
      p strs
    else
      for i in 0..ii - 1 do
      strs ="vgs   "
        meas[i]["vgs"]=vgs
        strs += ( ", " + meas[i]["vgs"].to_s)
      end
      p strs
    end

    # 'vds' set
    if vds.nil? then
    elsif vds.instance_of?(Array) then
      jj = vds.size
      for i in 0..[ii,jj].min - 1 do
        meas[i]["vds"] =vds[i]
      end
      strs ="vds   "
      for i in 0..ii - 1 do
        strs += ( ", " + meas[i]["vds"].to_s)
      end
    else
      strs ="vds   "
      for i in 0..ii - 1 do
        meas[i]["vds"]=vds
        strs += ( ", " + meas[i]["vds"].to_s)
      end
      p strs
    end

    # 'vbs' set
    if vbs.nil? then
    elsif vbs.instance_of?(Array) then
      jj = vbs.size
      for i in 0..[ii,jj].min - 1 do
        meas[i]["vbs"] =vbs[i]
      end
      strs ="vbs   "
      for i in 0..ii - 1 do
        strs += ( ", " + meas[i]["vbs"].to_s)
      end
      p strs
    else
      strs ="vbs   "
      for i in 0..ii - 1 do
        meas[i]["vbs"]=vbs
        strs += ( ", " + meas[i]["vbs"].to_s)
      end
      p strs
    end

    # 'l' set
    if l.nil? then
    elsif l.instance_of?(Array) then
      jj = l.size
      for i in 0..[ii,jj].min - 1 do
        meas[i]["l"] =l[i]
      end
      strs ="l     "
      for i in 0..ii - 1 do
        strs += ( ", " + meas[i]["l"].to_s)
      end
      p strs
    else
      strs ="l     "
      for i in 0..ii - 1 do
        meas[i]["l"]=l
        strs += ( ", " + meas[i]["l"].to_s)
      end
      p strs
    end

    # 'w' set
    if w.nil? then
    elsif l.instance_of?(Array) then
      jj = w.size
      for i in 0..[ii,jj].min - 1 do
        meas[i]["w"] =w[i]
      end
      strs ="w      "
      for i in 0..ii - 1 do
        strs += ( ", " + meas[i]["w"].to_s)
      end
      p strs
    else
      strs ="w     "
      for i in 0..ii - 1 do
        meas[i]["w"]=w
        strs += ( ", " + meas[i]["w"].to_s)
      end
      p strs
    end
   # print_condition
    "finished!"
  end


  # Convert data from "plotdata" to "measdata" and save file.converted.json
  def imitate_measdata json_file
    @jtable[1] =(read_json json_file)[1].dup

    if @jtable[1]["plotdata"] != [] then 
      p "['plotdata'] moves ['measdata']"
      @jtable[1]["measdata"] = @jtable[1]["plotdata"].dup
      @jtable[1]["plotdata"] = []
      meas = @jtable[1]["measdata"]
      for i in 0..meas.size - 1 do
        meas[i]["mode"] = "lines"
        for j in 0..meas[0]["x"].size - 1 do
          meas[i]["x"][j] = meas[i]["x"][j].round(7).dup #significant digit = 6
     #     meas[i]["y"][j] = meas[i]["y"][j].round(18).dup #significant digit = 6
        end
      end
      @jtable[0]["act"] = "plot=>meas ,"
     # @jtable[0]["filename"] = json_file
      @jtable[0]["ver"] = 0.99

      fname = json_file.split("/").last
      ext   = fname.split(".").last
      @jtable[0]["ext"]      = "json"  # not use ext
      @jtable[0]["dir"]      = json_file.split(fname)[0]
      @jtable[0]["basename"] = fname.split(ext)[0].split(".")[0]
      @jtable[0]["device"]   = ""
      write_json @jtable
    else
      "no changed!"
    end
  end

  def calculate_vth_vbs_relation flg: false, vgs: [], vds: 0.05, vbs: [0.0, -0.5 , -1.0, -1.5,-2.0], lw: [[30e-6,30e-6]], mode: "lines"

    meas = @jtable[1]["measdata"]

    for i in 0..meas.size - 1 do
      if meas[i]["vbs"] == nil then
        if vbs.count == 1 then
          meas[i]["vbs"] = vbs[0]
        else
          meas[i]["vbs"] = vbs[i]
        end
      end
      
      if meas[i]["vds"] == nil then
        meas[i]["vds"] = vds
      end
      
      if meas[i]["vgs"] == nil then
        if vgs.count == 1 then
          meas[i]["vgs"] = vgs[0]
        else
          meas[i]["vgs"] = vgs[i]
        end
      end

      if meas[i]["l"] == nil then
        if lw.count == 1 then
          meas[i]["l"] =lw[0][0]
          meas[i]["w"] =lw[0][1]
        else
          meas[i]["l"] =lw[i][0]
          meas[i]["w"] =lw[i][1]
        end
      end
      
      meas[i]["z"]=[]

      for j in 0..meas[i]["x"].size - 1 do
        meas[i]["x"][j] = meas[i]["x"][j].round(5) 
        if flg then
          meas[i]["x"][j] += meas[i]["vbs"]
        end

        if j < 1 then
          meas[i]["z"][0] = 0.0
        else
          meas[i]["z"][j] = (meas[i]["y"][j] - meas[i]["y"][j-1]) / (meas[i]["x"][j] - meas[i]["x"][j-1])
        end
      end
      ii  = meas[i]["z"].index(meas[i]["z"].max)
      vgm = meas[i]["x"][ii]
      idm = meas[i]["y"][ii]
      gmm = meas[i]["z"][ii]

      meas[i]["gmax"]= [vgm,idm,gmm]
      meas[i]["vth"] = ((gmm * vgm - idm)/gmm -vds/2.0).round(5)
      meas[i]["name"] = "vbs= " + meas[i]["vbs"].to_s
    end

#    meass = @jtable[1]["measdata"]
    @jtable[0]["act"] ||= ''
    @jtable[0]["act"] += "cal [vth,gm],"
    @jtable[0]["step"] = "STEP1"
    @jtable[0]["device"] = "Vth_Vbs"

    write_json @jtable
  end

  #### data change 0.2V step ####
  def change_step datas: @jtable[1]["measdata"],delta: 0.2
    data_c = []
    for j in 0..datas.size - 1 do
      data_c << datas[j].dup
      data_c[j]["x"]=[]
      data_c[j]["y"]=[]
      data_c[j]["z"]=[]
      for i in 0..datas[j]["x"].size - 1 do
        xxx = datas[j]["x"][i]
        if (xxx.modulo(delta).round(2)== 0 || xxx.modulo(delta).round(2)== delta ) then
          data_c[j]["x"] << datas[j]["x"][i].round(2)
          data_c[j]["y"] << datas[j]["y"][i]
          if datas[j]["z"].nil? != true then
            data_c[j]["z"] << datas[j]["z"][i]
          end
        end
      end
    end
    data_c
  end

  ### y-data and z-data change ####
  def exchange_y_z name = "measdata"
    data = @jtable[1][name]
    d_size =data.size
    for i in 0..d_size - 1 do
      mm = data[i]
#      p "y[0]="+mm["y"][0].to_s+"  z[0]="+mm["z"][0].to_s
      ancher = mm["y"].dup
      mm["y"] = []
      mm["y"] = mm["z"].dup
      mm["z"] = []
      mm["z"] = ancher.dup
#      p "y[0]="+mm["y"][0].to_s+"  z[0]="+mm["z"][0].to_s
    end
  end

  ###### graph operation methods ######
  
  ### list graphs    #####
  def list_graph
    @jtable[1].keys
  end
  

  ### Check graph exist ###
  def exist_graph target = "measdata"
    @jtable[1].key?(target)
  end
    
  ### graph copy from souce to dist
  def copy_graph source= "measdata",dist = "meas_org",force = false 
    if (source == dist) then
      p "source and dist graphs are same!!"
      return false
    end
    if (exist_graph(dist) == false) then
      #p "['" + dist + "'] is not exist. create ['"+ dist + "']"
    elsif force == false then
      if dist == "measdata" then
        p "['" + dist + "'] is protected. Use copy_graph source,dist,[true]"
        return false
      end
    end

    target = @jtable[1][source]
    @jtable[1][dist] = target.dup
    p list_graph
    true
  end

  ####  graph Move from source to dist
  def move_graph source = "measdata",dist = "meas_org",force = false
    if copy_graph(source,dist,force) then
      if source != "measdata" then
        delete_graph source
        list_graph
        return true
      else
        p "graph['measdata'] dose not delelete"
        return false
      end
    else
      p "move is not successed !"
      list_graph
      return false
    end
  end
      
  ####  graph delete  ######
  def delete_graph dist = "test"
    if (exist_graph(dist) == false) then
      p "['" + dist + "'] is not exist."
      return false
    end

    #p "['" + dist + "'] is exist. ['"+ dist + "'] is deleted."
    @jtable[1].delete(dist)
    p list_graph
    return true
  end
  
  ###### end of graph operation methods ######
  
  ### gm curve set   #####
  def step1_calc_gmdata delta: 0.05

    gmdata = change_step(delta: delta)

    for i in 0..gmdata.size - 1 do
      gmdata[i]["y"]=gmdata[i]["z"].dup
      gmdata[i]["z"]=[]
    end
    
    if @jtable[1]["gmdata"].nil? then
      p ' dataset "gmdata" create'
    end

    if @jtable[1]["simpledata"].nil? == false then
      simple = @jtable[1]["simpledata"]
      jj = gmdata.size 
      ii = simple.size - 1
      for i in 0..ii do
        gmdata[jj+i] = J_data.dup
        gmdata[jj+i]["x"] = simple[i]["x"].dup
        gmdata[jj+i]["y"] = simple[i]["z"].dup
        gmdata[jj+i]["name"] = simple[i]["name"].dup

      end
    else
      p "after step1_calc_simple_model,use step1_calc_gmdata"
    end
      
    @jtable[1]["gmdata"]=gmdata.dup
    list_graph
#    write_json @jtable
  end

  #[STEP1](2-1) calculate Id-Vg Curve using Simple model (Gm-Scale Create)
  def step1_calc_simplemodel 
    table = @jtable[1]["measdata"]
    gm = []
    for j in 0..table.size - 1 do
      gm << J_data.dup
      gm[j]["x"] = []
      gm[j]["y"] = []
      gm[j]["z"] = []
      vgm  = table[j]["gmax"][0].dup
      idm  = table[j]["gmax"][1].dup
      gmm  = table[j]["gmax"][2].dup
      vds  = table[j]["vds"].dup
      vths = table[j]["vth"].dup
      vbs  = table[j]["vbs"].dup

      deltax = 2.0
      delta = 0.01
      gm[j]["x"][0] = vths
      gm[j]["y"][0] = 0
      gm[j]["x"][1] = vths + vds/2.0
      gm[j]["y"][1] = 0
      gm[j]["x"][2] = vths + vds/2.0 + delta 
      gm[j]["y"][2] = gmm * delta
      gm[j]["x"][3] = vgm 
      gm[j]["y"][3] = idm
      gm[j]["x"][4] = vgm + deltax
      gm[j]["y"][4] = idm + gmm * deltax  
      gm[j]["z"][0] = 0.0
      gm[j]["z"][1] = 0.0
      gm[j]["z"][2] = gmm
      gm[j]["z"][3] = gmm
      gm[j]["z"][4] = gmm
      
      gm[j]["name"] = "vbs= " + vbs.to_s
    end

    if @jtable[1]["simpledata"].nil? then
      p ' dataset "simpledata" create'
    end

    @jtable[1]["simpledata"]=gm.dup
    
    #write_json @jtable
    list_graph
  end

  #### Id_Vgs Curves calculate and store in "idvgdata"
  def step1_calc_id_vgs
    idvgs =[]
    from_data =change_step(delta: 0.2)
    for i in 0..from_data.size - 1 do
      idvgs[i] = from_data[i].dup
    end
    ii =idvgs.size - 1
    
    from_data =@jtable[1]["simpledata"]
    for i in 0..from_data.size - 1 do
      idvgs[i+ii] = from_data[i].dup
    end
    @jtable[1]["idvgsdata"] = idvgs.dup
    list_graph
  end

  
  #### Vth-Vbg curve calicuration ######
  def step1_calc_vth_vbs
    if (@model.get :NSUB).nil? then
      na = 6e+16
    else
      na = (@model.get :NSUB).to_f
    end
    phis = 2.0*Vt*Math.log(na / Ni)
    phiss = Math.sqrt(phis)

    vth0 = (@model.get :VTH0).to_f
    k1   = (@model.get :K1).to_f
    k2   = (@model.get :K2).to_f
    
    vth0_org = (@model_org.get :VTH0).to_f
    k1_org   = (@model_org.get :K1).to_f
    k2_org   = (@model_org.get :K2).to_f

    meas1 =[0..2]
    for i in 0..2 do
      meas1[i] = J_data.dup
    end
    x1 = [] 
    vth =convert_vth(na: na) ##vth mesurement
    meas1[0]["x"] = vth["x"].dup
    meas1[0]["y"] = vth["y"].dup
    meas1[0]["name"] = "meas."
    y1 =[]
    y2=[]
    for i in 0..6 do
      x = - i * 0.5
      x1[i] = x
      y = Math.sqrt(phis - x)
      y1[i] = (k2 * y*y + k1 * y + vth0 -k1 * phiss + k2 * phis).round(5).dup
      y2[i] = (k2_org * y*y + k1_org * y + vth0_org -k1_org * phiss + k2_org * phis).round(5).dup
    end
    meas1[1]["x"] = x1.dup
    meas1[1]["y"] = y1.dup
    meas1[2]["x"] = x1.dup
    meas1[2]["y"] = y2.dup
    meas1[1]["name"]="extracted"
    meas1[2]["name"]="PTS06"

    d_from = @jtable[1]["measdata"][0]

    for i in 0..2 do
      meas1[i]["vgs"]  = d_from["vgs"].dup
      meas1[i]["vds"]  = d_from["vds"].dup
      meas1[i]["vgs"]  = d_from["vgs"].dup
      meas1[i]["l"]    = d_from["l"].dup
      meas1[i]["w"]    = d_from["w"].dup
      meas1[i]["mode"] = d_from["mode"].dup
    end

    @jtable[1]["vthdata"] = meas1.dup
    list_graph
    true
  end
    

    ### calculate some Guraphs and store Bsim3Fit  ######
    def step1_calc_graphs
      step1_calc_simplemodel
      #Id-Vgs  Graph using SimpleModel Calculates and stores in "simpledata"
      step1_calc_gmdata
      #Gm-Vgs  Graph Calculates and stores in "gmdata"     
      step1_calc_id_vgs    #Id-vgs Graphs using measure ad simpleModel Calulate and in "idvgdata"
      step1_calc_vth_vbs   #Vth-Vbs Graph Calculates and stores in "vthdata"

#      @jtable[0]["basename"] ="json/step1"
      @jtable[0]["ver"] = 0.99
      @jtable[0]["day"] = ""
      @jtable[0]["act"] += " set some graphs,"
      
      write_json @jtable
      list_graph
    end

  ###[STEP1](2-5-1) Define Vth Parameter (VTH0,K1,K2) Sub ###
    def convert_vth na: 6e+16

      phis = 2.0*Vt*Math.log(na / Ni)
      meas = {"x"=>[] , "y"=>[],"z"=>[],"name" =>""}
      for i in 0..@jtable[1]["measdata"].size - 1 do
        vbs = @jtable[1]["measdata"][i]["vbs"]
        meas["x"][i] = vbs
        meas["y"][i] = @jtable[1]["measdata"][i]["vth"].round(5)
        meas["z"][i] = Math.sqrt(phis - vbs) 
      end
      meas["name"] = "measured"
      meas
    end
      
    ###[STEP1](2-5-2) Extract Vth Parameter [VTH0,K1,K2] main ###
    def estimate_vth_k1_k2  #, model=@model,model_org=@model_org
      if (@model.get :NSUB).nil? then
        na = 6e+16
      else
        na = (@model.get :NSUB).to_f
      end
      vth = convert_vth(na: na)

      @jtable[0]["act"] ="determine VTHs "

      meas = {"x"=>[] , "y"=>[],"z"=>[],"vds"=>0.0,"name" =>""}

      x = vth["z"]
      y = vth["y"]
      z = determine_2nd x ,y

      phis = 2.0*Vt*Math.log(na/Ni)
      phiss = Math.sqrt(phis)

      k2   = z[0]
      k1   = z[1]
      vth0 = (z[2] + z[1]* phiss - z[0]*phis).round(5) #k2 * Math.sqrt(phi)

      @model.set :VTH0 => vth0.round(5)
      @model.set :K1   => k1.round(5)
      @model.set :K2   => k2.round(5)
      @model.save

      a = "VTH0 =" + (@model.get :VTH0)
      b = " K1 = "  + (@model.get :K1)
      c = " K2 = "  + (@model.get :K2)
      puts " model file \("+  @model.file + "\) is saved " + a +b + c 

      a = "VTH0 =" + (@model_org.get :VTH0)
      b = " K1 = "  + (@model_org.get :K1)
      c = " K2 = "  + (@model_org.get :K2)
      puts " model file \("+  @model_org.file + "\) is saved " + a +b + c 

      #@jtable
      true
    end

    def calc_delta model=@model,vbs=0.0,vds =0.05,l=30e-6,w=30e-6

      #model parameters
      nsub   =  (model.get:NSUB).to_f
      nch    =  (model.get:NCH).to_f
      tox    =  (model.get:TOX).to_f 
      nlx    =  (model.get:NLX).to_f
      k1     =  (model.get:K1).to_f
      k2     =  (model.get:K2).to_f
      k3     =  (model.get:K3).to_f
      k3b    =  (model.get:K3B).to_f
      w0     =  (model.get:W0).to_f
      dvt0   =  (model.get:DVT0).to_f
      dvt1   =  (model.get:DVT1).to_f
      dvt2   =  (model.get:DVT2).to_f
      dsub   =  (model.get:DSUB).to_f
      eta0   =  (model.get:ETA0).to_f
      etab   =  (model.get:ETAB).to_f
      dvt0w  =  (model.get:DVT0W).to_f
      dvt1w  =  (model.get:DVT1W).to_f
      dvt2w  =  (model.get:DVT2W).to_f
      lint   =  (model.get:LINT).to_f
      wint   =  (model.get:WINT).to_f
      leff   =  l + 2.0 * lint
      weff   =  w + 2.0 * wint
      nds    =  1.0e20
      nsub   =  6.0E16
      # parameters
      phis  = 2.0*Vt*Math.log(nsub/Ni)
      phiss = Math.sqrt(phis)
      vbi   = K*T/Q * Math.log(nch * nds/(Ni**2))
      xdep  = Math.sqrt(2.0 * ESi * E0 * (phis - vbs)/(Q * nch))
      xdep0 = Math.sqrt(2.0 * ESi * E0 * phis/(Q * nch))    
      lt    = Math.sqrt(ESi * E0 * xdep/(E0 / tox)) * (1.0 + dvt2 * vbs)
      lt0   = Math.sqrt(ESi * E0 * xdep/(E0 / tox))
      ltw   = Math.sqrt(ESi * E0 * xdep/(E0 / tox)) * (1.0 + dvt2w * vbs)

      # delta function
      delta10  = k1 * Math.sqrt(1.0 + nlx/leff - 1.0)
      delta11  =( k3 + k3b * vbs) * tox/(weff + w0) * phis
      delta20  = - dvt0 * (Math.exp(-dvt1 * leff / (2.0 * lt)) + 2.0 * Math.exp(- dvt1 * leff / lt))*(vbi - phis)
      delta30  = - (Math.exp(-dsub * leff / (2.0 * lt0)) + 2.0 * Math.exp(- dsub * leff / lt0))*(eta0 + etab *vbs)
      delta40  = dvt0w * (Math.exp(-dvt1w * (weff * leff)  / (2.0 * ltw)) + 2.0 * Math.exp(- dvt1w * (weff * leff) / ltw))*(vbi - phis)
      #output
      p "delta10 ="  + format("%4.4f",delta10)
      p "delta11 ="  + format("%4.4f",delta11)
      p "delta20 ="  + format("%4.4f",delta20)
      p "delta30 ="  + format("%4.4f",delta30)
      p "delta40 ="  + format("%4.4f",delta40)
      delta =delta10 + delta11 + delta20 + delta30 + delta40
      p "delta   ="  + format("%4.4f",delta)
      delta
    end

  ### Storage calc data ("gmdata","simpledata","vthdata#)
  def plot_graph gname = "measdata"
    target = list_graph
    if @jtable[1].key?(gname) != true  then
      p gname +" is not exist " + target.to_s
      return
    end

    mf_plot= Bsim3Fit::new
    mf_plot.jtable[0] = @jtable[0].dup
    gdata = mf_plot.jtable[1]
    gdata = @jtable[1][gname].dup
    mf_plot.jtable[1]["measdata"]=gdata.dup
    sdata =[]
    ["json/"].each { |dir|
      sdata = Dir.glob(dir + gname +".ver*.json")
    }
   # p sdata
    if sdata.empty? then
      ver=0.99
    else
      ver =sdata.max.slice(/[0-9]\.[0-9]+/).to_f
    end
    mf_plot.jtable[0]["ver"] = ver
    mf_plot.jtable[0]["act"] =gname + " data,"
    mf_plot.jtable[0]["device"] = gname
    write_json mf_plot.jtable
    p "data:[" + gname + "] is saved!!"
    mf_plot =nil
   end

  ### plot all Graphs except "plotdata"
  def plot_all_graphs
    graphs = list_graph #@jtable[1].keys
    graphs.delete("plotdata")
    graphs.each{|graph| 
      p graph
      plot_graph(graph)
    }
    #    p graphs
    true
  end

  ### [STEP2] Mobility Estimation Ueff[U0,UA,UB,UC]
  ### Analysis in [STEP2] is performed using the same data as in [STEP1]

  ### STEP2 setup
  def step2_setup
    head =@jtable[0]
    head["step"]     = "STEP2"
    head["ver"]      = 0.99
    head[day]        = ""
  end

  ### [STEP2-1]Calc. Ueff-Vgs Curve ["measdata"][i]["y"]:: Id => ueff  
  def step2_calc_ueff model: @model
    ### backup ["measdata"] => ["step1_org"]
    dist ="step1_org"
    #if print_gaph_names.select{|f|f == dist} == [] then
    if (exist_graph(dist) == nil) then
      copy_graph "mwasdata",dist,true
      p "['measdata'][i]['z'] is changed Ueff data"
    else
      p "[" + dist + "] is exist. Overwrite ["+ dist + "] is not allowed."
    end
    
    tox  = (model.get :TOX).to_f
    cox = Eox*E0/tox
    ### change ["measdata"][i]["z"] ####

    id_vgs0     = @Jtable[0]
    id          = @Jtable[1]["measdata"]

    id_vgs0["basename"] = "json/STEP2_Ueff"
    id_vgs0["ver"]=0.99
    id_vgs0["act"] += "Set Ueff,"

    for i in 0..id.size - 1 do
      
      l =  id[i]["l"]
      w =  id[i]["w"]
      vth = id[i]["vth"]
      vds = id[i]["vds"]
      
      #id[i]["ueff"] =[].dup
      ik = id[i]["x"].size - 1
      for j in 0..ik do
        x = id[i]["x"][j]
        tmp = (x - vth - vds/2.0)
        id[i]["y"][j] = (id[i]["z"][j]/tmp/cox/w*l/vds).dup
      end
    end 
  end

  ### [STEP2-2] Calculate Estimate datas #######
  
  def get_ueff model: @model,delta: 3.0
    step2         = @Jtable[1]["measdata"].dup
    id_vgs0       = step2[0]
    id            = step2[1]["measdata"]
      
    id_vgs0["basename"] = "json/STEP2_Ueff"
    id_vgs0["ver"]      = 0.99
    id_vgs0["act"]      = "for Ueff Cal."

    for i in 0..id.size - 1 do
      ii = id[i]["x"].index{|v| v>=delta*vth}
      ik = id[i]["x"].size - 1
      id[i]["x"]=[]
      id[i]["y"]=[]
      id[i]["z"]=[]
      p [i,ii,ik]
      for j in ii..ik do
        id[i]["x"] << step2_org[i]["x"][j].dup 
        id[j]["y"] << step2_org[i]["y"][j].dup
        id[j]["z"] << step2_org[i]["z"][j].dup
      end
    end  # end of i

    p  list_graph ##@jtable[1].keys
    id
  end

  # [STEP2-3] estimation ueff from ueff curve

    def estimation_u0_ua_ub_uc xyz , model=@model

      xy = get_ueff(model).dup
    
      tox  =(model.get :TOX).to_f
      u0ss = []
      uass = []
      ubss = []
      vbss = []
      
      for j in 0..xy.size - 1 do
        x11, x12, x13 = 0.0,0.0,0.0
        x21, x22, x23 = 0.0,0.0,0.0
        x31, x32, x33 = 0.0,0.0,0.0
        y11, y22, y33 = 0.0,0.0,0.0

        vds = xy[j]["vds"]
        vbs = xy[j]["vbs"]
        vth = xy[j]["vth"]
        vbss << vbs

        for i in 0..xy[j]["x"].size - 1 do

          x = xy[j]["x"][i].abs
          y = 1.0/xy[j]["y"][i].abs
          f1 = 1
          f2 = x + vth
          f3 = (x+vth)**2

          y11 += y*f1
          x11 += f1*f1
          x12 += f2*f1
          x13 += f3*f1
          
          y22 += y*f2
          x21 += f1*f2
          x22 += f2*f2
          x23 += f3*f2

          y33 += y*f3
          x31 += f1*f3
          x32 += f2*f3
          x33 += f3*f3
        end # end of i

        a1 = [x11,x12,x13]
        a2 = [x21,x22,x23]
        a3 = [x31,x32,x33]

        yy = [y11,y22,y33]

        f = Matrix.rows([a1,a2,a3], true).inv
        k = Matrix.columns([yy])

        zs = f*k

        u0 = 1.0/zs[0,0]
        ua = zs[1,0]*u0*tox
        ub = zs[2,0]*u0*tox**2

        puts u0a + uaa + uba
        u0ss << u0
        uass << ua
        ubss << ub

      end # end of j
    
      # average & std
      ii = u0ss.size
      avgs = (u0ss.sum / ii)
      stds = (u0ss.map{|x| ((x - avgs)/avgs)**2}.sum)/ii
      stdv = Math.sqrt(stds)
      puts 'U0 AVG= ' + format("%3.6f",avgs) + ' stdv = ' + format("%2.4f",stdv*100.0)+ "%"
      ii = uass.size
      avgs = (uass.sum / ii)
      stds = (uass.map{|x| ((x - avgs)/avgs)**2}.sum)/ii
      stdv = Math.sqrt(stds)
      puts 'UA AVG= ' + format("%2.6e",avgs) + ' stdv = ' + format("%2.4f",stdv*100.0)+ "%"
      ii = ubss.size
      avgs = (ubss.sum / ii)
      stds = (ubss.map{|x| ((x - avgs)/avgs)**2}.sum)/ii
      stdv = Math.sqrt(stds)
      puts 'UB AVG= ' + format("%3.6e",avgs) + ' stdv = ' + format("%2.4f",stdv*100.0) + "%"
    
      x11, x12 = 0.0,0.0
      x21, x22 = 0.0,0.0
      y11, y22 = 0.0,0.0
      for i in 0..vbss.count - 1 do
        # Uaa = UA + UC+Vbs
        # a1 = UA f1 = 1
        # a2 = UC f2 = Vbs
        # ua = a1
        # uc = a2

        x = vbss[i]
        y = uass[i]
        f1 = 1
        f2 = x
      
        y11 += y*f1
        x11 += f1*f1
        x12 += f2*f1
      
        y22 += y*f2
        x21 += f1*f2
        x22 += f2*f2
      end # end of i

      a1 = [x11,x12]
      a2 = [x21,x22]

      yy = [y11,y22]

      f = Matrix.rows([a1,a2], true).inv
      k = Matrix.columns([yy])

      zs = f*k

      ua = zs[0,0]
      uc = zs[1,0]
      
      u0 = u0ss[0]
      ub = ubss[0]

      model.set :U0 => (format("%5.5e",u0)).to_f
      model.set :UA => (format("%5.5e",ua)).to_f
      model.set :UB => (format("%5.5e",ub)).to_f
      model.set :UC => (format("%5.5e",uc)).to_f
      model.save

      u0x = "U0 = " + (model.get :U0).to_s
      uax = "UA = " + (model.get :UA).to_s
      ubx = "UB = " + (model.get :UB).to_s
      ucx = "UC = " + (model.get :UC).to_s
      puts 'Model Parameters SET:'
      puts u0x
      puts uax
      puts ubx
      puts ucx

      zz = []
      @jtable = get_ueff0 xyz,model
      @jtable[0]["basename"] ='json/Vg-Ueff'
      @jtable[0]["act"] ="Determine Ueff "
      @jtable[0]["ver"] = 0.99
      ii = xy.size
      @jtable[1]["measdata"].shift(ii)
      for i in 0..(ii-1) do
        data[1]["measdata"] << xy[i]
      end
      data
    end


    ## Calc standard deviation between 2 Curves
    def calc_stdv data_org
      ff = [] #1st curve
      gg = [] #2nd curve
      data = data_org[1]["measdata"].dup

      for i in 0..data.size / 2 - 1 do
        ff += data[2*i]["y"]
        gg += data[2*i+1]["y"]
      end
      p ff.size
      g_f = 0.0
      for i in 0..ff.size - 1 do
        if ff[i].abs > 1e-20 then 
        g_f += ((gg[i] - ff[i])/ff[i])**2
        end
      end
      p [g_f,ff.size]
      stdv = Math.sqrt(g_f)/ff.size * 100.0
      p format( "stdv = %4.4f",stdv)+"%"
    end


    ### -------------------------------------------------

    ###[STEP3] Get RDSW & Lint from Vgs-Id(several Curves)
    ###[STEP3] (1)Full Cal.

    def get_vth_l table
      data0 = table[0].dup
      get_vth table , vgs:[],vds: 0.05,vbs: [0.0],lw: [[0.6e-6,4e-6],[0.8e-6,4e-6],[1.0e-6,4e-6],[1.4e-6,4e-6],[2.0e-6,4e-6]]
      table[0] = data0.dup
      write_json table
      table
    end

    def define_rdsw mm0
      #  lint_m = convert_rds meas          #convert Rds-Vgs Curve

      zz =[]
      id0 =mm0.dup
      id = id0[1]["measdata"]
      delta =1.0
      ii = id[0]["x"].index { |v| v>= delta }

      for i in 0..id.size - 1 do
        z = J_data
        vth =id[i]["vth"]
        vds =id[i]["vds"]
        vbs = id[i]["vbs"]
        z["vth"] = vth
        z["vds"] = vds
        z["vbs"] = vbs
        z["l"] = id[i]["l"]
        z["w"] = id[i]["w"]
        z["name"] = format("l=%du",z["l"]*1e6)
        z["mode"] = "markers"
        ww = z["l"]*1.0e6
        for j in ii..id[i]["x"].size - 1 do
          z["x"] << id[i]["x"][j]
          z["y"] << id[i]["y"][j]
          z["z"] << vds / (id[i]["y"][j] )/ww 
        end
        zz << z.dup
      end
      rr = []
      for i in 0..zz[0]["x"].size - 1 do
        names = format("Vgs=%f",zz[0]["x"][i])
        r = { "x"=>[],"y"=>[],"name" => names,"w"=>zz[0]["w"],["vgs"]=>zz[0]["x"][i],["mode"]=>"lines+markers"}
        
        delta =0.5
        for j in 0.. zz.size - 2 do
          if (zz[j]["x"][i] % 0.5 == 0) then
            r["vgs"] = zz[0]["x"][i]
            r["x"]<< zz[j]["l"].dup
            r["y"] << zz[j]["z"][i].dup
          end
        end
        rr << r.dup
      end

      id0[0]["basename"] = 'json/l_rd_meas'
      id0[0]["ver"] = 0.99
      id0[0]["act"] = 'convert l-RD curve'
      id0[1]["measdata"] = rr
      id0
    end

    #### L-RDSW for Display ######
    def show_rdsw(l_rds,delta = 0.5)
      gdata = l_rds.dup
      meas =gdata[1]["measdata"]
      imax = meas.size - 1
      for i in 0..imax do
        if (meas[imax -i]["x"].modulo(delta) !=0) then
          meas[imax -i].delete(iax - i)
        else
          p "vgs=" + meas[imax- i]["x"].to_s
        end
      end
      gdata
    end
    ###[STE3](5) determine RDSW & LINT
    def determine_lint id0,model
      id = id0.dup
      rs_l = id[1]["measdata"]
      zzz = []
      rs_l.each do |z|
        y = determine_1st z["x"] ,z["y"]
  
        a = []
        b = []
        a << y[1]
        b << y[2]
      
        zc = {"x"=>[],"y"=>[] ,"name"=> rs_l[0]["name"]}
        for i in 0..1000 do
          zc["x"][i] = i * 1e-8 - 1e-6
          zc["y"][i] = y[1] * zc["x"][i] + y[2]
        end
        zzz << zc.dup
      end
      #   puts zzz
      dev =[]
      rrr = []
      for j in 0..zzz[0]["x"].size - 1 do
        dd =0
        rr = 0
        for i in 0..zzz.size - 1 do
          rr=rr + zzz[i]["y"][j]
          for k in i+1..zzz.size - 1 do
            dd =dd+(zzz[i]["y"][j]-zzz[k]["y"][j])**2
          end
        end
        dev << dd.dup
        rrr << rr.dup
      end
      w = id[1]["measdata"][0]["w"]
      ymin = dev.min
      yindex =dev.index(dev.min)
      xmin = zzz[0]["x"][yindex]
      rr = rrr[yindex]/zzz.size
      model.set :LINT => format("%5.3e",xmin/2.0).to_f
      # model.set :WINT => format("%5.3e",0.0).to_f
      model.set :RDSW => format("%5.3e",rr/(w*1e6)).to_f
      model.save
      puts "Model parameter Set:"
      puts format('[Lint = %5.3e]',xmin/2.0)
      puts format('[Wint = %5.3e]',0.0)
      puts format('[RDSW = %5.3e]',rr/(w*1.0e6))
      zzzz =[]
      for i in 0..rs_l.size - 1 do
        if i == 0 then

        end
        if (i % 50 ==0) then
          zzzz << rs_l[i]
        end
      end
    
      zz ={"x"=>[],"y"=> []}
      zz["x"][0] = 0.0
      zz["y"][0] = rr#*w*1e6
      zz["x"][1] = -xmin
      zz["y"][1] = rr#*w*1e6
      zz["x"][2] = -xmin
      zz["y"][2] = 0.0
      zzzz << zz.dup
      id[1]["measdata"] = zzzz
      id
    end

    ### Normalize Vds-Id  *****
    def get_normalize_id table0
      table = table0.dup
      meas = table[1]["measdata"]
      for i in 0..meas.size - 1 do
        l = meas[i]["l"]
        w = meas[i]["w"]
        #      p [meas[i]["y"].size,l/w]
        #      ii = meas[i]["y"].size
        for j in 0..meas[i]["y"].size - 1 do
          meas[i]["y"][j] *= l/w
        end
      end
      table[0]["act"] +="Id Normalize"
      table
    end

    ### 2nd-order least squares method y = Ax^2 + Bx + C
    def determine_2nd x  , y

      x11,x12,x13 = 0,0,0
      x21,x22,x23 = 0,0,0
      x31,x32,x33 = 0,0,0
      y1 ,y2 ,y3  = 0,0,0

      for i in 0..(x.size) - 1 do
        x11 += x[i]**4
        x12 += x[i]**3
        x13 += x[i]**2
        x21  = x12
        x22  = x13
        x23 += x[i]
        x31  = x22
        x32  = x23
        x33 += 1
        y1  += x[i]**2 * y[i]
        y2  += x[i] * y[i]
        y3  += 1.0*y[i]
      end
      a1 = [x11,x12,x13]
      a2 = [x21,x22,x23]
      a3 = [x31,x32,x33]
      yy = [y1,y2,y3]

      f = Matrix.rows([a1,a2,a3], true).inv
      k = Matrix.columns([yy])
      z = f*k

      a = z[0,0]
      b = z[1,0]
      c = z[2,0]

      [a,b,c]
    end

    ### 1st Order least squares method
    ###1st case determin
    def determine_1st x , y
      x11,x12 = 0,0
      x21,x22 = 0,0
      y1 ,y2  = 0,0
      for i in 0..x.size - 1 do
        x11 += x[i]**2
        x12 += x[i]
        x21 = x12
        x22 += 1.0
        y1  += x[i]*y[i]
        y2  += y[i]
      end
      a1 = [x11,x12]
      a2 = [x21,x22]
      yy = [y1,y2]

      f = Matrix.rows([a1,a2], true).inv
      k = Matrix.columns([yy])

      z = f*k

      a = z[0,0]
      b = z[1,0]

      [0 , a , b]
    end

end   # end of Bsim3Fit

if $0 == __FILE__
  mf = Bsim3Fit.new('models/test.lib', 'models/MinedaPTS06_TT')
  vg_id = mf.imitate_measdata('json/test.json')
  mf.set_condition
  mf.calculate_vth_vbs_relation
  mf.estimate_vth_k1_k2
end
