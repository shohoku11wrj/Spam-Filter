----------------
Readme: calc_auc
----------------

The program calc_auc calculates the AUC value, which is the evaluation criterion 
for the 2006 ECML-PKDD Discovery Challenge.

The AUC value is the area under the ROC curve (Receiver Operating Characteristic 
curve). A ROC curve is a plot of true positive rate vs. false positive rate 
as the prediction threshold sweeps through all the possible values. The area 
under this curve has the nice property that it specifies the probability that, 
when we draw one positive and one negative example at random, the decision function 
assigns a higher value to the positive than to the negative example.

You can use this program to tune parameters of your algorithm on the provided tuning data.


COMPILATION:

The program compiles and runs under linux, solaris or cygwin with gcc installed,
for compiling call:
make calc_auc


USAGE:
calc_auc <data_file_with_labels> <file_with_decision_function_values>


EXPLANATION:

<data_file_with_labels> is the data file of the tuning data that contains the true class labels as first token in each line. Each line represents one single email. The features after the label information will be ignored. For the Discovery Challenge the three tuning inboxes can be used as data file:
task_a_u00_tune.tf
task_b_u00_tune.tf
task_b_u01_tune.tf

<file_with_decision_function_values> is a list of decision function values, one in each line. The number of lines must be the same as in the data file. Each line in this file corresponds to the same line/email in the data file. The decision function values are the output of your spam classifier. The higher a decision function value, the higher is the likelihood of the email to be spam.


EXAMPLE:

There are two sample files included,
sample_datafile.tf and sample_decision_function_values.txt.

You can test the program with the following call:
calc_auc sample_datafile.tf sample_decision_function_values.txt

The output should be:
auc: 0.878788



If you have questions or comments please let us know:

Steffen Bickel (bickel@informatik.hu-berlin.de)
ECML-PKDD Discovery Challenge Chair 2006
