# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{あ} ne "\x82\xa0";

# ファイルテストが真になる場合は 1 が返るテスト

my $__FILE__ = __FILE__;

use Char::Egbk;
print "1..9\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..9) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if ((Char::Egbk::r 'file') == 1) {
    $_ = Char::Egbk::r 'file';
    print "ok - 1 Char::Egbk::r 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::r 'file';
    print "not ok - 1 Char::Egbk::r 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Char::Egbk::w 'file') == 1) {
    $_ = Char::Egbk::w 'file';
    print "ok - 2 Char::Egbk::w 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::w 'file';
    print "not ok - 2 Char::Egbk::w 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Char::Egbk::o 'file') == 1) {
    $_ = Char::Egbk::o 'file';
    print "ok - 3 Char::Egbk::o 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::o 'file';
    print "not ok - 3 Char::Egbk::o 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Char::Egbk::R 'file') == 1) {
    $_ = Char::Egbk::R 'file';
    print "ok - 4 Char::Egbk::R 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::R 'file';
    print "not ok - 4 Char::Egbk::R 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Char::Egbk::W 'file') == 1) {
    $_ = Char::Egbk::W 'file';
    print "ok - 5 Char::Egbk::W 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::W 'file';
    print "not ok - 5 Char::Egbk::W 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Char::Egbk::O 'file') == 1) {
    $_ = Char::Egbk::O 'file';
    print "ok - 6 Char::Egbk::O 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::O 'file';
    print "not ok - 6 Char::Egbk::O 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Char::Egbk::e 'file') == 1) {
    $_ = Char::Egbk::e 'file';
    print "ok - 7 Char::Egbk::e 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::e 'file';
    print "not ok - 7 Char::Egbk::e 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Char::Egbk::z 'file') == 1) {
    $_ = Char::Egbk::z 'file';
    print "ok - 8 Char::Egbk::z 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::z 'file';
    print "not ok - 8 Char::Egbk::z 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Char::Egbk::f 'file') == 1) {
    $_ = Char::Egbk::f 'file';
    print "ok - 9 Char::Egbk::f 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Char::Egbk::f 'file';
    print "not ok - 9 Char::Egbk::f 'file' ($_) == 1 $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
