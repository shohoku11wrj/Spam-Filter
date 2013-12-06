#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "dataIO.h"
#include "params.h"


int main(int argc, char **argv){

	struct Set *S;
	struct PARAMS P;
	FILE *fptr;
  double *cache;
  long int i;
  struct HistList *H;
  double val;
  int num;
  long int tp_,fp_,tn_,fn_;
  float tp,fp,tn,fn,accuracy;
  double auc;
	int cacheId;


	//inits
	P.numViews=1;
	P.verbose=0;
	P.partition=0;


	if(argc != 3) {
		printf("usage:\ncalc_auc <data_file_with_labels> <file_with_decision_function_values>\n");
		exit(1);
	}

	strcpy(P.inputFILE,argv[1]);
	strcpy(P.valuesFILE,argv[2]);

	S = load_svmlight_name(&P, P.inputFILE);


  fptr = fopen(P.valuesFILE, "r");
  if (!fptr) {
		printf("cannot open values file");
		exit(1);
	}

  cache=(double*)malloc(sizeof(double)*S->N);
  for(i=0;i<S->N;i++) {
		if(fscanf(fptr," %lf",&cache[i]) == EOF) {
			printf("error: values file does contain less entries than data file\n");
			exit(1);
		}
	}
	if(fscanf(fptr," %lf",&cache[i]) != EOF) {
		printf("error: values file does contain more entries than data file\n");
		exit(1);
	}
  fclose(fptr);


  tp_=fp_=tn_=fn_=0;
  H=NewHistList();

  auc=0;
  tp_=tn_=fn_=fp_=0;

	cacheId = 0;
	for(i=0;i<S->N;i++){
			val=0;
			num=0;
			val+=cache[cacheId];
			num++;

			val=val/num;

			if (val>=0){
				if (S->example[i]->trueLabel==+1){
					InsertPos(H,val);
					tp_++;
				}
				else {
					InsertNeg(H,val);
					fp_++;
				}
			}
			else if (S->example[i]->trueLabel==+1){
				InsertPos(H,val);
				fn_++;
			}
			else {
				InsertNeg(H,val);
				tn_++;
			}
			cacheId++;
	}

  accuracy=(float)(tp_+tn_)/(float)S->N;
  tp=(float)tp_/(float)S->N;
  fp=(float)fp_/(float)S->N;
  fn=(float)fn_/(float)S->N;
  tn=(float)tn_/(float)S->N;

  // accuracy
  //printf("acc: %f %f %f %f %f \n",accuracy,tp,fp,fn,tn);

  auc=PrintROCcurve(NULL,H,0);

  printf("auc: %f\n",auc);

  DeleteHistList(H);

	return 1;
}


