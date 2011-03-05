# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{あ} ne "\x82\xa0";

# 引数に _ が指定された場合のテスト

my $__FILE__ = __FILE__;

use Char::Egbk;
print "1..23\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..23) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if (-r ('file')) {
    if (Char::Egbk::r(_)) {
        print "ok - 1 Char::Egbk::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 Char::Egbk::r _ == -r _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::r(_)) {
        print "not ok - 1 Char::Egbk::r _ == -r _ $^X $__FILE__\n";
    }
    else {
        print "ok - 1 Char::Egbk::r _ == -r _ $^X $__FILE__\n";
    }
}

if (-w ('file')) {
    if (Char::Egbk::w(_)) {
        print "ok - 2 Char::Egbk::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 Char::Egbk::w _ == -w _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::w(_)) {
        print "not ok - 2 Char::Egbk::w _ == -w _ $^X $__FILE__\n";
    }
    else {
        print "ok - 2 Char::Egbk::w _ == -w _ $^X $__FILE__\n";
    }
}

if (-x ('file')) {
    if (Char::Egbk::x(_)) {
        print "ok - 3 Char::Egbk::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 Char::Egbk::x _ == -x _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::x(_)) {
        print "not ok - 3 Char::Egbk::x _ == -x _ $^X $__FILE__\n";
    }
    else {
        print "ok - 3 Char::Egbk::x _ == -x _ $^X $__FILE__\n";
    }
}

if (-o ('file')) {
    if (Char::Egbk::o(_)) {
        print "ok - 4 Char::Egbk::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 Char::Egbk::o _ == -o _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::o(_)) {
        print "not ok - 4 Char::Egbk::o _ == -o _ $^X $__FILE__\n";
    }
    else {
        print "ok - 4 Char::Egbk::o _ == -o _ $^X $__FILE__\n";
    }
}

if (-R ('file')) {
    if (Char::Egbk::R(_)) {
        print "ok - 5 Char::Egbk::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 5 Char::Egbk::R _ == -R _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::R(_)) {
        print "not ok - 5 Char::Egbk::R _ == -R _ $^X $__FILE__\n";
    }
    else {
        print "ok - 5 Char::Egbk::R _ == -R _ $^X $__FILE__\n";
    }
}

if (-W ('file')) {
    if (Char::Egbk::W(_)) {
        print "ok - 6 Char::Egbk::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 Char::Egbk::W _ == -W _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::W(_)) {
        print "not ok - 6 Char::Egbk::W _ == -W _ $^X $__FILE__\n";
    }
    else {
        print "ok - 6 Char::Egbk::W _ == -W _ $^X $__FILE__\n";
    }
}

if (-X ('file')) {
    if (Char::Egbk::X(_)) {
        print "ok - 7 Char::Egbk::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 7 Char::Egbk::X _ == -X _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::X(_)) {
        print "not ok - 7 Char::Egbk::X _ == -X _ $^X $__FILE__\n";
    }
    else {
        print "ok - 7 Char::Egbk::X _ == -X _ $^X $__FILE__\n";
    }
}

if (-O ('file')) {
    if (Char::Egbk::O(_)) {
        print "ok - 8 Char::Egbk::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 Char::Egbk::O _ == -O _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::O(_)) {
        print "not ok - 8 Char::Egbk::O _ == -O _ $^X $__FILE__\n";
    }
    else {
        print "ok - 8 Char::Egbk::O _ == -O _ $^X $__FILE__\n";
    }
}

if (-e ('file')) {
    if (Char::Egbk::e(_)) {
        print "ok - 9 Char::Egbk::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 9 Char::Egbk::e _ == -e _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::e(_)) {
        print "not ok - 9 Char::Egbk::e _ == -e _ $^X $__FILE__\n";
    }
    else {
        print "ok - 9 Char::Egbk::e _ == -e _ $^X $__FILE__\n";
    }
}

if (-z ('file')) {
    if (Char::Egbk::z(_)) {
        print "ok - 10 Char::Egbk::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 Char::Egbk::z _ == -z _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::z(_)) {
        print "not ok - 10 Char::Egbk::z _ == -z _ $^X $__FILE__\n";
    }
    else {
        print "ok - 10 Char::Egbk::z _ == -z _ $^X $__FILE__\n";
    }
}

$_ = -s 'file';
if (Char::Egbk::s(_) == $_) {
    print "ok - 11 Char::Egbk::s _ (@{[Char::Egbk::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 11 Char::Egbk::s _ (@{[Char::Egbk::s _]}) == -s 'file' ($_) $^X $__FILE__\n";
}

