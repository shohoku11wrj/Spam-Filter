#!/usr/bin/ruby

# Simple linear model, weights for the model are trained using 
# online gradient descent of a logistic regression model.
#
# We will learn a set of weights for each word
#
# When a new message arrives, we find this list of words, 
# and sum the weights associated with those words. In mathematical terms, 
# we will write w • x. In this notation, w is a vector of weights, 
# and x is a vector of 1’s and 0’s, 
# with a 1 in the position corresponding to each word that was found in the message. 
# The notation w • x simply means to take the sum of weights associated 
# with each of these words. We then convert this sum of weights to a probability, 
# using the“logistic” function,
#     P (Y = spam|x) = exp(w • x) / (1 + exp(w • x))

=begin
simple statistic
=end
@correct = 0
@wrong = 0
@trueLabel = nil # true label of each mail
@decisionLabel = nil # probability of being a spam for each mail

=begin
  variables 
=end

# learning rate, which makes sure that the step taken 
# in the direction of the gradient is not too large.
@rate = 0.02
@learn_boundary = 4.5

# w is a vector of weights
@weight = Array.new(210000){0.0}
@idf_min = 0.1
# x is a vector of 1’s and 0’s, with a 1 in the position corresponding to each word 

#############################################################
# TF-IDF
# TF -- term frequence 
#    = frequence of word in doc / total number of word in doc
# or = frequence of word in doc / max frequence of a word in doc
# IDF -- Inverse Document Frequence 
#     = log( corpus size / (number of docs including this word + 1) )

# TF-IDF = TF * IDF
# for each mail, there will be a TF for each word
# for each word, the IDF is consistent
# for each mail, there will be a TD-IDF for each word, 
#   we can order the TD-IDF by DESC, the former preceding ones are key words of this doc

# improved TF-IDF, conside the usability of each word depends on its difference
#   in spams and nonspams
# TF = log(|freq_i1 - freq_i2| + 1) + 1
#   , where freq_i1 is frequency of word t_i appears in spams
#          freq_i2 is frequency of word t_i appears in nonspams
# IDF = |log(n/n_i) - log(n/!n_i)|
#   , where n is corpus size, n_i is spams# including word t_i
#                             !n_i is nonspams# including word t_i
# usage of improved TF-IDF
# according to this new weight(t_i), sort_by DESC and pick limited # since begining
# those words are called better featured words, in order to improve the accuracy.

@corpus = 0
@word_in_doc = Array.new(210000) { 0 } # number of docs including this word
@freq1 = Array.new(210000) { 0 } # frequency of word t_i appears in spams
@freq2 = Array.new(210000) { 0 } # frequency of word t_i appears in spams
@n1 = Array.new(210000) { 0 } # number of spams including word t_i
@n2 = Array.new(210000) { 0 } # number of nonspams including word t_i
@tf = Array.new(210000) { 0.0 }
@idf = Array.new(210000) { 0.0 }
@tfidf = Array.new(210000) { 0.0 }
@pick_limit = 20

