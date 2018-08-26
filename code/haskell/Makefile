

.PHONY: all test test_suite undoc_tests

all: test

test: test_suite undoc_tests

test_suite:
	prove -I. long.t short.t semis.t note1.t short13.t listcomp.t

undoc_tests:
	perl -I. listcomp_ex.pl >listcomp_ex.pl.out 2>&1
	diff listcomp_ex.pl.out listcomp_trace.out || echo 'Trace example FAILED'

