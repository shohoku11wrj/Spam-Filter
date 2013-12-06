#if !defined( PARAMS_ )
#define PARAMS_

struct PARAMS{

  char inputFILE[1000];
	char valuesFILE[1000];
  int verbose;
  int partition;
  long int **part;
  int numViews;

};

#endif
