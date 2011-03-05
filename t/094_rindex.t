# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{‚ } ne "\x82\xa0";

use Char::GBK;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = '‚ ‚¢‚¤‚¦‚¨‚ ‚¢‚¤‚¦‚¨';
if (rindex($_,'‚¢‚¤') == 12) {
    print qq{ok - 1 rindex(\$_,'‚¢‚¤') == 12 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 rindex(\$_,'‚¢‚¤') == 12 $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚ ‚¢‚¤‚¦‚¨';
if (rindex($_,'‚¢‚¤',10) == 2) {
    print qq{ok - 2 rindex(\$_,'‚¢‚¤',10) == 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 rindex(\$_,'‚¢‚¤',10) == 2 $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚ ‚¢‚¤‚¦‚¨';
if (Char::GBK::rindex($_,'‚¢‚¤') == 6) {
    print qq{ok - 3 Char::GBK::rindex(\$_,'‚¢‚¤') == 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 Char::GBK::rindex(\$_,'‚¢‚¤') == 6 $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚ ‚¢‚¤‚¦‚¨';
if (Char::GBK::rindex($_,'‚¢‚¤',5) == 1) {
    print qq{ok - 4 Char::GBK::rindex(\$_,'‚¢‚¤',5) == 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 Char::GBK::rindex(\$_,'‚¢‚¤',5) == 1 $^X $__FILE__\n};
}

__END__
