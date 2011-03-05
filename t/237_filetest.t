# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{あ} ne "\x82\xa0";

# Char::Egbk::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト

my $__FILE__ = __FILE__;

use Char::Egbk;
print "1..48\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..48) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if (((Char::Egbk::r 'file') ne '') == ((-r 'file') ne '')) {
    print "ok - 1 Char::Egbk::r 'file' == -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Char::Egbk::r 'file' == -r 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::r FILE) ne '') == ((-r FILE) ne '')) {
    print "ok - 2 Char::Egbk::r FILE == -r FILE $^X $__FILE__\n";
}
else {
    print "not ok - 2 Char::Egbk::r FILE == -r FILE $^X $__FILE__\n";
}

if (((Char::Egbk::w 'file') ne '') == ((-w 'file') ne '')) {
    print "ok - 3 Char::Egbk::w 'file' == -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Char::Egbk::w 'file' == -w 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::w FILE) ne '') == ((-w FILE) ne '')) {
    print "ok - 4 Char::Egbk::w FILE == -w FILE $^X $__FILE__\n";
}
else {
    print "not ok - 4 Char::Egbk::w FILE == -w FILE $^X $__FILE__\n";
}

if (((Char::Egbk::x 'file') ne '') == ((-x 'file') ne '')) {
    print "ok - 5 Char::Egbk::x 'file' == -x 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Char::Egbk::x 'file' == -x 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::x FILE) ne '') == ((-x FILE) ne '')) {
    print "ok - 6 Char::Egbk::x FILE == -x FILE $^X $__FILE__\n";
}
else {
    print "not ok - 6 Char::Egbk::x FILE == -x FILE $^X $__FILE__\n";
}

if (((Char::Egbk::o 'file') ne '') == ((-o 'file') ne '')) {
    print "ok - 7 Char::Egbk::o 'file' == -o 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Char::Egbk::o 'file' == -o 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::o FILE) ne '') == ((-o FILE) ne '')) {
    print "ok - 8 Char::Egbk::o FILE == -o FILE $^X $__FILE__\n";
}
else {
    print "not ok - 8 Char::Egbk::o FILE == -o FILE $^X $__FILE__\n";
}

if (((Char::Egbk::R 'file') ne '') == ((-R 'file') ne '')) {
    print "ok - 9 Char::Egbk::R 'file' == -R 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Char::Egbk::R 'file' == -R 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::R FILE) ne '') == ((-R FILE) ne '')) {
    print "ok - 10 Char::Egbk::R FILE == -R FILE $^X $__FILE__\n";
}
else {
    print "not ok - 10 Char::Egbk::R FILE == -R FILE $^X $__FILE__\n";
}

if (((Char::Egbk::W 'file') ne '') == ((-W 'file') ne '')) {
    print "ok - 11 Char::Egbk::W 'file' == -W 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Char::Egbk::W 'file' == -W 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::W FILE) ne '') == ((-W FILE) ne '')) {
    print "ok - 12 Char::Egbk::W FILE == -W FILE $^X $__FILE__\n";
}
else {
    print "not ok - 12 Char::Egbk::W FILE == -W FILE $^X $__FILE__\n";
}

if (((Char::Egbk::X 'file') ne '') == ((-X 'file') ne '')) {
    print "ok - 13 Char::Egbk::X 'file' == -X 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Char::Egbk::X 'file' == -X 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::X FILE) ne '') == ((-X FILE) ne '')) {
    print "ok - 14 Char::Egbk::X FILE == -X FILE $^X $__FILE__\n";
}
else {
    print "not ok - 14 Char::Egbk::X FILE == -X FILE $^X $__FILE__\n";
}

if (((Char::Egbk::O 'file') ne '') == ((-O 'file') ne '')) {
    print "ok - 15 Char::Egbk::O 'file' == -O 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Char::Egbk::O 'file' == -O 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::O FILE) ne '') == ((-O FILE) ne '')) {
    print "ok - 16 Char::Egbk::O FILE == -O FILE $^X $__FILE__\n";
}
else {
    print "not ok - 16 Char::Egbk::O FILE == -O FILE $^X $__FILE__\n";
}

