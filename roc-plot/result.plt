# Specifies encoding and output format
set encoding default
set terminal svg
set output 'result.svg'

# Specifies the range of the axes and appearance
set xrange [0:100]
set yrange [0:100]
set grid
set key outside right
set xlabel "false-positiv-rate"
set ylabel "true-positiv-rate"




# Draws the plot and specifies its appearance ...
plot	'random_0.dat' using 1:2 title 'random' with lines, \
	'y.txt_1.dat'  using 2:1 title 'y.txt' with lines, \
	'y1.txt_2.dat'  using 2:1 title 'y1.txt' with lines, \
	'y2.txt_3.dat'  using 2:1 title 'y2.txt' with lines, \
	'y0.txt_4.dat'  using 2:1 title 'y0.txt' with lines


