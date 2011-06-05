package Egbk;
######################################################################
#
# Egbk - Run-time routines for GBK.pm
#
# Copyright (c) 2008, 2009, 2010, 2011 INABA Hitoshi <ina@cpan.org>
#
######################################################################

use 5.00503;
use strict qw(subs vars);

# 12.3. Delaying use Until Runtime
# in Chapter 12. Packages, Libraries, and Modules
# of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
# (and so on)

BEGIN { eval q{ use vars qw($VERSION) } }
$VERSION = sprintf '%d.%02d', q$Revision: 0.75 $ =~ m/(\d+)/xmsg;

BEGIN {
    my $PERL5LIB = __FILE__;

    # DOS-like system
    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        $PERL5LIB =~ s{[^/]*$}{GBK};
    }

    # UNIX-like system
    else {
        $PERL5LIB =~ s{[^/]*$}{GBK};
    }

    my @inc = ();
    my %inc = ();
    for my $path ($PERL5LIB, @INC) {
        if (not exists $inc{$path}) {
            push @inc, $path;
            $inc{$path} = 1;
        }
    }
    @INC = @inc;
}

BEGIN {

    # instead of utf8.pm
    eval q{
        no warnings qw(redefine);
        *utf8::upgrade   = sub { CORE::length $_[0] };
        *utf8::downgrade = sub { 1 };
        *utf8::encode    = sub {   };
        *utf8::decode    = sub { 1 };
        *utf8::is_utf8   = sub {   };
        *utf8::valid     = sub { 1 };
    };
    if ($@) {
        *utf8::upgrade   = sub { CORE::length $_[0] };
        *utf8::downgrade = sub { 1 };
        *utf8::encode    = sub {   };
        *utf8::decode    = sub { 1 };
        *utf8::is_utf8   = sub {   };
        *utf8::valid     = sub { 1 };
    }
}

# poor Symbol.pm - substitute of real Symbol.pm
BEGIN {
    my $genpkg = "Symbol::";
    my $genseq = 0;

    sub gensym () {
        my $name = "GEN" . $genseq++;
        my $ref = \*{$genpkg . $name};
        delete $$genpkg{$name};
        $ref;
    }

    sub qualify ($;$) {
        my ($name) = @_;
        if (!ref($name) && (Egbk::index($name, '::') == -1) && (Egbk::index($name, "'") == -1)) {
            my $pkg;
            my %global = map {$_ => 1} qw(ARGV ARGVOUT ENV INC SIG STDERR STDIN STDOUT);

            # Global names: special character, "^xyz", or other.
            if ($name =~ /^(([^a-z])|(\^[a-z_]+))\z/i || $global{$name}) {
                # RGS 2001-11-05 : translate leading ^X to control-char
                $name =~ s/^\^([a-z_])/'qq(\c'.$1.')'/eei;
                $pkg = "main";
            }
            else {
                $pkg = (@_ > 1) ? $_[1] : caller;
            }
            $name = $pkg . "::" . $name;
        }
        $name;
    }

    sub qualify_to_ref ($;$) {
        no strict qw(refs);
        return \*{ qualify $_[0], @_ > 1 ? $_[1] : caller };
    }
}

# P.714 29.2.39. flock
# in Chapter 29: Functions
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

sub LOCK_SH() {1}
sub LOCK_EX() {2}
sub LOCK_UN() {8}
sub LOCK_NB() {4}

# instead of Carp.pm
sub carp(@);
sub croak(@);
sub cluck(@);
sub confess(@);

my $__FILE__ = __FILE__;

BEGIN {
    if ($^X =~ m/ jperl /oxmsi) {
        die "$0 need perl(not jperl) 5.00503 or later. (\$^X==$^X)";
    }
}

my $your_char = q{[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]};

# regexp of character
my $q_char = qr/$your_char/oxms;

#
# GBK character range per length
#
my %range_tr = ();
my $is_shiftjis_family = 0;
my $is_eucjp_family    = 0;

#
# alias of encoding name
#

BEGIN { eval q{ use vars qw($encoding_alias) } }

if (0) {
}

# Big5HKSCS
elsif (__PACKAGE__ =~ m/ \b Ebig5hkscs \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x40..0x7E,0xA1..0xFE],
             ],
    );
    $encoding_alias = qr/ \b (?: big5-?hk(?:scs)? | hk(?:scs)?[-_]?big5 ) \b /oxmsi;
}

# Big5Plus
elsif (__PACKAGE__ =~ m/ \b Ebig5plus \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x40..0x7E,0x80..0xFE],
             ],
    );
    $encoding_alias = qr/ \b (?: big-?5-?(?:plus)? | big5-?et(?:en)? | tca[-_]?big5 ) \b /oxmsi;
}

# GB18030
elsif (__PACKAGE__ =~ m/ \b Egb18030 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x40..0x7E,0x80..0xFE],
             ],
        4 => [ [0x81..0xFE],[0x30..0x39],[0x81..0xFE],[0x30..0x39],
             ],
    );
    $encoding_alias = qr/ \b (?: euc.*cn | cn.*euc | gbk | cp936 | GB[-_ ]?2312(?!-?raw) | GB18030 ) \b /oxmsi;
}

# GBK
elsif (__PACKAGE__ =~ m/ \b Egbk \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x40..0x7E,0x80..0xFE],
             ],
    );
    $encoding_alias = qr/ \b (?: euc.*cn | cn.*euc | gbk | cp936 | GB[-_ ]?2312(?!-?raw) ) \b /oxmsi;
}

# HP-15
elsif (__PACKAGE__ =~ m/ \b Ehp15 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x7F,0xA1..0xDF,0xFF],
             ],
        2 => [ [0x80..0xA0,0xE0..0xFE],[0x21..0x7E,0x80..0xFF],
             ],
    );
    $is_shiftjis_family = 1;
    $encoding_alias = qr/ \b (?: shift.*jis | sjis | windows-31j | cp932 ) \b /oxmsi;
}

# INFORMIX V6 ALS
elsif (__PACKAGE__ =~ m/ \b Einformixv6als \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x80,0xA0..0xDF,0xFE..0xFF],
             ],
        2 => [ [0x81..0x9F,0xE0..0xFC],[0x40..0x7E,0x80..0xFC],
             ],
        3 => [ [0xFD..0xFD],[0xA1..0xFE],[0xA1..0xFE],
             ],
    );
    $is_shiftjis_family = 1;
    $encoding_alias = qr/ \b (?: shift.*jis | sjis | windows-31j | cp932 ) \b /oxmsi;
}

# Shift_JIS
elsif (__PACKAGE__ =~ m/ \b E s j i s \z/oxms) { # escape from build system
    %range_tr = (
        1 => [ [0x00..0x80,0xA0..0xDF,0xFD..0xFF],
             ],
        2 => [ [0x81..0x9F,0xE0..0xFC],[0x40..0x7E,0x80..0xFC],
             ],
    );
    $is_shiftjis_family = 1;
    $encoding_alias = qr/ \b (?: shift.*jis | sjis | windows-31j | cp932 ) \b /oxmsi;
}

# UHC
elsif (__PACKAGE__ =~ m/ \b Euhc \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x80,0xFF],
             ],
        2 => [ [0x81..0xFE],[0x41..0x5A,0x61..0x7A,0x81..0xFE],
             ],
    );
    $encoding_alias = qr/ \b (?: euc.*kr | kr.*euc | (?:x-)?uhc | (?:x-)?windows-949 | ks_c_5601-1987 | cp949 ) \b /oxmsi;
}

# US-ASCII
elsif (__PACKAGE__ =~ m/ \b Eusascii \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: (?:US-?)?ASCII ) \b /oxmsi;
}

# Latin-1
elsif (__PACKAGE__ =~ m/ \b Elatin1 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-1 | IEC[- ]?8859-1 | Latin-?1 ) \b /oxmsi;
}

# Latin-2
elsif (__PACKAGE__ =~ m/ \b Elatin2 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-2 | IEC[- ]?8859-2 | Latin-?2 ) \b /oxmsi;
}

# Latin-3
elsif (__PACKAGE__ =~ m/ \b Elatin3 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-3 | IEC[- ]?8859-3 | Latin-?3 ) \b /oxmsi;
}

# Latin-4
elsif (__PACKAGE__ =~ m/ \b Elatin4 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-4 | IEC[- ]?8859-4 | Latin-?4 ) \b /oxmsi;
}

# Cyrillic
elsif (__PACKAGE__ =~ m/ \b Ecyrillic \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-5 | IEC[- ]?8859-5 | Cyrillic ) \b /oxmsi;
}

# Greek
elsif (__PACKAGE__ =~ m/ \b Egreek \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-7 | IEC[- ]?8859-7 | Greek ) \b /oxmsi;
}

# Latin-5
elsif (__PACKAGE__ =~ m/ \b Elatin5 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-9 | IEC[- ]?8859-9 | Latin-?5 ) \b /oxmsi;
}

# Latin-6
elsif (__PACKAGE__ =~ m/ \b Elatin6 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-10 | IEC[- ]?8859-10 | Latin-?6 ) \b /oxmsi;
}

# Latin-7
elsif (__PACKAGE__ =~ m/ \b Elatin7 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-13 | IEC[- ]?8859-13 | Latin-?7 ) \b /oxmsi;
}

# Latin-8
elsif (__PACKAGE__ =~ m/ \b Elatin8 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-14 | IEC[- ]?8859-14 | Latin-?8 ) \b /oxmsi;
}

# Latin-9
elsif (__PACKAGE__ =~ m/ \b Elatin9 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-15 | IEC[- ]?8859-15 | Latin-?9 ) \b /oxmsi;
}

# Latin-10
elsif (__PACKAGE__ =~ m/ \b Elatin10 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: ISO[-_ ]?8859-16 | IEC[- ]?8859-16 | Latin-?10 ) \b /oxmsi;
}

# Windows-1252
elsif (__PACKAGE__ =~ m/ \b Ewindows1252 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: Windows-?1252 ) \b /oxmsi;
}

# EUC-JP
elsif (__PACKAGE__ =~ m/ \b Eeucjp \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x8D,0x90..0xA0,0xFF],
             ],
        2 => [ [0x8E..0x8E],[0xA1..0xDF],
               [0xA1..0xFE],[0xA1..0xFE],
             ],
        3 => [ [0x8F..0x8F],[0xA1..0xFE],[0xA1..0xFE],
             ],
    );
    $is_eucjp_family = 1;
    $encoding_alias = qr/ \b (?: euc.*jp | jp.*euc | ujis ) \b /oxmsi;
}

# UTF-2
elsif (__PACKAGE__ =~ m/ \b Eutf2 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x7F],
             ],
        2 => [ [0xC2..0xDF],[0x80..0xBF],
             ],
        3 => [ [0xE0..0xE0],[0xA0..0xBF],[0x80..0xBF],
               [0xE1..0xEC],[0x80..0xBF],[0x80..0xBF],
               [0xED..0xED],[0x80..0x9F],[0x80..0xBF],
               [0xEE..0xEF],[0x80..0xBF],[0x80..0xBF],
             ],
        4 => [ [0xF0..0xF0],[0x90..0xBF],[0x80..0xBF],[0x80..0xBF],
               [0xF1..0xF3],[0x80..0xBF],[0x80..0xBF],[0x80..0xBF],
               [0xF4..0xF4],[0x80..0x8F],[0x80..0xBF],[0x80..0xBF],
             ],
    );
    $encoding_alias = qr/ \b (?: UTF-8 | utf-8-strict | UTF-?2 ) \b /oxmsi;
}

# Old UTF-8
elsif (__PACKAGE__ =~ m/ \b Eoldutf8 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x7F],
             ],
        2 => [ [0xC0..0xDF],[0x80..0xBF],
             ],
        3 => [ [0xE0..0xEF],[0x80..0xBF],[0x80..0xBF],
             ],
        4 => [ [0xF0..0xF4],[0x80..0xBF],[0x80..0xBF],[0x80..0xBF],
             ],
    );
    $encoding_alias = qr/ \b (?: utf8 | CESU-?8 | Modified[ ]?UTF-?8 | Old[ ]?UTF-?8 ) \b /oxmsi;
}

else {
    croak "$0 don't know my package name '" . __PACKAGE__ . "'";
}

#
# Prototypes of subroutines
#
sub import() {}
sub unimport() {}
sub Egbk::split(;$$$);
sub Egbk::tr($$$$;$);
sub Egbk::chop(@);
sub Egbk::index($$;$);
sub Egbk::rindex($$;$);
sub Egbk::lcfirst(@);
sub Egbk::lcfirst_();
sub Egbk::lc(@);
sub Egbk::lc_();
sub Egbk::ucfirst(@);
sub Egbk::ucfirst_();
sub Egbk::uc(@);
sub Egbk::uc_();
sub Egbk::ignorecase(@);
sub Egbk::capture($);
sub Egbk::chr(;$);
sub Egbk::chr_();
sub Egbk::filetest(@);
sub Egbk::r(;*@);
sub Egbk::w(;*@);
sub Egbk::x(;*@);
sub Egbk::o(;*@);
sub Egbk::R(;*@);
sub Egbk::W(;*@);
sub Egbk::X(;*@);
sub Egbk::O(;*@);
sub Egbk::e(;*@);
sub Egbk::z(;*@);
sub Egbk::s(;*@);
sub Egbk::f(;*@);
sub Egbk::d(;*@);
sub Egbk::l(;*@);
sub Egbk::p(;*@);
sub Egbk::S(;*@);
sub Egbk::b(;*@);
sub Egbk::c(;*@);
sub Egbk::u(;*@);
sub Egbk::g(;*@);
sub Egbk::k(;*@);
sub Egbk::T(;*@);
sub Egbk::B(;*@);
sub Egbk::M(;*@);
sub Egbk::A(;*@);
sub Egbk::C(;*@);
sub Egbk::filetest_(@);
sub Egbk::r_();
sub Egbk::w_();
sub Egbk::x_();
sub Egbk::o_();
sub Egbk::R_();
sub Egbk::W_();
sub Egbk::X_();
sub Egbk::O_();
sub Egbk::e_();
sub Egbk::z_();
sub Egbk::s_();
sub Egbk::f_();
sub Egbk::d_();
sub Egbk::l_();
sub Egbk::p_();
sub Egbk::S_();
sub Egbk::b_();
sub Egbk::c_();
sub Egbk::u_();
sub Egbk::g_();
sub Egbk::k_();
sub Egbk::T_();
sub Egbk::B_();
sub Egbk::M_();
sub Egbk::A_();
sub Egbk::C_();
sub Egbk::glob($);
sub Egbk::glob_();
sub Egbk::lstat(*);
sub Egbk::lstat_();
sub Egbk::opendir(*$);
sub Egbk::stat(*);
sub Egbk::stat_();
sub Egbk::unlink(@);
sub Egbk::chdir(;$);
sub Egbk::do($);
sub Egbk::require(;$);
sub Egbk::telldir(*);

sub GBK::ord(;$);
sub GBK::ord_();
sub GBK::reverse(@);
sub GBK::length(;$);
sub GBK::substr($$;$$);
sub GBK::index($$;$);
sub GBK::rindex($$;$);

#
# @ARGV wildcard globbing
#
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    if ($ENV{'ComSpec'} =~ / (?: COMMAND\.COM | CMD\.EXE ) \z /oxmsi) {
        my @argv = ();
        for (@ARGV) {
            if (m/\A ' ((?:$q_char)*) ' \z/oxms) {
                push @argv, $1;
            }
            elsif (m/\A (?:$q_char)*? [*?] /oxms and (my @glob = Egbk::glob($_))) {
                push @argv, @glob;
            }
            else {
                push @argv, $_;
            }
        }
        @ARGV = @argv;
    }
}

#
# GBK split
#
sub Egbk::split(;$$$) {

    # P.794 29.2.161. split
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    my $pattern = $_[0];
    my $string  = $_[1];
    my $limit   = $_[2];

    # if $string is omitted, the function splits the $_ string
    if (not defined $string) {
        if (defined $_) {
            $string = $_;
        }
        else {
            $string = '';
        }
    }

    my @split = ();

    # when string is empty
    if ($string eq '') {

        # resulting list value in list context
        if (wantarray) {
            return @split;
        }

        # count of substrings in scalar context
        else {
            carp "$0: Use of implicit split to \@_ is deprecated" if $^W;
            @_ = @split;
            return scalar @_;
        }
    }

    # if $limit is negative, it is treated as if an arbitrarily large $limit has been specified
    if ((not defined $limit) or ($limit <= 0)) {

        # if $pattern is also omitted or is the literal space, " ", the function splits
        # on whitespace, /\s+/, after skipping any leading whitespace
        # (and so on)

        if ((not defined $pattern) or ($pattern eq ' ')) {
            $string =~ s/ \A \s+ //oxms;

            # P.1024 Appendix W.10 Multibyte Processing
            # of ISBN 1-56592-224-7 CJKV Information Processing
            # (and so on)

            # the //m modifier is assumed when you split on the pattern /^/
            # (and so on)

            while ($string =~ s/\A((?:$q_char)*?)\s+//m) {

                # if the $pattern contains parentheses, then the substring matched by each pair of parentheses
                # is included in the resulting list, interspersed with the fields that are ordinarily returned
                # (and so on)

                local $@;
                for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                    push @split, eval '$' . $digit;
                }
            }
        }

        # a pattern capable of matching either the null string or something longer than the
        # null string will split the value of $string into separate characters wherever it
        # matches the null string between characters
        # (and so on)

        elsif ('' =~ m/ \A $pattern \z /xms) {
            while ($string =~ s/\A((?:$q_char)+?)$pattern//m) {
                local $@;
                for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                    push @split, eval '$' . $digit;
                }
            }
        }

        else {
            while ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                local $@;
                for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                    push @split, eval '$' . $digit;
                }
            }
        }
    }

    else {
        if ((not defined $pattern) or ($pattern eq ' ')) {
            $string =~ s/ \A \s+ //oxms;
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)*?)\s+//m) {
                    local $@;
                    for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                        push @split, eval '$' . $digit;
                    }
                }
            }
        }
        elsif ('' =~ m/ \A $pattern \z /xms) {
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)+?)$pattern//m) {
                    local $@;
                    for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                        push @split, eval '$' . $digit;
                    }
                }
            }
        }
        else {
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                    local $@;
                    for (my $digit=1; eval "defined(\$$digit)"; $digit++) {
                        push @split, eval '$' . $digit;
                    }
                }
            }
        }
    }

    push @split, $string;

    # if $limit is omitted or zero, trailing null fields are stripped from the result
    if ((not defined $limit) or ($limit == 0)) {
        while ((scalar(@split) >= 1) and ($split[-1] eq '')) {
            pop @split;
        }
    }

    # resulting list value in list context
    if (wantarray) {
        return @split;
    }

    # count of substrings in scalar context
    else {
        carp "$0: Use of implicit split to \@_ is deprecated" if $^W;
        @_ = @split;
        return scalar @_;
    }
}