def tf_idf(filename, tune, tfidf)

  @word_in_doc = Array.new(210000) { 0 } 
  @freq1 = Array.new(210000) { 0 } 
  @freq2 = Array.new(210000) { 0 } 
  @n1 = Array.new(210000) { 0 } 
  @n2 = Array.new(210000) { 0 } 
  @tf = Array.new(210000) { 0.0 }
  @idf = Array.new(210000) { 0.0 }
  @tfidf = Array.new(210000) { 0.0 }

  @corpus = File.foreach(filename).inject(0) {|c, line| c+1}
  if tune == true       # then divide the tune.txt into 2 partition
    @corpus = @corpus / 2 # 1st partition for training, 2nd partition for parameter tuning
  end


  if tfidf == true

    lineNo = 0
    File.open(filename, "r").each_line do |line|
      if tune == false || (tune == true && lineNo <= @corpus) 
        # if tune==true, then just train then 1st partition
        words = Array.new()
        words = line.split(" ")
        y = words[0].to_i

        if y == 1
          words[1..-1].each do |word| # word(index:frequence) has the index of itself in @weight
            # @word_in_doc[word.split(":").first.to_i] += 1
            ## or
            ## improved statist see below
            @freq1[word.split(":").first.to_i] += word.split(":").last.to_i
            @n1[word.split(":").first.to_i] += 1
          end # end words loop
        else
          words[1..-1].each do |word|
            # @word_in_doc[word.split(":").first.to_i] += 1
            ## or
            ## improved statist see below
            @freq2[word.split(":").first.to_i] += word.split(":").last.to_i
            @n2[word.split(":").first.to_i] += 1
          end # end words loop
        end

      end # end if tune == false
      lineNo += 1
    end


    # @idf.each_with_index do |value, index|
    #   @idf[index] = Math.log(@corpus.to_f / (@word_in_doc[index] + 1) )
    # end
    ## or,
    ## improved statist see below
    (1..209999).step(1) { # word=210000 does NOT existed
      |id| 
      # begin
        @tf[id] = Math.log((@freq1[id] - @freq2[id]).to_f.abs + 1) + 1
        @idf[id] = (Math.log(@corpus.to_f / (@n1[id] + @idf_min) ) - Math.log(@corpus.to_f / (@n2[id] + @idf_min) ) ).abs
        @tfidf[id] = @tf[id] * @idf[id]
      # rescue Exception => e
      #   puts id
      #   $stderr.print "IO failed: " + e.to_s
      #   raise
      # end
    }

  end # end if tfidf == true

end


def LRtraining(filename, tune, tfidf)

  @weight = Array.new(210000){0.0}

  line_count = File.foreach(filename).inject(0) {|c, line| c+1}
  if tune == true
    line_count = line_count / 2
  end

  lineNo = 0
  File.open(filename, "r").each_line do |line|
    if tune == false || (tune == true && lineNo <= line_count)

      p = 0.5 # probability of each email

      words = Array.new()
      words = line.split(" ")
      y = words[0].to_i

      w_x = 0.0 #@weight[0]

      # calculate w*x for each mail
      if tfidf == true
        ## simple TF-IDF
        # tfidf_ = Hash.new
        # tf_ = Hash.new
        # max_freq = 0
        # words_count = 0
        # tfidf_total = 0.0

        # words[1..-1].each do |word|
        #   tf_[word.split(":").first.to_i] = word.split(":").last.to_i
        #   words_count += word.split(":").last.to_i
        #   if word.split(":").last.to_i > max_freq
        #     max_freq = word.split(":").last.to_f
        #   end
        # end

        # words[1..-1].each do |word|
        #   tf_[word.split(":").first.to_i] = tf_[word.split(":").first.to_i].to_f #/ max_freq
        # end

        # words[1..-1].each do |word|
        #   tfidf_[word.split(":").first.to_i] = tf_[word.split(":").first.to_i].to_f * @idf[word.split(":").first.to_i]
        #   # if lineNo == 0
        #   #   puts tfidf_[word.split(":").first.to_i]
        #   # end

        #   tfidf_total += tfidf_[word.split(":").first.to_i] * tfidf_[word.split(":").first.to_i]
        # end

        # tfidf_total = Math.sqrt(tfidf_total.to_f)

        # words[1..-1].each do |word| # word(index:frequence) has the index of itself in @weight
        #   w_x += @weight[word.split(":").first.to_i] * tfidf_[word.split(":").first.to_i] / tfidf_total
        # end

        ## or,
        ## improved TF-IDF
        tfidf_total = 0.0
        max_freq = 0.0
        tfidf_ = Hash.new(0.0)
        words[1..-1].each do |word|
          tfidf_[word.split(":").first.to_i] = @tfidf[word.split(":").first.to_i]
          tfidf_total += @tfidf[word.split(":").first.to_i] * @tfidf[word.split(":").first.to_i]
          if @tf[word.split(":").first.to_i] > max_freq
            max_freq = @tf[word.split(":").first.to_i]
          end
          ## or simple max frequency
          # if Math.log(word.split(":").last.to_i, 2) + 1 > max_freq
          #   max_freq = Math.log(word.split(":").last.to_i, 2) + 1
          # end
        end

        tfidf_total = Math.sqrt(tfidf_total.to_f)

        tfidf_ = tfidf_.sort_by {|k,v| v}.reverse
        
        # id = 0
        tfidf_.each do |key, value|
          # if id < @pick_limit
            w_x += @weight[key] * value / max_freq
          # end
          # id += 1
        end

      else # else if tfidf == false
        words[1..-1].each do |word| # word(index:frequence) has the index of itself in @weight
          w_x += @weight[word.split(":").first.to_i]
        end # end words loop

      end # end if tfidf


