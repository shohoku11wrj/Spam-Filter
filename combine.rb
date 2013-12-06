#!/usr/bin/ruby
=begin
  Combine the decision_label.txt of "Naive Bayes" and "Logistic Regression" to one file,
  decision_label_combined.txt, which might have less fpr on basement of LR results. 
=end

@total_line = 0
@p1 = Array.new() {0.00}
@p2 = Array.new() {0.00}
@verify = Array.new() {0.00}

def combine(p1, p2)
  readFileIntoP(p1, 1) # 1 is LR
  readFileIntoP(p2, 2) # 2 is NB

  doCombine()

  writeCombined()
end

def readFileIntoP(filename, which)
  total_line = File.open(filename, "r").each_line.count
  if @total_line != 0 && @total_line != total_line
      at_exit { puts "different total_line" }
  end

  if which == 1
    @p1 = Array.new(@total_line) {0.00}
  else
    @p2 = Array.new(@total_line) {0.00}
  end
  @verify = Array.new(@total_line) {0.00}

  lineCount = 0
  File.open(filename, "r").each_line do |line|
    if which == 1
      @p1[lineCount] = line.to_f
    else
      @p2[lineCount] = line.to_f
    end
    lineCount += 1
  end

end

def doCombine
  @p1.each_with_index do |value, index|
    if (value.to_f < 0.80) && (value.to_f > 0.10) 
      if @p2[index] > 0.99 || @p2[index] < 0.01
        @p1[index] = @p2[index]
      end
    end
  end
end

def writeCombined
  File.open('decision_label_combined.txt', 'w') do |f|  
    # use "\n" for two lines of text  
    @p1.each do |line|
      f.puts line
    end
  end

end

### Execute ###

combine("./decision_label_lr.txt", "./decision_label_nb.txt")
system('./calc_auc ./true_label.txt ./decision_label_lr.txt')
system('./calc_auc ./true_label.txt ./decision_label_nb.txt')
system('./calc_auc ./true_label.txt ./decision_label_combined.txt')