use 5.010;
use strict;
use warnings;

use Data::Dumper qw(Dumper);

say Dumper({ 42 => 711,
 -42 => 711,
 +42 => 711,
 key1 => 711,
 key2 => 711,
 first key => 711,
 second key => 711,
});
