# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{あ} ne "\x82\xa0";

use Char::GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

if ($] < 5.006) {
    print qq{ok - 1 # SKIP $^X $] $__FILE__\n};
    exit;
}

open(FILE,">$__FILE__.txt") || die;
print FILE <DATA>;
close(FILE);
open(my $fh,"<$__FILE__.txt") || die;

my @getc = ();
while (my $c = Char::GBK::getc($fh)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
close($fh);
unlink("$__FILE__.txt");

my $result = join('', map {"($_)"} @getc);

if ($result eq '(1)(2)(あ)(い)') {
    print "ok - 1 $^X $__FILE__ 12あい --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12あい --> $result.\n";
}

__END__
12あい
