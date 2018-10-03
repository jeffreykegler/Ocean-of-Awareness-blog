y=$1
m=$2
if test "$y" -le 2000
then
    echo Bad year $y 1>&2
    exit 1
fi
if test "$y" -ge 2525
then
    echo Bad year $y 1>&2
    exit 1
fi
if test "$m" -le 0
then
    echo Bad month $y 1>&2
fi
if test "$m" -gt 12
then
    echo Bad month $y 1>&2
fi
mkdir -p source/individual/$y/$m/ individual/$y/$m