=begin
  Now we calculate the w*x for each mail
=end
      exp_w_x = Math.exp(w_x.to_f)
      p = exp_w_x / (1 + exp_w_x)

      if y == 1 # Spam label is 1
        # @weight[0] += (1 - p) * @rate # ? need w_0 ?
        words[1..-1].each do |word|
          # formular: w = w + (1 − p) × xi × rate
          # so, xi=1 --> w = w + (1 − p) × rate ; xi=0 --> w = w
          # and, in this loop, all xi == 1
          @weight[word.split(":").first.to_i] += (1 - p) * @rate
        end
      else # y == -1
        # @weight[0] += (0 - p) * @rate # ? need w_0 ?
        words[1..-1].each do |word|
          # formular: w = w − p × xi × rate
          # so, xi=1 --> w = w + (0 − p) × rate ; xi=0 --> w = w
          # and, in this loop, all xi == 1
          @weight[word.split(":").first.to_i] += (0 - p) * @rate
        end
      end

    end # end if tune == false
    lineNo += 1
  end

end

def evaluate(filename, tune, tfidf, augment)

  @correct = 0
  @wrong = 0

  line_count = File.foreach(filename).inject(0) {|c, line| c+1}

  if tune == true
    line_count = line_count / 2
    # true label of each mail
    @trueLabel = Array.new(line_count / 2){0}
    # probability of being a spam for each mail
    @decisionLabel = Array.new(line_count / 2){0.00}
  else
    @trueLabel = Array.new(line_count){0} 
    @decisionLabel = Array.new(line_count){0.00} 
  end

  lineNo = 0
  File.open(filename, "r").each_line do |line|

    if tune == false || (tune == true && lineNo >= line_count)
      p = 0.5 # initial probability of each email

      words = Array.new()
      words = line.split(" ")
      y = words[0].to_i

      w_x = 0.0 #@weight[0]

      # calculate w*x for each mail
      if tfidf == true
        ## simple TF-IDF
        # tfidf_ = Hash.new
        # tf_ = Hash.new
        # max_freq = 0
        # words_count = 0
        # tfidf_total = 0.0

        # words[1..-1].each do |word|
        #   tf_[word.split(":").first.to_i] = word.split(":").last.to_i
        #   words_count += word.split(":").last.to_i
        #   if word.split(":").last.to_i > max_freq
        #     max_freq = word.split(":").last.to_f
        #   end
        # end

        # words[1..-1].each do |word|
        #   tf_[word.split(":").first.to_i] = tf_[word.split(":").first.to_i].to_f / max_freq
        # end

        # words[1..-1].each do |word|
        #   tfidf_[word.split(":").first.to_i] = tf_[word.split(":").first.to_i].to_f * @idf[word.split(":").first.to_i]
        #   tfidf_total += tfidf_[word.split(":").first.to_i]
        # end

        # # sort TF-IDF by DESC
        # tfidf_ = tfidf_.sort_by {|k,v| v}.reverse

        # id = 0
        # tfidf_.each do |key, value|
        #   if id < 30
        #     if lineNo == 1
        #       puts tfidf_[id][1]
        #     end
        #     w_x += @weight[key]
        #   end
        #   id += 1
        # end

        # words[1..-1].each do |word| # word(index:frequence) has the index of itself in @weight
        #   # w_x += @weight[word.split(":").first.to_i] * tfidf_[word.split(":").first.to_i] / tfidf_total
        # end

        ## or,
        ## improved TF-IDF

        tfidf_total = 0.0
        max_freq = 0.0
        tfidf_ = Hash.new(0.0)
        words[1..-1].each do |word|
          tfidf_[word.split(":").first.to_i] = @tfidf[word.split(":").first.to_i]
          tfidf_total += @tfidf[word.split(":").first.to_i] * @tfidf[word.split(":").first.to_i]

          if @tf[word.split(":").first.to_i] > max_freq
            max_freq = @tf[word.split(":").first.to_i]
          end
          ## or simple max frequency
          # if Math.log(word.split(":").last.to_i, 2) + 1 > max_freq
          #   max_freq = Math.log(word.split(":").last.to_i, 2) + 1
          # end
        end

        tfidf_total = Math.sqrt(tfidf_total.to_f)

        tfidf_ = tfidf_.sort_by {|k,v| (v * @weight[k]).abs }.reverse
        
        id = 0
        tfidf_.each do |key, value|
          if id < @pick_limit
            # if lineNo == 0
            #   puts @weight[key] * value / max_freq
            # end
            w_x += @weight[key] * value / max_freq
          end
          id += 1
        end

      else
        words[1..-1].each do |word| # word(index:frequence) has the index of itself in @weight
          w_x += @weight[word.split(":").first.to_i]
        end # end words loop

      end # end if tfidf

      exp_w_x = Math.exp(w_x)
      p = exp_w_x / (1 + exp_w_x)
        
      # predict
      if tune == true
        lineNo -= line_count
      end

      @trueLabel[lineNo] = y
      @decisionLabel[lineNo] = p
      if y == 1
        if p > 0.5
          @correct += 1
        else
          @wrong += 1
        end
      else
        if p > 0.5
          @wrong += 1
        else
          @correct += 1
        end
      end

      if tune == true
        lineNo += line_count
      end