if (((Char::Egbk::e 'file') ne '') == ((-e 'file') ne '')) {
    print "ok - 17 Char::Egbk::e 'file' == -e 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Char::Egbk::e 'file' == -e 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::e FILE) ne '') == ((-e FILE) ne '')) {
    print "ok - 18 Char::Egbk::e FILE == -e FILE $^X $__FILE__\n";
}
else {
    print "not ok - 18 Char::Egbk::e FILE == -e FILE $^X $__FILE__\n";
}

if (((Char::Egbk::z 'file') ne '') == ((-z 'file') ne '')) {
    print "ok - 19 Char::Egbk::z 'file' == -z 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Char::Egbk::z 'file' == -z 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::z FILE) ne '') == ((-z FILE) ne '')) {
    print "ok - 20 Char::Egbk::z FILE == -z FILE $^X $__FILE__\n";
}
else {
    print "not ok - 20 Char::Egbk::z FILE == -z FILE $^X $__FILE__\n";
}

if (((Char::Egbk::s 'file') ne '') == ((-s 'file') ne '')) {
    print "ok - 21 Char::Egbk::s 'file' == -s 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Char::Egbk::s 'file' == -s 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::s FILE) ne '') == ((-s FILE) ne '')) {
    print "ok - 22 Char::Egbk::s FILE == -s FILE $^X $__FILE__\n";
}
else {
    print "not ok - 22 Char::Egbk::s FILE == -s FILE $^X $__FILE__\n";
}

if (((Char::Egbk::f 'file') ne '') == ((-f 'file') ne '')) {
    print "ok - 23 Char::Egbk::f 'file' == -f 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 23 Char::Egbk::f 'file' == -f 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::f FILE) ne '') == ((-f FILE) ne '')) {
    print "ok - 24 Char::Egbk::f FILE == -f FILE $^X $__FILE__\n";
}
else {
    print "not ok - 24 Char::Egbk::f FILE == -f FILE $^X $__FILE__\n";
}

if (((Char::Egbk::d 'file') ne '') == ((-d 'file') ne '')) {
    print "ok - 25 Char::Egbk::d 'file' == -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 25 Char::Egbk::d 'file' == -d 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::d FILE) ne '') == ((-d FILE) ne '')) {
    print "ok - 26 Char::Egbk::d FILE == -d FILE $^X $__FILE__\n";
}
else {
    print "not ok - 26 Char::Egbk::d FILE == -d FILE $^X $__FILE__\n";
}

if (((Char::Egbk::p 'file') ne '') == ((-p 'file') ne '')) {
    print "ok - 27 Char::Egbk::p 'file' == -p 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 27 Char::Egbk::p 'file' == -p 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::p FILE) ne '') == ((-p FILE) ne '')) {
    print "ok - 28 Char::Egbk::p FILE == -p FILE $^X $__FILE__\n";
}
else {
    print "not ok - 28 Char::Egbk::p FILE == -p FILE $^X $__FILE__\n";
}

if (((Char::Egbk::S 'file') ne '') == ((-S 'file') ne '')) {
    print "ok - 29 Char::Egbk::S 'file' == -S 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 29 Char::Egbk::S 'file' == -S 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::S FILE) ne '') == ((-S FILE) ne '')) {
    print "ok - 30 Char::Egbk::S FILE == -S FILE $^X $__FILE__\n";
}
else {
    print "not ok - 30 Char::Egbk::S FILE == -S FILE $^X $__FILE__\n";
}

if (((Char::Egbk::b 'file') ne '') == ((-b 'file') ne '')) {
    print "ok - 31 Char::Egbk::b 'file' == -b 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 31 Char::Egbk::b 'file' == -b 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::b FILE) ne '') == ((-b FILE) ne '')) {
    print "ok - 32 Char::Egbk::b FILE == -b FILE $^X $__FILE__\n";
}
else {
    print "not ok - 32 Char::Egbk::b FILE == -b FILE $^X $__FILE__\n";
}

