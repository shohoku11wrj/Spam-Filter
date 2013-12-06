#!/usr/bin/ruby

##############
#
# This file is used to generate X-axis & Y-axis coordinate value,
# which are false-positive-rate & true-positive-rate pair into two files.
# And then use these two file, and the open source svg_roc_plot.rb programm
# to generate the ROC curves.
#
###########

@true_array = Array.new
@decision_array = Array.new
@tp = 0 # True Positive
@fp = 0 # False Positive
@tn = 0 # True Negative
@fn = 0 # False Negative
@tpr = Array.new # Y-coordinate values
@fpr = Array.new # X-coordinate values

@line_count = 0

=begin
load two generated files to arrays
=end
def load_files(true_label, decision_label)

  @line_count = File.foreach(true_label).inject(0) {|c, line| c+1}
  @true_array = Array.new(@line_count){0}
  @decision_array = Array.new(@line_count){0.00}

  # read true_label.file to array
  line_number = 0
  File.open(true_label, "r" ).each_line  do |line|
    @true_array[line_number] = line.to_i
    line_number += 1
  end

  # read decision_label.file to array
  line_number = 0
  File.open(decision_label, "r" ).each_line  do |line|
    @decision_array[line_number] = line.to_f * 100.0
    line_number += 1
  end

end


=begin
calculation, generate two arrays of Y/X-coordinates (ture-positiv-rate & false-positiv-rate)
=end
def calculate_tpr_fpr
  @tpr = Array.new(101){0.0} # Y-coordinate values
  @fpr = Array.new(101){0.0} # X-coordinate values

  x = 0
  (0.0..100.0).step(1.0) {
    |num| 
    @tp = 0 # True Positive
    @fp = 0 # False Positive
    @tn = 0 # True Negative
    @fn = 0 # False Negative

    @true_array.each_with_index do |value,index|

      if @true_array[index] == 1
        if @decision_array[index] >= num
          @tp += 1
        elsif @decision_array[index] < num
          @fn += 1
        end

      elsif @true_array[index] == -1
        if @decision_array[index] >= num
          @fp += 1
          # if num == 60.0
          #   puts "#{index}: #{@decision_array[index]}"
          # end
        elsif @decision_array[index] < num
          @tn += 1
        end
      end

    end #end of @true_array.each

    @fpr[x] = @fp * 100.0 / ( @fp + @tn )
    @tpr[x] = @tp * 100.0 / ( @tp + @fn )

    if num == 90.0
      puts "when threshold = #{num}%"
      puts "tp #{@tp} , fp #{@fp} "
      puts "tn #{@tn} , fn #{@fn} "
      puts "fpr #{@fpr[x]} , tpr #{@tpr[x]}"

      @correct = @tp + @tn
      @wrong = @fp + @fn
      @Accuracy = 0.0
      @Accuracy = @correct.to_f * 100 / (@correct + @wrong)
      puts "simple accuracy #{@Accuracy}%"

    end

    x += 1
  }

end


=begin
generate the two files "ture-positiv-rate data", "false-positiv-rate data"
from two arrays @tpr, @fpr respectively
=end
def generate_coordinate_files
  # false-positiv-rate ==> x-coordinate
  File.open('fpr_lr_basic_u01.txt', 'w') do |x|  
    @fpr.each do |line|
      x.puts line
    end
  end

  # ture-positiv-rate ==> y-coordinate
  File.open('tpr_lr_basic_u01.txt', 'w') do |y|  
    @tpr.each do |line|
      y.puts line
    end
  end
end

load_files("../result/task_a_u01_eval_lab.tf", "../result/decision_lr_basic_u01.txt")
calculate_tpr_fpr()
generate_coordinate_files()