#
# GBK transliteration (tr///)
#
sub Egbk::tr($$$$;$) {

    my $bind_operator   = $_[1];
    my $searchlist      = $_[2];
    my $replacementlist = $_[3];
    my $modifier        = $_[4] || '';

    if ($modifier =~ m/r/oxms) {
        if ($bind_operator =~ m/ !~ /oxms) {
            croak "$0: Using !~ with tr///r doesn't make sense";
        }
    }

    my @char            = $_[0] =~ m/\G ($q_char) /oxmsg;
    my @searchlist      = _charlist_tr($searchlist);
    my @replacementlist = _charlist_tr($replacementlist);

    my %tr = ();
    for (my $i=0; $i <= $#searchlist; $i++) {
        if (not exists $tr{$searchlist[$i]}) {
            if (defined $replacementlist[$i] and ($replacementlist[$i] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[$i];
            }
            elsif ($modifier =~ m/d/oxms) {
                $tr{$searchlist[$i]} = '';
            }
            elsif (defined $replacementlist[-1] and ($replacementlist[-1] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[-1];
            }
            else {
                $tr{$searchlist[$i]} = $searchlist[$i];
            }
        }
    }

    my $tr = 0;
    my $replaced = '';
    if ($modifier =~ m/c/oxms) {
        while (defined(my $char = shift @char)) {
            if (not exists $tr{$char}) {
                if (defined $replacementlist[0]) {
                    $replaced .= $replacementlist[0];
                }
                $tr++;
                if ($modifier =~ m/s/oxms) {
                    while (@char and (not exists $tr{$char[0]})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $replaced .= $char;
            }
        }
    }
    else {
        while (defined(my $char = shift @char)) {
            if (exists $tr{$char}) {
                $replaced .= $tr{$char};
                $tr++;
                if ($modifier =~ m/s/oxms) {
                    while (@char and (exists $tr{$char[0]}) and ($tr{$char[0]} eq $tr{$char})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $replaced .= $char;
            }
        }
    }

    if ($modifier =~ m/r/oxms) {
        return $replaced;
    }
    else {
        $_[0] = $replaced;
        if ($bind_operator =~ m/ !~ /oxms) {
            return not $tr;
        }
        else {
            return $tr;
        }
    }
}

#
# GBK chop
#
sub Egbk::chop(@) {

    my $chop;
    if (@_ == 0) {
        my @char = m/\G ($q_char) /oxmsg;
        $chop = pop @char;
        $_ = join '', @char;
    }
    else {
        for (@_) {
            my @char = m/\G ($q_char) /oxmsg;
            $chop = pop @char;
            $_ = join '', @char;
        }
    }
    return $chop;
}

#
# GBK index by octet
#
sub Egbk::index($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= 0;
    my $pos = 0;

    while ($pos < CORE::length($str)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            if ($pos >= $position) {
                return $pos;
            }
        }
        if (CORE::substr($str,$pos) =~ m/\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return -1;
}

#
# GBK reverse index
#
sub Egbk::rindex($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= CORE::length($str) - 1;
    my $pos = 0;
    my $rindex = -1;

    while (($pos < CORE::length($str)) and ($pos <= $position)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            $rindex = $pos;
        }
        if (CORE::substr($str,$pos) =~ m/\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return $rindex;
}

#
# GBK lower case
#
{
    # P.132 4.8.2. Lexically Scoped Variables: my
    # in Chapter 4: Statements and Declarations
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.
    # (and so on)

    my %lc = ();
    @lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
        qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

    if (0) {
    }

    elsif (__PACKAGE__ =~ m/ \b Eusascii \z/oxms) {
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin1 \z/oxms) {
        %lc = (%lc,
            "\xC0" => "\xE0", # LATIN LETTER A WITH GRAVE
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH TILDE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
            "\xC6" => "\xE6", # LATIN LETTER AE
            "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
            "\xC8" => "\xE8", # LATIN LETTER E WITH GRAVE
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER I WITH GRAVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
            "\xD0" => "\xF0", # LATIN LETTER ETH (Icelandic)
            "\xD1" => "\xF1", # LATIN LETTER N WITH TILDE
            "\xD2" => "\xF2", # LATIN LETTER O WITH GRAVE
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD8" => "\xF8", # LATIN LETTER O WITH STROKE
            "\xD9" => "\xF9", # LATIN LETTER U WITH GRAVE
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER Y WITH ACUTE
            "\xDE" => "\xFE", # LATIN LETTER THORN (Icelandic)
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin2 \z/oxms) {
        %lc = (%lc,
            "\xA1" => "\xB1", # LATIN LETTER A WITH OGONEK
            "\xA3" => "\xB3", # LATIN LETTER L WITH STROKE
            "\xA5" => "\xB5", # LATIN LETTER L WITH CARON
            "\xA6" => "\xB6", # LATIN LETTER S WITH ACUTE
            "\xA9" => "\xB9", # LATIN LETTER S WITH CARON
            "\xAA" => "\xBA", # LATIN LETTER S WITH CEDILLA
            "\xAB" => "\xBB", # LATIN LETTER T WITH CARON
            "\xAC" => "\xBC", # LATIN LETTER Z WITH ACUTE
            "\xAE" => "\xBE", # LATIN LETTER Z WITH CARON
            "\xAF" => "\xBF", # LATIN LETTER Z WITH DOT ABOVE
            "\xC0" => "\xE0", # LATIN LETTER R WITH ACUTE
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH BREVE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER L WITH ACUTE
            "\xC6" => "\xE6", # LATIN LETTER C WITH ACUTE
            "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
            "\xC8" => "\xE8", # LATIN LETTER C WITH CARON
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH OGONEK
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER E WITH CARON
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER D WITH CARON
            "\xD0" => "\xF0", # LATIN LETTER D WITH STROKE
            "\xD1" => "\xF1", # LATIN LETTER N WITH ACUTE
            "\xD2" => "\xF2", # LATIN LETTER N WITH CARON
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH DOUBLE ACUTE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD8" => "\xF8", # LATIN LETTER R WITH CARON
            "\xD9" => "\xF9", # LATIN LETTER U WITH RING ABOVE
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH DOUBLE ACUTE
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER Y WITH ACUTE
            "\xDE" => "\xFE", # LATIN LETTER T WITH CEDILLA
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin3 \z/oxms) {
        %lc = (%lc,
            "\xA1" => "\xB1", # LATIN LETTER H WITH STROKE
            "\xA6" => "\xB6", # LATIN LETTER H WITH CIRCUMFLEX
            "\xAA" => "\xBA", # LATIN LETTER S WITH CEDILLA
            "\xAB" => "\xBB", # LATIN LETTER G WITH BREVE
            "\xAC" => "\xBC", # LATIN LETTER J WITH CIRCUMFLEX
            "\xAF" => "\xBF", # LATIN LETTER Z WITH DOT ABOVE
            "\xC0" => "\xE0", # LATIN LETTER A WITH GRAVE
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER C WITH DOT ABOVE
            "\xC6" => "\xE6", # LATIN LETTER C WITH CIRCUMFLEX
            "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
            "\xC8" => "\xE8", # LATIN LETTER E WITH GRAVE
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER I WITH GRAVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
            "\xD1" => "\xF1", # LATIN LETTER N WITH TILDE
            "\xD2" => "\xF2", # LATIN LETTER O WITH GRAVE
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER G WITH DOT ABOVE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD8" => "\xF8", # LATIN LETTER G WITH CIRCUMFLEX
            "\xD9" => "\xF9", # LATIN LETTER U WITH GRAVE
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER U WITH BREVE
            "\xDE" => "\xFE", # LATIN LETTER S WITH CIRCUMFLEX
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin4 \z/oxms) {
        %lc = (%lc,
            "\xA1" => "\xB1", # LATIN LETTER A WITH OGONEK
            "\xA3" => "\xB3", # LATIN LETTER R WITH CEDILLA
            "\xA5" => "\xB5", # LATIN LETTER I WITH TILDE
            "\xA6" => "\xB6", # LATIN LETTER L WITH CEDILLA
            "\xA9" => "\xB9", # LATIN LETTER S WITH CARON
            "\xAA" => "\xBA", # LATIN LETTER E WITH MACRON
            "\xAB" => "\xBB", # LATIN LETTER G WITH CEDILLA
            "\xAC" => "\xBC", # LATIN LETTER T WITH STROKE
            "\xAE" => "\xBE", # LATIN LETTER Z WITH CARON
            "\xBD" => "\xBF", # LATIN LETTER ENG
            "\xC0" => "\xE0", # LATIN LETTER A WITH MACRON
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH TILDE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
            "\xC6" => "\xE6", # LATIN LETTER AE
            "\xC7" => "\xE7", # LATIN LETTER I WITH OGONEK
            "\xC8" => "\xE8", # LATIN LETTER C WITH CARON
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH OGONEK
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER E WITH DOT ABOVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH MACRON
            "\xD0" => "\xF0", # LATIN LETTER D WITH STROKE
            "\xD1" => "\xF1", # LATIN LETTER N WITH CEDILLA
            "\xD2" => "\xF2", # LATIN LETTER O WITH MACRON
            "\xD3" => "\xF3", # LATIN LETTER K WITH CEDILLA
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD8" => "\xF8", # LATIN LETTER O WITH STROKE
            "\xD9" => "\xF9", # LATIN LETTER U WITH OGONEK
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER U WITH TILDE
            "\xDE" => "\xFE", # LATIN LETTER U WITH MACRON
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Ecyrillic \z/oxms) {
        %lc = (%lc,
            "\xA1" => "\xF1", # CYRILLIC LETTER IO
            "\xA2" => "\xF2", # CYRILLIC LETTER DJE
            "\xA3" => "\xF3", # CYRILLIC LETTER GJE
            "\xA4" => "\xF4", # CYRILLIC LETTER UKRAINIAN IE
            "\xA5" => "\xF5", # CYRILLIC LETTER DZE
            "\xA6" => "\xF6", # CYRILLIC LETTER BYELORUSSIAN-UKRAINIAN I
            "\xA7" => "\xF7", # CYRILLIC LETTER YI
            "\xA8" => "\xF8", # CYRILLIC LETTER JE
            "\xA9" => "\xF9", # CYRILLIC LETTER LJE
            "\xAA" => "\xFA", # CYRILLIC LETTER NJE
            "\xAB" => "\xFB", # CYRILLIC LETTER TSHE
            "\xAC" => "\xFC", # CYRILLIC LETTER KJE
            "\xAE" => "\xFE", # CYRILLIC LETTER SHORT U
            "\xAF" => "\xFF", # CYRILLIC LETTER DZHE
            "\xB0" => "\xD0", # CYRILLIC LETTER A
            "\xB1" => "\xD1", # CYRILLIC LETTER BE
            "\xB2" => "\xD2", # CYRILLIC LETTER VE
            "\xB3" => "\xD3", # CYRILLIC LETTER GHE
            "\xB4" => "\xD4", # CYRILLIC LETTER DE
            "\xB5" => "\xD5", # CYRILLIC LETTER IE
            "\xB6" => "\xD6", # CYRILLIC LETTER ZHE
            "\xB7" => "\xD7", # CYRILLIC LETTER ZE
            "\xB8" => "\xD8", # CYRILLIC LETTER I
            "\xB9" => "\xD9", # CYRILLIC LETTER SHORT I
            "\xBA" => "\xDA", # CYRILLIC LETTER KA
            "\xBB" => "\xDB", # CYRILLIC LETTER EL
            "\xBC" => "\xDC", # CYRILLIC LETTER EM
            "\xBD" => "\xDD", # CYRILLIC LETTER EN
            "\xBE" => "\xDE", # CYRILLIC LETTER O
            "\xBF" => "\xDF", # CYRILLIC LETTER PE
            "\xC0" => "\xE0", # CYRILLIC LETTER ER
            "\xC1" => "\xE1", # CYRILLIC LETTER ES
            "\xC2" => "\xE2", # CYRILLIC LETTER TE
            "\xC3" => "\xE3", # CYRILLIC LETTER U
            "\xC4" => "\xE4", # CYRILLIC LETTER EF
            "\xC5" => "\xE5", # CYRILLIC LETTER HA
            "\xC6" => "\xE6", # CYRILLIC LETTER TSE
            "\xC7" => "\xE7", # CYRILLIC LETTER CHE
            "\xC8" => "\xE8", # CYRILLIC LETTER SHA
            "\xC9" => "\xE9", # CYRILLIC LETTER SHCHA
            "\xCA" => "\xEA", # CYRILLIC LETTER HARD SIGN
            "\xCB" => "\xEB", # CYRILLIC LETTER YERU
            "\xCC" => "\xEC", # CYRILLIC LETTER SOFT SIGN
            "\xCD" => "\xED", # CYRILLIC LETTER E
            "\xCE" => "\xEE", # CYRILLIC LETTER YU
            "\xCF" => "\xEF", # CYRILLIC LETTER YA
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Egreek \z/oxms) {
        %lc = (%lc,
            "\xB6" => "\xDC", # GREEK LETTER ALPHA WITH TONOS
            "\xB8" => "\xDD", # GREEK LETTER EPSILON WITH TONOS
            "\xB9" => "\xDE", # GREEK LETTER ETA WITH TONOS
            "\xBA" => "\xDF", # GREEK LETTER IOTA WITH TONOS
            "\xBC" => "\xFC", # GREEK LETTER OMICRON WITH TONOS
            "\xBE" => "\xFD", # GREEK LETTER UPSILON WITH TONOS
            "\xBF" => "\xFE", # GREEK LETTER OMEGA WITH TONOS
            "\xC1" => "\xE1", # GREEK LETTER ALPHA
            "\xC2" => "\xE2", # GREEK LETTER BETA
            "\xC3" => "\xE3", # GREEK LETTER GAMMA
            "\xC4" => "\xE4", # GREEK LETTER DELTA
            "\xC5" => "\xE5", # GREEK LETTER EPSILON
            "\xC6" => "\xE6", # GREEK LETTER ZETA
            "\xC7" => "\xE7", # GREEK LETTER ETA
            "\xC8" => "\xE8", # GREEK LETTER THETA
            "\xC9" => "\xE9", # GREEK LETTER IOTA
            "\xCA" => "\xEA", # GREEK LETTER KAPPA
            "\xCB" => "\xEB", # GREEK LETTER LAMDA
            "\xCC" => "\xEC", # GREEK LETTER MU
            "\xCD" => "\xED", # GREEK LETTER NU
            "\xCE" => "\xEE", # GREEK LETTER XI
            "\xCF" => "\xEF", # GREEK LETTER OMICRON
            "\xD0" => "\xF0", # GREEK LETTER PI
            "\xD1" => "\xF1", # GREEK LETTER RHO
            "\xD3" => "\xF3", # GREEK LETTER SIGMA
            "\xD4" => "\xF4", # GREEK LETTER TAU
            "\xD5" => "\xF5", # GREEK LETTER UPSILON
            "\xD6" => "\xF6", # GREEK LETTER PHI
            "\xD7" => "\xF7", # GREEK LETTER CHI
            "\xD8" => "\xF8", # GREEK LETTER PSI
            "\xD9" => "\xF9", # GREEK LETTER OMEGA
            "\xDA" => "\xFA", # GREEK LETTER IOTA WITH DIALYTIKA
            "\xDB" => "\xFB", # GREEK LETTER UPSILON WITH DIALYTIKA
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin5 \z/oxms) {
        %lc = (%lc,
            "\xC0" => "\xE0", # LATIN LETTER A WITH GRAVE
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH TILDE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
            "\xC6" => "\xE6", # LATIN LETTER AE
            "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
            "\xC8" => "\xE8", # LATIN LETTER E WITH GRAVE
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER I WITH GRAVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
            "\xD0" => "\xF0", # LATIN LETTER G WITH BREVE
            "\xD1" => "\xF1", # LATIN LETTER N WITH TILDE
            "\xD2" => "\xF2", # LATIN LETTER O WITH GRAVE
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD8" => "\xF8", # LATIN LETTER O WITH STROKE
            "\xD9" => "\xF9", # LATIN LETTER U WITH GRAVE
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDE" => "\xFE", # LATIN LETTER S WITH CEDILLA
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin6 \z/oxms) {
        %lc = (%lc,
            "\xA1" => "\xB1", # LATIN LETTER A WITH OGONEK
            "\xA2" => "\xB2", # LATIN LETTER E WITH MACRON
            "\xA3" => "\xB3", # LATIN LETTER G WITH CEDILLA
            "\xA4" => "\xB4", # LATIN LETTER I WITH MACRON
            "\xA5" => "\xB5", # LATIN LETTER I WITH TILDE
            "\xA6" => "\xB6", # LATIN LETTER K WITH CEDILLA
            "\xA8" => "\xB8", # LATIN LETTER L WITH CEDILLA
            "\xA9" => "\xB9", # LATIN LETTER D WITH STROKE
            "\xAA" => "\xBA", # LATIN LETTER S WITH CARON
            "\xAB" => "\xBB", # LATIN LETTER T WITH STROKE
            "\xAC" => "\xBC", # LATIN LETTER Z WITH CARON
            "\xAE" => "\xBE", # LATIN LETTER U WITH MACRON
            "\xAF" => "\xBF", # LATIN LETTER ENG
            "\xC0" => "\xE0", # LATIN LETTER A WITH MACRON
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH TILDE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
            "\xC6" => "\xE6", # LATIN LETTER AE
            "\xC7" => "\xE7", # LATIN LETTER I WITH OGONEK
            "\xC8" => "\xE8", # LATIN LETTER C WITH CARON
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH OGONEK
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER E WITH DOT ABOVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
            "\xD0" => "\xF0", # LATIN LETTER ETH (Icelandic)
            "\xD1" => "\xF1", # LATIN LETTER N WITH CEDILLA
            "\xD2" => "\xF2", # LATIN LETTER O WITH MACRON
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD7" => "\xF7", # LATIN LETTER U WITH TILDE
            "\xD8" => "\xF8", # LATIN LETTER O WITH STROKE
            "\xD9" => "\xF9", # LATIN LETTER U WITH OGONEK
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER Y WITH ACUTE
            "\xDE" => "\xFE", # LATIN LETTER THORN (Icelandic)
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin7 \z/oxms) {
        %lc = (%lc,
            "\xA8" => "\xB8", # LATIN LETTER O WITH STROKE
            "\xAA" => "\xBA", # LATIN LETTER R WITH CEDILLA
            "\xAF" => "\xBF", # LATIN LETTER AE
            "\xC0" => "\xE0", # LATIN LETTER A WITH OGONEK
            "\xC1" => "\xE1", # LATIN LETTER I WITH OGONEK
            "\xC2" => "\xE2", # LATIN LETTER A WITH MACRON
            "\xC3" => "\xE3", # LATIN LETTER C WITH ACUTE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
            "\xC6" => "\xE6", # LATIN LETTER E WITH OGONEK
            "\xC7" => "\xE7", # LATIN LETTER E WITH MACRON
            "\xC8" => "\xE8", # LATIN LETTER C WITH CARON
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER Z WITH ACUTE
            "\xCB" => "\xEB", # LATIN LETTER E WITH DOT ABOVE
            "\xCC" => "\xEC", # LATIN LETTER G WITH CEDILLA
            "\xCD" => "\xED", # LATIN LETTER K WITH CEDILLA
            "\xCE" => "\xEE", # LATIN LETTER I WITH MACRON
            "\xCF" => "\xEF", # LATIN LETTER L WITH CEDILLA
            "\xD0" => "\xF0", # LATIN LETTER S WITH CARON
            "\xD1" => "\xF1", # LATIN LETTER N WITH ACUTE
            "\xD2" => "\xF2", # LATIN LETTER N WITH CEDILLA
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH MACRON
            "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD8" => "\xF8", # LATIN LETTER U WITH OGONEK
            "\xD9" => "\xF9", # LATIN LETTER L WITH STROKE
            "\xDA" => "\xFA", # LATIN LETTER S WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH MACRON
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER Z WITH DOT ABOVE
            "\xDE" => "\xFE", # LATIN LETTER Z WITH CARON
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin8 \z/oxms) {
        %lc = (%lc,
            "\xA1" => "\xA2", # LATIN LETTER B WITH DOT ABOVE
            "\xA4" => "\xA5", # LATIN LETTER C WITH DOT ABOVE
            "\xA6" => "\xAB", # LATIN LETTER D WITH DOT ABOVE
            "\xA8" => "\xB8", # LATIN LETTER W WITH GRAVE
            "\xAA" => "\xBA", # LATIN LETTER W WITH ACUTE
            "\xAC" => "\xBC", # LATIN LETTER Y WITH GRAVE
            "\xAF" => "\xFF", # LATIN LETTER Y WITH DIAERESIS
            "\xB0" => "\xB1", # LATIN LETTER F WITH DOT ABOVE
            "\xB2" => "\xB3", # LATIN LETTER G WITH DOT ABOVE
            "\xB4" => "\xB5", # LATIN LETTER M WITH DOT ABOVE
            "\xB7" => "\xB9", # LATIN LETTER P WITH DOT ABOVE
            "\xBB" => "\xBF", # LATIN LETTER S WITH DOT ABOVE
            "\xBD" => "\xBE", # LATIN LETTER W WITH DIAERESIS
            "\xC0" => "\xE0", # LATIN LETTER A WITH GRAVE
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH TILDE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
            "\xC6" => "\xE6", # LATIN LETTER AE
            "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
            "\xC8" => "\xE8", # LATIN LETTER E WITH GRAVE
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER I WITH GRAVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
            "\xD0" => "\xF0", # LATIN LETTER W WITH CIRCUMFLEX
            "\xD1" => "\xF1", # LATIN LETTER N WITH TILDE
            "\xD2" => "\xF2", # LATIN LETTER O WITH GRAVE
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD7" => "\xF7", # LATIN LETTER T WITH DOT ABOVE
            "\xD8" => "\xF8", # LATIN LETTER O WITH STROKE
            "\xD9" => "\xF9", # LATIN LETTER U WITH GRAVE
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER Y WITH ACUTE
            "\xDE" => "\xFE", # LATIN LETTER Y WITH CIRCUMFLEX
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin9 \z/oxms) {
        %lc = (%lc,
            "\xA6" => "\xA8", # LATIN LETTER S WITH CARON
            "\xB4" => "\xB8", # LATIN LETTER Z WITH CARON
            "\xBC" => "\xBD", # LATIN LIGATURE OE
            "\xBE" => "\xFF", # LATIN LETTER Y WITH DIAERESIS
            "\xC0" => "\xE0", # LATIN LETTER A WITH GRAVE
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH TILDE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
            "\xC6" => "\xE6", # LATIN LETTER AE
            "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
            "\xC8" => "\xE8", # LATIN LETTER E WITH GRAVE
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER I WITH GRAVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
            "\xD0" => "\xF0", # LATIN LETTER ETH
            "\xD1" => "\xF1", # LATIN LETTER N WITH TILDE
            "\xD2" => "\xF2", # LATIN LETTER O WITH GRAVE
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD8" => "\xF8", # LATIN LETTER O WITH STROKE
            "\xD9" => "\xF9", # LATIN LETTER U WITH GRAVE
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER Y WITH ACUTE
            "\xDE" => "\xFE", # LATIN LETTER THORN
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin10 \z/oxms) {
        %lc = (%lc,
            "\xA1" => "\xA2", # LATIN LETTER A WITH OGONEK
            "\xA3" => "\xB3", # LATIN LETTER L WITH STROKE
            "\xA6" => "\xA8", # LATIN LETTER S WITH CARON
            "\xAA" => "\xBA", # LATIN LETTER S WITH COMMA BELOW
            "\xAC" => "\xAE", # LATIN LETTER Z WITH ACUTE
            "\xAF" => "\xBF", # LATIN LETTER Z WITH DOT ABOVE
            "\xB2" => "\xB9", # LATIN LETTER C WITH CARON
            "\xB4" => "\xB8", # LATIN LETTER Z WITH CARON
            "\xBC" => "\xBD", # LATIN LIGATURE OE
            "\xBE" => "\xFF", # LATIN LETTER Y WITH DIAERESIS
            "\xC0" => "\xE0", # LATIN LETTER A WITH GRAVE
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH BREVE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER C WITH ACUTE
            "\xC6" => "\xE6", # LATIN LETTER AE
            "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
            "\xC8" => "\xE8", # LATIN LETTER E WITH GRAVE
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER I WITH GRAVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
            "\xD0" => "\xF0", # LATIN LETTER D WITH STROKE
            "\xD1" => "\xF1", # LATIN LETTER N WITH ACUTE
            "\xD2" => "\xF2", # LATIN LETTER O WITH GRAVE
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH DOUBLE ACUTE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD7" => "\xF7", # LATIN LETTER S WITH ACUTE
            "\xD8" => "\xF8", # LATIN LETTER U WITH DOUBLE ACUTE
            "\xD9" => "\xF9", # LATIN LETTER U WITH GRAVE
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER E WITH OGONEK
            "\xDE" => "\xFE", # LATIN LETTER T WITH COMMA BELOW
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Ewindows1252 \z/oxms) {
        %lc = (%lc,
            "\x8A" => "\x9A", # LATIN LETTER S WITH CARON
            "\x8C" => "\x9C", # LATIN LIGATURE OE
            "\x8E" => "\x9E", # LATIN LETTER Z WITH CARON
            "\x9F" => "\xFF", # LATIN LETTER Y WITH DIAERESIS
            "\xC0" => "\xE0", # LATIN LETTER A WITH GRAVE
            "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
            "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xC3" => "\xE3", # LATIN LETTER A WITH TILDE
            "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
            "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
            "\xC6" => "\xE6", # LATIN LETTER AE
            "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
            "\xC8" => "\xE8", # LATIN LETTER E WITH GRAVE
            "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
            "\xCA" => "\xEA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
            "\xCC" => "\xEC", # LATIN LETTER I WITH GRAVE
            "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
            "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
            "\xD0" => "\xF0", # LATIN LETTER ETH
            "\xD1" => "\xF1", # LATIN LETTER N WITH TILDE
            "\xD2" => "\xF2", # LATIN LETTER O WITH GRAVE
            "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
            "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
            "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
            "\xD8" => "\xF8", # LATIN LETTER O WITH STROKE
            "\xD9" => "\xF9", # LATIN LETTER U WITH GRAVE
            "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
            "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
            "\xDD" => "\xFD", # LATIN LETTER Y WITH ACUTE
            "\xDE" => "\xFE", # LATIN LETTER THORN
        );
    }

    # lower case first with parameter
    sub Egbk::lcfirst(@) {
        if (@_) {
            my $s = shift @_;
            if (@_ and wantarray) {
                return Egbk::lc(CORE::substr($s,0,1)) . CORE::substr($s,1), @_;
            }
            else {
                return Egbk::lc(CORE::substr($s,0,1)) . CORE::substr($s,1);
            }
        }
        else {
            return Egbk::lc(CORE::substr($_,0,1)) . CORE::substr($_,1);
        }
    }

    # lower case first without parameter
    sub Egbk::lcfirst_() {
        return Egbk::lc(CORE::substr($_,0,1)) . CORE::substr($_,1);
    }

    # lower case with parameter
    sub Egbk::lc(@) {
        if (@_) {
            my $s = shift @_;
            if (@_ and wantarray) {
                return join('', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg)), @_;
            }
            else {
                return join('', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg));
            }
        }
        else {
            return Egbk::lc_();
        }
    }

    # lower case without parameter
    sub Egbk::lc_() {
        my $s = $_;
        return join '', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg);
    }
}

#
# GBK upper case
#
{
    my %uc = ();
    @uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
        qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

    if (0) {
    }

    elsif (__PACKAGE__ =~ m/ \b Eusascii \z/oxms) {
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin1 \z/oxms) {
        %uc = (%uc,
            "\xE0" => "\xC0", # LATIN LETTER A WITH GRAVE
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
            "\xE6" => "\xC6", # LATIN LETTER AE
            "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
            "\xE8" => "\xC8", # LATIN LETTER E WITH GRAVE
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER I WITH GRAVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
            "\xF0" => "\xD0", # LATIN LETTER ETH (Icelandic)
            "\xF1" => "\xD1", # LATIN LETTER N WITH TILDE
            "\xF2" => "\xD2", # LATIN LETTER O WITH GRAVE
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
            "\xF9" => "\xD9", # LATIN LETTER U WITH GRAVE
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER Y WITH ACUTE
            "\xFE" => "\xDE", # LATIN LETTER THORN (Icelandic)
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin2 \z/oxms) {
        %uc = (%uc,
            "\xB1" => "\xA1", # LATIN LETTER A WITH OGONEK
            "\xB3" => "\xA3", # LATIN LETTER L WITH STROKE
            "\xB5" => "\xA5", # LATIN LETTER L WITH CARON
            "\xB6" => "\xA6", # LATIN LETTER S WITH ACUTE
            "\xB9" => "\xA9", # LATIN LETTER S WITH CARON
            "\xBA" => "\xAA", # LATIN LETTER S WITH CEDILLA
            "\xBB" => "\xAB", # LATIN LETTER T WITH CARON
            "\xBC" => "\xAC", # LATIN LETTER Z WITH ACUTE
            "\xBE" => "\xAE", # LATIN LETTER Z WITH CARON
            "\xBF" => "\xAF", # LATIN LETTER Z WITH DOT ABOVE
            "\xE0" => "\xC0", # LATIN LETTER R WITH ACUTE
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH BREVE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER L WITH ACUTE
            "\xE6" => "\xC6", # LATIN LETTER C WITH ACUTE
            "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
            "\xE8" => "\xC8", # LATIN LETTER C WITH CARON
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH OGONEK
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER E WITH CARON
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER D WITH CARON
            "\xF0" => "\xD0", # LATIN LETTER D WITH STROKE
            "\xF1" => "\xD1", # LATIN LETTER N WITH ACUTE
            "\xF2" => "\xD2", # LATIN LETTER N WITH CARON
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH DOUBLE ACUTE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF8" => "\xD8", # LATIN LETTER R WITH CARON
            "\xF9" => "\xD9", # LATIN LETTER U WITH RING ABOVE
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH DOUBLE ACUTE
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER Y WITH ACUTE
            "\xFE" => "\xDE", # LATIN LETTER T WITH CEDILLA
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin3 \z/oxms) {
        %uc = (%uc,
            "\xB1" => "\xA1", # LATIN LETTER H WITH STROKE
            "\xB6" => "\xA6", # LATIN LETTER H WITH CIRCUMFLEX
            "\xBA" => "\xAA", # LATIN LETTER S WITH CEDILLA
            "\xBB" => "\xAB", # LATIN LETTER G WITH BREVE
            "\xBC" => "\xAC", # LATIN LETTER J WITH CIRCUMFLEX
            "\xBF" => "\xAF", # LATIN LETTER Z WITH DOT ABOVE
            "\xE0" => "\xC0", # LATIN LETTER A WITH GRAVE
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER C WITH DOT ABOVE
            "\xE6" => "\xC6", # LATIN LETTER C WITH CIRCUMFLEX
            "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
            "\xE8" => "\xC8", # LATIN LETTER E WITH GRAVE
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER I WITH GRAVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
            "\xF1" => "\xD1", # LATIN LETTER N WITH TILDE
            "\xF2" => "\xD2", # LATIN LETTER O WITH GRAVE
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER G WITH DOT ABOVE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF8" => "\xD8", # LATIN LETTER G WITH CIRCUMFLEX
            "\xF9" => "\xD9", # LATIN LETTER U WITH GRAVE
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER U WITH BREVE
            "\xFE" => "\xDE", # LATIN LETTER S WITH CIRCUMFLEX
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin4 \z/oxms) {
        %uc = (%uc,
            "\xB1" => "\xA1", # LATIN LETTER A WITH OGONEK
            "\xB3" => "\xA3", # LATIN LETTER R WITH CEDILLA
            "\xB5" => "\xA5", # LATIN LETTER I WITH TILDE
            "\xB6" => "\xA6", # LATIN LETTER L WITH CEDILLA
            "\xB9" => "\xA9", # LATIN LETTER S WITH CARON
            "\xBA" => "\xAA", # LATIN LETTER E WITH MACRON
            "\xBB" => "\xAB", # LATIN LETTER G WITH CEDILLA
            "\xBC" => "\xAC", # LATIN LETTER T WITH STROKE
            "\xBE" => "\xAE", # LATIN LETTER Z WITH CARON
            "\xBF" => "\xBD", # LATIN LETTER ENG
            "\xE0" => "\xC0", # LATIN LETTER A WITH MACRON
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
            "\xE6" => "\xC6", # LATIN LETTER AE
            "\xE7" => "\xC7", # LATIN LETTER I WITH OGONEK
            "\xE8" => "\xC8", # LATIN LETTER C WITH CARON
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH OGONEK
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER E WITH DOT ABOVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH MACRON
            "\xF0" => "\xD0", # LATIN LETTER D WITH STROKE
            "\xF1" => "\xD1", # LATIN LETTER N WITH CEDILLA
            "\xF2" => "\xD2", # LATIN LETTER O WITH MACRON
            "\xF3" => "\xD3", # LATIN LETTER K WITH CEDILLA
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
            "\xF9" => "\xD9", # LATIN LETTER U WITH OGONEK
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER U WITH TILDE
            "\xFE" => "\xDE", # LATIN LETTER U WITH MACRON
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Ecyrillic \z/oxms) {
        %uc = (%uc,
            "\xD0" => "\xB0", # CYRILLIC LETTER A
            "\xD1" => "\xB1", # CYRILLIC LETTER BE
            "\xD2" => "\xB2", # CYRILLIC LETTER VE
            "\xD3" => "\xB3", # CYRILLIC LETTER GHE
            "\xD4" => "\xB4", # CYRILLIC LETTER DE
            "\xD5" => "\xB5", # CYRILLIC LETTER IE
            "\xD6" => "\xB6", # CYRILLIC LETTER ZHE
            "\xD7" => "\xB7", # CYRILLIC LETTER ZE
            "\xD8" => "\xB8", # CYRILLIC LETTER I
            "\xD9" => "\xB9", # CYRILLIC LETTER SHORT I
            "\xDA" => "\xBA", # CYRILLIC LETTER KA
            "\xDB" => "\xBB", # CYRILLIC LETTER EL
            "\xDC" => "\xBC", # CYRILLIC LETTER EM
            "\xDD" => "\xBD", # CYRILLIC LETTER EN
            "\xDE" => "\xBE", # CYRILLIC LETTER O
            "\xDF" => "\xBF", # CYRILLIC LETTER PE
            "\xE0" => "\xC0", # CYRILLIC LETTER ER
            "\xE1" => "\xC1", # CYRILLIC LETTER ES
            "\xE2" => "\xC2", # CYRILLIC LETTER TE
            "\xE3" => "\xC3", # CYRILLIC LETTER U
            "\xE4" => "\xC4", # CYRILLIC LETTER EF
            "\xE5" => "\xC5", # CYRILLIC LETTER HA
            "\xE6" => "\xC6", # CYRILLIC LETTER TSE
            "\xE7" => "\xC7", # CYRILLIC LETTER CHE
            "\xE8" => "\xC8", # CYRILLIC LETTER SHA
            "\xE9" => "\xC9", # CYRILLIC LETTER SHCHA
            "\xEA" => "\xCA", # CYRILLIC LETTER HARD SIGN
            "\xEB" => "\xCB", # CYRILLIC LETTER YERU
            "\xEC" => "\xCC", # CYRILLIC LETTER SOFT SIGN
            "\xED" => "\xCD", # CYRILLIC LETTER E
            "\xEE" => "\xCE", # CYRILLIC LETTER YU
            "\xEF" => "\xCF", # CYRILLIC LETTER YA
            "\xF1" => "\xA1", # CYRILLIC LETTER IO
            "\xF2" => "\xA2", # CYRILLIC LETTER DJE
            "\xF3" => "\xA3", # CYRILLIC LETTER GJE
            "\xF4" => "\xA4", # CYRILLIC LETTER UKRAINIAN IE
            "\xF5" => "\xA5", # CYRILLIC LETTER DZE
            "\xF6" => "\xA6", # CYRILLIC LETTER BYELORUSSIAN-UKRAINIAN I
            "\xF7" => "\xA7", # CYRILLIC LETTER YI
            "\xF8" => "\xA8", # CYRILLIC LETTER JE
            "\xF9" => "\xA9", # CYRILLIC LETTER LJE
            "\xFA" => "\xAA", # CYRILLIC LETTER NJE
            "\xFB" => "\xAB", # CYRILLIC LETTER TSHE
            "\xFC" => "\xAC", # CYRILLIC LETTER KJE
            "\xFE" => "\xAE", # CYRILLIC LETTER SHORT U
            "\xFF" => "\xAF", # CYRILLIC LETTER DZHE
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Egreek \z/oxms) {
        %uc = (%uc,
            "\xDC" => "\xB6", # GREEK LETTER ALPHA WITH TONOS
            "\xDD" => "\xB8", # GREEK LETTER EPSILON WITH TONOS
            "\xDE" => "\xB9", # GREEK LETTER ETA WITH TONOS
            "\xDF" => "\xBA", # GREEK LETTER IOTA WITH TONOS
            "\xE1" => "\xC1", # GREEK LETTER ALPHA
            "\xE2" => "\xC2", # GREEK LETTER BETA
            "\xE3" => "\xC3", # GREEK LETTER GAMMA
            "\xE4" => "\xC4", # GREEK LETTER DELTA
            "\xE5" => "\xC5", # GREEK LETTER EPSILON
            "\xE6" => "\xC6", # GREEK LETTER ZETA
            "\xE7" => "\xC7", # GREEK LETTER ETA
            "\xE8" => "\xC8", # GREEK LETTER THETA
            "\xE9" => "\xC9", # GREEK LETTER IOTA
            "\xEA" => "\xCA", # GREEK LETTER KAPPA
            "\xEB" => "\xCB", # GREEK LETTER LAMDA
            "\xEC" => "\xCC", # GREEK LETTER MU
            "\xED" => "\xCD", # GREEK LETTER NU
            "\xEE" => "\xCE", # GREEK LETTER XI
            "\xEF" => "\xCF", # GREEK LETTER OMICRON
            "\xF0" => "\xD0", # GREEK LETTER PI
            "\xF1" => "\xD1", # GREEK LETTER RHO
            "\xF3" => "\xD3", # GREEK LETTER SIGMA
            "\xF4" => "\xD4", # GREEK LETTER TAU
            "\xF5" => "\xD5", # GREEK LETTER UPSILON
            "\xF6" => "\xD6", # GREEK LETTER PHI
            "\xF7" => "\xD7", # GREEK LETTER CHI
            "\xF8" => "\xD8", # GREEK LETTER PSI
            "\xF9" => "\xD9", # GREEK LETTER OMEGA
            "\xFA" => "\xDA", # GREEK LETTER IOTA WITH DIALYTIKA
            "\xFB" => "\xDB", # GREEK LETTER UPSILON WITH DIALYTIKA
            "\xFC" => "\xBC", # GREEK LETTER OMICRON WITH TONOS
            "\xFD" => "\xBE", # GREEK LETTER UPSILON WITH TONOS
            "\xFE" => "\xBF", # GREEK LETTER OMEGA WITH TONOS
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin5 \z/oxms) {
        %uc = (%uc,
            "\xE0" => "\xC0", # LATIN LETTER A WITH GRAVE
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
            "\xE6" => "\xC6", # LATIN LETTER AE
            "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
            "\xE8" => "\xC8", # LATIN LETTER E WITH GRAVE
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER I WITH GRAVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
            "\xF0" => "\xD0", # LATIN LETTER G WITH BREVE
            "\xF1" => "\xD1", # LATIN LETTER N WITH TILDE
            "\xF2" => "\xD2", # LATIN LETTER O WITH GRAVE
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
            "\xF9" => "\xD9", # LATIN LETTER U WITH GRAVE
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFE" => "\xDE", # LATIN LETTER S WITH CEDILLA
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin6 \z/oxms) {
        %uc = (%uc,
            "\xB1" => "\xA1", # LATIN LETTER A WITH OGONEK
            "\xB2" => "\xA2", # LATIN LETTER E WITH MACRON
            "\xB3" => "\xA3", # LATIN LETTER G WITH CEDILLA
            "\xB4" => "\xA4", # LATIN LETTER I WITH MACRON
            "\xB5" => "\xA5", # LATIN LETTER I WITH TILDE
            "\xB6" => "\xA6", # LATIN LETTER K WITH CEDILLA
            "\xB8" => "\xA8", # LATIN LETTER L WITH CEDILLA
            "\xB9" => "\xA9", # LATIN LETTER D WITH STROKE
            "\xBA" => "\xAA", # LATIN LETTER S WITH CARON
            "\xBB" => "\xAB", # LATIN LETTER T WITH STROKE
            "\xBC" => "\xAC", # LATIN LETTER Z WITH CARON
            "\xBE" => "\xAE", # LATIN LETTER U WITH MACRON
            "\xBF" => "\xAF", # LATIN LETTER ENG
            "\xE0" => "\xC0", # LATIN LETTER A WITH MACRON
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
            "\xE6" => "\xC6", # LATIN LETTER AE
            "\xE7" => "\xC7", # LATIN LETTER I WITH OGONEK
            "\xE8" => "\xC8", # LATIN LETTER C WITH CARON
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH OGONEK
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER E WITH DOT ABOVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
            "\xF0" => "\xD0", # LATIN LETTER ETH (Icelandic)
            "\xF1" => "\xD1", # LATIN LETTER N WITH CEDILLA
            "\xF2" => "\xD2", # LATIN LETTER O WITH MACRON
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF7" => "\xD7", # LATIN LETTER U WITH TILDE
            "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
            "\xF9" => "\xD9", # LATIN LETTER U WITH OGONEK
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER Y WITH ACUTE
            "\xFE" => "\xDE", # LATIN LETTER THORN (Icelandic)
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin7 \z/oxms) {
        %uc = (%uc,
            "\xB8" => "\xA8", # LATIN LETTER O WITH STROKE
            "\xBA" => "\xAA", # LATIN LETTER R WITH CEDILLA
            "\xBF" => "\xAF", # LATIN LETTER AE
            "\xE0" => "\xC0", # LATIN LETTER A WITH OGONEK
            "\xE1" => "\xC1", # LATIN LETTER I WITH OGONEK
            "\xE2" => "\xC2", # LATIN LETTER A WITH MACRON
            "\xE3" => "\xC3", # LATIN LETTER C WITH ACUTE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
            "\xE6" => "\xC6", # LATIN LETTER E WITH OGONEK
            "\xE7" => "\xC7", # LATIN LETTER E WITH MACRON
            "\xE8" => "\xC8", # LATIN LETTER C WITH CARON
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER Z WITH ACUTE
            "\xEB" => "\xCB", # LATIN LETTER E WITH DOT ABOVE
            "\xEC" => "\xCC", # LATIN LETTER G WITH CEDILLA
            "\xED" => "\xCD", # LATIN LETTER K WITH CEDILLA
            "\xEE" => "\xCE", # LATIN LETTER I WITH MACRON
            "\xEF" => "\xCF", # LATIN LETTER L WITH CEDILLA
            "\xF0" => "\xD0", # LATIN LETTER S WITH CARON
            "\xF1" => "\xD1", # LATIN LETTER N WITH ACUTE
            "\xF2" => "\xD2", # LATIN LETTER N WITH CEDILLA
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH MACRON
            "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF8" => "\xD8", # LATIN LETTER U WITH OGONEK
            "\xF9" => "\xD9", # LATIN LETTER L WITH STROKE
            "\xFA" => "\xDA", # LATIN LETTER S WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH MACRON
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER Z WITH DOT ABOVE
            "\xFE" => "\xDE", # LATIN LETTER Z WITH CARON
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin8 \z/oxms) {
        %uc = (%uc,
            "\xA2" => "\xA1", # LATIN LETTER B WITH DOT ABOVE
            "\xA5" => "\xA4", # LATIN LETTER C WITH DOT ABOVE
            "\xAB" => "\xA6", # LATIN LETTER D WITH DOT ABOVE
            "\xB1" => "\xB0", # LATIN LETTER F WITH DOT ABOVE
            "\xB3" => "\xB2", # LATIN LETTER G WITH DOT ABOVE
            "\xB5" => "\xB4", # LATIN LETTER M WITH DOT ABOVE
            "\xB8" => "\xA8", # LATIN LETTER W WITH GRAVE
            "\xB9" => "\xB7", # LATIN LETTER P WITH DOT ABOVE
            "\xBA" => "\xAA", # LATIN LETTER W WITH ACUTE
            "\xBC" => "\xAC", # LATIN LETTER Y WITH GRAVE
            "\xBE" => "\xBD", # LATIN LETTER W WITH DIAERESIS
            "\xBF" => "\xBB", # LATIN LETTER S WITH DOT ABOVE
            "\xE0" => "\xC0", # LATIN LETTER A WITH GRAVE
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
            "\xE6" => "\xC6", # LATIN LETTER AE
            "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
            "\xE8" => "\xC8", # LATIN LETTER E WITH GRAVE
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER I WITH GRAVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
            "\xF0" => "\xD0", # LATIN LETTER W WITH CIRCUMFLEX
            "\xF1" => "\xD1", # LATIN LETTER N WITH TILDE
            "\xF2" => "\xD2", # LATIN LETTER O WITH GRAVE
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF7" => "\xD7", # LATIN LETTER T WITH DOT ABOVE
            "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
            "\xF9" => "\xD9", # LATIN LETTER U WITH GRAVE
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER Y WITH ACUTE
            "\xFE" => "\xDE", # LATIN LETTER Y WITH CIRCUMFLEX
            "\xFF" => "\xAF", # LATIN LETTER Y WITH DIAERESIS
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin9 \z/oxms) {
        %uc = (%uc,
            "\xA8" => "\xA6", # LATIN LETTER S WITH CARON
            "\xB8" => "\xB4", # LATIN LETTER Z WITH CARON
            "\xBD" => "\xBC", # LATIN LIGATURE OE
            "\xE0" => "\xC0", # LATIN LETTER A WITH GRAVE
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
            "\xE6" => "\xC6", # LATIN LETTER AE
            "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
            "\xE8" => "\xC8", # LATIN LETTER E WITH GRAVE
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER I WITH GRAVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
            "\xF0" => "\xD0", # LATIN LETTER ETH
            "\xF1" => "\xD1", # LATIN LETTER N WITH TILDE
            "\xF2" => "\xD2", # LATIN LETTER O WITH GRAVE
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
            "\xF9" => "\xD9", # LATIN LETTER U WITH GRAVE
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER Y WITH ACUTE
            "\xFE" => "\xDE", # LATIN LETTER THORN
            "\xFF" => "\xBE", # LATIN LETTER Y WITH DIAERESIS
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Elatin10 \z/oxms) {
        %uc = (%uc,
            "\xA2" => "\xA1", # LATIN LETTER A WITH OGONEK
            "\xA8" => "\xA6", # LATIN LETTER S WITH CARON
            "\xAE" => "\xAC", # LATIN LETTER Z WITH ACUTE
            "\xB3" => "\xA3", # LATIN LETTER L WITH STROKE
            "\xB8" => "\xB4", # LATIN LETTER Z WITH CARON
            "\xB9" => "\xB2", # LATIN LETTER C WITH CARON
            "\xBA" => "\xAA", # LATIN LETTER S WITH COMMA BELOW
            "\xBD" => "\xBC", # LATIN LIGATURE OE
            "\xBF" => "\xAF", # LATIN LETTER Z WITH DOT ABOVE
            "\xE0" => "\xC0", # LATIN LETTER A WITH GRAVE
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH BREVE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER C WITH ACUTE
            "\xE6" => "\xC6", # LATIN LETTER AE
            "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
            "\xE8" => "\xC8", # LATIN LETTER E WITH GRAVE
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER I WITH GRAVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
            "\xF0" => "\xD0", # LATIN LETTER D WITH STROKE
            "\xF1" => "\xD1", # LATIN LETTER N WITH ACUTE
            "\xF2" => "\xD2", # LATIN LETTER O WITH GRAVE
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH DOUBLE ACUTE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF7" => "\xD7", # LATIN LETTER S WITH ACUTE
            "\xF8" => "\xD8", # LATIN LETTER U WITH DOUBLE ACUTE
            "\xF9" => "\xD9", # LATIN LETTER U WITH GRAVE
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER E WITH OGONEK
            "\xFE" => "\xDE", # LATIN LETTER T WITH COMMA BELOW
            "\xFF" => "\xBE", # LATIN LETTER Y WITH DIAERESIS
        );
    }

    elsif (__PACKAGE__ =~ m/ \b Ewindows1252 \z/oxms) {
        %uc = (%uc,
            "\x9A" => "\x8A", # LATIN LETTER S WITH CARON
            "\x9C" => "\x8C", # LATIN LIGATURE OE
            "\x9E" => "\x8E", # LATIN LETTER Z WITH CARON
            "\xE0" => "\xC0", # LATIN LETTER A WITH GRAVE
            "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
            "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
            "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
            "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
            "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
            "\xE6" => "\xC6", # LATIN LETTER AE
            "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
            "\xE8" => "\xC8", # LATIN LETTER E WITH GRAVE
            "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
            "\xEA" => "\xCA", # LATIN LETTER E WITH CIRCUMFLEX
            "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
            "\xEC" => "\xCC", # LATIN LETTER I WITH GRAVE
            "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
            "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
            "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
            "\xF0" => "\xD0", # LATIN LETTER ETH
            "\xF1" => "\xD1", # LATIN LETTER N WITH TILDE
            "\xF2" => "\xD2", # LATIN LETTER O WITH GRAVE
            "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
            "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
            "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
            "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
            "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
            "\xF9" => "\xD9", # LATIN LETTER U WITH GRAVE
            "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
            "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
            "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
            "\xFD" => "\xDD", # LATIN LETTER Y WITH ACUTE
            "\xFE" => "\xDE", # LATIN LETTER THORN
            "\xFF" => "\x9F", # LATIN LETTER Y WITH DIAERESIS
        );
    }

    # upper case first with parameter
    sub Egbk::ucfirst(@) {
        if (@_) {
            my $s = shift @_;
            if (@_ and wantarray) {
                return Egbk::uc(CORE::substr($s,0,1)) . CORE::substr($s,1), @_;
            }
            else {
                return Egbk::uc(CORE::substr($s,0,1)) . CORE::substr($s,1);
            }
        }
        else {
            return Egbk::uc(CORE::substr($_,0,1)) . CORE::substr($_,1);
        }
    }

    # upper case first without parameter
    sub Egbk::ucfirst_() {
        return Egbk::uc(CORE::substr($_,0,1)) . CORE::substr($_,1);
    }

    # upper case with parameter
    sub Egbk::uc(@) {
        if (@_) {
            my $s = shift @_;
            if (@_ and wantarray) {
                return join('', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg)), @_;
            }
            else {
                return join('', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg));
            }
        }
        else {
            return Egbk::uc_();
        }
    }

    # upper case without parameter
    sub Egbk::uc_() {
        my $s = $_;
        return join '', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg);
    }
}

#
# GBK regexp capture
#
{
    # 10.3. Creating Persistent Private Variables
    # in Chapter 10. Subroutines
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.

    my $last_s_matched = 0;

    sub Egbk::capture($) {
        if ($last_s_matched and ($_[0] =~ m/\A [1-9][0-9]* \z/oxms)) {
            return $_[0] + 1;
        }
        return $_[0];
    }

    # GBK regexp mark last m// or qr// matched
    sub Egbk::m_matched() {
        $last_s_matched = 0;
    }

    # GBK regexp mark last s/// or qr matched
    sub Egbk::s_matched() {
        $last_s_matched = 1;
    }

    # which matched of m// or s/// at last

    # P.854 31.17. use re
    # in Chapter 31. Pragmatic Modules
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    @Egbk::m_matched = (qr/(?{Egbk::m_matched})/);
    @Egbk::s_matched = (qr/(?{Egbk::s_matched})/);
}

#
# GBK regexp ignore case modifier
#
sub Egbk::ignorecase(@) {

    my @string = @_;
    my $metachar = qr/[\@\\|[\]{]/oxms;

    # ignore case of $scalar or @array
    for my $string (@string) {

        # split regexp
        my @char = $string =~ m{\G(
            \[\^ |
                \\? (?:$q_char)
        )}oxmsg;

        # unescape character
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # open character class [...]
            if ($char[$i] eq '[') {
                my $left = $i;

                # [] make die "unmatched [] in regexp ..."

                if ($char[$i+1] eq ']') {
                    $i++;
                }

                while (1) {
                    if (++$i > $#char) {
                        croak "$0: unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {

                            # do not use quotemeta here
                            if ($char =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ m/\A [.|)] \z/oxms) {
                                $char = $1 . '\\' . $char;
                            }
                        }

                        # [...]
                        splice @char, $left, $right-$left+1, '(?:' . join('|', @charlist) . ')';

                        $i = $left;
                        last;
                    }
                }
            }

            # open character class [^...]
            elsif ($char[$i] eq '[^') {
                my $left = $i;

                # [^] make die "unmatched [] in regexp ..."

                if ($char[$i+1] eq ']') {
                    $i++;
                }

                while (1) {
                    if (++$i > $#char) {
                        croak "$0: unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_not_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {

                            # do not use quotemeta here
                            if ($char =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ m/\A [.|)] \z/oxms) {
                                $char = '\\' . $char;
                            }
                        }

                        # [^...]
                        splice @char, $left, $right-$left+1, '(?!' . join('|', @charlist) . ")(?:$your_char)";

                        $i = $left;
                        last;
                    }
                }
            }

            # rewrite character class or escape character
            elsif (my $char = {
                '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^0-9])',
                '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\x09\x0A\x0C\x0D\x20])',
                '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^0-9A-Z_a-z])',
                '\d' => '[0-9]',
                '\s' => '[\x09\x0A\x0C\x0D\x20]',
                '\w' => '[0-9A-Z_a-z]',

                # \h \v \H \V
                #
                # P.114 Character Class Shortcuts
                # in Chapter 7: In the World of Regular Expressions
                # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

                '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\x09\x20])',
                '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\x0C\x0A\x0D])',
                '\h' => '[\x09\x20]',
                '\v' => '[\x0C\x0A\x0D]',

                # \b \B
                #
                # P.131 Word boundaries: \b, \B, \<, \>, ...
                # in Chapter 3: Overview of Regular Expression Features and Flavors
                # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

                # '\b' => '(?:(?<=\A|\W)(?=\w)|(?<=\w)(?=\W|\z))',
                '\b' => '(?:\A(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[0-9A-Z_a-z])|(?<=[0-9A-Z_a-z])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]|\z))',

                # '\B' => '(?:(?<=\w)(?=\w)|(?<=\W)(?=\W))',
                '\B' => '(?:(?<=[0-9A-Z_a-z])(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]))',

                }->{$char[$i]}
            ) {
                $char[$i] = $char;
            }

            # /i modifier
            elsif ($char[$i] =~ m/\A [\x00-\xFF] \z/oxms) {
                my $uc = Egbk::uc($char[$i]);
                my $lc = Egbk::lc($char[$i]);
                if ($uc ne $lc) {
                    $char[$i] = '[' . $uc . $lc . ']';
                }
            }
        }

        # characterize
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # escape last octet of multiple octet
            if ($char[$i] =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                $char[$i] = $1 . '\\' . $2;
            }

            # quote character before ? + * {
            elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
                if ($char[$i-1] !~ m/\A [\x00-\xFF] \z/oxms) {
                    $char[$i-1] = '(?:' . $char[$i-1] . ')';
                }
            }
        }

        $string = join '', @char;
    }

    # make regexp string
    return @string;
}

#
# prepare GBK characters per length
#

# 1 octet characters
my @chars1 = ();
sub chars1 {
    if (@chars1) {
        return @chars1;
    }
    if (exists $range_tr{1}) {
        my @ranges = @{ $range_tr{1} };
        while (my @range = splice(@ranges,0,1)) {
            for my $oct0 (@{$range[0]}) {
                push @chars1, pack 'C', $oct0;
            }
        }
    }
    return @chars1;
}

# 2 octets characters
my @chars2 = ();
sub chars2 {
    if (@chars2) {
        return @chars2;
    }
    if (exists $range_tr{2}) {
        my @ranges = @{ $range_tr{2} };
        while (my @range = splice(@ranges,0,2)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    push @chars2, pack 'CC', $oct0,$oct1;
                }
            }
        }
    }
    return @chars2;
}

# 3 octets characters
my @chars3 = ();
sub chars3 {
    if (@chars3) {
        return @chars3;
    }
    if (exists $range_tr{3}) {
        my @ranges = @{ $range_tr{3} };
        while (my @range = splice(@ranges,0,3)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    for my $oct2 (@{$range[2]}) {
                        push @chars3, pack 'CCC', $oct0,$oct1,$oct2;
                    }
                }
            }
        }
    }
    return @chars3;
}

# 4 octets characters
my @chars4 = ();
sub chars4 {
    if (@chars4) {
        return @chars4;
    }
    if (exists $range_tr{4}) {
        my @ranges = @{ $range_tr{4} };
        while (my @range = splice(@ranges,0,4)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    for my $oct2 (@{$range[2]}) {
                        for my $oct3 (@{$range[3]}) {
                            push @chars4, pack 'CCCC', $oct0,$oct1,$oct2,$oct3;
                        }
                    }
                }
            }
        }
    }
    return @chars4;
}

# minimum value of each octet
my @minchar = ();
sub minchar {
    if (defined $minchar[$_[0]]) {
        return $minchar[$_[0]];
    }
    $minchar[$_[0]] = (&{(sub {}, \&chars1, \&chars2, \&chars3, \&chars4)[$_[0]]})[0];
}

# maximum value of each octet
my @maxchar = ();
sub maxchar {
    if (defined $maxchar[$_[0]]) {
        return $maxchar[$_[0]];
    }
    $maxchar[$_[0]] = (&{(sub {}, \&chars1, \&chars2, \&chars3, \&chars4)[$_[0]]})[-1];
}

#
# GBK open character list for tr
#
sub _charlist_tr {

    local $_ = shift @_;

    # unescape character
    my @char = ();
    while (not m/\G \z/oxmsgc) {
        if (m/\G (\\0?55|\\x2[Dd]|\\-) /oxmsgc) {
            push @char, '\-';
        }
        elsif (m/\G \\ ([0-7]{2,3}) /oxmsgc) {
            push @char, CORE::chr(oct $1);
        }
        elsif (m/\G \\x ([0-9A-Fa-f]{1,2}) /oxmsgc) {
            push @char, CORE::chr(hex $1);
        }
        elsif (m/\G \\c ([\x40-\x5F]) /oxmsgc) {
            push @char, CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif (m/\G (\\ [0nrtfbae]) /oxmsgc) {
            push @char, {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
            }->{$1};
        }
        elsif (m/\G \\ ($q_char) /oxmsgc) {
            push @char, $1;
        }
        elsif (m/\G ($q_char) /oxmsgc) {
            push @char, $1;
        }
    }

    # join separated multiple octet
    @char = join('',@char) =~ m/\G (\\-|$q_char) /oxmsg;

    # unescape '-'
    my @i = ();
    for my $i (0 .. $#char) {
        if ($char[$i] eq '\-') {
            $char[$i] = '-';
        }
        elsif ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                push @i, $i;
            }
        }
    }

    # open character list (reverse for splice)
    for my $i (CORE::reverse @i) {
        my @range = ();

        # range error
        if ((length($char[$i-1]) > length($char[$i+1])) or ($char[$i-1] gt $char[$i+1])) {
            croak "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
        }

        # range of multiple octet code
        if (length($char[$i-1]) == 1) {
            if (length($char[$i+1]) == 1) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} &chars1();
            }
            elsif (length($char[$i+1]) == 2) {
                push @range, grep {$char[$i-1] le $_}                           &chars1();
                push @range, grep {$_ le $char[$i+1]}                           &chars2();
            }
            elsif (length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           &chars1();
                push @range,                                                    &chars2();
                push @range, grep {$_ le $char[$i+1]}                           &chars3();
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           &chars1();
                push @range,                                                    &chars2();
                push @range,                                                    &chars3();
                push @range, grep {$_ le $char[$i+1]}                           &chars4();
            }
        }
        elsif (length($char[$i-1]) == 2) {
            if (length($char[$i+1]) == 2) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} &chars2();
            }
            elsif (length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           &chars2();
                push @range, grep {$_ le $char[$i+1]}                           &chars3();
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           &chars2();
                push @range,                                                    &chars3();
                push @range, grep {$_ le $char[$i+1]}                           &chars4();
            }
        }
        elsif (length($char[$i-1]) == 3) {
            if (length($char[$i+1]) == 3) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} &chars3();
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           &chars3();
                push @range, grep {$_ le $char[$i+1]}                           &chars4();
            }
        }
        elsif (length($char[$i-1]) == 4) {
            if (length($char[$i+1]) == 4) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} &chars4();
            }
        }

        splice @char, $i-1, 3, @range;
    }

    return @char;
}

#
# GBK octet range
#
sub _octets {

    my $modifier = pop @_;
    my $length = shift;

    my($a) = unpack 'C', $_[0];
    my($z) = unpack 'C', $_[1];

    # single octet code
    if ($length == 1) {

        # single octet and ignore case
        if (((caller(1))[3] ne 'Egbk::_octets') and ($modifier =~ m/i/oxms)) {
            if ($a == $z) {
                return sprintf('(?i:\x%02X)',          $a);
            }
            elsif (($a+1) == $z) {
                return sprintf('(?i:[\x%02X\x%02X])',  $a, $z);
            }
            else {
                return sprintf('(?i:[\x%02X-\x%02X])', $a, $z);
            }
        }

        # not ignore case or one of multiple octet
        else {
            if ($a == $z) {
                return sprintf('\x%02X',          $a);
            }
            elsif (($a+1) == $z) {
                return sprintf('[\x%02X\x%02X]',  $a, $z);
            }
            else {
                return sprintf('[\x%02X-\x%02X]', $a, $z);
            }
        }
    }

    # double octet code of Shift_JIS family
    elsif (($length == 2) and $is_shiftjis_family and ($a <= 0x9F) and (0xE0 <= $z)) {
        my(undef,$a2) = unpack 'CC', $_[0];
        my(undef,$z2) = unpack 'CC', $_[1];
        my $octets1;
        my $octets2;

        if ($a == 0x9F) {
            $octets1 = sprintf('\x%02X[\x%02X-\xFF]',                            0x9F,$a2);
        }
        elsif (($a+1) == 0x9F) {
            $octets1 = sprintf('\x%02X[\x%02X-\xFF]|\x%02X[\x00-\xFF]',          $a,  $a2,$a+1);
        }
        elsif (($a+2) == 0x9F) {
            $octets1 = sprintf('\x%02X[\x%02X-\xFF]|[\x%02X\x%02X][\x00-\xFF]',  $a,  $a2,$a+1,$a+2);
        }
        else {
            $octets1 = sprintf('\x%02X[\x%02X-\xFF]|[\x%02X-\x%02X][\x00-\xFF]', $a,  $a2,$a+1,$a+2);
        }

        if ($z == 0xE0) {
            $octets2 = sprintf('\x%02X[\x00-\x%02X]',                                      $z,$z2);
        }
        elsif (($z-1) == 0xE0) {
            $octets2 = sprintf('\x%02X[\x00-\xFF]|\x%02X[\x00-\x%02X]',               $z-1,$z,$z2);
        }
        elsif (($z-2) == 0xE0) {
            $octets2 = sprintf('[\x%02X\x%02X][\x00-\xFF]|\x%02X[\x00X-\x%02X]', $z-2,$z-1,$z,$z2);
        }
        else {
            $octets2 = sprintf('[\x%02X-\x%02X][\x00-\xFF]|\x%02X[\x00-\x%02X]', 0xE0,$z-1,$z,$z2);
        }

        return "(?:$octets1|$octets2)";
    }

    # double octet code of EUC-JP family
    elsif (($length == 2) and $is_eucjp_family and ($a == 0x8E) and (0xA1 <= $z)) {
        my(undef,$a2) = unpack 'CC', $_[0];
        my(undef,$z2) = unpack 'CC', $_[1];
        my $octets1;
        my $octets2;

        $octets1 = sprintf('\x%02X[\x%02X-\xFF]',                                0x8E,$a2);

        if ($z == 0xA1) {
            $octets2 = sprintf('\x%02X[\x00-\x%02X]',                                      $z,$z2);
        }
        elsif (($z-1) == 0xA1) {
            $octets2 = sprintf('\x%02X[\x00-\xFF]|\x%02X[\x00-\x%02X]',               $z-1,$z,$z2);
        }
        elsif (($z-2) == 0xA1) {
            $octets2 = sprintf('[\x%02X\x%02X][\x00-\xFF]|\x%02X[\x00X-\x%02X]', $z-2,$z-1,$z,$z2);
        }
        else {
            $octets2 = sprintf('[\x%02X-\x%02X][\x00-\xFF]|\x%02X[\x00-\x%02X]', 0xA1,$z-1,$z,$z2);
        }

        return "(?:$octets1|$octets2)";
    }

    # multiple octet code
    else {
        my(undef,$aa) = unpack 'Ca*', $_[0];
        my(undef,$zz) = unpack 'Ca*', $_[1];

        if ($a == $z) {
            return '(?:' . join('|',
                sprintf('\x%02X%s',         $a,         _octets($length-1,$aa,                $zz,                $modifier)),
            ) . ')';
        }
        elsif (($a+1) == $z) {
            return '(?:' . join('|',
                sprintf('\x%02X%s',         $a,         _octets($length-1,$aa,                &maxchar($length-1),$modifier)),
                sprintf('\x%02X%s',              $z,    _octets($length-1,&minchar($length-1),$zz,                $modifier)),
            ) . ')';
        }
        elsif (($a+2) == $z) {
            return '(?:' . join('|',
                sprintf('\x%02X%s',         $a,         _octets($length-1,$aa,                &maxchar($length-1),$modifier)),
                sprintf('\x%02X%s',         $a+1,       _octets($length-1,&minchar($length-1),&maxchar($length-1),$modifier)),
                sprintf('\x%02X%s',              $z,    _octets($length-1,&minchar($length-1),$zz,                $modifier)),
            ) . ')';
        }
        elsif (($a+3) == $z) {
            return '(?:' . join('|',
                sprintf('\x%02X%s',         $a,         _octets($length-1,$aa,                &maxchar($length-1),$modifier)),
                sprintf('[\x%02X\x%02X]%s', $a+1,$z-1,  _octets($length-1,&minchar($length-1),&maxchar($length-1),$modifier)),
                sprintf('\x%02X%s',              $z,    _octets($length-1,&minchar($length-1),$zz,                $modifier)),
            ) . ')';
        }
        else {
            return '(?:' . join('|',
                sprintf('\x%02X%s',          $a,        _octets($length-1,$aa,                &maxchar($length-1),$modifier)),
                sprintf('[\x%02X-\x%02X]%s', $a+1,$z-1, _octets($length-1,&minchar($length-1),&maxchar($length-1),$modifier)),
                sprintf('\x%02X%s',               $z,   _octets($length-1,&minchar($length-1),$zz,                $modifier)),
            ) . ')';
        }
    }
}

#
# GBK open character list for qr and not qr
#
sub _charlist {

    my $modifier = pop @_;
    my @char = @_;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = CORE::chr oct $1;
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{1,2}) \z/oxms) {
            $char[$i] = CORE::chr hex $1;
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ m/\A (\\ [0nrtfbaedDhHsSvVwW]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
                '\d' => '[0-9]',
                '\s' => '[\x09\x0A\x0C\x0D\x20]',
                '\w' => '[0-9A-Z_a-z]',
                '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^0-9])',
                '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\x09\x0A\x0C\x0D\x20])',
                '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^0-9A-Z_a-z])',

                '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\x09\x20])',
                '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\x0C\x0A\x0D])',
                '\h' => '[\x09\x20]',
                '\v' => '[\x0C\x0A\x0D]',

            }->{$1};
        }
        elsif ($char[$i] =~ m/\A \\ ($q_char) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet = ();
    my @charlist    = ();
    for (my $i=0; $i <= $#char; ) {

        # escaped -
        if (defined($char[$i+1]) and ($char[$i+1] eq '...')) {
            $i += 1;
            next;
        }
        elsif ($char[$i] eq '...') {

            # range error
            if ((length($char[$i-1]) > length($char[$i+1])) or ($char[$i-1] gt $char[$i+1])) {
                croak "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
            }

            # range of single octet code and not ignore case
            if ((length($char[$i-1]) == 1) and (length($char[$i+1]) == 1) and ($modifier !~ m/i/oxms)) {
                my $a = unpack 'C', $char[$i-1];
                my $z = unpack 'C', $char[$i+1];

                if ($a == $z) {
                    push @singleoctet, sprintf('\x%02X',        $a);
                }
                elsif (($a+1) == $z) {
                    push @singleoctet, sprintf('\x%02X\x%02X',  $a, $z);
                }
                else {
                    push @singleoctet, sprintf('\x%02X-\x%02X', $a, $z);
                }
            }

            # range of multiple octet code
            elsif (length($char[$i-1]) == length($char[$i+1])) {
                push @charlist, _octets(length($char[$i-1]), $char[$i-1], $char[$i+1], $modifier);
            }
            elsif (length($char[$i-1]) == 1) {
                if (length($char[$i+1]) == 2) {
                    push @charlist,
                        _octets(1, $char[$i-1], &maxchar(1), $modifier),
                        _octets(2, &minchar(2), $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 3) {
                    push @charlist,
                        _octets(1, $char[$i-1], &maxchar(1), $modifier),
                        _octets(2, &minchar(2), &maxchar(2), $modifier),
                        _octets(3, &minchar(3), $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(1, $char[$i-1], &maxchar(1), $modifier),
                        _octets(2, &minchar(2), &maxchar(2), $modifier),
                        _octets(3, &minchar(3), &maxchar(3), $modifier),
                        _octets(4, &minchar(4), $char[$i+1], $modifier);
                }
            }
            elsif (length($char[$i-1]) == 2) {
                if (length($char[$i+1]) == 3) {
                    push @charlist,
                        _octets(2, $char[$i-1], &maxchar(2), $modifier),
                        _octets(3, &minchar(3), $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(2, $char[$i-1], &maxchar(2), $modifier),
                        _octets(3, &minchar(3), &maxchar(3), $modifier),
                        _octets(4, &minchar(4), $char[$i+1], $modifier);
                }
            }
            elsif (length($char[$i-1]) == 3) {
                if (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(3, $char[$i-1], &maxchar(3), $modifier),
                        _octets(4, &minchar(4), $char[$i+1], $modifier);
                }
            }
            else {
                croak "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
            }

            $i += 2;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A [\x00-\xFF] \z/oxms) {
            if ($modifier =~ m/i/oxms) {
                my $uc = Egbk::uc($char[$i]);
                my $lc = Egbk::lc($char[$i]);
                if ($uc ne $lc) {
                    push @singleoctet, $uc, $lc;
                }
                else {
                    push @singleoctet, $char[$i];
                }
            }
            else {
                push @singleoctet, $char[$i];
            }
            $i += 1;
        }

        # single character of single octet code

        # \h \v
        #
        # P.114 Character Class Shortcuts
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        elsif ($char[$i] =~ m/\A (?: \\h ) \z/oxms) {
            push @singleoctet, "\t", "\x20";
            $i += 1;
        }
        elsif ($char[$i] =~ m/\A (?: \\v ) \z/oxms) {
            push @singleoctet, "\f","\n","\r";
            $i += 1;
        }
        elsif ($char[$i] =~ m/\A (?: [\x00-\xFF] | \\d | \\s | \\w ) \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }

        # single character of multiple octet code
        else {
            push @charlist, $char[$i];
            $i += 1;
        }
    }

    # quote metachar
    for (@singleoctet) {
        if (m/\A \n \z/oxms) {
            $_ = '\n';
        }
        elsif (m/\A \r \z/oxms) {
            $_ = '\r';
        }
        elsif (m/\A ([\x00-\x20\x7F-\xFF]) \z/oxms) {
            $_ = sprintf('\x%02X', CORE::ord $1);
        }
        elsif (m/\A [\x00-\xFF] \z/oxms) {
            $_ = quotemeta $_;
        }
    }
    for (@charlist) {
        if (m/\A ([\x81-\xFE]) ([\x00-\xFF]) \z/oxms) {
            $_ = $1 . quotemeta $2;
        }
    }

    # return character list
    return \@singleoctet, \@charlist;
}

#
# GBK open character list for qr
#
sub charlist_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $charlist) = _charlist(@char, $modifier);
    my @singleoctet = @$singleoctet;
    my @charlist    = @$charlist;

    # return character list
    if (scalar(@singleoctet) == 0) {
    }
    elsif (scalar(@singleoctet) >= 2) {
        push @charlist, '[' . join('',@singleoctet) . ']';
    }
    elsif ($singleoctet[0] =~ m/ . - . /oxms) {
        push @charlist, '[' . $singleoctet[0] . ']';
    }
    else {
        push @charlist, $singleoctet[0];
    }
    if (scalar(@charlist) >= 2) {
        return '(?:' . join('|', @charlist) . ')';
    }
    else {
        return $charlist[0];
    }
}

#
# GBK open character list for not qr
#
sub charlist_not_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $charlist) = _charlist(@char, $modifier);
    my @singleoctet = @$singleoctet;
    my @charlist    = @$charlist;

    # return character list
    if (scalar(@charlist) >= 1) {
        if (scalar(@singleoctet) >= 1) {

            # any character other than multiple octet and single octet character class
            return '(?!' . join('|', @charlist) . ')(?:[\x81-\xFE][\x00-\xFF]|[^'. join('', @singleoctet) . '])';
        }
        else {

            # any character other than multiple octet character class
            return '(?!' . join('|', @charlist) . ")(?:$your_char)";
        }
    }
    else {
        if (scalar(@singleoctet) >= 1) {

            # any character other than single octet character class
            return                                 '(?:[\x81-\xFE][\x00-\xFF]|[^'. join('', @singleoctet) . '])';
        }
        else {

            # any character
            return                                 "(?:$your_char)";
        }
    }
}

#
# GBK order to character (with parameter)
#
sub Egbk::chr(;$) {

    my $c = @_ ? $_[0] : $_;

    if ($c == 0x00) {
        return "\x00";
    }
    else {
        my @chr = ();
        while ($c > 0) {
            unshift @chr, ($c % 0x100);
            $c = int($c / 0x100);
        }
        return pack 'C*', @chr;
    }
}

#
# GBK order to character (without parameter)
#
sub Egbk::chr_() {

    my $c = $_;

    if ($c == 0x00) {
        return "\x00";
    }
    else {
        my @chr = ();
        while ($c > 0) {
            unshift @chr, ($c % 0x100);
            $c = int($c / 0x100);
        }
        return pack 'C*', @chr;
    }
}

#
# GBK stacked file test expr
#
sub Egbk::filetest(@) {

    my $file     = pop @_;
    my $filetest = substr(pop @_, 1);

    unless (eval qq{Egbk::$filetest(\$file)}) {
        return '';
    }
    for my $filetest (reverse @_) {
        unless (eval qq{ $filetest _ }) {
            return '';
        }
    }
    return 1;
}

#
# GBK file test -r expr
#
sub Egbk::r(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -r (Egbk::r)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-r _,@_) : -r _;
    }

    # P.908 32.39. Symbol
    # in Chapter 32: Standard Modules
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.
    # (and so on)

    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-r $fh,@_) : -r $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-r _,@_) : -r _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-r _,@_) : -r _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $r = -r $fh;
                close $fh;
                return wantarray ? ($r,@_) : $r;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -w expr
