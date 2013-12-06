#include "dataIO.h"


struct Example *parse_svmlight(char* line, struct PARAMS *P){
  int label,i;
  long int nr,pos,id;
  double value,cost;
  int numread;
  char featurepair[1000],junk[1000];
  struct Example *E;

  E=(struct Example*)malloc(sizeof(struct Example));

  //initialise views
  E->View=(struct Attributes**)malloc(sizeof(struct Attributes));
  E->View[0]=NewAttributes();

  //read label
  if(sscanf(line,"%d",&label) == EOF) return(0);
  //set labels/cost
  E->trueLabel=E->label=label;
  E->unlabeled=label==0;
  E->cost=1;

  pos=0;
  while(isspace((int)line[pos]))pos++;
  while((!isspace((int)line[pos])) && line[pos]) pos++;
  while((numread=sscanf(line+pos,"%s",featurepair))!=EOF){
    //found a featurepair
    while(isspace((int)line[pos])) pos++;
    while((!isspace((int)line[pos])) && line[pos]) pos++;
    if(sscanf(featurepair,"cost:%lf%s",&cost,junk)==1){
      //read costs
      E->cost=cost;
    }
    else if(sscanf(featurepair,"%ld:%lf%s",&nr,&value,junk)==2){
      //found feature nr:value
      //printf("feature(%ld:%g)\n",nr,value);
      if(P->partition==0){
	InsertAttributes(E->View[0],nr,value);
      }
      else{

	  for(id=0;id<MAX_ATTRIBS_PER_VIEW;id++)if(P->part[0][id]==nr)break;
	  if(P->part[i][id]==nr)break;

	InsertAttributes(E->View[i],nr,value);

      }
    }
  }
  //extra example init
  E->holdout=0;
  return E;
}


struct Set *load_svmlight_name(struct PARAMS *P, char *fname){

	FILE *fp;
	char *line;
	long int i,num_lines,num_attribs,ll,total;
	struct Set *S;
	ldiv_t tmp;
	int v;
	char *c_id;


	if(P->partition==1){
		P->part=(long int**)malloc(sizeof(long int)*P->numViews);
		for(v=0;v<P->numViews;v++)P->part[v]=(long int*)malloc(sizeof(long int)*MAX_ATTRIBS_PER_VIEW);
		for(v=0;v<P->numViews;v++)for(i=0;i<MAX_ATTRIBS_PER_VIEW;i++)P->part[v][i]=0;
		//read partition file
		nol_ll("partition.coem",&num_lines,&num_attribs,&ll);
		line=(char*)malloc(sizeof(char)*(2+ll));
		printf("reading partition.coem...views ");fflush(stdout);
		num_lines--;
		if(P->numViews!=num_lines)halt("are not corresponding!\n");
		fp=fopen("partition.coem","r");
		for(v=0;v<num_lines;v++){
			printf("[%d]",v);
			fgets(line,(int)ll+2,fp);
			c_id=strtok(line," ,");
			i=0;
			do{
				if(atol(c_id)!=0){
					P->part[v][i]=atol(c_id);
					//printf("(%ld)",P->part[v][i]);
					i++;
				}
			}while ((c_id=strtok(NULL,", "))!=0);
		}
		fclose(fp);
		free(line);
		printf("...done\n");
	}



	nol_ll(fname,&num_lines,&num_attribs,&ll);
	line=(char*)malloc(sizeof(char)*(ll+2));
	S=(struct Set*)malloc(sizeof(struct Set));
	S->maxId = 0;
	S->example=(struct Example**)malloc(sizeof(struct Example*)*num_lines);

	if (!(fp=fopen(fname,"r"))) halt("cannot open fv file");

	total=0;
	for(i=0;i<=num_lines;i++){
		if(fgets(line,(int)ll+2,fp)) {
			if (*line!='\n'){
				S->example[total]=parse_svmlight(line, P);
				if(S->example[total]->View[0]->dim > S->maxId)
					S->maxId = S->example[total]->View[0]->dim;
				S->example[total]->nr=total;
				total++;
			}
			tmp=ldiv(total,100);

			/*
			if (tmp.rem==0){
				printf("...");
				printf("%ld",total);
				fflush(stdout);
			}
			*/
		}
	}
	//if(tmp.rem!=0)printf("...%ld",total);
	//printf(" examples read.\n");
	fflush(stdout);
	S->N=total;
	free(line);
	fclose(fp);

	S->num_labeled = total;
	S->num_unlabeled=0;
	S->num_positive=0;
	S->num_negative=0;

	if(P->partition==1){
		//free mem
		for(v=0;v<P->numViews;v++)free(P->part[v]);
		free(P->part);
	}

