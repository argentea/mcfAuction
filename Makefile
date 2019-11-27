CXX=g++
SHELL=/bin/bash

DATADIR=../data
LOGDIR=./log

override PRETESTDATA=data1.min
override PRELOG=data1.min
PRELOG=data1.min
LOGCOUNT=0
TESTDATA=$(patsubst %,$(DATADIR)/%,$(PRETESTDATA))
LOGNAME=$(patsubst %, $(LOGDIR)/%.log,$(PRELOG))

TESTPARAMETERS=1

auction.out:auction.cpp
	$(CXX) -o $@ $<

test:auction.out
	#ToDo Distingush between data file names when generate log names 
	@echo "test start"
	@echo "Generate log name"
	$(eval LOGCOUNT=$(shell ls $(LOGDIR) |wc -l))
	$(eval LOGNAME=$(patsubst %.log, %$(LOGCOUNT).log,$(LOGNAME)))
	@echo -n "Log name is "
	@echo $(LOGNAME)
	./auction.out $(TESTPARAMETERS) < $(TESTDATA) > $(LOGNAME)

.PHONY: clean cleanLog
clean:
	@rm -f *.out

cleanLog:
	@rm -r $(LOGNAME)