#
sub Egbk::w(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -w (Egbk::w)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-w _,@_) : -w _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-w $fh,@_) : -w $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-w _,@_) : -w _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-w _,@_) : -w _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, ">>$_") {
                my $w = -w $fh;
                close $fh;
                return wantarray ? ($w,@_) : $w;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -x expr
#
sub Egbk::x(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -x (Egbk::x)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-x _,@_) : -x _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-x $fh,@_) : -x $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-x _,@_) : -x _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-x _,@_) : -x _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $dummy_for_underline_cache = -x $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return wantarray ? ('',@_) : '';
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -o expr
#
sub Egbk::o(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -o (Egbk::o)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-o _,@_) : -o _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-o $fh,@_) : -o $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-o _,@_) : -o _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-o _,@_) : -o _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $o = -o $fh;
                close $fh;
                return wantarray ? ($o,@_) : $o;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -R expr
#
sub Egbk::R(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -R (Egbk::R)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-R _,@_) : -R _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-R $fh,@_) : -R $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-R _,@_) : -R _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-R _,@_) : -R _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $R = -R $fh;
                close $fh;
                return wantarray ? ($R,@_) : $R;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -W expr
#
sub Egbk::W(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -W (Egbk::W)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-W _,@_) : -W _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-W $fh,@_) : -W $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-W _,@_) : -W _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-W _,@_) : -W _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, ">>$_") {
                my $W = -W $fh;
                close $fh;
                return wantarray ? ($W,@_) : $W;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -X expr
#
sub Egbk::X(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -X (Egbk::X)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-X _,@_) : -X _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-X $fh,@_) : -X $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-X _,@_) : -X _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-X _,@_) : -X _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $dummy_for_underline_cache = -X $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return wantarray ? ('',@_) : '';
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -O expr
#
sub Egbk::O(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -O (Egbk::O)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-O _,@_) : -O _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-O $fh,@_) : -O $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-O _,@_) : -O _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-O _,@_) : -O _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $O = -O $fh;
                close $fh;
                return wantarray ? ($O,@_) : $O;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -e expr