=begin
  Continue learning while evaluating
=end
      if augment == true # learning while evaluating
        # TD-IDF SELF-LEARNING
        @corpus += 1
        if p >= 0.5 + @learn_boundary
          words[1..-1].each do |word| # word(index:frequence) has the index of itself in @weight
            # @word_in_doc[word.split(":").first.to_i] += 1
            ## or
            ## improved statist see below
            @freq1[word.split(":").first.to_i] += word.split(":").last.to_i
            @n1[word.split(":").first.to_i] += 1
          end # end words loop
        elsif p <= 0.5 - @learn_boundary
          words[1..-1].each do |word|
            # @word_in_doc[word.split(":").first.to_i] += 1
            ## or
            ## improved statist see below
            @freq2[word.split(":").first.to_i] += word.split(":").last.to_i
            @n2[word.split(":").first.to_i] += 1
          end # end words loop
        else
          # @uncertain += 1
        end

        if p >= 0.5 + @learn_boundary || p <= 0.5 + @learn_boundary
          (1..209999).step(1) { # word=210000 does NOT existed
            |id| 
              @tf[id] = Math.log((@freq1[id] - @freq2[id]).to_f.abs + 1) + 1
              @idf[id] = (Math.log(@corpus.to_f / (@n1[id] + @idf_min) ) - Math.log(@corpus.to_f / (@n2[id] + @idf_min) ) ).abs
              @tfidf[id] = @tf[id] * @idf[id]
          }
        end

        if lineNo % 100 == 0
          puts lineNo
        end

        # WEIGHT SELF-LEARNING
        if p >= 0.5 + @learn_boundary  # learn_boundary
          # @weight[0] += (1 - p) * @rate # ? need w_0 ?
          words[1..-1].each do |word|
            # formular: w = w + (1 − p) × xi × rate
            # so, xi=1 --> w = w + (1 − p) × rate ; xi=0 --> w = w
            # and, in this loop, all xi == 1
            @weight[word.split(":").first.to_i] += (1 - p) * @rate
          end
        elsif p <= 0.5 - @learn_boundary
          # @weight[0] += (0 - p) * @rate # ? need w_0 ?
          words[1..-1].each do |word|
            # formular: w = w − p × xi × rate
            # so, xi=1 --> w = w + (0 − p) × rate ; xi=0 --> w = w
            # and, in this loop, all xi == 1
            @weight[word.split(":").first.to_i] += (0 - p) * @rate
          end
        else
          # @uncertain += 1
        end
      end

    end # end if tune == false  
    lineNo += 1
  end # end of File.open

