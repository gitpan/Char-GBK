# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{あ} ne "\x82\xa0";

use Char::GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あxyzえ' =~ /(あ.*う)/) {
    print "not ok - 1 $^X $__FILE__ not ('あxyzえ' =~ /あ.*う/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('あxyzえ' =~ /あ.*う/).\n";
}

__END__