#
sub Egbk::e(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -e (Egbk::e)' if @_ and not wantarray;

    local $^W = 0;

    my $fh = qualify_to_ref $_;
    if ($_ eq '_') {
        return wantarray ? (-e _,@_) : -e _;
    }

    # return false if directory handle
    elsif (defined Egbk::telldir($fh)) {
        return wantarray ? ('',@_) : '';
    }

    # return true if file handle
    elsif (fileno $fh) {
        return wantarray ? (1,@_) : 1;
    }

    elsif (-e $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (1,@_) : 1;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $e = -e $fh;
                close $fh;
                return wantarray ? ($e,@_) : $e;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -z expr
#
sub Egbk::z(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -z (Egbk::z)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-z _,@_) : -z _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-z $fh,@_) : -z $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-z _,@_) : -z _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-z _,@_) : -z _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $z = -z $fh;
                close $fh;
                return wantarray ? ($z,@_) : $z;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -s expr
#
sub Egbk::s(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -s (Egbk::s)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-s _,@_) : -s _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-s $fh,@_) : -s $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-s _,@_) : -s _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-s _,@_) : -s _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $s = -s $fh;
                close $fh;
                return wantarray ? ($s,@_) : $s;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -f expr
#
sub Egbk::f(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -f (Egbk::f)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-f _,@_) : -f _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-f $fh,@_) : -f $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-f _,@_) : -f _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? ('',@_) : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $f = -f $fh;
                close $fh;
                return wantarray ? ($f,@_) : $f;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -d expr
