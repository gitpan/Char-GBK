# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{‚ } ne "\x82\xa0";

use Char::GBK;
print "1..2\n";

my $__FILE__ = __FILE__;

if (Char::GBK::ord('‚ ') == 0x82A0) {
    print qq{ok - 1 Char::GBK::ord('‚ ') == 0x82A0 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 Char::GBK::ord('‚ ') == 0x82A0 $^X $__FILE__\n};
}

$_ = '‚¢';
if (Char::GBK::ord == 0x82A2) {
    print qq{ok - 2 \$_ = '‚¢'; Char::GBK::ord() == 0x82A2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = '‚¢'; Char::GBK::ord() == 0x82A2 $^X $__FILE__\n};
}

__END__
