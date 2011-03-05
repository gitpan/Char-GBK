# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{‚ } ne "\x82\xa0";

use Char::GBK;
print "1..20\n";

my $__FILE__ = __FILE__;

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,10) eq '‚©‚«‚­‚¯‚±') {
    print qq{ok - 1 substr(\$_,10) eq '‚©‚«‚­‚¯‚±' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 substr(\$_,10) eq '‚©‚«‚­‚¯‚±' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,4,6) eq '‚¤‚¦‚¨') {
    print qq{ok - 2 substr(\$_,4,6) eq '‚¤‚¦‚¨' $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 substr(\$_,4,6) eq '‚¤‚¦‚¨' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,4,6,'‚³‚µ‚·‚¹‚»') eq '‚¤‚¦‚¨') {
    if ($_ eq '‚ ‚¢‚³‚µ‚·‚¹‚»‚©‚«‚­‚¯‚±') {
        print qq{ok - 3 substr(\$_,4,6,'‚³‚µ‚·‚¹‚»') eq '‚¤‚¦‚¨' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 substr(\$_,4,6,'‚³‚µ‚·‚¹‚»') eq '‚¤‚¦‚¨' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 substr(\$_,4,6,'‚³‚µ‚·‚¹‚»') eq '‚¤‚¦‚¨' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,-6) eq '‚­‚¯‚±') {
    print qq{ok - 4 substr(\$_,-6) eq '‚­‚¯‚±' $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 substr(\$_,-6) eq '‚­‚¯‚±' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,-10,6) eq '‚©‚«‚­') {
    print qq{ok - 5 substr(\$_,-10,6) eq '‚©‚«‚­' $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 substr(\$_,-10,6) eq '‚©‚«‚­' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,-10,6,'‚â‚ä‚æ') eq '‚©‚«‚­') {
    if ($_ eq '‚ ‚¢‚¤‚¦‚¨‚â‚ä‚æ‚¯‚±') {
        print qq{ok - 6 substr(\$_,-10,6,'‚â‚ä‚æ') eq '‚©‚«‚­' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 substr(\$_,-10,6,'‚â‚ä‚æ') eq '‚©‚«‚­' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 substr(\$_,-10,6,'‚â‚ä‚æ') eq '‚©‚«‚­' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,10,0) eq '') {
    print qq{ok - 7 substr(\$_,10,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 substr(\$_,10,0) eq '' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,10,0,'‚â‚ä‚æ') eq '') {
    if ($_ eq '‚ ‚¢‚¤‚¦‚¨‚â‚ä‚æ‚©‚«‚­‚¯‚±') {
        print qq{ok - 8 substr(\$_,10,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 substr(\$_,10,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 substr(\$_,10,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,-10,0) eq '') {
    print qq{ok - 9 substr(\$_,-10,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 substr(\$_,-10,0) eq '' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (substr($_,-10,0,'‚â‚ä‚æ') eq '') {
    if ($_ eq '‚ ‚¢‚¤‚¦‚¨‚â‚ä‚æ‚©‚«‚­‚¯‚±') {
        print qq{ok - 10 substr(\$_,-10,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 substr(\$_,-10,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 substr(\$_,-10,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,5) eq '‚©‚«‚­‚¯‚±') {
    print qq{ok - 11 Char::GBK::substr(\$_,5) eq '‚©‚«‚­‚¯‚±' $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 Char::GBK::substr(\$_,5) eq '‚©‚«‚­‚¯‚±' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,2,3) eq '‚¤‚¦‚¨') {
    print qq{ok - 12 Char::GBK::substr(\$_,2,3) eq '‚¤‚¦‚¨' $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 Char::GBK::substr(\$_,2,3) eq '‚¤‚¦‚¨' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,2,3,'‚³‚µ‚·‚¹‚»') eq '‚¤‚¦‚¨') {
    if ($_ eq '‚ ‚¢‚³‚µ‚·‚¹‚»‚©‚«‚­‚¯‚±') {
        print qq{ok - 13 Char::GBK::substr(\$_,2,3,'‚³‚µ‚·‚¹‚»') eq '‚¤‚¦‚¨' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 Char::GBK::substr(\$_,2,3,'‚³‚µ‚·‚¹‚»') eq '‚¤‚¦‚¨' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 Char::GBK::substr(\$_,2,3,'‚³‚µ‚·‚¹‚»') eq '‚¤‚¦‚¨' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,-3) eq '‚­‚¯‚±') {
    print qq{ok - 14 Char::GBK::substr(\$_,-3) eq '‚­‚¯‚±' $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 Char::GBK::substr(\$_,-3) eq '‚­‚¯‚±' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,-5,3) eq '‚©‚«‚­') {
    print qq{ok - 15 Char::GBK::substr(\$_,-5,3) eq '‚©‚«‚­' $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 Char::GBK::substr(\$_,-5,3) eq '‚©‚«‚­' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,-5,3,'‚â‚ä‚æ') eq '‚©‚«‚­') {
    if ($_ eq '‚ ‚¢‚¤‚¦‚¨‚â‚ä‚æ‚¯‚±') {
        print qq{ok - 16 Char::GBK::substr(\$_,-5,3,'‚â‚ä‚æ') eq '‚©‚«‚­' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 Char::GBK::substr(\$_,-5,3,'‚â‚ä‚æ') eq '‚©‚«‚­' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 Char::GBK::substr(\$_,-5,3,'‚â‚ä‚æ') eq '‚©‚«‚­' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,5,0) eq '') {
    print qq{ok - 17 Char::GBK::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 Char::GBK::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,5,0,'‚â‚ä‚æ') eq '') {
    if ($_ eq '‚ ‚¢‚¤‚¦‚¨‚â‚ä‚æ‚©‚«‚­‚¯‚±') {
        print qq{ok - 18 Char::GBK::substr(\$_,5,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 Char::GBK::substr(\$_,5,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 Char::GBK::substr(\$_,5,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,-5,0) eq '') {
    print qq{ok - 19 Char::GBK::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 Char::GBK::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}

$_ = '‚ ‚¢‚¤‚¦‚¨‚©‚«‚­‚¯‚±';
if (Char::GBK::substr($_,-5,0,'‚â‚ä‚æ') eq '') {
    if ($_ eq '‚ ‚¢‚¤‚¦‚¨‚â‚ä‚æ‚©‚«‚­‚¯‚±') {
        print qq{ok - 20 Char::GBK::substr(\$_,-5,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 20 Char::GBK::substr(\$_,-5,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 20 Char::GBK::substr(\$_,-5,0,'‚â‚ä‚æ') eq '' $^X $__FILE__\n};
}

__END__
