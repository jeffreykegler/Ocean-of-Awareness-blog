
dummy:
	echo the target is '"all"'

all: \
  ../source/individual/2018/05/fast_power.txt \
  ../source/individual/2018/05/chomsky_1956.txt \
  ../source/individual/2018/05/language_timeline.txt

../source/individual/2018/05/fast_power.txt: fast_power.pl
	perl fast_power.pl > ../source/individual/2018/05/fast_power.txt

../source/individual/2018/05/chomsky_1956.txt: chomsky_1956.pl
	perl chomsky_1956.pl > ../source/individual/2018/05/chomsky_1956.txt

../source/individual/2018/05/language_timeline.txt: language_timeline.pl
	perl language_timeline.pl > ../source/individual/2018/05/language_timeline.txt