if (-f ('file')) {
    if (Char::Egbk::f(_)) {
        print "ok - 12 Char::Egbk::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 Char::Egbk::f _ == -f _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::f(_)) {
        print "not ok - 12 Char::Egbk::f _ == -f _ $^X $__FILE__\n";
    }
    else {
        print "ok - 12 Char::Egbk::f _ == -f _ $^X $__FILE__\n";
    }
}

if (-d ('file')) {
    if (Char::Egbk::d(_)) {
        print "ok - 13 Char::Egbk::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 13 Char::Egbk::d _ == -d _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::d(_)) {
        print "not ok - 13 Char::Egbk::d _ == -d _ $^X $__FILE__\n";
    }
    else {
        print "ok - 13 Char::Egbk::d _ == -d _ $^X $__FILE__\n";
    }
}

if (-p ('file')) {
    if (Char::Egbk::p(_)) {
        print "ok - 14 Char::Egbk::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 14 Char::Egbk::p _ == -p _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::p(_)) {
        print "not ok - 14 Char::Egbk::p _ == -p _ $^X $__FILE__\n";
    }
    else {
        print "ok - 14 Char::Egbk::p _ == -p _ $^X $__FILE__\n";
    }
}

if (-S ('file')) {
    if (Char::Egbk::S(_)) {
        print "ok - 15 Char::Egbk::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 15 Char::Egbk::S _ == -S _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::S(_)) {
        print "not ok - 15 Char::Egbk::S _ == -S _ $^X $__FILE__\n";
    }
    else {
        print "ok - 15 Char::Egbk::S _ == -S _ $^X $__FILE__\n";
    }
}

if (-b ('file')) {
    if (Char::Egbk::b(_)) {
        print "ok - 16 Char::Egbk::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 16 Char::Egbk::b _ == -b _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::b(_)) {
        print "not ok - 16 Char::Egbk::b _ == -b _ $^X $__FILE__\n";
    }
    else {
        print "ok - 16 Char::Egbk::b _ == -b _ $^X $__FILE__\n";
    }
}

if (-c ('file')) {
    if (Char::Egbk::c(_)) {
        print "ok - 17 Char::Egbk::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 17 Char::Egbk::c _ == -c _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::c(_)) {
        print "not ok - 17 Char::Egbk::c _ == -c _ $^X $__FILE__\n";
    }
    else {
        print "ok - 17 Char::Egbk::c _ == -c _ $^X $__FILE__\n";
    }
}

if (-u ('file')) {
    if (Char::Egbk::u(_)) {
        print "ok - 18 Char::Egbk::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 18 Char::Egbk::u _ == -u _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::u(_)) {
        print "not ok - 18 Char::Egbk::u _ == -u _ $^X $__FILE__\n";
    }
    else {
        print "ok - 18 Char::Egbk::u _ == -u _ $^X $__FILE__\n";
    }
}

if (-g ('file')) {
    if (Char::Egbk::g(_)) {
        print "ok - 19 Char::Egbk::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 19 Char::Egbk::g _ == -g _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::g(_)) {
        print "not ok - 19 Char::Egbk::g _ == -g _ $^X $__FILE__\n";
    }
    else {
        print "ok - 19 Char::Egbk::g _ == -g _ $^X $__FILE__\n";
    }
}

if (-k ('file')) {
    if (Char::Egbk::k(_)) {
        print "ok - 20 Char::Egbk::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "not ok - 20 Char::Egbk::k _ == -k _ $^X $__FILE__\n";
    }
}
else {
    if (Char::Egbk::k(_)) {
        print "not ok - 20 Char::Egbk::k _ == -k _ $^X $__FILE__\n";
    }
    else {
        print "ok - 20 Char::Egbk::k _ == -k _ $^X $__FILE__\n";
    }
}

$_ = -M 'file';
if (Char::Egbk::M(_) == $_) {
    print "ok - 21 Char::Egbk::M _ (@{[Char::Egbk::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 21 Char::Egbk::M _ (@{[Char::Egbk::M _]}) == -M 'file' ($_) $^X $__FILE__\n";
}

$_ = -A 'file';
if (Char::Egbk::A(_) == $_) {
    print "ok - 22 Char::Egbk::A _ (@{[Char::Egbk::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 22 Char::Egbk::A _ (@{[Char::Egbk::A _]}) == -A 'file' ($_) $^X $__FILE__\n";
}

$_ = -C 'file';
if (Char::Egbk::C(_) == $_) {
    print "ok - 23 Char::Egbk::C _ (@{[Char::Egbk::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}
else {
    print "not ok - 23 Char::Egbk::C _ (@{[Char::Egbk::C _]}) == -C 'file' ($_) $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