end

def accuracy

    @Accuracy = 0.0

    @Accuracy = @correct.to_f * 100 / (@correct + @wrong)

    puts "Count of evaluate wrong: #{@wrong}"
    puts "Count of evaluate correct: #{@correct}"
    puts "Simple Accuracy: #{@Accuracy}%"

    File.open('true_label.txt', 'w') do |f1|  
      # use "\n" for two lines of text  
      @trueLabel.each do |line|
        f1.puts line
      end
    end

    File.open('decision_label.txt', 'w') do |f2|  
      # use "\n" for two lines of text  
      @decisionLabel.each do |line|
        f2.puts line
      end
    end

  begin
    system('./calc_auc ./true_label.txt ./decision_label.txt')
  rescue Exception => e
    # nan error occurs when 0/0
    system.print e.to_s
  end
end

############################# OUTPUT RESULT #############################

def testStep
  task_a_prefix = "./SpamFilterData/data_task_a/data_task_a/"
  evaluate_a_prefix = "./SpamFilterData/evaluation_data_labeled/task_a_lab/"

  puts "             --- tune ---"
  tf_idf(task_a_prefix + "task_a_u00_tune.tf", true, true) #task_a_labeled_tune
  LRtraining(task_a_prefix + "task_a_u00_tune.tf", true, true)#task_a_u00_tune
  evaluate(task_a_prefix + "task_a_u00_tune.tf", true, true, false)
  accuracy()

  puts "             --- train ---"
  tf_idf(task_a_prefix + "task_a_labeled_train.tf", false, true)
  LRtraining(task_a_prefix + "task_a_labeled_train.tf", false, true)

  puts "             --- evaluate u00 ---"
  evaluate(evaluate_a_prefix + "task_a_u00_eval_lab.tf", false, true, false)
  accuracy()

  # puts "             --- evaluate u01 ---"
  # evaluate(evaluate_a_prefix + "task_a_u01_eval_lab.tf", false, true, false)
  # accuracy()

  # puts "             --- evaluate u02 ---"
  # evaluate(evaluate_a_prefix + "task_a_u02_eval_lab.tf", false, true, false)
  # accuracy()
end

################## PARAMETER TUNING LOOP ##################

# @pick_limit = 10000
# @rate = 0.02
# @idf_min = 0.1
# @learn_boundary = 0.4999999999

# u00
@pick_limit = 1000
@rate = 0.042
@idf_min = 0.05
@learn_boundary = 0.4999999999 #0.45

testStep()

# (1000..1000).step(50) {
#   |num|
#   @pick_limit = num
#   (0.042..0.042).step(0.005) {
#     |r|
#     @rate = r
#     (0.15..0.15).step(0.05) {
#       |m|
#       @idf_min = m
#       puts "==> #{@pick_limit}, #{@idf_min}, #{@rate}"
#       testStep()
#     }
#   }
#   puts "---------------------------------------------------------"
# }