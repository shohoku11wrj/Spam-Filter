#!/usr/bin/ruby

# The emails are in a bag-of-words vector space representation. 
# Attributes are the term frequencies of the words. 
# We removed words with less than four counts in the data set resulting
# in a dictionary size of about 150,000 words. 
# The data set files are in the sparse data format used by SVMlight. 
# Each line represents one email, the first token in each line is 
# the class label (+1=spam; -1=non-spam; 0=unlabeled-evaluation-data). 
# The tokens following the label information are pairs of word IDs and 
# term frequencies in ascending order of the word IDs.

=begin
simple statistic
=end
    @correct = 0
    @wrong = 0
    @tp = 0
    @fp = 0
    @tn = 0
    @fn = 0

=begin
variables
=end
    # training
    @spamNo = 0 # count # for spam mails
    @nonSpamNo = 0 # count # for nonspam mails
    @unlabeled = 0 # count # for unlabeled mails
    @uncertain = 0 # count # for uncertained mails while evaluating, which below learn_boundary
    # occurance: NOT take considersion into frequency, just +1 or 0
    @spam = Array.new(210000){0} # count occurance of each word in spams
    @nonspam = Array.new(210000){0} # count occurance of each word in nonspams
    # evaluation
    @verify = nil # true label of each mail
    @posterior = nil # probability of being a spam for each mail

=begin
parameter tuning
=end
    @occur_rate_one_side = 0.0001 # only occur in other Class, then assume has a minimum rate in this Class
    @min_freq = 1 # I only consider words that occur more than five times in total 
                  # (actually, because of the doubling, 
                  # occurring three times in nonspam mail would be enough).
    @max_freq = 4 # if the log(freq) is too big, this word will not be considered
    @PE_NO = 9 # how many words should be taken into calculation of prior
    # 5:0.907,0.952 , 3:0.834,0.947, 10:0.895,0.950 , 7:0.905,0.952 , 
    # 15:0.889683,0.947364
    @learn_boundary = 0.49999999999 # SELF-CONFIDENCE,
                           # for augment learning when evaluating,
                           # the learning process should be triggered when the 
                           # evaluate @P of this mail is beyond this (boundary +-0.5)
    @enlarge = 1 # enlarge the influence of trained evaluation data

def clearTrain  

    @spamNo = 0 # count # for spam mails
    @nonSpamNo = 0 # count # for nonspam mails
    @unlabeled = 0 # count # for unlabeled mails
    @uncertain = 0
    # occurance: NOT take considersion into frequency, just +1 or 0
    @spam = Array.new(210000){0} # count occurance of each word in spams
    @nonspam = Array.new(210000){0} # count occurance of each word in nonspams

end

def train(filename, tune)

    line_count = File.foreach(filename).inject(0) {|c, line| c+1}
    current_line = 0

    File.open(filename, "r").each_line do |line|
        if tune == false || (tune == true && current_line < line_count / 2) # evaluate self by divide 2
=begin
likelihood
=end
        calculate_likelihood(line)
        end  #end if current_line <= 2000

        current_line += 1
    end


    puts "end training"

    puts "Count of spam mail: #{@spamNo}"
    puts "Count of health mail: #{@nonSpamNo}"
    puts "Count of unlabeled mail: #{@unlabeled}"

end

def calculate_likelihood(line)
    words = Array.new()
    words = line.split(" ")
    if words[0] == '1' then
        @spamNo += 1
        words[1..-1].each do |word|
            @index = word.split(":").first.to_i
            if word.split(":").last.to_i >= @min_freq then
=begin
Consider the frequency.
1) spam would add a pile of normal words 
to make the total Bayes Combination more healthy
2) Although 1) can be avoided by setting the limit @PE_NO,
but I also want those purposely additional words not been considered
=end
                # Why 1?
                # Cause if a certain mail has too much interesting words freq,
                # that mail would affect the total probability too much.
