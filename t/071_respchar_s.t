# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{あ} ne "\x82\xa0";

use Char::GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "アソア";
if ($a !~ s/(ア([イウエ])ア)//) {
    print qq{ok - 1 "アソア" !~ s/(ア([イウエ])ア)// \$1=(), \$2=() $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "アソア" !~ s/(ア([イソウ])ア)// \$1=($1), \$2=($2) $^X $__FILE__\n};
}

__END__
