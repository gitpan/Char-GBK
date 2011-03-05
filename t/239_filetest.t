# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{あ} ne "\x82\xa0";

# Char::Egbk::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト(対象はディレクトリ)

my $__FILE__ = __FILE__;

use Char::Egbk;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Char::Egbk::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Char::Egbk::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Char::Egbk::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Char::Egbk::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Char::Egbk::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Char::Egbk::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Char::Egbk::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Char::Egbk::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Char::Egbk::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Char::Egbk::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Char::Egbk::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Char::Egbk::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Char::Egbk::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Char::Egbk::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Char::Egbk::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Char::Egbk::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Char::Egbk::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Char::Egbk::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Char::Egbk::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Char::Egbk::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Char::Egbk::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Char::Egbk::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Char::Egbk::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Char::Egbk::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Char::Egbk::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Char::Egbk::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Char::Egbk::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Char::Egbk::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Char::Egbk::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Char::Egbk::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Char::Egbk::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Char::Egbk::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Char::Egbk::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Char::Egbk::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Char::Egbk::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Char::Egbk::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Char::Egbk::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Char::Egbk::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Char::Egbk::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Char::Egbk::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Char::Egbk::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Char::Egbk::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Char::Egbk::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Char::Egbk::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Char::Egbk::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Char::Egbk::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
