#!/usr/bin/ruby1.8
# svg_roc_plot program - svg_roc_plot.rb
#       
#	Copyright 2010 vorgrimmler <dv(a_t)fdm.uni-freiburg.de>
#	This ruby program exports inputs data(from true-positive-rate and false-positive-rate files) to a *.svg file using gnuplot. Depending on the amount of input data is possible to create 1 to n curves in one plot. 
#	Gnuplot is needed. Please install befor using svg_roc_plot. "sudo apt-get install gnuplot" (on debian systems).
#	Usage: See below.

# Main

STDOUT.sync = true

# -----------------------------------------------------
# checking input files
# -----------------------------------------------------
# check arguments: at least 2 and a even number of arguments
status=false
input_number=$*.size
puts "#{input_number} input files entered"
if input_number%2 != 0  || $*.size<=1
    status=true
end

if status
    puts "Usage: #{$0} ([filename_1] [filename_2]) ... ([filename_1] [filename_2])"
    puts "       cmd=filename_1 : This should be the filename of the ture-positiv-rate data."
    puts "       cmd=filename_2 : This should be the filename of the false-positiv-rate data."
	puts "       Only pairs of input files are allowed but at least one."
	puts "       Each input file has to provide one float/int number from 0 to 100 per line."
    exit
end

# gnuplot check
gnuplot=`which gnuplot | grep -o gnuplot`
if gnuplot == "gnuplot\n"
	puts "Gnuplot installed."
else
	puts "Please install gnuplot."
	puts "sudo apt-get install gnuplot"
	exit
end

dat_number=0
# -----------------------------------------------------
# create random_0.dat file for gnuplot
# -----------------------------------------------------
output_dat_arr = Array.new
for i in 0..100
	output_dat_arr[i] = "#{i} #{i}"
end
# -----------------------------------------------------
# write random_0.dat files
# -----------------------------------------------------
# write output_dat_arr content in new *.dat file
File.open( "random_#{dat_number}.dat", "w" ) do |the_file|
   	the_file.puts output_dat_arr
end
puts "random_#{dat_number}.dat created."
output_dat_arr.clear

# float check
def numeric?(object)
  true if Float(object) rescue false
end

# -----------------------------------------------------
# create *.dat files of imported data for gnuplot
# -----------------------------------------------------
# write true/false arrays to one array
for i in 0..input_number/2-1
	
	# set paths
	true_pos_path = File.expand_path($*[dat_number*2])
	false_pos_path= File.expand_path($*[dat_number*2+1])
	dat_number += 1
	
	# check files
	if File.exist?(true_pos_path) && File.exist?(false_pos_path)
		# read files to array
		true_pos_arr = IO.readlines(true_pos_path)
		false_pos_arr = IO.readlines(false_pos_path)
			
			# check length of input files
			if true_pos_arr.length == false_pos_arr.length
				#puts "Same length!"
				for i in 0..true_pos_arr.length-1
					# check if array entries are float format and between 0.0 and 100.0
					if numeric?(true_pos_arr[i].tr(',', '.')) && true_pos_arr[i].tr(',', '.').to_f <= 100 && true_pos_arr[i].tr(',', '.').to_f >= 0
						if  numeric?(false_pos_arr[i].tr(',', '.')) && false_pos_arr[i].tr(',', '.').to_f <= 100 && false_pos_arr[i].tr(',', '.').to_f >= 0
							output_dat_arr[i] = " #{true_pos_arr[i].chop} #{false_pos_arr[i]}"
						else
							puts "The following file has not the right format #{false_pos_path} in line ##{i+1}"
							puts "The right format is one float/int from 0 to 100 each line (e.g. '0'; '23,34'; '65.87' or '99')"
							exit
						end
					else
						puts "The following file has not the right format: #{true_pos_path} in line ##{i+1}"
						puts "The right format is one float/int from 0 to 100 each line (e.g. '0'; '23,34'; '65.87' or '99')"
						exit
					end
				end
				
				# -----------------------------------------------------
				# write *.dat files
				# -----------------------------------------------------
				# write output_dat_arr content in new *.dat file
				File.open( "#{$*[dat_number*2-2]}_#{dat_number}.dat", "w" ) do |the_file|
				   	the_file.puts output_dat_arr
				end
				puts "#{$*[dat_number*2-2]}_#{dat_number}.dat created."
				output_dat_arr.clear
						
			else
				puts "Input file pair(#{$*[dat_number*2-2]}, #{$*[dat_number*2-1]}) have no the same number of elements."
				exit
			end
		
	else
		puts "Unable to open one or more input file!"
		exit
	end
end

# -----------------------------------------------------
# create *.plt file for gnuplot
# -----------------------------------------------------
# 
output_plt_arr = Array.new
output_plt_arr.push "# Specifies encoding and output format"
output_plt_arr.push "set encoding default"
output_plt_arr.push "set terminal svg"
output_plt_arr.push "set output 'result.svg'"
output_plt_arr.push ""
output_plt_arr.push "# Specifies the range of the axes and appearance"
output_plt_arr.push "set xrange [0:100]"
output_plt_arr.push "set yrange [0:100]"
output_plt_arr.push "set grid"
output_plt_arr.push "set key outside right"
output_plt_arr.push "set xlabel \"false-positiv-rate\""
output_plt_arr.push "set ylabel \"true-positiv-rate\""
output_plt_arr.push ""
output_plt_arr.push ""
output_plt_arr.push ""
output_plt_arr.push ""
output_plt_arr.push "# Draws the plot and specifies its appearance ..."
output_plt_arr.push "plot	'random_0.dat' using 1:2 title 'random' with lines, \\"
for i in 0..input_number/2-1
	if i == input_number/2-1
		output_plt_arr.push "	'#{$*[i*2]}_#{i+1}.dat'  using 2:1 title '#{$*[i*2]}' with lines"
	else
		output_plt_arr.push "	'#{$*[i*2]}_#{i+1}.dat'  using 2:1 title '#{$*[i*2]}' with lines, \\"
	end
end
output_plt_arr.push ""
output_plt_arr.push ""

# -----------------------------------------------------
# write *.plt files
# -----------------------------------------------------
# write output_dat_arr content in new *.dat file
File.open( "result.plt", "w" ) do |the_file|
	the_file.puts output_plt_arr
end
puts "result.plt created."

# start gnuplot with created *.plt file
`gnuplot result.plt`

puts "result.svg created."