#
sub Egbk::d(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -d (Egbk::d)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-d _,@_) : -d _;
    }

    # return false if file handle or directory handle
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? ('',@_) : '';
    }
    elsif (-e $_) {
        return wantarray ? (-d _,@_) : -d _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        return wantarray ? (-d "$_/.",@_) : -d "$_/.";
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -l expr
#
sub Egbk::l(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -l (Egbk::l)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-l _,@_) : -l _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-l $fh,@_) : -l $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-l _,@_) : -l _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-l _,@_) : -l _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $l = -l $fh;
                close $fh;
                return wantarray ? ($l,@_) : $l;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -p expr
#
sub Egbk::p(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -p (Egbk::p)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-p _,@_) : -p _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-p $fh,@_) : -p $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-p _,@_) : -p _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-p _,@_) : -p _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $p = -p $fh;
                close $fh;
                return wantarray ? ($p,@_) : $p;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -S expr
#
sub Egbk::S(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -S (Egbk::S)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-S _,@_) : -S _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-S $fh,@_) : -S $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-S _,@_) : -S _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-S _,@_) : -S _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $S = -S $fh;
                close $fh;
                return wantarray ? ($S,@_) : $S;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -b expr
#
sub Egbk::b(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -b (Egbk::b)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-b _,@_) : -b _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-b $fh,@_) : -b $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-b _,@_) : -b _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-b _,@_) : -b _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $b = -b $fh;
                close $fh;
                return wantarray ? ($b,@_) : $b;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -c expr