if (((Char::Egbk::c 'file') ne '') == ((-c 'file') ne '')) {
    print "ok - 33 Char::Egbk::c 'file' == -c 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 33 Char::Egbk::c 'file' == -c 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::c FILE) ne '') == ((-c FILE) ne '')) {
    print "ok - 34 Char::Egbk::c FILE == -c FILE $^X $__FILE__\n";
}
else {
    print "not ok - 34 Char::Egbk::c FILE == -c FILE $^X $__FILE__\n";
}

if (((Char::Egbk::u 'file') ne '') == ((-u 'file') ne '')) {
    print "ok - 35 Char::Egbk::u 'file' == -u 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 35 Char::Egbk::u 'file' == -u 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::u FILE) ne '') == ((-u FILE) ne '')) {
    print "ok - 36 Char::Egbk::u FILE == -u FILE $^X $__FILE__\n";
}
else {
    print "not ok - 36 Char::Egbk::u FILE == -u FILE $^X $__FILE__\n";
}

if (((Char::Egbk::g 'file') ne '') == ((-g 'file') ne '')) {
    print "ok - 37 Char::Egbk::g 'file' == -g 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 37 Char::Egbk::g 'file' == -g 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::g FILE) ne '') == ((-g FILE) ne '')) {
    print "ok - 38 Char::Egbk::g FILE == -g FILE $^X $__FILE__\n";
}
else {
    print "not ok - 38 Char::Egbk::g FILE == -g FILE $^X $__FILE__\n";
}

if (((Char::Egbk::T 'file') ne '') == ((-T 'file') ne '')) {
    print "ok - 39 Char::Egbk::T 'file' == -T 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 39 Char::Egbk::T 'file' == -T 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::T FILE) ne '') == ((-T FILE) ne '')) {
    print "ok - 40 Char::Egbk::T FILE == -T FILE $^X $__FILE__\n";
}
else {
    print "not ok - 40 Char::Egbk::T FILE == -T FILE $^X $__FILE__\n";
}

if (((Char::Egbk::B 'file') ne '') == ((-B 'file') ne '')) {
    print "ok - 41 Char::Egbk::B 'file' == -B 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 41 Char::Egbk::B 'file' == -B 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::B FILE) ne '') == ((-B FILE) ne '')) {
    print "ok - 42 Char::Egbk::B FILE == -B FILE $^X $__FILE__\n";
}
else {
    print "not ok - 42 Char::Egbk::B FILE == -B FILE $^X $__FILE__\n";
}

if (((Char::Egbk::M 'file') ne '') == ((-M 'file') ne '')) {
    print "ok - 43 Char::Egbk::M 'file' == -M 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 43 Char::Egbk::M 'file' == -M 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::M FILE) ne '') == ((-M FILE) ne '')) {
    print "ok - 44 Char::Egbk::M FILE == -M FILE $^X $__FILE__\n";
}
else {
    print "not ok - 44 Char::Egbk::M FILE == -M FILE $^X $__FILE__\n";
}

if (((Char::Egbk::A 'file') ne '') == ((-A 'file') ne '')) {
    print "ok - 45 Char::Egbk::A 'file' == -A 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 45 Char::Egbk::A 'file' == -A 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::A FILE) ne '') == ((-A FILE) ne '')) {
    print "ok - 46 Char::Egbk::A FILE == -A FILE $^X $__FILE__\n";
}
else {
    print "not ok - 46 Char::Egbk::A FILE == -A FILE $^X $__FILE__\n";
}

if (((Char::Egbk::C 'file') ne '') == ((-C 'file') ne '')) {
    print "ok - 47 Char::Egbk::C 'file' == -C 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 47 Char::Egbk::C 'file' == -C 'file' $^X $__FILE__\n";
}

if (((Char::Egbk::C FILE) ne '') == ((-C FILE) ne '')) {
    print "ok - 48 Char::Egbk::C FILE == -C FILE $^X $__FILE__\n";
}
else {
    print "not ok - 48 Char::Egbk::C FILE == -C FILE $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
