#if !defined( DATA_IO )
#define DATA_IO

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <ctype.h>
#include "params.h"



#define MAX_ATTRIBS_PER_VIEW 1000000

struct Example{
  long int nr;
  double cost;
  int label,trueLabel;
  int holdout,unlabeled;
  struct Attributes **View;
};

struct Set{
  struct Example **example;
  long int N;
  long int num_labeled, num_unlabeled, num_positive, num_negative, num_tune;
  int maxId;
};

struct HistListElem
{
  float threshold;
  int num;
  struct HistListElem *Next;
};

struct HistList
{
  int accP;
  int accN;
  int totalP;
  struct HistListElem *pos;
  struct HistListElem *neg;
};




struct AttribEl{
	double val;
	long int ID;
	struct AttribEl *Next;
};


struct Attributes{
	long int total;
	long int dim;
	struct AttribEl *begin;
};


struct ListEl{

  float threshold;
  int num;
  struct ListEl *Next;

};


struct List {

  int totalP;
  struct ListEl *begin;

};


struct HistList *NewHistList(void);
void DeleteHistList (struct HistList *h);
float PrintROCcurve (FILE *fp, struct HistList *h, int pool);
void InsertPos(struct HistList *h, float thresh);
void InsertNeg(struct HistList *h, float thresh);
int AccHistListElem (struct HistListElem *h);
struct Example *parse_svmlight(char *line, struct PARAMS *P);
struct Set *load_svmlight_name(struct PARAMS *P, char *fname);
void nol_ll(char* file, long int *nol, long int *wol, long int *ll);
void halt(char *s);


struct AttribEl *NewAttrib(double value,long int nID);
struct AttribEl *InsertAttrib(struct AttribEl *A, double value, long int nID);
struct Attributes *NewAttributes(void);
void InsertAttributes(struct Attributes *A, long int nID, double value);
float GetThreshold(struct List *h,int number);
struct ListEl *NewListEl(float thresh);
struct ListEl *InsertListEl (struct ListEl *h, float thresh);
void DeleteListEl (struct ListEl *h);
struct List *NewList(void);
void DeleteList (struct List *h);
void PrintList(struct List *h, char *file);
void PrintListEl (struct ListEl *h);
int AccListEl (struct ListEl *h);
void Insert(struct List *h, float thresh);
int NumList(struct List *h);

int PrintListNr(struct List *h, char *file, int start);



#endif