#
sub Egbk::c(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -c (Egbk::c)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-c _,@_) : -c _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-c $fh,@_) : -c $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-c _,@_) : -c _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-c _,@_) : -c _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $c = -c $fh;
                close $fh;
                return wantarray ? ($c,@_) : $c;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -u expr
#
sub Egbk::u(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -u (Egbk::u)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-u _,@_) : -u _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-u $fh,@_) : -u $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-u _,@_) : -u _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-u _,@_) : -u _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $u = -u $fh;
                close $fh;
                return wantarray ? ($u,@_) : $u;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -g expr
#
sub Egbk::g(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -g (Egbk::g)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-g _,@_) : -g _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-g $fh,@_) : -g $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-g _,@_) : -g _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-g _,@_) : -g _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $g = -g $fh;
                close $fh;
                return wantarray ? ($g,@_) : $g;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -k expr
#
sub Egbk::k(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -k (Egbk::k)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? ('',@_) : '';
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? ('',@_) : '';
    }
    elsif ($] =~ m/^5\.008/oxms) {
        return wantarray ? ('',@_) : '';
    }
    return wantarray ? ($_,@_) : $_;
}

#
# GBK file test -T expr
#
sub Egbk::T(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -T (Egbk::T)' if @_ and not wantarray;
    my $T = 1;

    my $fh = qualify_to_ref $_;
    if (fileno $fh) {

        if (defined Egbk::telldir($fh)) {
            return wantarray ? (undef,@_) : undef;
        }

        # P.813 29.2.176. tell
        # in Chapter 29: Functions
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.
        # (and so on)

        my $systell = sysseek $fh, 0, 1;

        if (sysread $fh, my $block, 512) {

            # P.163 Binary file check in Little Perl Parlor 16
            # of Book No. T1008901080816 ZASSHI 08901-8 UNIX MAGAZINE 1993 Aug VOL8#8
            # (and so on)

            if ($block =~ /[\000\377]/oxms) {
                $T = '';
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $T = '';
            }
        }

        # 0 byte or eof
        else {
            $T = 1;
        }

        sysseek $fh, $systell, 0;
    }
    else {
        if (-d $_ or -d "$_/.") {
            return wantarray ? (undef,@_) : undef;
        }

        $fh = gensym();
        unless (CORE::open $fh, $_) {
            return wantarray ? (undef,@_) : undef;
        }
        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $T = '';
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $T = '';
            }
        }

        # 0 byte or eof
        else {
            $T = 1;
        }
        close $fh;
    }

    my $dummy_for_underline_cache = -T $_;
    return wantarray ? ($T,@_) : $T;
}

#
# GBK file test -B expr
#
sub Egbk::B(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -B (Egbk::B)' if @_ and not wantarray;
    my $B = '';

    my $fh = qualify_to_ref $_;
    if (fileno $fh) {

        if (defined Egbk::telldir($fh)) {
            return wantarray ? (undef,@_) : undef;
        }

        my $systell = sysseek $fh, 0, 1;

        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $B = 1;
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $B = 1;
            }
        }

        # 0 byte or eof
        else {
            $B = 1;
        }

        sysseek $fh, $systell, 0;
    }
    else {
        if (-d $_ or -d "$_/.") {
            return wantarray ? (undef,@_) : undef;
        }

        $fh = gensym();
        unless (CORE::open $fh, $_) {
            return wantarray ? (undef,@_) : undef;
        }
        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $B = 1;
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $B = 1;
            }
        }

        # 0 byte or eof
        else {
            $B = 1;
        }
        close $fh;
    }

    my $dummy_for_underline_cache = -B $_;
    return wantarray ? ($B,@_) : $B;
}

#
# GBK file test -M expr
#
sub Egbk::M(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -M (Egbk::M)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-M _,@_) : -M _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-M $fh,@_) : -M $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-M _,@_) : -M _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-M _,@_) : -M _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $M = ($^T - $mtime) / (24*60*60);
                return wantarray ? ($M,@_) : $M;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -A expr
#
sub Egbk::A(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -A (Egbk::A)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-A _,@_) : -A _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-A $fh,@_) : -A $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-A _,@_) : -A _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-A _,@_) : -A _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $A = ($^T - $atime) / (24*60*60);
                return wantarray ? ($A,@_) : $A;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK file test -C expr
#
sub Egbk::C(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -C (Egbk::C)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-C _,@_) : -C _;
    }
    elsif (fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-C $fh,@_) : -C $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-C _,@_) : -C _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-C _,@_) : -C _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $C = ($^T - $ctime) / (24*60*60);
                return wantarray ? ($C,@_) : $C;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# GBK stacked file test $_
#
sub Egbk::filetest_(@) {

    my $filetest = substr(pop @_, 1);

    unless (eval qq{Egbk::${filetest}_}) {
        return '';
    }
    for my $filetest (reverse @_) {
        unless (eval qq{ $filetest _ }) {
            return '';
        }
    }
    return 1;
}

