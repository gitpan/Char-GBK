# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{��} ne "\x82\xa0";

use Char::GBK;

print "1..12\n";

# Char::GBK::eval qq{...} has Char::GBK::eval "..."
if (Char::GBK::eval qq{ Char::GBK::eval " if ('�A�\' !~ /A/) { return 1 } else { return 0 } " }) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has Char::GBK::eval qq{...}
if (Char::GBK::eval qq{ Char::GBK::eval qq{ if ('�A�\' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has Char::GBK::eval '...'
if (Char::GBK::eval qq{ Char::GBK::eval ' if (qq{�A�\} !~ /A/) { return 1 } else { return 0 } ' }) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has Char::GBK::eval q{...}
if (Char::GBK::eval qq{ Char::GBK::eval q{ if ('�A�\' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has Char::GBK::eval $var
my $var = q{q{ if ('�A�\' !~ /A/) { return 1 } else { return 0 } }};
if (Char::GBK::eval qq{ Char::GBK::eval $var }) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has Char::GBK::eval (omit)
$_ = "if ('�A�\' !~ /A/) { return 1 } else { return 0 }";
if (Char::GBK::eval qq{ Char::GBK::eval }) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has Char::GBK::eval {...}
if (Char::GBK::eval qq{ Char::GBK::eval { if ('�A�\' !~ /A/) { return 1 } else { return 0 } } }) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has "..."
if (Char::GBK::eval qq{ if ('�A�\' !~ /A/) { return "1" } else { return "0" } }) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has qq{...}
if (Char::GBK::eval qq{ if ('�A�\' !~ /A/) { return qq{1} } else { return qq{0} } }) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has '...'
if (Char::GBK::eval qq{ if ('�A�\' !~ /A/) { return '1' } else { return '0' } }) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has q{...}
if (Char::GBK::eval qq{ if ('�A�\' !~ /A/) { return q{1} } else { return q{0} } }) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Char::GBK::eval qq{...} has $var
my $var1 = 1;
my $var0 = 0;
if (Char::GBK::eval qq{ if ('�A�\' !~ /A/) { return $var1 } else { return $var0 } }) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