	return S;
}

struct HistListElem *NewHistListElem(float thresh)
{
  struct HistListElem *h;

  h = (struct HistListElem *)malloc(sizeof (struct HistListElem));
  h->threshold = thresh;
  h->num = 1;
  h->Next = 0;
  return h;
}

void DeleteHistListElems (struct HistListElem *h)
{
  if (h->Next) DeleteHistListElems (h->Next);
  free (h);
}

struct HistListElem *InsertHistListElem (struct HistListElem *h, float thresh)
{
  struct HistListElem *nh;
  if (!h) return NewHistListElem (thresh);
  if (h && h->threshold > thresh) {
    h->Next = InsertHistListElem (h->Next, thresh);
    return h;
  }
  if (h && h->threshold == thresh) {
    h->num++;
    return h;
  } else {
    nh = NewHistListElem (thresh);
    nh->Next = h;
    return nh;
  }
}

struct HistList *NewHistList(void)
{
  struct HistList *h;

  h = (struct HistList *)malloc (sizeof (struct HistList));
  h->pos = h->neg = 0;
  h->accP = h->accN = h->totalP = 0;
  return h;
}

void DeleteHistList (struct HistList *h)
{
  if (h->pos) DeleteHistListElems (h->pos);
  if (h->neg) DeleteHistListElems (h->neg);
  free (h);
}

int AccHistListElem (struct HistListElem *h)
{
  if (!h) return 0;
  else return h->num + AccHistListElem (h->Next);
}

void InsertPos(struct HistList *h, float thresh)
{

  if (isnan(thresh)) halt ("nan error");
  h->pos = InsertHistListElem (h->pos, thresh);
}

void InsertNeg(struct HistList *h, float thresh)
{
  if (isnan(thresh)) halt ("nan error");
  h->neg = InsertHistListElem (h->neg, thresh);
}

float PrintROCcurve (FILE *fp, struct HistList *h, int pool)
{
  int truepos=0, falsepos=0, totalpos, totalneg, lastx=0, lasty=0;
  int areaupdated;
  struct HistListElem *n, *p;
  float area=.0, se, Q1, Q2;

  totalpos = AccHistListElem (h->pos);
  totalneg = AccHistListElem (h->neg);

  p = h->pos; n = h->neg;
  while (p || n) {
    if (p && n && p->threshold == n->threshold) {
      truepos += p->num;
      falsepos += n->num;
      p = p->Next;
      n = n->Next;
    }
    else if (!n || (p && p->threshold > n->threshold)) {
      truepos += p->num;
      p = p->Next;
    } else {
      falsepos += n->num;
      n = n->Next;
    }
    if (!totalneg || !totalpos) halt ("need both pos and neg examples");
    if (fp) fprintf(fp, "%g %g\n", (float)falsepos / (float)totalneg,
		    (float)truepos / (float)totalpos);
    if (lastx == falsepos) {
      lasty = truepos;
      areaupdated=0;
    }
    else {
      area += (float)(falsepos - lastx) * (float)(truepos + lasty) / 2.0;
      lastx = falsepos; lasty = truepos;
      areaupdated = 1;
    }
  }
  if (!areaupdated)
    area += (float)(falsepos - lastx) * (float)(truepos + lasty) / 2.0;

  area = area / (float)totalpos / (float)totalneg;

  Q1 = area / (2.0-area); Q2 = 2.0*area*area/(1.0+area);

  se = sqrt ((area * (1.0-area) + (totalpos-1)*(Q1-area*area)
	      + (totalneg-1)*(Q2-area*area)) / (float)(totalpos * totalneg));
  if (pool) printf("Pooled AUC = %g +- %g\n", area, se);
  return area;
}

void nol_ll(char *file, long int *nol, long int *wol, long int *ll) {
  FILE *fl;
  int ic;
  char c;
  long current_length,current_wol;

  if ((fl = fopen (file, "r")) == NULL)
  { perror (file); exit (1); }
  current_length=0;
  current_wol=0;
  (*ll)=0;
  (*nol)=1;
  (*wol)=0;
  while((ic=getc(fl)) != EOF) {
    c=(char)ic;
    current_length++;
    if(isspace((int)c)) {
      current_wol++;
    }
    if(c == '\n') {
      (*nol)++;
      if(current_length>(*ll)) {
	(*ll)=current_length;
      }
      if(current_wol>(*wol)) {
	(*wol)=current_wol;
      }
      current_length=0;
      current_wol=0;
    }
  }
  fclose(fl);
}

void halt (char *s){
  printf("Error: %s\n", s);
  while(1);
}



struct AttribEl *NewAttrib(double value,long int nID){
  struct AttribEl *a;

