HEADERS = dataIO.h params.h
OPTIONS = -g -Wall

calc_auc.o: calc_auc.c $(HEADERS)
	gcc -c $(OPTIONS) calc_auc.c	

dataIO.o: dataIO.c $(HEADERS)
	gcc -c $(OPTIONS) dataIO.c
	
calc_auc: calc_auc.o dataIO.o
	gcc $(OPTIONS) -o calc_auc calc_auc.o dataIO.o -lm