=begin
Basic NB, freq = 1   
=end
                freq = Math.log(word.split(":").last.to_i,2).to_i + 1
                # tune label: 4, tune u00: 1, if tune +-> train data, 8
                if freq > @max_freq
                    freq = 0
                else
                    @spam[@index] += freq
                end
                                    #word.split(":").last.to_i
                                    # this is a simplified version
            end
            # end
        end
    elsif words[0] == '-1' then
        @nonSpamNo += 1
        words[1..-1].each do |word|
            @index = word.split(":").first.to_i
            if word.split(":").last.to_i >= @min_freq then
                # Why "freq" is considered different from spam?
                # Because only the spam would intently spoof some nonspam words
                freq = 1 #Math.log(word.split(":").last.to_i,5).to_i / 2 + 1
                @nonspam[@index] += freq
                                    #word.split(":").last.to_i
                                    # this is a simplified version
            end
            # end
        end
    else
        # unlabeled
        @unlabeled += 1
    end
end


=begin
evaluate
=end
def evaluate(evaluateFileName, tune, augment)
    line_count = File.foreach(evaluateFileName).inject(0) {|c, line| c+1}
    # line_count = 2000
    if tune == true
        @verify = Array.new(line_count / 2){0} # true label of each mail
        @posterior = Array.new(line_count / 2){0.00}
    else
        @verify = Array.new(line_count){0} # true label of each mail
        @posterior = Array.new(line_count){0.00}
    end

    @correct = 0
    @wrong = 0
    @tp = 0
    @fp = 0
    @tn = 0
    @fn = 0

    lineNo = 0

    File.open(evaluateFileName, "r").each_line do |line|
        if tune == true
            if lineNo > line_count / 2 - 1 # evaluate self by divide 2
                lineNo -= line_count / 2 - 1 # change index<--lineNo from 0 to 1999
                    # calculate @posterior & remember true label in @verify
                    calculate_posterior(lineNo, line, augment)

                lineNo += line_count / 2 - 1
            end #end if lineNo > 2000
        else
            calculate_posterior(lineNo, line, augment)
        end
            
        lineNo += 1
        # end

        # current_line += 1
    end

end

def calculate_posterior (lineNo, line, augment)
    words = Array.new()
    words = line.split(" ")
    @verify[lineNo] = words[0]

    @PSW = Array.new(words.length - 1){0.00}
    words[1..-1].each_with_index.map do |word, index|
        @index = word.split(":").first.to_i
        # P(S|W) = P(W|S)*P(S) / ( P(W|S)*P(S) + P(W|H)*P(H) ) 
        if @spam[@index] == 0 && @nonspam[@index] == 0 then
            @PSW[index] = 0.4
        else
            @PWS = (@spam[@index] == 0? @occur_rate_one_side : @spam[@index].to_f / @spamNo)
            @PWH = (@nonspam[@index] == 0? @occur_rate_one_side : @nonspam[@index].to_f / @nonSpamNo)
            @PSW[index] = @PWS / (@PWS + @PWH)
            # if (@spam[@index] < 10 && @nonspam[@index] == 0)
            #     @PSW[index] = 0.9999
            # elsif (@nonspam[@index] < 10 && @spam[@index] == 0)
            #     @PSW[index] = 0.0001
            # end
        end
    end

    # P = P1P2…P15 / P1P2…P15 + (1-P1)(1-P2)…(1-P15)
    # @PSW.sort! {|x,y| y <=> x }
