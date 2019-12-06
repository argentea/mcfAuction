IDIR = ../include
ODIR = obj


CC=gcc
CFLAGS=-I${IDIR}
DEPS = auction.h
OBJ = auction.o
objects := $(wildcard *.c)

.PHONY: all clean

all: auction

%.o: %.c ${DEPS}
	$(CC) -c -o $@ $< $(CFLAGS)

auction: auction.o
	$(CC) -o $@ $^ $(CFLAGS)

clean:
	rm -r $(ODIR)/*.o *~ core ${INCDIR}/*~