#
# GBK file test -r $_
#
sub Egbk::r_() {

    if (-e $_) {
        return -r _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -r _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $r = -r $fh;
                close $fh;
                return $r ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -w $_
#
sub Egbk::w_() {

    if (-e $_) {
        return -w _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -w _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, ">>$_") {
                my $w = -w $fh;
                close $fh;
                return $w ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -x $_
#
sub Egbk::x_() {

    if (-e $_) {
        return -x _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -x _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $dummy_for_underline_cache = -x $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return '';
        }
    }
    return;
}

#
# GBK file test -o $_
#
sub Egbk::o_() {

    if (-e $_) {
        return -o _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -o _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $o = -o $fh;
                close $fh;
                return $o ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -R $_
#
sub Egbk::R_() {

    if (-e $_) {
        return -R _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -R _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $R = -R $fh;
                close $fh;
                return $R ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -W $_
#
sub Egbk::W_() {

    if (-e $_) {
        return -W _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -W _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, ">>$_") {
                my $W = -W $fh;
                close $fh;
                return $W ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -X $_
#
sub Egbk::X_() {

    if (-e $_) {
        return -X _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -X _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $dummy_for_underline_cache = -X $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return '';
        }
    }
    return;
}

#
# GBK file test -O $_
#
sub Egbk::O_() {

    if (-e $_) {
        return -O _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -O _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $O = -O $fh;
                close $fh;
                return $O ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -e $_
#
sub Egbk::e_() {

    if (-e $_) {
        return 1;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return 1;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $e = -e $fh;
                close $fh;
                return $e ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -z $_
#
sub Egbk::z_() {

    if (-e $_) {
        return -z _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -z _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $z = -z $fh;
                close $fh;
                return $z ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -s $_
#
sub Egbk::s_() {

    if (-e $_) {
        return -s _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -s _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $s = -s $fh;
                close $fh;
                return $s;
            }
        }
    }
    return;
}

#
# GBK file test -f $_
#
sub Egbk::f_() {

    if (-e $_) {
        return -f _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $f = -f $fh;
                close $fh;
                return $f ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -d $_
#
sub Egbk::d_() {

    if (-e $_) {
        return -d _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        return -d "$_/." ? 1 : '';
    }
    return;
}

#
# GBK file test -l $_
#
sub Egbk::l_() {

    if (-e $_) {
        return -l _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -l _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $l = -l $fh;
                close $fh;
                return $l ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -p $_
#
sub Egbk::p_() {

    if (-e $_) {
        return -p _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -p _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $p = -p $fh;
                close $fh;
                return $p ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -S $_
#
sub Egbk::S_() {

    if (-e $_) {
        return -S _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -S _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $S = -S $fh;
                close $fh;
                return $S ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -b $_
#
sub Egbk::b_() {

    if (-e $_) {
        return -b _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -b _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $b = -b $fh;
                close $fh;
                return $b ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -c $_
#
sub Egbk::c_() {

    if (-e $_) {
        return -c _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -c _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $c = -c $fh;
                close $fh;
                return $c ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -u $_
#
sub Egbk::u_() {

    if (-e $_) {
        return -u _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -u _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $u = -u $fh;
                close $fh;
                return $u ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -g $_
#
sub Egbk::g_() {

    if (-e $_) {
        return -g _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -g _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my $g = -g $fh;
                close $fh;
                return $g ? 1 : '';
            }
        }
    }
    return;
}

#
# GBK file test -k $_
#
sub Egbk::k_() {

    if ($] =~ m/^5\.008/oxms) {
        return wantarray ? ('',@_) : '';
    }
    return wantarray ? ($_,@_) : $_;
}

#
# GBK file test -T $_
#
sub Egbk::T_() {

    my $T = 1;

    if (-d $_ or -d "$_/.") {
        return;
    }
    my $fh = gensym();
    unless (CORE::open $fh, $_) {
        return;
    }

    if (sysread $fh, my $block, 512) {
        if ($block =~ /[\000\377]/oxms) {
            $T = '';
        }
        elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
            $T = '';
        }
    }

    # 0 byte or eof
    else {
        $T = 1;
    }
    close $fh;

    my $dummy_for_underline_cache = -T $_;
    return $T;
}

#
# GBK file test -B $_
#
sub Egbk::B_() {

    my $B = '';

    if (-d $_ or -d "$_/.") {
        return;
    }
    my $fh = gensym();
    unless (CORE::open $fh, $_) {
        return;
    }

    if (sysread $fh, my $block, 512) {
        if ($block =~ /[\000\377]/oxms) {
            $B = 1;
        }
        elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
            $B = 1;
        }
    }

    # 0 byte or eof
    else {
        $B = 1;
    }
    close $fh;

    my $dummy_for_underline_cache = -B $_;
    return $B;
}

#
# GBK file test -M $_
#
sub Egbk::M_() {

    if (-e $_) {
        return -M _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -M _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $M = ($^T - $mtime) / (24*60*60);
                return $M;
            }
        }
    }
    return;
}

#
# GBK file test -A $_
#
sub Egbk::A_() {

    if (-e $_) {
        return -A _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -A _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $A = ($^T - $atime) / (24*60*60);
                return $A;
            }
        }
    }
    return;
}

#
# GBK file test -C $_
#
sub Egbk::C_() {

    if (-e $_) {
        return -C _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -C _;
        }
        else {
            my $fh = gensym();
            if (CORE::open $fh, $_) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $C = ($^T - $ctime) / (24*60*60);
                return $C;
            }
        }
    }
    return;
}

#
# GBK path globbing (with parameter)
#
sub Egbk::glob($) {

    return _dosglob(@_);
}

#
# GBK path globbing (without parameter)
#
sub Egbk::glob_() {

    return _dosglob();
}

#
# GBK path globbing from File::DosGlob module
#
my %iter;
my %entries;
sub _dosglob {

    # context (keyed by second cxix argument provided by core)
    my($expr,$cxix) = @_;

    # glob without args defaults to $_
    $expr = $_ if not defined $expr;

    # represents the current user's home directory
    #
    # 7.3. Expanding Tildes in Filenames
    # in Chapter 7. File Access
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
    #
    # and File::HomeDir, File::HomeDir::Windows module

    # DOS-like system
    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        $expr =~ s{ \A ~ (?= [^/\\] ) }
                  { $ENV{'HOME'} || $ENV{'USERPROFILE'} || "$ENV{'HOMEDRIVE'}$ENV{'HOMEPATH'}" }oxmse;
    }

    # UNIX-like system
    else {
        $expr =~ s{ \A ~ ( (?:[\x81-\xFE][\x00-\xFF]|[^/])* ) }
                  { $1 ? (getpwnam($1))[7] : ($ENV{'HOME'} || $ENV{'LOGDIR'} || (getpwuid($<))[7]) }oxmse;
    }

    # assume global context if not provided one
    $cxix = '_G_' if not defined $cxix;
    $iter{$cxix} = 0 if not exists $iter{$cxix};

    # if we're just beginning, do it all first
    if ($iter{$cxix} == 0) {
            $entries{$cxix} = [ _do_glob(1, _parse_line($expr)) ];
    }

    # chuck it all out, quick or slow
    if (wantarray) {
        delete $iter{$cxix};
        return @{delete $entries{$cxix}};
    }
    else {
        if ($iter{$cxix} = scalar @{$entries{$cxix}}) {
            return shift @{$entries{$cxix}};
        }
        else {
            # return undef for EOL
            delete $iter{$cxix};
            delete $entries{$cxix};
            return undef;
        }
    }
}

#
# GBK path globbing subroutine
#
sub _do_glob {

    my($cond,@expr) = @_;
    my @glob = ();

OUTER:
    for my $expr (@expr) {
        next OUTER if not defined $expr;
        next OUTER if $expr eq '';

        my @matched = ();
        my @globdir = ();
        my $head    = '.';
        my $pathsep = '/';
        my $tail;

        # if argument is within quotes strip em and do no globbing
        if ($expr =~ m/\A " ((?:$q_char)*) " \z/oxms) {
            $expr = $1;
            if ($cond eq 'd') {
                if (Egbk::d $expr) {
                    push @glob, $expr;
                }
            }
            else {
                if (Egbk::e $expr) {
                    push @glob, $expr;
                }
            }
            next OUTER;
        }

        # wildcards with a drive prefix such as h:*.pm must be changed
        # to h:./*.pm to expand correctly
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            $expr =~ s# \A ((?:[A-Za-z]:)?) ([\x81-\xFE][\x00-\xFF]|[^/\\]) #$1./$2#oxms;
        }

        if (($head, $tail) = _parse_path($expr,$pathsep)) {
            if ($tail eq '') {
                push @glob, $expr;
                next OUTER;
            }
            if ($head =~ m/ \A (?:$q_char)*? [*?] /oxms) {
                if (@globdir = _do_glob('d', $head)) {
                    push @glob, _do_glob($cond, map {"$_$pathsep$tail"} @globdir);
                    next OUTER;
                }
            }
            if ($head eq '' or $head =~ m/\A [A-Za-z]: \z/oxms) {
                $head .= $pathsep;
            }
            $expr = $tail;
        }

        # If file component has no wildcards, we can avoid opendir
        if ($expr !~ m/ \A (?:$q_char)*? [*?] /oxms) {
            if ($head eq '.') {
                $head = '';
            }
            if ($head ne '' and ($head =~ m/ \G ($q_char) /oxmsg)[-1] ne $pathsep) {
                $head .= $pathsep;
            }
            $head .= $expr;
            if ($cond eq 'd') {
                if (Egbk::d $head) {
                    push @glob, $head;
                }
            }
            else {
                if (Egbk::e $head) {
                    push @glob, $head;
                }
            }
            next OUTER;
        }
        Egbk::opendir(*DIR, $head) or next OUTER;
        my @leaf = readdir DIR;
        closedir DIR;

        if ($head eq '.') {
            $head = '';
        }
        if ($head ne '' and ($head =~ m/ \G ($q_char) /oxmsg)[-1] ne $pathsep) {
            $head .= $pathsep;
        }

        my $pattern = '';
        while ($expr =~ m/ \G ($q_char) /oxgc) {
            my $char = $1;
            if ($char eq '*') {
                $pattern .= "(?:$your_char)*",
            }
            elsif ($char eq '?') {
                $pattern .= "(?:$your_char)?",  # DOS style
#               $pattern .= "(?:$your_char)",   # UNIX style
            }
            elsif ((my $uc = Egbk::uc($char)) ne $char) {
                $pattern .= $uc;
            }
            else {
                $pattern .= quotemeta $char;
            }
        }
        my $matchsub = sub { Egbk::uc($_[0]) =~ m{\A $pattern \z}xms };

#       if ($@) {
#           print STDERR "$0: $@\n";
#           next OUTER;
#       }

INNER:
        for my $leaf (@leaf) {
            if ($leaf eq '.' or $leaf eq '..') {
                next INNER;
            }
            if ($cond eq 'd' and not Egbk::d "$head$leaf") {
                next INNER;
            }

            if (&$matchsub($leaf)) {
                push @matched, "$head$leaf";
                next INNER;
            }

            # [DOS compatibility special case]
            # Failed, add a trailing dot and try again, but only...

            if (Egbk::index($leaf,'.') == -1 and   # if name does not have a dot in it *and*
                CORE::length($leaf) <= 8 and        # name is shorter than or equal to 8 chars *and*
                Egbk::index($pattern,'\\.') != -1  # pattern has a dot.
            ) {
                if (&$matchsub("$leaf.")) {
                    push @matched, "$head$leaf";
                    next INNER;
                }
            }
        }
        if (@matched) {
            push @glob, @matched;
        }
    }
    return @glob;
}

#
# GBK parse line
#
sub _parse_line {

    my($line) = @_;

    $line .= ' ';
    my @piece = ();
    while ($line =~ m{
        " ( (?: [\x81-\xFE][\x00-\xFF]|[^"]   )*  ) " \s+ |
          ( (?: [\x81-\xFE][\x00-\xFF]|[^"\s] )*  )   \s+
        }oxmsg
    ) {
        push @piece, defined($1) ? $1 : $2;
    }
    return @piece;
}

#
# GBK parse path
#
sub _parse_path {

    my($path,$pathsep) = @_;

    $path .= '/';
    my @subpath = ();
    while ($path =~ m{
        ((?: [\x81-\xFE][\x00-\xFF]|[^/\\] )+?) [/\\] }oxmsg
    ) {
        push @subpath, $1;
    }

    my $tail = pop @subpath;
    my $head = join $pathsep, @subpath;
    return $head, $tail;
}

#
# GBK file lstat (with parameter)
#
sub Egbk::lstat(*) {

    local $_ = shift if @_;

    if (-e $_) {
        return CORE::lstat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = gensym();
        if (CORE::open $fh, $_) {
            my @lstat = CORE::stat $fh; # not CORE::lstat
            close $fh;
            return @lstat;
        }
    }
    return;
}

#
# GBK file lstat (without parameter)
#
sub Egbk::lstat_() {

    if (-e $_) {
        return CORE::lstat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = gensym();
        if (CORE::open $fh, $_) {
            my @lstat = CORE::stat $fh; # not CORE::lstat
            close $fh;
            return @lstat;
        }
    }
    return;
}

#
# GBK path opendir
#
sub Egbk::opendir(*$) {

    my $dh = qualify_to_ref $_[0];
    if (CORE::opendir $dh, $_[1]) {
        return 1;
    }
    elsif (_MSWin32_5Cended_path($_[1])) {
        if (CORE::opendir $dh, "$_[1]/.") {
            return 1;
        }
    }
    return;
}

#
# GBK file stat (with parameter)
#
sub Egbk::stat(*) {

    local $_ = shift if @_;

    my $fh = qualify_to_ref $_;
    if (fileno $fh) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = gensym();
        if (CORE::open $fh, $_) {
            my @stat = CORE::stat $fh;
            close $fh;
            return @stat;
        }
    }
    return;
}

#
# GBK file stat (without parameter)
#
sub Egbk::stat_() {

    my $fh = qualify_to_ref $_;
    if (fileno $fh) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = gensym();
        if (CORE::open $fh, $_) {
            my @stat = CORE::stat $fh;
            close $fh;
            return @stat;
        }
    }
    return;
}

#
# GBK path unlink
#
sub Egbk::unlink(@) {

    local @_ = ($_) unless @_;

    my $unlink = 0;
    for (@_) {
        if (CORE::unlink) {
            $unlink++;
        }
        elsif (_MSWin32_5Cended_path($_)) {
            my @char = m/\G ($q_char) /oxmsg;
            my $file = join '', map {{'/' => '\\'}->{$_} || $_} @char;
            if ($file =~ m/ \A (?:$q_char)*? [ ] /oxms) {
                $file = qq{"$file"};
            }

            # P.565 23.1.2. Cleaning Up Your Environment
            # in Chapter 23: Security
            # of ISBN 0-596-00027-8 Programming Perl Third Edition.
            # (and so on)

            # local $ENV{'PATH'} = '.';
            local @ENV{qw(IFS CDPATH ENV BASH_ENV)};

            system qq{del $file >NUL 2>NUL};

            my $fh = gensym();
            if (CORE::open $fh, $_) {
                close $fh;
            }
            else {
                $unlink++;
            }
        }
    }
    return $unlink;
}

#
# GBK chdir
#
sub Egbk::chdir(;$) {

    if (@_ == 0) {
        return CORE::chdir;
    }

    my($dir) = @_;

    if (_MSWin32_5Cended_path($dir)) {
        if (not Egbk::d $dir) {
            return 0;
        }

        if ($] =~ m/^5\.005/oxms) {
            return CORE::chdir $dir;
        }
        elsif ($] =~ m/^(?:5\.006|5\.008000)/oxms) {
            if ($^O eq 'MSWin32') {
                local $@;
                my $chdir = eval q{
                    require 'jacode.pl';

                    # P.676 ${^WIDE_SYSTEM_CALLS}
                    # in Chapter 28: Special Names
                    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                    local ${^WIDE_SYSTEM_CALLS} = 1;
                    return CORE::chdir jcode::utf8($dir,'sjis');
                };
                if (not $@) {
                    return $chdir;
                }
            }
        }

        local $@;
        my $shortdir = '';
        my $chdir = eval q{
            use Win32;
            $shortdir = Win32::GetShortPathName($dir);
            if ($shortdir ne $dir) {
                return CORE::chdir $shortdir;
            }
            else {
                return 0;
            }
        };
        if ($@) {
            my @char = $dir =~ m/\G ($q_char) /oxmsg;
            while ($char[-1] eq "\x5C") {
                pop @char;
            }
            $dir = join '', @char;
            croak "perl$] can't chdir to $dir (chr(0x5C) ended path), Win32.pm module may help you";
        }
        elsif ($shortdir eq $dir) {
            my @char = $dir =~ m/\G ($q_char) /oxmsg;
            while ($char[-1] eq "\x5C") {
                pop @char;
            }
            $dir = join '', @char;
            croak "perl$] can't chdir to $dir (chr(0x5C) ended path)";
        }
        return $chdir;
    }
    else {
        return CORE::chdir $dir;
    }
}

#
# GBK chr(0x5C) ended path on MSWin32
#
sub _MSWin32_5Cended_path {

    if ((@_ >= 1) and ($_[0] ne '')) {
        if ($^O =~ m/\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            my @char = $_[0] =~ /\G ($q_char) /oxmsg;
            if ($char[-1] =~ m/ \x5C \z/oxms) {
                return 1;
            }
        }
    }
    return;
}

#
# do GBK file
#
sub Egbk::do($) {

    my($filename) = @_;

    my $realfilename;
    my $result;
ITER_DO:
    {
        for my $prefix (@INC) {
            if ($^O eq 'MacOS') {
                $realfilename = "$prefix$filename";
            }
            else {
                $realfilename = "$prefix/$filename";
            }

            if (Egbk::f($realfilename)) {

                my $script = '';

                if (Egbk::e("$realfilename.e")) {
                    my $e_mtime      = (Egbk::stat("$realfilename.e"))[9];
                    my $mtime        = (Egbk::stat($realfilename))[9];
                    my $module_mtime = (Egbk::stat(__FILE__))[9];
                    if (($e_mtime < $mtime) or ($mtime < $module_mtime)) {
                        Egbk::unlink "$realfilename.e";
                    }
                }

                if (Egbk::e("$realfilename.e")) {
                    my $fh = gensym();
                    if (CORE::open $fh, "$realfilename.e") {
                        if ($^O eq 'MacOS') {
                            eval q{
                                require Mac::Files;
                                Mac::Files::FSpSetFLock("$realfilename.e");
                            };
                        }
                        elsif (exists $ENV{'SJIS_NONBLOCK'}) {

                            # 7.18. Locking a File
                            # in Chapter 7. File Access
                            # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
                            # (and so on)

                            eval q{
                                unless (flock($fh, LOCK_SH | LOCK_NB)) {
                                    carp "$__FILE__: Can't immediately read-lock the file: $realfilename.e";
                                    exit;
                                }
                            };
                        }
                        else {
                            eval q{ flock($fh, LOCK_SH) };
                        }
                        local $/ = undef; # slurp mode
                        $script = <$fh>;
                        if ($^O eq 'MacOS') {
                            eval q{
                                require Mac::Files;
                                Mac::Files::FSpRstFLock("$realfilename.e");
                            };
                        }
                        close $fh;
                    }
                }
                else {
                    my $fh = gensym();
                    CORE::open $fh, $realfilename;
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    close $fh;

                    if ($script =~ m/^ \s* use \s+ GBK \s* ([^;]*) ; \s* \n? $/oxms) {
                        CORE::require GBK;
                        $script = GBK::escape_script($script);
                        my $fh = gensym();
                        if ((eval q{ use Fcntl qw(O_WRONLY O_APPEND O_CREAT); 1 } and CORE::sysopen($fh, "$realfilename.e", &O_WRONLY|&O_APPEND|&O_CREAT))
                            or CORE::open($fh, ">>$realfilename.e")
                        ) {
                            if ($^O eq 'MacOS') {
                                eval q{
                                    require Mac::Files;
                                    Mac::Files::FSpSetFLock("$realfilename.e");
                                };
                            }
                            elsif (exists $ENV{'SJIS_NONBLOCK'}) {
                                eval q{
                                    unless (flock($fh, LOCK_EX | LOCK_NB)) {
                                        carp "$__FILE__: Can't immediately write-lock the file: $realfilename.e";
                                        exit;
                                    }
                                };
                            }
                            else {
                                eval q{ flock($fh, LOCK_EX) };
                            }
                            truncate($fh, 0) or croak "$__FILE__: Can't truncate file: $realfilename.e";
                            seek($fh, 0, 0)  or croak "$__FILE__: Can't seek file: $realfilename.e";
                            print {$fh} $script;
                            if ($^O eq 'MacOS') {
                                eval q{
                                    require Mac::Files;
                                    Mac::Files::FSpRstFLock("$realfilename.e");
                                };
                            }
                            close $fh;
                        }
                    }
                }

                no strict;
                local $@;
                $result = eval $script;

                last ITER_DO;
            }
        }
    }
    $INC{$filename} = $realfilename;
    return $result;
}

#
# require GBK file
#

# require
# in Chapter 3: Functions
# of ISBN 1-56592-149-6 Programming Perl, Second Edition.

sub Egbk::require(;$) {

    local $_ = shift if @_;
    return 1 if $INC{$_};

    # jcode.pl
    # ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/

    # jacode.pl
    # http://search.cpan.org/dist/jacode/

    if (m{ \b (?: jcode\.pl | jacode\.pl ) \z }oxms) {
        return CORE::require($_);
    }

    my $realfilename;
    my $result;
ITER_REQUIRE:
    {
        for my $prefix (@INC) {
            if ($^O eq 'MacOS') {
                $realfilename = "$prefix$_";
            }
            else {
                $realfilename = "$prefix/$_";
            }

            if (Egbk::f($realfilename)) {

                my $script = '';

                if (Egbk::e("$realfilename.e")) {
                    my $e_mtime      = (Egbk::stat("$realfilename.e"))[9];
                    my $mtime        = (Egbk::stat($realfilename))[9];
                    my $module_mtime = (Egbk::stat(__FILE__))[9];
                    if (($e_mtime < $mtime) or ($mtime < $module_mtime)) {
                        Egbk::unlink "$realfilename.e";
                    }
                }

                if (Egbk::e("$realfilename.e")) {
                    my $fh = gensym();
                    CORE::open($fh, "$realfilename.e") or croak "Can't open file: $realfilename.e";
                    if ($^O eq 'MacOS') {
                        eval q{
                            require Mac::Files;
                            Mac::Files::FSpSetFLock("$realfilename.e");
                        };
                    }
                    elsif (exists $ENV{'SJIS_NONBLOCK'}) {
                        eval q{
                            unless (flock($fh, LOCK_SH | LOCK_NB)) {
                                carp "$__FILE__: Can't immediately read-lock the file: $realfilename.e";
                                exit;
                            }
                        };
                    }
                    else {
                        eval q{ flock($fh, LOCK_SH) };
                    }
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    if ($^O eq 'MacOS') {
                        eval q{
                            require Mac::Files;
                            Mac::Files::FSpRstFLock("$realfilename.e");
                        };
                    }
                    close($fh) or croak "Can't close file: $realfilename";
                }
                else {
                    my $fh = gensym();
                    CORE::open($fh, $realfilename) or croak "Can't open file: $realfilename";
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    close($fh) or croak "Can't close file: $realfilename";

                    if ($script =~ m/^ \s* use \s+ GBK \s* ([^;]*) ; \s* \n? $/oxms) {
                        CORE::require GBK;
                        $script = GBK::escape_script($script);
                        my $fh = gensym();
                        if (eval q{ use Fcntl qw(O_WRONLY O_APPEND O_CREAT); 1 } and CORE::sysopen($fh,"$realfilename.e",&O_WRONLY|&O_APPEND|&O_CREAT)) {
                        }
                        else {
                            CORE::open($fh, ">>$realfilename.e") or croak "Can't write open file: $realfilename.e";
                        }
                        if ($^O eq 'MacOS') {
                            eval q{
                                require Mac::Files;
                                Mac::Files::FSpSetFLock("$realfilename.e");
                            };
                        }
                        elsif (exists $ENV{'SJIS_NONBLOCK'}) {
                            eval q{
                                unless (flock($fh, LOCK_EX | LOCK_NB)) {
                                    carp "$__FILE__: Can't immediately write-lock the file: $realfilename.e";
                                    exit;
                                }
                            };
                        }
                        else {
                            eval q{ flock($fh, LOCK_EX) };
                        }
                        truncate($fh, 0) or croak "$__FILE__: Can't truncate file: $realfilename.e";
                        seek($fh, 0, 0)  or croak "$__FILE__: Can't seek file: $realfilename.e";
                        print {$fh} $script;
                        if ($^O eq 'MacOS') {
                            eval q{
                                require Mac::Files;
                                Mac::Files::FSpRstFLock("$realfilename.e");
                            };
                        }
                        close($fh) or croak "Can't close file: $realfilename";
                    }
                }

                no strict;
                local $@;
                $result = eval $script;

                last ITER_REQUIRE;
            }
        }
        croak "Can't find $_ in \@INC";
    }
    croak $@ if $@;
    croak "$_ did not return true value" unless $result;
    $INC{$_} = $realfilename;
    return $result;
}

#
# GBK telldir avoid warning
#
sub Egbk::telldir(*) {

    local $^W = 0;

    return CORE::telldir $_[0];
}

#
# GBK character to order (with parameter)
#
sub GBK::ord(;$) {

    local $_ = shift if @_;

    if (m/\A ($q_char) /oxms) {
        my @ord = unpack 'C*', $1;
        my $ord = 0;
        while (my $o = shift @ord) {
            $ord = $ord * 0x100 + $o;
        }
        return $ord;
    }
    else {
        return CORE::ord $_;
    }
}

#
# GBK character to order (without parameter)
#
sub GBK::ord_() {

    if (m/\A ($q_char) /oxms) {
        my @ord = unpack 'C*', $1;
        my $ord = 0;
        while (my $o = shift @ord) {
            $ord = $ord * 0x100 + $o;
        }
        return $ord;
    }
    else {
        return CORE::ord $_;
    }
}

#
# GBK reverse
#
sub GBK::reverse(@) {

    if (wantarray) {
        return CORE::reverse @_;
    }
    else {
        return join '', CORE::reverse(join('',@_) =~ m/\G ($q_char) /oxmsg);
    }
}

#
# GBK length by character
#
sub GBK::length(;$) {

    local $_ = shift if @_;

    local @_ = m/\G ($q_char) /oxmsg;
    return scalar @_;
}

#
# GBK substr by character
#
sub GBK::substr($$;$$) {

    my @char = $_[0] =~ m/\G ($q_char) /oxmsg;

    # substr($string,$offset,$length,$replacement)
    if (@_ == 4) {
        my(undef,$offset,$length,$replacement) = @_;
        my $substr = join '', splice(@char, $offset, $length, $replacement);
        $_[0] = join '', @char;
        return $substr;
    }

    # substr($string,$offset,$length)
    elsif (@_ == 3) {
        my(undef,$offset,$length) = @_;
        if ($length == 0) {
            return '';
        }
        if ($offset >= 0) {
            return join '', (@char[$offset            .. $#char])[0 .. $length-1];
        }
        else {
            return join '', (@char[($#char+$offset+1) .. $#char])[0 .. $length-1];
        }
    }

    # substr($string,$offset)
    else {
        my(undef,$offset) = @_;
        if ($offset >= 0) {
            return join '', @char[$offset            .. $#char];
        }
        else {
            return join '', @char[($#char+$offset+1) .. $#char];
        }
    }
}

#
# GBK index by character
#
sub GBK::index($$;$) {

    my $index;
    if (@_ == 3) {
        $index = Egbk::index($_[0], $_[1], CORE::length(GBK::substr($_[0], 0, $_[2])));
    }
    else {
        $index = Egbk::index($_[0], $_[1]);
    }

    if ($index == -1) {
        return -1;
    }
    else {
        return GBK::length(CORE::substr $_[0], 0, $index);
    }
}

#
# GBK rindex by character
#
sub GBK::rindex($$;$) {

    my $rindex;
    if (@_ == 3) {
        $rindex = Egbk::rindex($_[0], $_[1], CORE::length(GBK::substr($_[0], 0, $_[2])));
    }
    else {
        $rindex = Egbk::rindex($_[0], $_[1]);
    }

    if ($rindex == -1) {
        return -1;
    }
    else {
        return GBK::length(CORE::substr $_[0], 0, $rindex);
    }
}

#
# instead of Carp::carp
#
sub carp(@) {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
}

#
# instead of Carp::croak
#
sub croak(@) {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
    die "\n";
}

#
# instead of Carp::cluck
#
sub cluck(@) {
    my $i = 0;
    my @cluck = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @cluck, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR reverse @cluck;
    print STDERR "\n";
    carp @_;
}

#
# instead of Carp::confess
#
sub confess(@) {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR reverse @confess;
    print STDERR "\n";
    croak @_;
}

1;

__END__

=pod

=head1 NAME

Egbk - Run-time routines for GBK.pm

=head1 SYNOPSIS

  use Egbk;

    Egbk::split(...);
    Egbk::tr(...);
    Egbk::chop(...);
    Egbk::index(...);
    Egbk::rindex(...);
    Egbk::lc(...);
    Egbk::lc_;
    Egbk::lcfirst(...);
    Egbk::lcfirst_;
    Egbk::uc(...);
    Egbk::uc_;
    Egbk::ucfirst(...);
    Egbk::ucfirst_;
    Egbk::ignorecase(...);
    Egbk::capture(...);
    Egbk::chr(...);
    Egbk::chr_;
    Egbk::X ...;
    Egbk::X_;
    Egbk::glob(...);
    Egbk::glob_;
    Egbk::lstat(...);
    Egbk::lstat_;
    Egbk::opendir(...);
    Egbk::stat(...);
    Egbk::stat_;
    Egbk::unlink(...);
    Egbk::chdir(...);
    Egbk::do(...);
    Egbk::require(...);
    Egbk::telldir(...);

  # "no Egbk;" not supported

=head1 ABSTRACT

This module is a run-time routines of the GBK.pm.
Because the GBK.pm automatically uses this module, you need not use directly.

=head1 BUGS AND LIMITATIONS

Please patches and report problems to author are welcome.

=head1 HISTORY

This Egbk module first appeared in ActivePerl Build 522 Built under
MSWin32 Compiled at Nov 2 1999 09:52:28

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.
For any questions, use E<lt>ina@cpan.orgE<gt> so we can share
this file.

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 EXAMPLES

=over 2

=item Split string

  @split = Egbk::split(/pattern/,$string,$limit);
  @split = Egbk::split(/pattern/,$string);
  @split = Egbk::split(/pattern/);
  @split = Egbk::split('',$string,$limit);
  @split = Egbk::split('',$string);
  @split = Egbk::split('');
  @split = Egbk::split();
  @split = Egbk::split;

  Scans a GBK $string for delimiters that match pattern and splits the GBK
  $string into a list of substrings, returning the resulting list value in list
  context, or the count of substrings in scalar context. The delimiters are
  determined by repeated pattern matching, using the regular expression given in
  pattern, so the delimiters may be of any size and need not be the same GBK
  $string on every match. If the pattern doesn't match at all, Egbk::split returns
  the original GBK $string as a single substring. If it matches once, you get
  two substrings, and so on.
  If $limit is specified and is not negative, the function splits into no more than
  that many fields. If $limit is negative, it is treated as if an arbitrarily large
  $limit has been specified. If $limit is omitted, trailing null fields are stripped
  from the result (which potential users of pop would do well to remember).
  If GBK $string is omitted, the function splits the $_ GBK string.
  If $patten is also omitted, the function splits on whitespace, /\s+/, after
  skipping any leading whitespace.
  If the pattern contains parentheses, then the substring matched by each pair of
  parentheses is included in the resulting list, interspersed with the fields that
  are ordinarily returned.

=item Transliteration

  $tr = Egbk::tr($variable,$bind_operator,$searchlist,$replacementlist,$modifier);
  $tr = Egbk::tr($variable,$bind_operator,$searchlist,$replacementlist);

  This function scans a GBK string character by character and replaces all
  occurrences of the characters found in $searchlist with the corresponding character
  in $replacementlist. It returns the number of characters replaced or deleted.
  If no GBK string is specified via =~ operator, the $_ variable is translated.
  $modifier are:

  Modifier   Meaning
  ------------------------------------------------------
  c          Complement $searchlist
  d          Delete found but unreplaced characters
  s          Squash duplicate replaced characters
  ------------------------------------------------------

=item Chop string

  $chop = Egbk::chop(@list);
  $chop = Egbk::chop();
  $chop = Egbk::chop;

  Chops off the last character of a GBK string contained in the variable (or
  GBK strings in each element of a @list) and returns the character chopped.
  The Egbk::chop operator is used primarily to remove the newline from the end of
  an input record but is more efficient than s/\n$//. If no argument is given, the
  function chops the $_ variable.

=item Index string

  $pos = Egbk::index($string,$substr,$position);
  $pos = Egbk::index($string,$substr);

  Returns the position of the first occurrence of $substr in GBK $string.
  The start, if specified, specifies the $position to start looking in the GBK
  $string. Positions are integer numbers based at 0. If the substring is not found,
  the Egbk::index function returns -1.

=item Reverse index string

  $pos = Egbk::rindex($string,$substr,$position);
  $pos = Egbk::rindex($string,$substr);

  Works just like Egbk::index except that it returns the position of the last
  occurence of $substr in GBK $string (a reverse index). The function returns
  -1 if not found. $position, if specified, is the rightmost position that may be
  returned, i.e., how far in the GBK string the function can search.

=item Lower case string

  $lc = Egbk::lc($string);
  $lc = Egbk::lc_;

  Returns a lowercase version of GBK string (or $_, if omitted). This is the
  internal function implementing the \L escape in double-quoted strings.

=item Lower case first character of string

  $lcfirst = Egbk::lcfirst($string);
  $lcfirst = Egbk::lcfirst_;

  Returns a version of GBK string (or $_, if omitted) with the first character
  lowercased. This is the internal function implementing the \l escape in double-
  quoted strings.

=item Upper case string

  $uc = Egbk::uc($string);
  $uc = Egbk::uc_;

  Returns an uppercased version of GBK string (or $_, if string is omitted).
  This is the internal function implementing the \U escape in double-quoted
  strings.

=item Upper case first character of string

  $ucfirst = Egbk::ucfirst($string);
  $ucfirst = Egbk::ucfirst_;

  Returns a version of GBK string (or $_, if omitted) with the first character
  uppercased. This is the internal function implementing the \u escape in double-
  quoted strings.

=item Make ignore case string

  @ignorecase = Egbk::ignorecase(@string);

  This function is internal use to m/ /i, s/ / /i, split / /i and qr/ /i.

=item Make capture number

  $capturenumber = Egbk::capture($string);

  This function is internal use to m/ /, s/ / /, split / / and qr/ /.

=item Make character

  $chr = Egbk::chr($code);
  $chr = Egbk::chr_;

  This function returns the character represented by that $code in the character
  set. For example, Egbk::chr(65) is "A" in either ASCII or GBK, and
  Egbk::chr(0x82a0) is a GBK HIRAGANA LETTER A. For the reverse of Egbk::chr,
  use GBK::ord.

=item File test operator -X

  A file test operator is an unary operator that tests a pathname or a filehandle.
  If $string is omitted, it uses $_ by function Egbk::r_.
  The following functions function when the pathname ends with chr(0x5C) on MSWin32.

  $test = Egbk::r $string;
  $test = Egbk::r_;

  Returns 1 when true case or '' when false case.
  Returns undef unless successful.

  Function and Prototype     Meaning
  ------------------------------------------------------------------------------
  Egbk::r(*), Egbk::r_()   File is readable by effective uid/gid
  Egbk::w(*), Egbk::w_()   File is writable by effective uid/gid
  Egbk::x(*), Egbk::x_()   File is executable by effective uid/gid
  Egbk::o(*), Egbk::o_()   File is owned by effective uid
  Egbk::R(*), Egbk::R_()   File is readable by real uid/gid
  Egbk::W(*), Egbk::W_()   File is writable by real uid/gid
  Egbk::X(*), Egbk::X_()   File is executable by real uid/gid
  Egbk::O(*), Egbk::O_()   File is owned by real uid
  Egbk::e(*), Egbk::e_()   File exists
  Egbk::z(*), Egbk::z_()   File has zero size
  Egbk::f(*), Egbk::f_()   File is a plain file
  Egbk::d(*), Egbk::d_()   File is a directory
  Egbk::l(*), Egbk::l_()   File is a symbolic link
  Egbk::p(*), Egbk::p_()   File is a named pipe (FIFO)
  Egbk::S(*), Egbk::S_()   File is a socket
  Egbk::b(*), Egbk::b_()   File is a block special file
  Egbk::c(*), Egbk::c_()   File is a character special file
  Egbk::u(*), Egbk::u_()   File has setuid bit set
  Egbk::g(*), Egbk::g_()   File has setgid bit set
  Egbk::k(*), Egbk::k_()   File has sticky bit set
  ------------------------------------------------------------------------------

  Returns 1 when true case or '' when false case.
  Returns undef unless successful.

  The Egbk::T, Egbk::T_, Egbk::B and Egbk::B_ work as follows. The first block
  or so of the file is examined for strange chatracters such as
  [\000-\007\013\016-\032\034-\037\377] (that don't look like GBK). If more
  than 10% of the bytes appear to be strange, it's a *maybe* binary file;
  otherwise, it's a *maybe* text file. Also, any file containing ASCII NUL(\0) or
  \377 in the first block is considered a binary file. If Egbk::T or Egbk::B is
  used on a filehandle, the current input (standard I/O or "stdio") buffer is
  examined rather than the first block of the file. Both Egbk::T and Egbk::B
  return 1 as true on an empty file, or on a file at EOF (end-of-file) when testing
  a filehandle. Both Egbk::T and Egbk::B deosn't work when given the special
  filehandle consisting of a solitary underline.

  Function and Prototype     Meaning
  ------------------------------------------------------------------------------
  Egbk::T(*), Egbk::T_()   File is a text file
  Egbk::B(*), Egbk::B_()   File is a binary file (opposite of -T)
  ------------------------------------------------------------------------------

  Returns useful value if successful, or undef unless successful.

  $value = Egbk::s $string;
  $value = Egbk::s_;

  Function and Prototype     Meaning
  ------------------------------------------------------------------------------
  Egbk::s(*), Egbk::s_()   File has nonzero size (returns size)
  Egbk::M(*), Egbk::M_()   Age of file (at startup) in days since modification
  Egbk::A(*), Egbk::A_()   Age of file (at startup) in days since last access
  Egbk::C(*), Egbk::C_()   Age of file (at startup) in days since inode change
  ------------------------------------------------------------------------------

=item Filename expansion (globbing)

  @glob = Egbk::glob($string);
  @glob = Egbk::glob_;

  Performs filename expansion (DOS-like globbing) on $string, returning the next
  successive name on each call. If $string is omitted, $_ is globbed instead.
  This function function when the pathname ends with chr(0x5C) on MSWin32.

  For example, C<<..\\l*b\\file/*glob.p?>> on MSWin32 or UNIX will work as
  expected (in that it will find something like '..\lib\File/DosGlob.pm'
  alright).
  Note that all path components are
  case-insensitive, and that backslashes and forward slashes are both accepted,
  and preserved. You may have to double the backslashes if you are putting them in
  literally, due to double-quotish parsing of the pattern by perl.
  A tilde ("~") expands to the current user's home directory.

  Spaces in the argument delimit distinct patterns, so C<glob('*.exe *.dll')> globs
  all filenames that end in C<.exe> or C<.dll>. If you want to put in literal spaces
  in the glob pattern, you can escape them with either double quotes.
  e.g. C<glob('c:/"Program Files"/*/*.dll')>.

=item Statistics about link

  @lstat = Egbk::lstat($file);
  @lstat = Egbk::lstat_;

  Like Egbk::stat, returns information on file, except that if file is a symbolic
  link, Egbk::lstat returns information about the link; Egbk::stat returns
  information about the file pointed to by the link. (If symbolic links are
  unimplemented on your system, a normal Egbk::stat is done instead.) If file is
  omitted, returns information on file given in $_.
  This function function when the filename ends with chr(0x5C) on MSWin32.

=item Open directory handle

  $rc = Egbk::opendir(DIR,$dir);

  Opens a directory for processing by readdir, telldir, seekdir, rewinddir and
  closedir. The function returns true if successful.
  This function function when the directory name ends with chr(0x5C) on MSWin32.

=item Statistics about file

  @stat = Egbk::stat($file);
  @stat = Egbk::stat_;

  Returns a 13-element list giving the statistics for a file, indicated by either
  a filehandle or an expression that gives its name. It's typically used as
  follows:

  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks) = Egbk::stat($file);

  Not all fields are supported on all filesystem types. Here are the meanings of
  the fields:

  Field     Meaning
  -----------------------------------------------------------------
  dev       Device number of filesystem
  ino       Inode number
  mode      File mode (type and permissions)
  nlink     Nunmer of (hard) links to the file
  uid       Numeric user ID of file's owner
  gid       Numeric group ID of file's owner
  rdev      The device identifier (special files only)
  size      Total size of file, in bytes
  atime     Last access time since the epoch
  mtime     Last modification time since the epoch
  ctime     Inode change time (not creation time!) since the epoch
  blksize   Preferred blocksize for file system I/O
  blocks    Actual number of blocks allocated
  -----------------------------------------------------------------

  $dev and $ino, token together, uniquely identify a file. The $blksize and
  $blocks are likely defined only on BSD-derived filesystem. The $blocks field
  (if defined) is reported in 512-byte blocks.
  If stat is passed the special filehandle consisting of an underline, no
  actual stat is done, but the current contents of the stat structure from the
  last stat or stat-based file test (the -x operators) is returned.
  If file is omitted, returns information on file given in $_.
  This function function when the filename ends with chr(0x5C) on MSWin32.

=item Deletes a list of files.

  $unlink = Egbk::unlink(@list);
  $unlink = Egbk::unlink($file);
  $unlink = Egbk::unlink;

  Delete a list of files. (Under Unix, it will remove a link to a file, but the
  file may still exist if another link references it.) If list is omitted, it
  unlinks the file given in $_. The function returns the number of files
  successfully deleted.
  This function function when the filename ends with chr(0x5C) on MSWin32.

=item Changes the working directory.

  $chdir = Egbk::chdir($dirname);
  $chdir = Egbk::chdir;

  Changes the working directory to $dirname, if possible. If $dirname is omitted,
  it changes to the home directory. The function returns 1 upon success, 0
  otherwise (and puts the error code into $!).

  This function can't function when the $dirname ends with chr(0x5C) on perl5.006,
  perl5.008, perl5.010, perl5.012, perl5.014 on MSWin32.

=item do file

  $return = Egbk::do($file);

  The do FILE form uses the value of FILE as a filename and executes the contents
  of the file as a Perl script. Its primary use is (or rather was) to include
  subroutines from a Perl subroutine library, so that:

  Egbk::do('stat.pl');

  is rather like: 

  scalar eval `cat stat.pl`;   # `type stat.pl` on Windows

  except that Egbk::do is more efficient, more concise, keeps track of the current
  filename for error messages, searches all the directories listed in the @INC
  array, and updates %INC if the file is found.
  It also differs in that code evaluated with Egbk::do FILE can not see lexicals in
  the enclosing scope, whereas code in eval FILE does. It's the same, however, in
  that it reparses the file every time you call it -- so you might not want to do
  this inside a loop unless the filename itself changes at each loop iteration.

  If Egbk::do can't read the file, it returns undef and sets $! to the error. If 
  Egbk::do can read the file but can't compile it, it returns undef and sets an
  error message in $@. If the file is successfully compiled, do returns the value of
  the last expression evaluated.

  Inclusion of library modules (which have a mandatory .pm suffix) is better done
  with the use and require operators, which also Egbk::do error checking and raise
  an exception if there's a problem. They also offer other benefits: they avoid
  duplicate loading, help with object-oriented programming, and provide hints to the
  compiler on function prototypes.

  But Egbk::do FILE is still useful for such things as reading program configuration
  files. Manual error checking can be done this way:

  # read in config files: system first, then user
  for $file ("/usr/share/proggie/defaults.rc", "$ENV{HOME}/.someprogrc") {
      unless ($return = Egbk::do($file)) {
          warn "couldn't parse $file: $@" if $@;
          warn "couldn't Egbk::do($file): $!" unless defined $return;
          warn "couldn't run $file"            unless $return;
      }
  }

  A long-running daemon could periodically examine the timestamp on its configuration
  file, and if the file has changed since it was last read in, the daemon could use
  Egbk::do to reload that file. This is more tidily accomplished with Egbk::do than
  with Egbk::require.

=item require file

  Egbk::require($file);
  Egbk::require();

  This function asserts a dependency of some kind on its argument. If an argument is not
  supplied, $_ is used.

  If the argument is a string, Egbk::require loads and executes the Perl code found in
  the separate file whose name is given by the string. This is similar to performing a
  Egbk::do on a file, except that Egbk::require checks to see whether the library
  file has been loaded already and raises an exception if any difficulties are
  encountered. (It can thus be used to express file dependencies without worrying about
  duplicate compilation.) Like its cousins Egbk::do and use, Egbk::require knows how
  to search the include path stored in the @INC array and to update %INC upon success.

  The file must return true as the last value to indicate successful execution of any
  initialization code, so it's customary to end such a file with 1; unless you're sure
  it'll return true otherwise.

  See also do file.

=item current position of the readdir

  $telldir = Egbk::telldir(DIRHANDLE);

  This function returns the current position of the readdir routines on DIRHANDLE.
  This value may be given to seekdir to access a particular location in a directory.
  The function has the same caveats about possible directory compaction as the
  corresponding system library routine. This function might not be implemented
  everywhere that readdir is. Even if it is, no calculation may be done with the
  return value. It's just an opaque value, meaningful only to seekdir.

=cut

