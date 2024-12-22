require 'roo-xls'
#xls = Roo::Excel.new('Grape\csv_samples\24R1A1_L_NL6W12Std.xls')
def xls_read file, select=[0, 1], x_mult=1.0, y_mult=1.0
  xls = Roo::Excel.new(file)
  sheet = xls.sheet(0)
  header = sheet.row(sheet.header_line) # like DrainI(1), DrainV(1), BulkI(1)...
  header[0] =~ /(\S+)[\(,:\[]/ # data name like 'DrainI'
  first_name = $1
  nitem = header[1..-1].find_index{|f| f =~ /#{first_name}/} + 1
  puts "First #{nitem} data names:", header[0..nitem]
  data = []
  header.length.times{|i|
    j = i % nitem
    k = sheet.header_line + 1
    if j == 0 
      c = []
      while sheet.cell(k, i+1)
        c << sheet.row(k)[i..i+nitem-1]
        k = k + 1
      end
      ee = c.transpose
      data << {x: ee[select[0]].map{|x| x*x_mult}, 
               y: ee[select[1]].map{|y| y*y_mult}, 
               name: select[2] ? ee[select[2]][0] : (i/nitem).to_s}
    end
  }
  data
end
if $0 == __FILE__
  file = "Grape/csv_samples/24R1A1_L_NL6W12Std.xls"
  xls_read file, [1,0], x_mult=1.0, y_mult=1.0
end