=begin
Important! Interesting words:
Just consider the top 15 ranked PSW, whose absolute values are far from 0.5.
=end
    @PSW.sort_by! {|psw| (psw - 0.5).abs}
    @PSW.reverse!

    @PE1 = 1 # P(E1) = P(S|W1) * P(S|W2) * P(S)
    @PE2 = 1 # (1 - P(S|W1)) * (1 - P(S|W2)) * (1 - P(S))
    # if lineNo == 1000 || lineNo == 999 then
    #     @PSW.each do |psw|
    #         printf("%1.2f ", psw)
    #     end
    #     puts " "
    # end
    @PSW.each_with_index do |psw, id|
        if id < @PE_NO then
            @PE1 *= psw
            @PE2 *= (1 - psw)
        else
            break
        end
    end

    @P = @PE1 / (@PE1 + @PE2)
    @posterior[lineNo] = @P
    if @P < 0.9 then
        if words[0].to_i == -1 then
            @correct += 1
            @tn += 1
        else
            @wrong += 1
            @fn += 1
        end
    else
        if words[0].to_i == 1 then
            @correct += 1
            @tp += 1
        else
            @wrong += 1
            @fp += 1
        end
    end


=begin
    Continue learning while evaluating
=end
    if augment == true # learning while evaluating
        @uncertain = 0
        # there is a parameter here, for learning boundary of @P
        if @P >= 0.5 + @learn_boundary  # learn_boundary
            @spamNo += 1 * @enlarge
            words[1..-1].each do |word|
                @index = word.split(":").first.to_i
                if word.split(":").last.to_i >= @min_freq then

                    freq = (Math.log(word.split(":").last.to_i,2).to_i + 1) * @enlarge
                    if freq > @max_freq * @enlarge
                        freq = 0
                    else
                        @spam[@index] += freq
                    end
                end
            end
        elsif @P <= 0.5 - @learn_boundary
            @nonSpamNo += 1 * @enlarge
            words[1..-1].each do |word|
                @index = word.split(":").first.to_i
                if word.split(":").last.to_i >= @min_freq then
                    freq = 1 * @enlarge #Math.log(word.split(":").last.to_i,5).to_i / 2 + 1
                    @nonspam[@index] += freq
                end
            end
        else
            @uncertain += 1
        end
    end

end

def accuracy

    @Accuracy = 0.0

    @Accuracy = @correct.to_f * 100 / (@correct + @wrong)

    puts "Count of evaluate uncertain: #{@uncertain}"
    puts "fp: #{@fp} , fn: #{@fn} , tp: #{@tp} , tn: #{@tn}"
    puts "Count of evaluate wrong: #{@wrong}"
    puts "Count of evaluate correct: #{@correct}"
    puts "Simple Accuracy: #{@Accuracy}%"

    File.open('true_label.txt', 'w') do |f1|  
      # use "\n" for two lines of text  
      @verify.each do |line|
        f1.puts line
      end
    end

    File.open('decision_label.txt', 'w') do |f2|  
      # use "\n" for two lines of text  
      @posterior.each do |line|
        f2.puts line
      end
    end

    r = `./calc_auc ./true_label.txt ./decision_label.txt`
    puts r
    return r.to_s
end

############################# OUTPUT RESULT #############################

def testFilter

    task_a_prefix = "./SpamFilterData/data_task_a/data_task_a/"
    evaluate_a_prefix = "./SpamFilterData/evaluation_data_labeled/task_a_lab/"

    puts "           --- tune ---"
    clearTrain()
    # The tuning data can be used for parameter tuning 
    # but can not be used to augment the training data 
    # because the word/feature IDs (the dictionary) of the tuning data 
    # differ from the training/evaluation data.
    # u00's parameters
    @occur_rate_one_side = 0.0006
    @PE_NO = 7
    @learn_boundary = 0.4999999999
    train(task_a_prefix + "task_a_u00_tune.tf", true) #task_a_labeled_tune
    evaluate(task_a_prefix + "task_a_u00_tune.tf", true, true) #task_a_u00_tune
    r1 = accuracy().gsub("\n", "")



    puts "           --- train ---"
    clearTrain()
    train(task_a_prefix + "task_a_labeled_train.tf", false)

    # puts "           --- cheat ---"
    # evaluate(task_a_prefix + "task_a_labeled_tune.tf")
    # accuracy()


    puts "           --- evaluate u01 ---"
    evaluate(evaluate_a_prefix + "task_a_u01_eval_lab.tf", false, true)
    r2 = accuracy().gsub("\n", "")

    puts "           --- evaluate u02 ---"
    evaluate(evaluate_a_prefix + "task_a_u02_eval_lab.tf", false, true)
    r2 = accuracy().gsub("\n", "")

    puts "           --- evaluate u00 ---"
    # @occur_rate_one_side = 0.0006
    # @PE_NO = 7
    # @learn_boundary = 0.4999999999
    evaluate(evaluate_a_prefix + "task_a_u00_eval_lab.tf", false, true)
    r2 = accuracy().gsub("\n", "")

    # ##### NOT allowed!! Do not add tune_data on train_data #####
    # train(task_a_prefix + "task_a_u00_tune.tf", false)
    # evaluate(evaluate_a_prefix + "task_a_u00_eval_lab.tf", false)
    # r2 = accuracy().gsub("\n", "")

    # return (r1.to_s + "," + r2.to_s)
