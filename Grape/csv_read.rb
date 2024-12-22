require 'csv'

def valid_data c, select=[0, 1], x_mult=1.0, y_mult=1.0
  start = stop = nil
  dd = []
  ddd = []
  remarks = []
  puts "valid_data x_mult=#{x_mult} y_mult=#{y_mult}"
  c.each_with_index{|l, i|
    # puts "#{i}: #{l}"
    if l[0] == 'MetaData' && l[1] == ' TestRecord.Remarks'
      remarks << l[2]
      next
    end
    start, stop = numbers_range(l, start, stop)
    if start && stop && stop > start && i > 1 && c[i][start].to_f*x_mult > c[i-1][start].to_f*x_mult
      if start >= 0 # && i > 1
        flag = true
        (0..start-1).each{|j| flag = false if c[i][j] != c[i-1][j]}
        dd << l[start..stop].map{|a| a.to_f} if flag
      end
    else
      if dd.length > 2
        #puts remarks[-1] 
        #puts dd.inspect
        ddd << dd
      end
      start = stop = nil
      dd = []
    end
  }
  ddd << dd if dd.length > 2
  data = []
  ddd.each_with_index{|dd, i|
    ee = dd.transpose
    data << {x: ee[select[0]].map{|x| x*x_mult}, y: ee[select[1]].map{|y| y*y_mult}, name: remarks[i]? remarks[i].strip : i.to_s}
  }
  data
end

def number? a
  a && a =~ /^\s*[+-]?[0-9]+/
end

def numbers_range l, start, stop
  if start && stop
    if number?(l[start]) && number?(l[stop])
      [start, stop]
    else
      nil
    end
  else
    l.each_with_index{|v, i|
      # puts "v=#{v} at #{i}"
      if start
        if number? v
          stop = i
        else
          return [start, stop]
        end
      else
        if number? v
          start ||= i
        end
      end
    }
    #puts "start:#{start}, stop:#{stop}"
    if start && stop
      [start, stop]
    else
      nil
    end
  end
end

if $0 == __FILE__
  puts 'hello'

  [['a','1','2','b','3'], ['a','1','2',''], ['a','1','2',nil],
      [nil,'1','2','b'] ].each{|l|
      puts numbers_range(l, nil, nil).inspect
  }

  #Dir.glob('Grape/csv_samples/58_A0_NFET_L6W24_VDID_5_29_2024_3_23_21_PM.csv').each{|f|
  Dir.glob('Grape/csv_samples/#63 B1 PFET idvd 7_12_2024 4_48_08 PM.csv').each{|f|
  #Dir.glob('Grape/csv_samples/#63 B1 NFET idvd 7_12_2024 4_43_35 PM.csv').each{|f|
    puts f
    c = CSV.read f
    d = valid_data c, [0, 2], -1, 1
    puts d.inspect
  }
end