  a = (struct AttribEl *)malloc(sizeof (struct AttribEl));
  a->val = value;
  a->ID = nID;
  a->Next = 0;
  return a;
}

struct AttribEl *InsertAttrib(struct AttribEl *A, double value,long int nID){
  struct AttribEl *nA;

  if (!A) return NewAttrib(value,nID);

  if (A && A->ID < nID) {
    A->Next = InsertAttrib(A->Next, value, nID);
    return A;
  }
  if (A && A->ID == nID) {
    A->val=value;
    return A;
  }
  else {
    nA=NewAttrib(value, nID);
    nA->Next = A;
    return nA;
  }
}



struct Attributes *NewAttributes(void)
{
  struct Attributes *A;

  A = (struct Attributes *)malloc (sizeof (struct Attributes));
  A->begin =0;
  A->total = 0;
  A->dim = 0;
  return A;
}




void InsertAttributes(struct Attributes *A, long int nID, double value){
  if (isnan(value)) halt ("nan error");

  A->begin = InsertAttrib(A->begin, value, nID);
  A->total++;
  if (nID>A->dim)A->dim=nID;
}


int NumList(struct List* h){
	return h->totalP;
	}


struct ListEl *NewListEl(float thresh)
{
  struct ListEl *h;

  h = (struct ListEl *)malloc(sizeof (struct ListEl));
  h->threshold = thresh;
  h->num = 1;
  h->Next = 0;
  return h;
}

void DeleteListEl (struct ListEl *h)
{
  if (h->Next) DeleteListEl (h->Next);
  free (h);
}



struct ListEl *InsertListEl (struct ListEl *h, float thresh)
{
  struct ListEl *nh;
  
  if (!h) return NewListEl (thresh);
  if (h && h->threshold > thresh) {
    h->Next = InsertListEl (h->Next, thresh);
    return h;
  }
  //if (h && h->threshold == thresh) {
  //  h->num++;
  //  return h;
  //} else {
    nh = NewListEl (thresh);
    nh->Next = h;
    return nh;
  //}
}

float GetThreshold(struct List *h, int number){
	
	struct ListEl *tmp;
	int count;
	
	count=1;
	if(!h)return -1;
	tmp=h->begin;
	//printf("[%d=%f]\n",count,tmp->threshold);
	while((tmp->Next!=0)&&(count!=number)){
		//printf("[%d=%f]\n",count,tmp->threshold);
		tmp=tmp->Next;
		count+=tmp->num;}
		
	
	//printf("[%d=%f][%d=%f]",count,tmp->threshold,count+1,tmp->Next->threshold);
	
	return (tmp->threshold+tmp->Next->threshold)/2;
}
		




struct List *NewList(void)
{
  struct List *h;

  h = (struct List *)malloc (sizeof (struct List));
  h->begin=0;
  h->totalP = 0;
  return h;
}

void DeleteList (struct List *h)
{
  if (h->begin) DeleteListEl(h->begin);
  free (h);
}

int AccListEl (struct ListEl *h)
{
  if (!h) return 0;
  else return h->num + AccListEl(h->Next);
}

void PrintListEl (struct ListEl *h)
{
  if (!h) return;
  printf ("[%g:%d] ", h->threshold, h->num);
  PrintListEl (h->Next);
}

void PrintList(struct List *h, char *file)
{
  FILE *pf;
  struct ListEl *e;
  char buffer[1000];
  int accP=0;

  
  if (!h) halt ("h empty");
  sprintf(buffer, "%s.list", file);
  if (!(pf=fopen(buffer,"w"))) halt("cannot open List file");

  e = h->begin;
  while (e) {
    accP += e->num;
    fprintf (pf, "%g %d\n", e->threshold, accP);
    printf("%g %d\n", e->threshold, accP);
    e = e->Next;
  }

  fclose (pf); 
}


int PrintListNr(struct List *h, char *file, int start)
{
  FILE *pf;
  struct ListEl *e;
  char buffer[1000];
  int accP=0;

  
  if (!h) halt ("h empty");
  sprintf(buffer, "%s.list", file);
  if (!(pf=fopen(buffer,"w"))) halt("cannot open List file");

  e = h->begin;
  while (e) {
    accP += e->num;
    fprintf (pf, "%g %d\n", e->threshold, start);
    //printf("%g %d\n", e->threshold, accP);
    e = e->Next;
		start++;
  }

  fclose (pf);
	return start;
}



void Insert(struct List *h, float thresh)
{

  if (isnan(thresh)) halt ("nan error");
  h->begin = InsertListEl (h->begin, thresh);
  h->totalP++;
}


