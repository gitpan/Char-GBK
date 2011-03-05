# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{‚ } ne "\x82\xa0";

# ˆø”‚ªÈ—ª‚³‚ê‚½ê‡‚ÌƒeƒXƒg

my $__FILE__ = __FILE__;

use Char::Egbk;
print "1..25\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..25) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

$_ = 'file';
if ((Char::Egbk::r_ ne '') == (-r ne '')) {
    print "ok - 1 Char::Egbk::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Char::Egbk::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::w_ ne '') == (-w ne '')) {
    print "ok - 2 Char::Egbk::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Char::Egbk::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::x_ ne '') == (-x ne '')) {
    print "ok - 3 Char::Egbk::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Char::Egbk::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::o_ ne '') == (-o ne '')) {
    print "ok - 4 Char::Egbk::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Char::Egbk::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::R_ ne '') == (-R ne '')) {
    print "ok - 5 Char::Egbk::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Char::Egbk::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::W_ ne '') == (-W ne '')) {
    print "ok - 6 Char::Egbk::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Char::Egbk::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::X_ ne '') == (-X ne '')) {
    print "ok - 7 Char::Egbk::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Char::Egbk::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::O_ ne '') == (-O ne '')) {
    print "ok - 8 Char::Egbk::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Char::Egbk::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::e_ ne '') == (-e ne '')) {
    print "ok - 9 Char::Egbk::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Char::Egbk::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::z_ ne '') == (-z ne '')) {
    print "ok - 10 Char::Egbk::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Char::Egbk::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::s_ ne '') == (-s ne '')) {
    print "ok - 11 Char::Egbk::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Char::Egbk::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::f_ ne '') == (-f ne '')) {
    print "ok - 12 Char::Egbk::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Char::Egbk::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::d_ ne '') == (-d ne '')) {
    print "ok - 13 Char::Egbk::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Char::Egbk::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::p_ ne '') == (-p ne '')) {
    print "ok - 14 Char::Egbk::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Char::Egbk::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::S_ ne '') == (-S ne '')) {
    print "ok - 15 Char::Egbk::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Char::Egbk::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::b_ ne '') == (-b ne '')) {
    print "ok - 16 Char::Egbk::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Char::Egbk::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::c_ ne '') == (-c ne '')) {
    print "ok - 17 Char::Egbk::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Char::Egbk::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::u_ ne '') == (-u ne '')) {
    print "ok - 18 Char::Egbk::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Char::Egbk::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::g_ ne '') == (-g ne '')) {
    print "ok - 19 Char::Egbk::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Char::Egbk::g_ == -g  $^X $__FILE__\n";
}

local $^W = 0;
$_ = 'file';
if ((Char::Egbk::k_ ne '') == (-k ne '')) {
    print "ok - 20 Char::Egbk::k_ == -k  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Char::Egbk::k_ == -k  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::T_ ne '') == (-T ne '')) {
    print "ok - 21 Char::Egbk::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Char::Egbk::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::B_ ne '') == (-B ne '')) {
    print "ok - 22 Char::Egbk::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Char::Egbk::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::M_ ne '') == (-M ne '')) {
    print "ok - 23 Char::Egbk::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Char::Egbk::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::A_ ne '') == (-A ne '')) {
    print "ok - 24 Char::Egbk::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Char::Egbk::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Char::Egbk::C_ ne '') == (-C ne '')) {
    print "ok - 25 Char::Egbk::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 25 Char::Egbk::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
