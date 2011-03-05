# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{あ} ne "\x82\xa0";

use Char::GBK;
print "1..1\n";

# マッチするはずなのにマッチしない（１）
if ("運転免許" =~ m'運転') {
    print qq<ok - 1 "UNTENMENKYO" =~ m'UNTEN'>;
}
else {
    print qq<not ok - 1 "UNTENMENKYO" =~ m'UNTEN'>;
}

__END__

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