end

@occur_rate_one_side = 0.0001
@min_freq = 1 # do not iterate
@PE_NO = 9
#90: freq > 4
@learn_boundary = 0.49999999999
@enlarge = 20

testFilter();

################## PARAMETER TUNING LOOP ##################

# max_auc = 0.0
# max_PE_NO = 0
# max_rate = 0.0

#  # for u00
# @occur_rate_one_side = 0.0001
# @learn_boundary = 0.49999999999

# result = Hash.new
# (11..11).step(1) {
#   |pn|
#   @PE_NO = pn
#   (1..1).step(1) { |o|
#     @enlarge = o
#     puts "\n==> limit of PE_NO: #{@PE_NO} , enlarge: #{@enlarge}"
#     result[@PE_NO.to_s + "," + @enlarge.to_s] = testFilter()
#     if result[@PE_NO.to_s + "," + @enlarge.to_s].split(",").last.split(" ").last.to_f > max_auc
#         max_auc = result[@PE_NO.to_s + "," + @enlarge.to_s].split(",").last.split(" ").last.to_f
#         max_PE_NO = @PE_NO
#         max_rate = @enlarge
#     end
#   }


# #   (0.0001..0.001).step(0.0001) { |o|
# #     @occur_rate_one_side = o
# #     puts "\n==> limit of PE_NO: #{@PE_NO} , occur_rate_one_side: #{@occur_rate_one_side}"
# #     result[@PE_NO.to_s + "," + @occur_rate_one_side.to_s] = testFilter()
# #     if result[@PE_NO.to_s + "," + @occur_rate_one_side.to_s].split(",").last.split(" ").last.to_f > max_auc
# #         max_auc = result[@PE_NO.to_s + "," + @occur_rate_one_side.to_s].split(",").last.split(" ").last.to_f
# #         max_PE_NO = @PE_NO
# #         max_rate = @occur_rate_one_side
# #     end
# #   }


# #   # boundarryy = [4.5,4.9,4.99,4.999,0.499999999,0.4999999999,0.49999999999,0.499999999999,0.4999999999999,5.0]
# #   # boundarryy.each do |b|
# #   #   @learn_boundary = b
# #   #   puts "\n==> limit of PE_NO: #{@PE_NO} , learn_boundary: #{@learn_boundary}"
# #   #   result[@PE_NO.to_s + "," + @learn_boundary.to_s] = testFilter()
# #   #   if result[@PE_NO.to_s + "," + @learn_boundary.to_s].split(",").last.split(" ").last.to_f > max_auc
# #   #       max_auc = result[@PE_NO.to_s + "," + @learn_boundary.to_s].split(",").last.split(" ").last.to_f
# #   #       max_PE_NO = @PE_NO
# #   #       max_rate = @learn_boundary
# #   #   end
# #   # end

# }

# puts "\n########################\n"
# result.each do |k,v|
#     puts ""
#     printf("%-20s: %-20s\n",k,v)
# end

# puts "max auc: #{max_auc}, max_PE_NO: #{max_PE_NO}, max_rate: #{max_rate}"