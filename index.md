Spam-Filter
===========

My result of [Discovery Challenge 2006](http://www.ecmlpkdd2006.org/challenge.html), and also a project for CS 559 Machine Learning @ Stevens 2013 Fall.

I implemented two basic machine learning technologies learned from the class: __Naive Bayes__ and __Logistic Regression__. And made some improvement based on practical implementation. Another improvement I have used is Self-Learning which augments the evaluation data on training set.

Through about two weeks effort, I have achieved the Average AUC as 0.955191 witout enlarge the Self-Learning process. This is higher than the 1st ranked teams at Challenge of that time. They have further achieved higher AUC results after the challenge, the highest one is above 0.98.

## Bayesian Filter 

bayesianFiltering.rb is my implementation of Bayesian Filter. 

The basic idea is learned from [A PLAN FOR SPAM](http://www.paulgraham.com/spam.html) by Paul Graham & [Ruan Yi-feng's Chinese translation version](http://www.ruanyifeng.com/blog/2011/08/bayesian_inference_part_two.html). I also have made a bit of improvement by taking frequency into consideration.

## Logistic Regression Filter

logisticRegressionFilter.rb is my implementation of Logistic Regression Filter.

The basic idea is learned form [Online discriminative spam filter training](http://www.ceas.cc/2006/22.pdf) by Joshua Goodman & Wen-tau Yih in [CEAS 2006](http://www.ceas.cc/2006/).
I have improved on it by adding TF-IDF into calculation of weights vector. I have made three attempts on this improvement. The first two were learned from some profressional paper, which had not worked weel. And I got my third appempt inspired by the concepts and reasoning from the first two attempts.

## Self-Learning

It was concident that I used the same term "Self-Learning" as the same as what is called in Machine Learning Techniques. And this is just a simply version among many complicated Self-Learning algorithms. However, my idea works fine and is reasonable in Spam Filtering field.

## ROC Cruve Drawing 

I found a powerful tool __ruby-plot__, "./roc-plot/svg_roc_plot.rb", which is an open source program to draw curves written by Ruby. The authoer is Vorgrimmler from University of Freiburg, Germany.

I have also wirte a small scripts "./roc-plot/draw_roc.rb" to convert <i>probability prediction file & labeld data</i> into two files: X-axis.txt is the false-positive-rate, Y-axis is the true-positive-rate.



Thanks to my teammate Hang Zhang, who has helped in ROC theory and Logistic Regression part during the project.

More detailed project information could be found at "./presentation/" folder:

[Project Slide Show](https://github.com/shohoku11wrj/Spam-Filter/blob/master/presentation/SpamFilter.pptx)

[Project Report](https://github.com/shohoku11wrj/Spam-Filter/blob/master/presentation/Project_Report.pdf)

