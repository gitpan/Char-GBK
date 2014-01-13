package Char::Egbk;
######################################################################
#
# Char::Egbk - Run-time routines for Char/GBK.pm
#
# http://search.cpan.org/dist/Char-Char::GBK/
#
# Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014 INABA Hitoshi <ina@cpan.org>
######################################################################

use 5.00503;    # Galapagos Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

# 12.3. Delaying use Until Runtime
# in Chapter 12. Packages, Libraries, and Modules
# of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
# (and so on)

BEGIN { eval q{ use vars qw($VERSION) } }
$VERSION = sprintf '%d.%02d', q$Revision: 0.94 $ =~ /(\d+)/xmsg;

BEGIN {
    if ($^X =~ / jperl /oxmsi) {
        die __FILE__, ": needs perl(not jperl) 5.00503 or later. (\$^X==$^X)";
    }
    if (CORE::ord('A') == 193) {
        die __FILE__, ": is not US-ASCII script (may be EBCDIC or EBCDIK script).";
    }
    if (CORE::ord('A') != 0x41) {
        die __FILE__, ": is not US-ASCII script (must be US-ASCII script).";
    }
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

# instead of Symbol.pm
BEGIN {
    my $genpkg = "Symbol::";
    my $genseq = 0;

    sub gensym () {
        my $name = "GEN" . $genseq++;

        # here, no strict qw(refs); if strict.pm exists

        my $ref = \*{$genpkg . $name};
        delete $$genpkg{$name};
        return $ref;
    }

    sub qualify ($;$) {
        my ($name) = @_;
        if (!ref($name) && (Char::Egbk::index($name, '::') == -1) && (Char::Egbk::index($name, "'") == -1)) {
            my $pkg;
            my %global = map {$_ => 1} qw(ARGV ARGVOUT ENV INC SIG STDERR STDIN STDOUT DATA);

            # Global names: special character, "^xyz", or other.
            if ($name =~ /^(([^\x81-\xFEa-z])|(\^[a-z_]+))\z/i || $global{$name}) {
                # RGS 2001-11-05 : translate leading ^X to control-char
                $name =~ s/^\^([a-z_])/'qq(\c'.$1.')'/eei;
                $pkg = "main";
            }
            else {
                $pkg = (@_ > 1) ? $_[1] : caller;
            }
            $name = $pkg . "::" . $name;
        }
        return $name;
    }

    sub qualify_to_ref ($;$) {

        # here, no strict qw(refs); if strict.pm exists

        return \*{ qualify $_[0], @_ > 1 ? $_[1] : caller };
    }
}

# Column: local $@
# in Chapter 9. Osaete okitai Perl no kiso
# of ISBN 10: 4798119172 | ISBN 13: 978-4798119175 MODAN Perl NYUMON
# (and so on)

# use strict; if strict.pm exists
BEGIN {
    if (eval { local $@; CORE::require strict }) {
        strict::->import;
    }
}

# P.714 29.2.39. flock
# in Chapter 29: Functions
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# P.863 flock
# in Chapter 27: Functions
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

sub LOCK_SH() {1}
sub LOCK_EX() {2}
sub LOCK_UN() {8}
sub LOCK_NB() {4}

# instead of Carp.pm
sub carp;
sub croak;
sub cluck;
sub confess;

my $your_char = q{[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]};

# regexp of character
BEGIN { eval q{ use vars qw($q_char) } }
$q_char = qr/$your_char/oxms;

#
# GBK character range per length
#
my %range_tr = ();

#
# alias of encoding name
#
BEGIN { eval q{ use vars qw($encoding_alias) } }

#
# GBK case conversion
#
my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
my %fc = ();
@fc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

if (0) {
}

elsif (__PACKAGE__ =~ / \b Egbk \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x80],
               [0xFF..0xFF],
             ],
        2 => [ [0x81..0xFE],[0x40..0x7E],
               [0x81..0xFE],[0x80..0xFE],
             ],
    );
    $encoding_alias = qr/ \b (?: euc.*cn | cn.*euc | gbk | cp936 | gb[-_ ]?2312(?!-?raw) ) \b /oxmsi;
}

else {
    croak "Don't know my package name '@{[__PACKAGE__]}'";
}

#
# @ARGV wildcard globbing
#
sub import {

    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        my @argv = ();
        for (@ARGV) {

            # has space
            if (/\A (?:$q_char)*? [ ] /oxms) {
                if (my @glob = Char::Egbk::glob(qq{"$_"})) {
                    push @argv, @glob;
                }
                else {
                    push @argv, $_;
                }
            }

            # has wildcard metachar
            elsif (/\A (?:$q_char)*? [*?] /oxms) {
                if (my @glob = Char::Egbk::glob($_)) {
                    push @argv, @glob;
                }
                else {
                    push @argv, $_;
                }
            }

            # no wildcard globbing
            else {
                push @argv, $_;
            }
        }
        @ARGV = @argv;
    }
}

# P.230 Care with Prototypes
# in Chapter 6: Subroutines
# of ISBN 0-596-00027-8 Programming Perl Third Edition.
#
# If you aren't careful, you can get yourself into trouble with prototypes.
# But if you are careful, you can do a lot of neat things with them. This is
# all very powerful, of course, and should only be used in moderation to make
# the world a better place.

# P.332 Care with Prototypes
# in Chapter 7: Subroutines
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.
#
# If you aren't careful, you can get yourself into trouble with prototypes.
# But if you are careful, you can do a lot of neat things with them. This is
# all very powerful, of course, and should only be used in moderation to make
# the world a better place.

#
# Prototypes of subroutines
#
sub unimport {}
sub Char::Egbk::split(;$$$);
sub Char::Egbk::tr($$$$;$);
sub Char::Egbk::chop(@);
sub Char::Egbk::index($$;$);
sub Char::Egbk::rindex($$;$);
sub Char::Egbk::lcfirst(@);
sub Char::Egbk::lcfirst_();
sub Char::Egbk::lc(@);
sub Char::Egbk::lc_();
sub Char::Egbk::ucfirst(@);
sub Char::Egbk::ucfirst_();
sub Char::Egbk::uc(@);
sub Char::Egbk::uc_();
sub Char::Egbk::fc(@);
sub Char::Egbk::fc_();
sub Char::Egbk::ignorecase;
sub Char::Egbk::classic_character_class;
sub Char::Egbk::capture;
sub Char::Egbk::chr(;$);
sub Char::Egbk::chr_();
sub Char::Egbk::filetest;
sub Char::Egbk::r(;*@);
sub Char::Egbk::w(;*@);
sub Char::Egbk::x(;*@);
sub Char::Egbk::o(;*@);
sub Char::Egbk::R(;*@);
sub Char::Egbk::W(;*@);
sub Char::Egbk::X(;*@);
sub Char::Egbk::O(;*@);
sub Char::Egbk::e(;*@);
sub Char::Egbk::z(;*@);
sub Char::Egbk::s(;*@);
sub Char::Egbk::f(;*@);
sub Char::Egbk::d(;*@);
sub Char::Egbk::l(;*@);
sub Char::Egbk::p(;*@);
sub Char::Egbk::S(;*@);
sub Char::Egbk::b(;*@);
sub Char::Egbk::c(;*@);
sub Char::Egbk::u(;*@);
sub Char::Egbk::g(;*@);
sub Char::Egbk::k(;*@);
sub Char::Egbk::T(;*@);
sub Char::Egbk::B(;*@);
sub Char::Egbk::M(;*@);
sub Char::Egbk::A(;*@);
sub Char::Egbk::C(;*@);
sub Char::Egbk::filetest_;
sub Char::Egbk::r_();
sub Char::Egbk::w_();
sub Char::Egbk::x_();
sub Char::Egbk::o_();
sub Char::Egbk::R_();
sub Char::Egbk::W_();
sub Char::Egbk::X_();
sub Char::Egbk::O_();
sub Char::Egbk::e_();
sub Char::Egbk::z_();
sub Char::Egbk::s_();
sub Char::Egbk::f_();
sub Char::Egbk::d_();
sub Char::Egbk::l_();
sub Char::Egbk::p_();
sub Char::Egbk::S_();
sub Char::Egbk::b_();
sub Char::Egbk::c_();
sub Char::Egbk::u_();
sub Char::Egbk::g_();
sub Char::Egbk::k_();
sub Char::Egbk::T_();
sub Char::Egbk::B_();
sub Char::Egbk::M_();
sub Char::Egbk::A_();
sub Char::Egbk::C_();
sub Char::Egbk::glob($);
sub Char::Egbk::glob_();
sub Char::Egbk::lstat(*);
sub Char::Egbk::lstat_();
sub Char::Egbk::opendir(*$);
sub Char::Egbk::stat(*);
sub Char::Egbk::stat_();
sub Char::Egbk::unlink(@);
sub Char::Egbk::chdir(;$);
sub Char::Egbk::do($);
sub Char::Egbk::require(;$);
sub Char::Egbk::telldir(*);

sub Char::GBK::ord(;$);
sub Char::GBK::ord_();
sub Char::GBK::reverse(@);
sub Char::GBK::getc(;*@);
sub Char::GBK::length(;$);
sub Char::GBK::substr($$;$$);
sub Char::GBK::index($$;$);
sub Char::GBK::rindex($$;$);

#
# Regexp work
#
BEGIN { eval q{ use vars qw(
    $Char::GBK::re_a
    $Char::GBK::re_t
    $Char::GBK::re_n
    $Char::GBK::re_r
) } }

#
# Character class
#
BEGIN { eval q{ use vars qw(
    $dot
    $dot_s
    $eD
    $eS
    $eW
    $eH
    $eV
    $eR
    $eN
    $not_alnum
    $not_alpha
    $not_ascii
    $not_blank
    $not_cntrl
    $not_digit
    $not_graph
    $not_lower
    $not_lower_i
    $not_print
    $not_punct
    $not_space
    $not_upper
    $not_upper_i
    $not_word
    $not_xdigit
    $eb
    $eB
) } }

BEGIN { eval q{ use vars qw(
    $anchor
    $matched
) } }
${Char::Egbk::anchor}      = qr{\G(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])*?}oxms;
BEGIN { eval q{ use vars qw(
    $q_char_SADAHIRO_Tomoyuki_2002_01_17
) } }

# Quantifiers
#   {n,m}  ---  Match at least n but not more than m times
#
# n and m are limited to non-negative integral values less than a
# preset limit defined when perl is built. This is usually 32766 on
# the most common platforms.
#
# The following code is an attempt to solve the above limitations
# in a multi-byte anchoring.

# avoid "Segmentation fault" and "Error: Parse exception"

# perl5101delta
# http://perldoc.perl.org/perl5101delta.html
# In 5.10.0, the * quantifier in patterns was sometimes treated as {0,32767}
# [RT #60034, #60464]. For example, this match would fail:
#   ("ab" x 32768) =~ /^(ab)*$/

if (($] >= 5.010001) or
    # ActivePerl 5.6 or later (include 5.10.0)
    (defined($ActivePerl::VERSION) and ($ActivePerl::VERSION > 800)) or
    (($^O eq 'MSWin32') and ($] =~ /\A 5\.006/oxms))
) {
    my $sbcs = ''; # Single Byte Character Set
    for my $range (@{ $range_tr{1} }) {
        $sbcs .= sprintf('\\x%02X-\\x%02X', $range->[0], $range->[-1]);
    }

    # GB18030 encoding
    if (__PACKAGE__ =~ / \b Egb18030 \z/oxms) {
        ${Char::Egbk::q_char_SADAHIRO_Tomoyuki_2002_01_17} = qr{.*?[^\x30-\x39\x81-\xFE](?:[\x30-\x39]|[\x81-\xFE][\x30-\x39][\x81-\xFE][\x30-\x39]|[\x81-\xFE]{2})*?}oxms;
    }

    # other encoding
    else {
        my $tbcs_1st = ''; # 1st octet of Triple Byte Character Set
        if (exists($range_tr{3}) and not exists($range_tr{4})) {
            for my $range (@{ $range_tr{3} }) {
                if ($range->[0] != $range->[-1]) {
                    $tbcs_1st .= sprintf('\\x%02X-\\x%02X', $range->[0], $range->[-1]);
                }
                else {
                    $tbcs_1st .= sprintf('\\x%02X',         $range->[0]);
                }
            }
            $tbcs_1st = "[$tbcs_1st]?";
        }
        ${Char::Egbk::q_char_SADAHIRO_Tomoyuki_2002_01_17} = qr{.*?[$sbcs](?:$tbcs_1st[^$sbcs]{2})*?}oxms;
    }

    ${Char::Egbk::anchor_SADAHIRO_Tomoyuki_2002_01_17} =
    qr{\G(?(?=.{0,32766}\z)(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])*?|(?(?=[$sbcs]+\z).*?|(?:${Char::Egbk::q_char_SADAHIRO_Tomoyuki_2002_01_17})))}oxms;
#   qr{
#      \G # (1), (2)
#        (? # (3)
#          (?=.{0,32766}\z) # (4)
#                          (?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])*?| # (5)
#                                                                                      (?(?=[$sbcs]+\z) # (6)
#                                                                                                      .*?| #(7)
#                                                                                                          (?:${Char::Egbk::q_char_SADAHIRO_Tomoyuki_2002_01_17}) # (8)
#                                                                                                                                                           ))}oxms;

    # avoid: Complex regular subexpression recursion limit (32766) exceeded at here.
    local $^W = 0;

    if (((('A' x 32768).'B') !~ / ${Char::Egbk::anchor}                              B /oxms) and
        ((('A' x 32768).'B') =~ / ${Char::Egbk::anchor_SADAHIRO_Tomoyuki_2002_01_17} B /oxms)
    ) {
        ${Char::Egbk::anchor} = ${Char::Egbk::anchor_SADAHIRO_Tomoyuki_2002_01_17};
    }
    else {
        undef ${Char::Egbk::q_char_SADAHIRO_Tomoyuki_2002_01_17};
    }
}

# (1)
# P.128 Start of match (or end of previous match): \G
# P.130 Advanced Use of \G with Perl
# in Chapter3: Over view of Regular Expression Features and Flavors
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

# (2)
# P.255 Use leading anchors
# P.256 Expose ^ and \G at the front of expressions
# in Chapter6: Crafting an Efficient Expression
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

# (3)
# P.138 Conditional: (? if then| else)
# in Chapter3: Over view of Regular Expression Features and Flavors
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

# (4)
# perlre
# http://perldoc.perl.org/perlre.html
# The "*" quantifier is equivalent to {0,} , the "+" quantifier to {1,} ,
# and the "?" quantifier to {0,1} . n and m are limited to non-negative
# integral values less than a preset limit defined when perl is built.
# This is usually 32766 on the most common platforms. The actual limit
# can be seen in the error message generated by code such as this:
#  $_ **= $_ , / {$_} / for 2 .. 42;

# (5)
# P.1023 Multiple-Byte Anchoring
# in Appendix W Perl Code Examples
# of ISBN 1-56592-224-7 CJKV Information Processing

# (6)
# if string has only SBCS (Single Byte Character Set)

# (7)
# then .*? (isn't limited to 32766)

# (8)
# else GBK::Regexp::Const (SADAHIRO Tomoyuki)
# http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm#long
# http://search.cpan.org/~sadahiro/GBK-Regexp/
# $PadA  = '  (?:\A|                                           [\x00-\x80\xA0-\xDF])(?:[\x81-\xFE]{2})*?';
# $PadG  = '\G(?:                                |[\x00-\xFF]*?[\x00-\x80\xA0-\xDF])(?:[\x81-\xFE]{2})*?';
# $PadGA = '\G(?:\A|(?:[\x81-\xFE]{2})+?|[\x00-\xFF]*?[\x00-\x80\xA0-\xDF] (?:[\x81-\xFE]{2})*?)';

${Char::Egbk::dot}         = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x0A])};
${Char::Egbk::dot_s}       = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])};
${Char::Egbk::eD}          = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE0-9])};

# Vertical tabs are now whitespace
# \s in a regex now matches a vertical tab in all circumstances.
# http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#Vertical_tabs_are_now_whitespace
# ${Char::Egbk::eS}        = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x09\x0A    \x0C\x0D\x20])};
# ${Char::Egbk::eS}        = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x09\x0A\x0B\x0C\x0D\x20])};
${Char::Egbk::eS}          = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\s])};

${Char::Egbk::eW}          = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE0-9A-Z_a-z])};
${Char::Egbk::eH}          = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x09\x20])};
${Char::Egbk::eV}          = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x0A\x0B\x0C\x0D])};
${Char::Egbk::eR}          = qr{(?:\x0D\x0A|[\x0A\x0D])};
${Char::Egbk::eN}          = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x0A])};
${Char::Egbk::not_alnum}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x30-\x39\x41-\x5A\x61-\x7A])};
${Char::Egbk::not_alpha}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x41-\x5A\x61-\x7A])};
${Char::Egbk::not_ascii}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x00-\x7F])};
${Char::Egbk::not_blank}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x09\x20])};
${Char::Egbk::not_cntrl}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x00-\x1F\x7F])};
${Char::Egbk::not_digit}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x30-\x39])};
${Char::Egbk::not_graph}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x21-\x7F])};
${Char::Egbk::not_lower}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x61-\x7A])};
${Char::Egbk::not_lower_i} = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])};
${Char::Egbk::not_print}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x20-\x7F])};
${Char::Egbk::not_punct}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])};
${Char::Egbk::not_space}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\s\x0B])};
${Char::Egbk::not_upper}   = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x41-\x5A])};
${Char::Egbk::not_upper_i} = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])};
${Char::Egbk::not_word}    = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x30-\x39\x41-\x5A\x5F\x61-\x7A])};
${Char::Egbk::not_xdigit}  = qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x30-\x39\x41-\x46\x61-\x66])};
${Char::Egbk::eb}          = qr{(?:\A(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[0-9A-Z_a-z])|(?<=[0-9A-Z_a-z])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]|\z))};
${Char::Egbk::eB}          = qr{(?:(?<=[0-9A-Z_a-z])(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]))};

# avoid: Name "Char::Egbk::foo" used only once: possible typo at here.
${Char::Egbk::dot}         = ${Char::Egbk::dot};
${Char::Egbk::dot_s}       = ${Char::Egbk::dot_s};
${Char::Egbk::eD}          = ${Char::Egbk::eD};
${Char::Egbk::eS}          = ${Char::Egbk::eS};
${Char::Egbk::eW}          = ${Char::Egbk::eW};
${Char::Egbk::eH}          = ${Char::Egbk::eH};
${Char::Egbk::eV}          = ${Char::Egbk::eV};
${Char::Egbk::eR}          = ${Char::Egbk::eR};
${Char::Egbk::eN}          = ${Char::Egbk::eN};
${Char::Egbk::not_alnum}   = ${Char::Egbk::not_alnum};
${Char::Egbk::not_alpha}   = ${Char::Egbk::not_alpha};
${Char::Egbk::not_ascii}   = ${Char::Egbk::not_ascii};
${Char::Egbk::not_blank}   = ${Char::Egbk::not_blank};
${Char::Egbk::not_cntrl}   = ${Char::Egbk::not_cntrl};
${Char::Egbk::not_digit}   = ${Char::Egbk::not_digit};
${Char::Egbk::not_graph}   = ${Char::Egbk::not_graph};
${Char::Egbk::not_lower}   = ${Char::Egbk::not_lower};
${Char::Egbk::not_lower_i} = ${Char::Egbk::not_lower_i};
${Char::Egbk::not_print}   = ${Char::Egbk::not_print};
${Char::Egbk::not_punct}   = ${Char::Egbk::not_punct};
${Char::Egbk::not_space}   = ${Char::Egbk::not_space};
${Char::Egbk::not_upper}   = ${Char::Egbk::not_upper};
${Char::Egbk::not_upper_i} = ${Char::Egbk::not_upper_i};
${Char::Egbk::not_word}    = ${Char::Egbk::not_word};
${Char::Egbk::not_xdigit}  = ${Char::Egbk::not_xdigit};
${Char::Egbk::eb}          = ${Char::Egbk::eb};
${Char::Egbk::eB}          = ${Char::Egbk::eB};

#
# GBK split
#
sub Char::Egbk::split(;$$$) {

    # P.794 29.2.161. split
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.951 split
    # in Chapter 27: Functions
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    my $pattern = $_[0];
    my $string  = $_[1];
    my $limit   = $_[2];

    # if $pattern is also omitted or is the literal space, " "
    if (not defined $pattern) {
        $pattern = ' ';
    }

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
            carp "Use of implicit split to \@_ is deprecated" if $^W;
            @_ = @split;
            return scalar @_;
        }
    }

    # split's first argument is more consistently interpreted
    #
    # After some changes earlier in v5.17, split's behavior has been simplified:
    # if the PATTERN argument evaluates to a string containing one space, it is
    # treated the way that a literal string containing one space once was.
    # http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#split's_first_argument_is_more_consistently_interpreted

    # if $pattern is also omitted or is the literal space, " ", the function splits
    # on whitespace, /\s+/, after skipping any leading whitespace
    # (and so on)

    elsif ($pattern eq ' ') {
        if (not defined $limit) {
            return CORE::split(' ', $string);
        }
        else {
            return CORE::split(' ', $string, $limit);
        }
    }

    local $q_char = $q_char;
    if (CORE::length($string) > 32766) {
        if ($string =~ /\A [\x00-\x7F]+ \z/oxms) {
            $q_char = qr{.}s;
        }
        elsif (defined ${Char::Egbk::q_char_SADAHIRO_Tomoyuki_2002_01_17}) {
            $q_char = ${Char::Egbk::q_char_SADAHIRO_Tomoyuki_2002_01_17};
        }
    }

    # if $limit is negative, it is treated as if an arbitrarily large $limit has been specified
    if ((not defined $limit) or ($limit <= 0)) {

        # a pattern capable of matching either the null string or something longer than the
        # null string will split the value of $string into separate characters wherever it
        # matches the null string between characters
        # (and so on)

        if ('' =~ / \A $pattern \z /xms) {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            my $limit = scalar(() = $string =~ /($pattern)/oxmsg);

            # P.1024 Appendix W.10 Multibyte Processing
            # of ISBN 1-56592-224-7 CJKV Information Processing
            # (and so on)

            # the //m modifier is assumed when you split on the pattern /^/
            # (and so on)

            #                                                     V
            while ((--$limit > 0) and ($string =~ s/\A((?:$q_char)+?)$pattern//m)) {

                # if the $pattern contains parentheses, then the substring matched by each pair of parentheses
                # is included in the resulting list, interspersed with the fields that are ordinarily returned
                # (and so on)

                local $@;
                for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                    push @split, eval('$' . $digit);
                }
            }
        }

        else {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);

            #                                 V
            while ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                local $@;
                for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                    push @split, eval('$' . $digit);
                }
            }
        }
    }

    elsif ($limit > 0) {
        if ('' =~ / \A $pattern \z /xms) {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            while ((--$limit > 0) and (CORE::length($string) > 0)) {

                #                              V
                if ($string =~ s/\A((?:$q_char)+?)$pattern//m) {
                    local $@;
                    for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                        push @split, eval('$' . $digit);
                    }
                }
            }
        }
        else {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            while ((--$limit > 0) and (CORE::length($string) > 0)) {

                #                              V
                if ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                    local $@;
                    for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                        push @split, eval('$' . $digit);
                    }
                }
            }
        }
    }

    if (CORE::length($string) > 0) {
        push @split, $string;
    }

    # if $_[2] (NOT "$limit") is omitted or zero, trailing null fields are stripped from the result
    if ((not defined $_[2]) or ($_[2] == 0)) {
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
        carp "Use of implicit split to \@_ is deprecated" if $^W;
        @_ = @split;
        return scalar @_;
    }
}

#
# get last subexpression offsets
#
sub _last_subexpression_offsets {
    my $pattern = $_[0];

    # remove comment
    $pattern =~ s/\(\?\# .*? \)//oxmsg;

    my $modifier = '';
    if ($pattern =~ /\(\?\^? ([\-A-Za-z]+) :/oxms) {
        $modifier = $1;
        $modifier =~ s/-[A-Za-z]*//;
    }

    # with /x modifier
    my @char = ();
    if ($modifier =~ /x/oxms) {
        @char = $pattern =~ /\G(
            \\ (?:$q_char)                  |
            \# (?:$q_char)*? $              |
            \[ (?: \\\] | (?:$q_char))+? \] |
            \(\?                            |
            (?:$q_char)
        )/oxmsg;
    }

    # without /x modifier
    else {
        @char = $pattern =~ /\G(
            \\ (?:$q_char)                  |
            \[ (?: \\\] | (?:$q_char))+? \] |
            \(\?                            |
            (?:$q_char)
        )/oxmsg;
    }

    return scalar grep { $_ eq '(' } @char;
}

#
# GBK transliteration (tr///)
#
sub Char::Egbk::tr($$$$;$) {

    my $bind_operator   = $_[1];
    my $searchlist      = $_[2];
    my $replacementlist = $_[3];
    my $modifier        = $_[4] || '';

    if ($modifier =~ /r/oxms) {
        if ($bind_operator =~ / !~ /oxms) {
            croak "Using !~ with tr///r doesn't make sense";
        }
    }

    my @char            = $_[0] =~ /\G ($q_char) /oxmsg;
    my @searchlist      = _charlist_tr($searchlist);
    my @replacementlist = _charlist_tr($replacementlist);

    my %tr = ();
    for (my $i=0; $i <= $#searchlist; $i++) {
        if (not exists $tr{$searchlist[$i]}) {
            if (defined $replacementlist[$i] and ($replacementlist[$i] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[$i];
            }
            elsif ($modifier =~ /d/oxms) {
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
    if ($modifier =~ /c/oxms) {
        while (defined(my $char = shift @char)) {
            if (not exists $tr{$char}) {
                if (defined $replacementlist[0]) {
                    $replaced .= $replacementlist[0];
                }
                $tr++;
                if ($modifier =~ /s/oxms) {
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
                if ($modifier =~ /s/oxms) {
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

    if ($modifier =~ /r/oxms) {
        return $replaced;
    }
    else {
        $_[0] = $replaced;
        if ($bind_operator =~ / !~ /oxms) {
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
sub Char::Egbk::chop(@) {

    my $chop;
    if (@_ == 0) {
        my @char = /\G ($q_char) /oxmsg;
        $chop = pop @char;
        $_ = join '', @char;
    }
    else {
        for (@_) {
            my @char = /\G ($q_char) /oxmsg;
            $chop = pop @char;
            $_ = join '', @char;
        }
    }
    return $chop;
}

#
# GBK index by octet
#
sub Char::Egbk::index($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= 0;
    my $pos = 0;

    while ($pos < CORE::length($str)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            if ($pos >= $position) {
                return $pos;
            }
        }
        if (CORE::substr($str,$pos) =~ /\A ($q_char) /oxms) {
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
sub Char::Egbk::rindex($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= CORE::length($str) - 1;
    my $pos = 0;
    my $rindex = -1;

    while (($pos < CORE::length($str)) and ($pos <= $position)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            $rindex = $pos;
        }
        if (CORE::substr($str,$pos) =~ /\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return $rindex;
}

#
# GBK lower case first with parameter
#
sub Char::Egbk::lcfirst(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return Char::Egbk::lc(CORE::substr($s,0,1)) . CORE::substr($s,1), @_;
        }
        else {
            return Char::Egbk::lc(CORE::substr($s,0,1)) . CORE::substr($s,1);
        }
    }
    else {
        return Char::Egbk::lc(CORE::substr($_,0,1)) . CORE::substr($_,1);
    }
}

#
# GBK lower case first without parameter
#
sub Char::Egbk::lcfirst_() {
    return Char::Egbk::lc(CORE::substr($_,0,1)) . CORE::substr($_,1);
}

#
# GBK lower case with parameter
#
sub Char::Egbk::lc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg));
        }
    }
    else {
        return Char::Egbk::lc_();
    }
}

#
# GBK lower case without parameter
#
sub Char::Egbk::lc_() {
    my $s = $_;
    return join '', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg);
}

#
# GBK upper case first with parameter
#
sub Char::Egbk::ucfirst(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return Char::Egbk::uc(CORE::substr($s,0,1)) . CORE::substr($s,1), @_;
        }
        else {
            return Char::Egbk::uc(CORE::substr($s,0,1)) . CORE::substr($s,1);
        }
    }
    else {
        return Char::Egbk::uc(CORE::substr($_,0,1)) . CORE::substr($_,1);
    }
}

#
# GBK upper case first without parameter
#
sub Char::Egbk::ucfirst_() {
    return Char::Egbk::uc(CORE::substr($_,0,1)) . CORE::substr($_,1);
}

#
# GBK upper case with parameter
#
sub Char::Egbk::uc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg));
        }
    }
    else {
        return Char::Egbk::uc_();
    }
}

#
# GBK upper case without parameter
#
sub Char::Egbk::uc_() {
    my $s = $_;
    return join '', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg);
}

#
# GBK fold case with parameter
#
sub Char::Egbk::fc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg));
        }
    }
    else {
        return Char::Egbk::fc_();
    }
}

#
# GBK fold case without parameter
#
sub Char::Egbk::fc_() {
    my $s = $_;
    return join '', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg);
}

#
# GBK regexp capture
#
{
    # 10.3. Creating Persistent Private Variables
    # in Chapter 10. Subroutines
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.

    my $last_s_matched = 0;

    sub Char::Egbk::capture {
        if ($last_s_matched and ($_[0] =~ /\A [1-9][0-9]* \z/oxms)) {
            return $_[0] + 1;
        }
        return $_[0];
    }

    # GBK mark last regexp matched
    sub Char::Egbk::matched() {
        $last_s_matched = 0;
    }

    # GBK mark last s/// matched
    sub Char::Egbk::s_matched() {
        $last_s_matched = 1;
    }

    # P.854 31.17. use re
    # in Chapter 31. Pragmatic Modules
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.1026 re
    # in Chapter 29. Pragmatic Modules
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    $Char::Egbk::matched = qr/(?{Char::Egbk::matched})/;
}

#
# GBK regexp ignore case modifier
#
sub Char::Egbk::ignorecase {

    my @string = @_;
    my $metachar = qr/[\@\\|[\]{]/oxms;

    # ignore case of $scalar or @array
    for my $string (@string) {

        # split regexp
        my @char = $string =~ /\G(
            \[\^ |
                \\? (?:$q_char)
        )/oxmsg;

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
                        croak "Unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {
                            if (0) {
                            }

                            # do not use quotemeta here
                            elsif ($char =~ /\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ /\A [.|)] \z/oxms) {
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
                        croak "Unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_not_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {
                            if (0) {
                            }

                            # do not use quotemeta here
                            elsif ($char =~ /\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ /\A [.|)] \z/oxms) {
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

            # rewrite classic character class or escape character
            elsif (my $char = classic_character_class($char[$i])) {
                $char[$i] = $char;
            }

            # with /i modifier
            elsif ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) {
                my $uc = Char::Egbk::uc($char[$i]);
                my $fc = Char::Egbk::fc($char[$i]);
                if ($uc ne $fc) {
                    if (CORE::length($fc) == 1) {
                        $char[$i] = '['   . $uc       . $fc . ']';
                    }
                    else {
                        $char[$i] = '(?:' . $uc . '|' . $fc . ')';
                    }
                }
            }
        }

        # characterize
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            if (0) {
            }

            # escape last octet of multiple-octet
            elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                $char[$i] = $1 . '\\' . $2;
            }

            # quote character before ? + * {
            elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
                if ($char[$i-1] !~ /\A [\x00-\xFF] \z/oxms) {
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
# classic character class ( \D \S \W \d \s \w \C \X \H \V \h \v \R \N \b \B )
#
sub Char::Egbk::classic_character_class {
    my($char) = @_;

    return {
        '\D' => '${Char::Egbk::eD}',
        '\S' => '${Char::Egbk::eS}',
        '\W' => '${Char::Egbk::eW}',
        '\d' => '[0-9]',

        # Before Perl 5.6, \s only matched the five whitespace characters
        # tab, newline, form-feed, carriage return, and the space character
        # itself, which, taken together, is the character class [\t\n\f\r ].

        # Vertical tabs are now whitespace
        # \s in a regex now matches a vertical tab in all circumstances.
        # http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#Vertical_tabs_are_now_whitespace
        #            \t  \n  \v  \f  \r space
        # '\s' => '[\x09\x0A    \x0C\x0D\x20]',
        # '\s' => '[\x09\x0A\x0B\x0C\x0D\x20]',
        '\s'   => '\s',

        '\w' => '[0-9A-Z_a-z]',
        '\C' => '[\x00-\xFF]',
        '\X' => 'X',

        # \h \v \H \V

        # P.114 Character Class Shortcuts
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        # P.357 13.2.3 Whitespace
        # in Chapter 13: perlrecharclass: Perl Regular Expression Character Classes
        # of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)
        #
        # 0x00009   CHARACTER TABULATION  h s
        # 0x0000a         LINE FEED (LF)   vs
        # 0x0000b        LINE TABULATION   v
        # 0x0000c         FORM FEED (FF)   vs
        # 0x0000d   CARRIAGE RETURN (CR)   vs
        # 0x00020                  SPACE  h s

        # P.196 Table 5-9. Alphanumeric regex metasymbols
        # in Chapter 5. Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # (and so on)

        '\H' => '${Char::Egbk::eH}',
        '\V' => '${Char::Egbk::eV}',
        '\h' => '[\x09\x20]',
        '\v' => '[\x0A\x0B\x0C\x0D]',
        '\R' => '${Char::Egbk::eR}',

        # \N
        #
        # http://perldoc.perl.org/perlre.html
        # Character Classes and other Special Escapes
        # Any character but \n (experimental). Not affected by /s modifier

        '\N' => '${Char::Egbk::eN}',

        # \b \B

        # P.180 Boundaries: The \b and \B Assertions
        # in Chapter 5: Pattern Matching
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.219 Boundaries: The \b and \B Assertions
        # in Chapter 5: Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # '\b' => '(?:(?<=\A|\W)(?=\w)|(?<=\w)(?=\W|\z))',
        '\b' => '${Char::Egbk::eb}',

        # '\B' => '(?:(?<=\w)(?=\w)|(?<=\W)(?=\W))',
        '\B' => '${Char::Egbk::eB}',

    }->{$char} || '';
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

#
# GBK open character list for tr
#
sub _charlist_tr {

    local $_ = shift @_;

    # unescape character
    my @char = ();
    while (not /\G \z/oxmsgc) {
        if (/\G (\\0?55|\\x2[Dd]|\\-) /oxmsgc) {
            push @char, '\-';
        }
        elsif (/\G \\ ([0-7]{2,3}) /oxmsgc) {
            push @char, CORE::chr(oct $1);
        }
        elsif (/\G \\x ([0-9A-Fa-f]{1,2}) /oxmsgc) {
            push @char, CORE::chr(hex $1);
        }
        elsif (/\G \\c ([\x40-\x5F]) /oxmsgc) {
            push @char, CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif (/\G (\\ [0nrtfbae]) /oxmsgc) {
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
        elsif (/\G \\ ($q_char) /oxmsgc) {
            push @char, $1;
        }
        elsif (/\G ($q_char) /oxmsgc) {
            push @char, $1;
        }
    }

    # join separated multiple-octet
    @char = join('',@char) =~ /\G (\\-|$q_char) /oxmsg;

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
        if ((CORE::length($char[$i-1]) > CORE::length($char[$i+1])) or ($char[$i-1] gt $char[$i+1])) {
            croak "Invalid tr/// range \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
        }

        # range of multiple-octet code
        if (CORE::length($char[$i-1]) == 1) {
            if (CORE::length($char[$i+1]) == 1) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars1();
            }
            elsif (CORE::length($char[$i+1]) == 2) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range, grep {$_ le $char[$i+1]}                           chars2();
            }
            elsif (CORE::length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range,                                                    chars2();
                push @range, grep {$_ le $char[$i+1]}                           chars3();
            }
            elsif (CORE::length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range,                                                    chars2();
                push @range,                                                    chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
            else {
                croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
            }
        }
        elsif (CORE::length($char[$i-1]) == 2) {
            if (CORE::length($char[$i+1]) == 2) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars2();
            }
            elsif (CORE::length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           chars2();
                push @range, grep {$_ le $char[$i+1]}                           chars3();
            }
            elsif (CORE::length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars2();
                push @range,                                                    chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
            else {
                croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
            }
        }
        elsif (CORE::length($char[$i-1]) == 3) {
            if (CORE::length($char[$i+1]) == 3) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars3();
            }
            elsif (CORE::length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
            else {
                croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
            }
        }
        elsif (CORE::length($char[$i-1]) == 4) {
            if (CORE::length($char[$i+1]) == 4) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars4();
            }
            else {
                croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
            }
        }
        else {
            croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
        }

        splice @char, $i-1, 3, @range;
    }

    return @char;
}

#
# GBK open character class
#
sub _cc {
    if (scalar(@_) == 0) {
        die __FILE__, ": subroutine cc got no parameter.";
    }
    elsif (scalar(@_) == 1) {
        return sprintf('\x%02X',$_[0]);
    }
    elsif (scalar(@_) == 2) {
        if ($_[0] > $_[1]) {
            die __FILE__, ": subroutine cc got \$_[0] > \$_[1] parameters).";
        }
        elsif ($_[0] == $_[1]) {
            return sprintf('\x%02X',$_[0]);
        }
        elsif (($_[0]+1) == $_[1]) {
            return sprintf('[\\x%02X\\x%02X]',$_[0],$_[1]);
        }
        else {
            return sprintf('[\\x%02X-\\x%02X]',$_[0],$_[1]);
        }
    }
    else {
        die __FILE__, ": subroutine cc got 3 or more parameters (@{[scalar(@_)]} parameters).";
    }
}

#
# GBK octet range
#
sub _octets {
    my $length = shift @_;

    if ($length == 1) {
        my($a1) = unpack 'C', $_[0];
        my($z1) = unpack 'C', $_[1];

        if ($a1 > $z1) {
            croak 'Invalid [] range in regexp (CORE::ord(A) > CORE::ord(B)) ' . '\x' . unpack('H*',$a1) . '-\x' . unpack('H*',$z1);
        }

        if ($a1 == $z1) {
            return sprintf('\x%02X',$a1);
        }
        elsif (($a1+1) == $z1) {
            return sprintf('\x%02X\x%02X',$a1,$z1);
        }
        else {
            return sprintf('\x%02X-\x%02X',$a1,$z1);
        }
    }
    elsif ($length == 2) {
        my($a1,$a2) = unpack 'CC', $_[0];
        my($z1,$z2) = unpack 'CC', $_[1];
        my($A1,$A2) = unpack 'CC', $_[2];
        my($Z1,$Z2) = unpack 'CC', $_[3];

        if ($a1 == $z1) {
            return (
            #   11111111   222222222222
            #        A          A   Z
                _cc($a1) . _cc($a2,$z2), # a2-z2
            );
        }
        elsif (($a1+1) == $z1) {
            return (
            #   11111111111   222222222222
            #        A  Z          A   Z
                _cc($a1)    . _cc($a2,$Z2), # a2-
                _cc(   $z1) . _cc($A2,$z2), #   -z2
            );
        }
        else {
            return (
            #   1111111111111111   222222222222
            #        A     Z            A   Z
                _cc($a1)         . _cc($a2,$Z2), # a2-
                _cc($a1+1,$z1-1) . _cc($A2,$Z2), #   -
                _cc(      $z1)   . _cc($A2,$z2), #   -z2
            );
        }
    }
    elsif ($length == 3) {
        my($a1,$a2,$a3) = unpack 'CCC', $_[0];
        my($z1,$z2,$z3) = unpack 'CCC', $_[1];
        my($A1,$A2,$A3) = unpack 'CCC', $_[2];
        my($Z1,$Z2,$Z3) = unpack 'CCC', $_[3];

        if ($a1 == $z1) {
            if ($a2 == $z2) {
                return (
                #   11111111   22222222   333333333333
                #        A          A          A   Z
                    _cc($a1) . _cc($a2) . _cc($a3,$z3), # a3-z3
                );
            }
            elsif (($a2+1) == $z2) {
                return (
                #   11111111   22222222222   333333333333
                #        A          A  Z          A   Z
                    _cc($a1) . _cc($a2)    . _cc($a3,$Z3), # a3-
                    _cc($a1) . _cc(   $z2) . _cc($A3,$z3), #   -z3
                );
            }
            else {
                return (
                #   11111111   2222222222222222   333333333333
                #        A          A     Z            A   Z
                    _cc($a1) . _cc($a2)         . _cc($a3,$Z3), # a3-
                    _cc($a1) . _cc($a2+1,$z2-1) . _cc($A3,$Z3), #   -
                    _cc($a1) . _cc(      $z2)   . _cc($A3,$z3), #   -z3
                );
            }
        }
        elsif (($a1+1) == $z1) {
            return (
            #   11111111111   22222222222222   333333333333
            #        A  Z          A     Z          A   Z
                _cc($a1)    . _cc($a2)       . _cc($a3,$Z3), # a3-
                _cc($a1)    . _cc($a2+1,$Z2) . _cc($A3,$Z3), #   -
                _cc(   $z1) . _cc($A2,$z2-1) . _cc($A3,$Z3), #   -
                _cc(   $z1) . _cc(    $z2)   . _cc($A3,$z3), #   -z3
            );
        }
        else {
            return (
            #   1111111111111111   22222222222222   333333333333
            #        A     Z            A     Z          A   Z
                _cc($a1)         . _cc($a2)       . _cc($a3,$Z3), # a3-
                _cc($a1)         . _cc($a2+1,$Z2) . _cc($A3,$Z3), #   -
                _cc($a1+1,$z1-1) . _cc($A2,$Z2)   . _cc($A3,$Z3), #   -
                _cc(      $z1)   . _cc($A2,$z2-1) . _cc($A3,$Z3), #   -
                _cc(      $z1)   . _cc(    $z2)   . _cc($A3,$z3), #   -z3
            );
        }
    }
    elsif ($length == 4) {
        my($a1,$a2,$a3,$a4) = unpack 'CCCC', $_[0];
        my($z1,$z2,$z3,$z4) = unpack 'CCCC', $_[1];
        my($A1,$A2,$A3,$A4) = unpack 'CCCC', $_[0];
        my($Z1,$Z2,$Z3,$Z4) = unpack 'CCCC', $_[1];

        if ($a1 == $z1) {
            if ($a2 == $z2) {
                if ($a3 == $z3) {
                    return (
                    #   11111111   22222222   33333333   444444444444
                    #        A          A          A          A   Z
                        _cc($a1) . _cc($a2) . _cc($a3) . _cc($a4,$z4), # a4-z4
                    );
                }
                elsif (($a3+1) == $z3) {
                    return (
                    #   11111111   22222222   33333333333   444444444444
                    #        A          A          A  Z          A   Z
                        _cc($a1) . _cc($a2) . _cc($a3)    . _cc($a4,$Z4), # a4-
                        _cc($a1) . _cc($a2) . _cc(   $z3) . _cc($A4,$z4), #   -z4
                    );
                }
                else {
                    return (
                    #   11111111   22222222   3333333333333333   444444444444
                    #        A          A          A     Z            A   Z
                        _cc($a1) . _cc($a2) . _cc($a3)         . _cc($a4,$Z4), # a4-
                        _cc($a1) . _cc($a2) . _cc($a3+1,$z3-1) . _cc($A4,$Z4), #   -
                        _cc($a1) . _cc($a2) . _cc(      $z3)   . _cc($A4,$z4), #   -z4
                    );
                }
            }
            elsif (($a2+1) == $z2) {
                return (
                #   11111111   22222222222   33333333333333   444444444444
                #        A          A  Z          A     Z          A   Z
                    _cc($a1) . _cc($a2)    . _cc($a3)       . _cc($a4,$Z4), # a4-
                    _cc($a1) . _cc($a2)    . _cc($a3+1,$Z3) . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc(   $z2) . _cc($A3,$z3-1) . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc(   $z2) . _cc(    $z3)   . _cc($A4,$z4), #   -z4
                );
            }
            else {
                return (
                #   11111111   2222222222222222   33333333333333   444444444444
                #        A          A     Z            A     Z          A   Z
                    _cc($a1) . _cc($a2)         . _cc($a3)       . _cc($a4,$Z4), # a4-
                    _cc($a1) . _cc($a2)         . _cc($a3+1,$Z3) . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc($a2+1,$z2-1) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc(      $z2)   . _cc($A3,$z3-1) . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc(      $z2)   . _cc(    $z3)   . _cc($A4,$z4), #   -z4
                );
            }
        }
        elsif (($a1+1) == $z1) {
            return (
            #   11111111111   22222222222222   33333333333333   444444444444
            #        A  Z          A     Z          A     Z          A   Z
                _cc($a1)    . _cc($a2)       . _cc($a3)       . _cc($a4,$Z4), # a4-
                _cc($a1)    . _cc($a2)       . _cc($a3+1,$Z3) . _cc($A4,$Z4), #   -
                _cc($a1)    . _cc($a2+1,$Z2) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc(   $z1) . _cc($A2,$z2-1) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc(   $z1) . _cc(    $z2)   . _cc($A3,$z3-1) . _cc($A4,$Z4), #   -
                _cc(   $z1) . _cc(    $z2)   . _cc(    $z3)   . _cc($A4,$z4), #   -z4
            );
        }
        else {
            return (
            #   1111111111111111   22222222222222   33333333333333   444444444444
            #        A     Z            A     Z          A     Z          A   Z
                _cc($a1)         . _cc($a2)       . _cc($a3)       . _cc($a4,$Z4), # a4-
                _cc($a1)         . _cc($a2)       . _cc($a3+1,$Z3) . _cc($A4,$Z4), #   -
                _cc($a1)         . _cc($a2+1,$Z2) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc($a1+1,$z1-1) . _cc($A2,$Z2)   . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc(      $z1)   . _cc($A2,$z2-1) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc(      $z1)   . _cc(    $z2)   . _cc($A3,$z3-1) . _cc($A4,$Z4), #   -
                _cc(      $z1)   . _cc(    $z2)   . _cc(    $z3)   . _cc($A4,$z4), #   -z4
            );
        }
    }
    else {
        die __FILE__, ": subroutine _octets got invalid length ($length).";
    }
}

#
# GBK range regexp
#
sub _range_regexp {
    my($length,$first,$last) = @_;

    my @range_regexp = ();
    if (not exists $range_tr{$length}) {
        return @range_regexp;
    }

    my @ranges = @{ $range_tr{$length} };
    while (my @range = splice(@ranges,0,$length)) {
        my $min = '';
        my $max = '';
        for (my $i=0; $i < $length; $i++) {
            $min .= pack 'C', $range[$i][0];
            $max .= pack 'C', $range[$i][-1];
        }

# min___max
#            FIRST_____________LAST
#       (nothing)

        if ($max lt $first) {
        }

#            **********
#       min_________max
#            FIRST_____________LAST
#            **********

        elsif (($min le $first) and ($first le $max) and ($max le $last)) {
            push @range_regexp, _octets($length,$first,$max,$min,$max);
        }

#            **********************
#            min________________max
#            FIRST_____________LAST
#            **********************

        elsif (($min eq $first) and ($max eq $last)) {
            push @range_regexp, _octets($length,$first,$last,$min,$max);
        }

#                   *********
#                   min___max
#            FIRST_____________LAST
#                   *********

        elsif (($first le $min) and ($max le $last)) {
            push @range_regexp, _octets($length,$min,$max,$min,$max);
        }

#            **********************
#       min__________________________max
#            FIRST_____________LAST
#            **********************

        elsif (($min le $first) and ($last le $max)) {
            push @range_regexp, _octets($length,$first,$last,$min,$max);
        }

#                         *********
#                         min________max
#            FIRST_____________LAST
#                         *********

        elsif (($first le $min) and ($min le $last) and ($last le $max)) {
            push @range_regexp, _octets($length,$min,$last,$min,$max);
        }

#                                    min___max
#            FIRST_____________LAST
#                              (nothing)

        elsif ($last lt $min) {
        }

        else {
            die __FILE__, ": subroutine _range_regexp panic.";
        }
    }

    return @range_regexp;
}

#
# GBK open character list for qr and not qr
#
sub _charlist {

    my $modifier = pop @_;
    my @char = @_;

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = hexchr($1);
        }

        # \N{CHARNAME} --> N\{CHARNAME}
        elsif ($char[$i] =~ /\A \\ (N) ( \{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \p{PROPERTY} --> p\{PROPERTY}
        elsif ($char[$i] =~ /\A \\ (p) ( \{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \P{PROPERTY} --> P\{PROPERTY}
        elsif ($char[$i] =~ /\A \\ (P) ( \{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \p, \P, \X --> p, P, X
        elsif ($char[$i] =~ /\A \\ ( [pPX] ) \z/oxms) {
            $char[$i] = $1;
        }

        elsif ($char[$i] =~ /\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = CORE::chr oct $1;
        }
        elsif ($char[$i] =~ /\A \\x ([0-9A-Fa-f]{1,2}) \z/oxms) {
            $char[$i] = CORE::chr hex $1;
        }
        elsif ($char[$i] =~ /\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ /\A (\\ [0nrtfbaedswDSWHVhvR]) \z/oxms) {
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

                # Vertical tabs are now whitespace
                # \s in a regex now matches a vertical tab in all circumstances.
                # http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#Vertical_tabs_are_now_whitespace
                #            \t  \n  \v  \f  \r space
                # '\s' => '[\x09\x0A    \x0C\x0D\x20]',
                # '\s' => '[\x09\x0A\x0B\x0C\x0D\x20]',
                '\s'   => '\s',

                '\w' => '[0-9A-Z_a-z]',
                '\D' => '${Char::Egbk::eD}',
                '\S' => '${Char::Egbk::eS}',
                '\W' => '${Char::Egbk::eW}',

                '\H' => '${Char::Egbk::eH}',
                '\V' => '${Char::Egbk::eV}',
                '\h' => '[\x09\x20]',
                '\v' => '[\x0A\x0B\x0C\x0D]',
                '\R' => '${Char::Egbk::eR}',

            }->{$1};
        }

        # POSIX-style character classes
        elsif ($ignorecase and ($char[$i] =~ /\A ( \[\: \^? (?:lower|upper) :\] ) \z/oxms)) {
            $char[$i] = {

                '[:lower:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:upper:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:^lower:]'  => '${Char::Egbk::not_lower_i}',
                '[:^upper:]'  => '${Char::Egbk::not_upper_i}',

            }->{$1};
        }
        elsif ($char[$i] =~ /\A ( \[\: \^? (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] ) \z/oxms) {
            $char[$i] = {

                '[:alnum:]'   => '[\x30-\x39\x41-\x5A\x61-\x7A]',
                '[:alpha:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:ascii:]'   => '[\x00-\x7F]',
                '[:blank:]'   => '[\x09\x20]',
                '[:cntrl:]'   => '[\x00-\x1F\x7F]',
                '[:digit:]'   => '[\x30-\x39]',
                '[:graph:]'   => '[\x21-\x7F]',
                '[:lower:]'   => '[\x61-\x7A]',
                '[:print:]'   => '[\x20-\x7F]',
                '[:punct:]'   => '[\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E]',

                # P.174 POSIX-Style Character Classes
                # in Chapter 5: Pattern Matching
                # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                # P.311 11.2.4 Character Classes and other Special Escapes
                # in Chapter 11: perlre: Perl regular expressions
                # of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)

                # P.210 POSIX-Style Character Classes
                # in Chapter 5: Pattern Matching
                # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

                '[:space:]'   => '[\s\x0B]', # "\s" plus vertical tab ("\cK")

                '[:upper:]'   => '[\x41-\x5A]',
                '[:word:]'    => '[\x30-\x39\x41-\x5A\x5F\x61-\x7A]',
                '[:xdigit:]'  => '[\x30-\x39\x41-\x46\x61-\x66]',
                '[:^alnum:]'  => '${Char::Egbk::not_alnum}',
                '[:^alpha:]'  => '${Char::Egbk::not_alpha}',
                '[:^ascii:]'  => '${Char::Egbk::not_ascii}',
                '[:^blank:]'  => '${Char::Egbk::not_blank}',
                '[:^cntrl:]'  => '${Char::Egbk::not_cntrl}',
                '[:^digit:]'  => '${Char::Egbk::not_digit}',
                '[:^graph:]'  => '${Char::Egbk::not_graph}',
                '[:^lower:]'  => '${Char::Egbk::not_lower}',
                '[:^print:]'  => '${Char::Egbk::not_print}',
                '[:^punct:]'  => '${Char::Egbk::not_punct}',
                '[:^space:]'  => '${Char::Egbk::not_space}',
                '[:^upper:]'  => '${Char::Egbk::not_upper}',
                '[:^word:]'   => '${Char::Egbk::not_word}',
                '[:^xdigit:]' => '${Char::Egbk::not_xdigit}',

            }->{$1};
        }
        elsif ($char[$i] =~ /\A \\ ($q_char) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet   = ();
    my @multipleoctet = ();
    for (my $i=0; $i <= $#char; ) {

        # escaped -
        if (defined($char[$i+1]) and ($char[$i+1] eq '...')) {
            $i += 1;
            next;
        }

        # make range regexp
        elsif ($char[$i] eq '...') {

            # range error
            if (CORE::length($char[$i-1]) > CORE::length($char[$i+1])) {
                croak 'Invalid [] range in regexp (length(A) > length(B)) ' . '\x' . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]);
            }
            elsif (CORE::length($char[$i-1]) == CORE::length($char[$i+1])) {
                if ($char[$i-1] gt $char[$i+1]) {
                    croak 'Invalid [] range in regexp (CORE::ord(A) > CORE::ord(B)) ' . '\x' . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]);
                }
            }

            # make range regexp per length
            for my $length (CORE::length($char[$i-1]) .. CORE::length($char[$i+1])) {
                my @regexp = ();

                # is first and last
                if (($length == CORE::length($char[$i-1])) and ($length == CORE::length($char[$i+1]))) {
                    push @regexp, _range_regexp($length, $char[$i-1], $char[$i+1]);
                }

                # is first
                elsif ($length == CORE::length($char[$i-1])) {
                    push @regexp, _range_regexp($length, $char[$i-1], "\xFF" x $length);
                }

                # is inside in first and last
                elsif ((CORE::length($char[$i-1]) < $length) and ($length < CORE::length($char[$i+1]))) {
                    push @regexp, _range_regexp($length, "\x00" x $length, "\xFF" x $length);
                }

                # is last
                elsif ($length == CORE::length($char[$i+1])) {
                    push @regexp, _range_regexp($length, "\x00" x $length, $char[$i+1]);
                }

                else {
                    die __FILE__, ": subroutine make_regexp panic.";
                }

                if ($length == 1) {
                    push @singleoctet, @regexp;
                }
                else {
                    push @multipleoctet, @regexp;
                }
            }

            $i += 2;
        }

        # with /i modifier
        elsif ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) {
            if ($modifier =~ /i/oxms) {
                my $uc = Char::Egbk::uc($char[$i]);
                my $fc = Char::Egbk::fc($char[$i]);
                if ($uc ne $fc) {
                    if (CORE::length($fc) == 1) {
                        push @singleoctet, $uc, $fc;
                    }
                    else {
                        push @singleoctet,   $uc;
                        push @multipleoctet, $fc;
                    }
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
        elsif ($char[$i] =~ /\A (?: \\h ) \z/oxms) {
            push @singleoctet, "\t", "\x20";
            $i += 1;
        }
        elsif ($char[$i] =~ /\A (?: \\v ) \z/oxms) {
            push @singleoctet, "\x0A", "\x0B", "\x0C", "\x0D";
            $i += 1;
        }
        elsif ($char[$i] =~ /\A (?: \\d | \\s | \\w ) \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }

        # single character of multiple-octet code
        else {
            push @multipleoctet, $char[$i];
            $i += 1;
        }
    }

    # quote metachar
    for (@singleoctet) {
        if ($_ eq '...') {
            $_ = '-';
        }
        elsif (/\A \n \z/oxms) {
            $_ = '\n';
        }
        elsif (/\A \r \z/oxms) {
            $_ = '\r';
        }
        elsif (/\A ([\x00-\x20\x7F-\xFF]) \z/oxms) {
            $_ = sprintf('\x%02X', CORE::ord $1);
        }
        elsif (/\A [\x00-\xFF] \z/oxms) {
            $_ = quotemeta $_;
        }
    }
    for (@multipleoctet) {
        if (/\A ([\x81-\xFE]) ([\x00-\xFF]) \z/oxms) {
            $_ = $1 . quotemeta $2;
        }
    }

    # return character list
    return \@singleoctet, \@multipleoctet;
}

#
# GBK octal escape sequence
#
sub octchr {
    my($octdigit) = @_;

    my @binary = ();
    for my $octal (split(//,$octdigit)) {
        push @binary, {
            '0' => '000',
            '1' => '001',
            '2' => '010',
            '3' => '011',
            '4' => '100',
            '5' => '101',
            '6' => '110',
            '7' => '111',
        }->{$octal};
    }
    my $binary = join '', @binary;

    my $octchr = {
        #                1234567
        1 => pack('B*', "0000000$binary"),
        2 => pack('B*', "000000$binary"),
        3 => pack('B*', "00000$binary"),
        4 => pack('B*', "0000$binary"),
        5 => pack('B*', "000$binary"),
        6 => pack('B*', "00$binary"),
        7 => pack('B*', "0$binary"),
        0 => pack('B*', "$binary"),

    }->{CORE::length($binary) % 8};

    return $octchr;
}

#
# GBK hexadecimal escape sequence
#
sub hexchr {
    my($hexdigit) = @_;

    my $hexchr = {
        1 => pack('H*', "0$hexdigit"),
        0 => pack('H*', "$hexdigit"),

    }->{CORE::length($_[0]) % 2};

    return $hexchr;
}

#
# GBK open character list for qr
#
sub charlist_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $multipleoctet) = _charlist(@char, $modifier);
    my @singleoctet   = @$singleoctet;
    my @multipleoctet = @$multipleoctet;

    # return character list
    if (scalar(@singleoctet) >= 1) {

        # with /i modifier
        if ($modifier =~ m/i/oxms) {
            my %singleoctet_ignorecase = ();
            for (@singleoctet) {
                while (s/ \A \\x(..) - \\x(..) //oxms or s/ \A \\x((..)) //oxms) {
                    for my $ord (hex($1) .. hex($2)) {
                        my $char = CORE::chr($ord);
                        my $uc = Char::Egbk::uc($char);
                        my $fc = Char::Egbk::fc($char);
                        if ($uc eq $fc) {
                            $singleoctet_ignorecase{unpack 'C*', $char} = 1;
                        }
                        else {
                            if (CORE::length($fc) == 1) {
                                $singleoctet_ignorecase{unpack 'C*', $uc} = 1;
                                $singleoctet_ignorecase{unpack 'C*', $fc} = 1;
                            }
                            else {
                                $singleoctet_ignorecase{unpack 'C*', $uc} = 1;
                                push @multipleoctet, join '', map {sprintf('\x%02X',$_)} unpack 'C*', $fc;
                            }
                        }
                    }
                }
            }
            my $i = 0;
            my @singleoctet_ignorecase = ();
            for my $ord (0 .. 255) {
                if (exists $singleoctet_ignorecase{$ord}) {
                    push @{$singleoctet_ignorecase[$i]}, $ord;
                }
                else {
                    $i++;
                }
            }
            @singleoctet = ();
            for my $range (@singleoctet_ignorecase) {
                if (ref $range) {
                    if (scalar(@{$range}) == 1) {
                        push @singleoctet, sprintf('\x%02X', @{$range}[0]);
                    }
                    elsif (scalar(@{$range}) == 2) {
                        push @singleoctet, sprintf('\x%02X\x%02X', @{$range}[0], @{$range}[-1]);
                    }
                    else {
                        push @singleoctet, sprintf('\x%02X-\x%02X', @{$range}[0], @{$range}[-1]);
                    }
                }
            }
        }

        my $not_anchor = '';
        $not_anchor = '(?![\x81-\xFE])';

        push @multipleoctet, join('', $not_anchor, '[', @singleoctet, ']' );
    }
    if (scalar(@multipleoctet) >= 2) {
        return '(?:' . join('|', @multipleoctet) . ')';
    }
    else {
        return $multipleoctet[0];
    }
}

#
# GBK open character list for not qr
#
sub charlist_not_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $multipleoctet) = _charlist(@char, $modifier);
    my @singleoctet   = @$singleoctet;
    my @multipleoctet = @$multipleoctet;

    # with /i modifier
    if ($modifier =~ m/i/oxms) {
        my %singleoctet_ignorecase = ();
        for (@singleoctet) {
            while (s/ \A \\x(..) - \\x(..) //oxms or s/ \A \\x((..)) //oxms) {
                for my $ord (hex($1) .. hex($2)) {
                    my $char = CORE::chr($ord);
                    my $uc = Char::Egbk::uc($char);
                    my $fc = Char::Egbk::fc($char);
                    if ($uc eq $fc) {
                        $singleoctet_ignorecase{unpack 'C*', $char} = 1;
                    }
                    else {
                        if (CORE::length($fc) == 1) {
                            $singleoctet_ignorecase{unpack 'C*', $uc} = 1;
                            $singleoctet_ignorecase{unpack 'C*', $fc} = 1;
                        }
                        else {
                            $singleoctet_ignorecase{unpack 'C*', $uc} = 1;
                            push @multipleoctet, join '', map {sprintf('\x%02X',$_)} unpack 'C*', $fc;
                        }
                    }
                }
            }
        }
        my $i = 0;
        my @singleoctet_ignorecase = ();
        for my $ord (0 .. 255) {
            if (exists $singleoctet_ignorecase{$ord}) {
                push @{$singleoctet_ignorecase[$i]}, $ord;
            }
            else {
                $i++;
            }
        }
        @singleoctet = ();
        for my $range (@singleoctet_ignorecase) {
            if (ref $range) {
                if (scalar(@{$range}) == 1) {
                    push @singleoctet, sprintf('\x%02X', @{$range}[0]);
                }
                elsif (scalar(@{$range}) == 2) {
                    push @singleoctet, sprintf('\x%02X\x%02X', @{$range}[0], @{$range}[-1]);
                }
                else {
                    push @singleoctet, sprintf('\x%02X-\x%02X', @{$range}[0], @{$range}[-1]);
                }
            }
        }
    }

    # return character list
    if (scalar(@multipleoctet) >= 1) {
        if (scalar(@singleoctet) >= 1) {

            # any character other than multiple-octet and single octet character class
            return '(?!' . join('|', @multipleoctet) . ')(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE' . join('', @singleoctet) . '])';
        }
        else {

            # any character other than multiple-octet character class
            return '(?!' . join('|', @multipleoctet) . ")(?:$your_char)";
        }
    }
    else {
        if (scalar(@singleoctet) >= 1) {

            # any character other than single octet character class
            return                                      '(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE' . join('', @singleoctet) . '])';
        }
        else {

            # any character
            return                                      "(?:$your_char)";
        }
    }
}

#
# open file in read mode
#
sub _open_r {
    my(undef,$file) = @_;
    $file =~ s#\A (\s) #./$1#oxms;
    return eval(q{open($_[0],'<',$_[1])}) ||
                  open($_[0],"< $file\0");
}

#
# open file in write mode
#
sub _open_w {
    my(undef,$file) = @_;
    $file =~ s#\A (\s) #./$1#oxms;
    return eval(q{open($_[0],'>',$_[1])}) ||
                  open($_[0],"> $file\0");
}

#
# open file in append mode
#
sub _open_a {
    my(undef,$file) = @_;
    $file =~ s#\A (\s) #./$1#oxms;
    return eval(q{open($_[0],'>>',$_[1])}) ||
                  open($_[0],">> $file\0");
}

#
# safe system
#
sub _systemx {

    # P.707 29.2.33. exec
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.
    #
    # Be aware that in older releases of Perl, exec (and system) did not flush
    # your output buffer, so you needed to enable command buffering by setting $|
    # on one or more filehandles to avoid lost output in the case of exec, or
    # misordererd output in the case of system. This situation was largely remedied
    # in the 5.6 release of Perl. (So, 5.005 release not yet.)

    # P.855 exec
    # in Chapter 27: Functions
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.
    #
    # In very old release of Perl (before v5.6), exec (and system) did not flush
    # your output buffer, so you needed to enable command buffering by setting $|
    # on one or more filehandles to avoid lost output with exec or misordered
    # output with system.

    $| = 1;

    # P.565 23.1.2. Cleaning Up Your Environment
    # in Chapter 23: Security
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.656 Cleaning Up Your Environment
    # in Chapter 20: Security
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # local $ENV{'PATH'} = '.';
    local @ENV{qw(IFS CDPATH ENV BASH_ENV)}; # Make %ENV safer

    # P.707 29.2.33. exec
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.
    #
    # As we mentioned earlier, exec treats a discrete list of arguments as an
    # indication that it should bypass shell processing. However, there is one
    # place where you might still get tripped up. The exec call (and system, too)
    # will not distinguish between a single scalar argument and an array containing
    # only one element.
    #
    #     @args = ("echo surprise");  # just one element in list
    #     exec @args                  # still subject to shell escapes
    #         or die "exec: $!";      #   because @args == 1
    #
    # To avoid this, you can use the PATHNAME syntax, explicitly duplicating the
    # first argument as the pathname, which forces the rest of the arguments to be
    # interpreted as a list, even if there is only one of them:
    #
    #     exec { $args[0] } @args  # safe even with one-argument list
    #         or die "can't exec @args: $!";

    # P.855 exec
    # in Chapter 27: Functions
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.
    #
    # As we mentioned earlier, exec treats a discrete list of arguments as a
    # directive to bypass shell processing. However, there is one place where
    # you might still get tripped up. The exec call (and system, too) cannot
    # distinguish between a single scalar argument and an array containing
    # only one element.
    #
    #     @args = ("echo surprise");  # just one element in list
    #     exec @args                  # still subject to shell escapes
    #         || die "exec: $!";      #   because @args == 1
    #
    # To avoid this, use the PATHNAME syntax, explicitly duplicating the first
    # argument as the pathname, which forces the rest of the arguments to be
    # interpreted as a list, even if there is only one of them:
    #
    #     exec { $args[0] } @args  # safe even with one-argument list
    #         || die "can't exec @args: $!";

    return CORE::system { $_[0] } @_; # safe even with one-argument list
}

#
# GBK order to character (with parameter)
#
sub Char::Egbk::chr(;$) {

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
sub Char::Egbk::chr_() {

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
sub Char::Egbk::filetest {

    my $file     = pop @_;
    my $filetest = substr(pop @_, 1);

    unless (eval qq{Char::Egbk::$filetest(\$file)}) {
        return '';
    }
    for my $filetest (CORE::reverse @_) {
        unless (eval qq{ $filetest _ }) {
            return '';
        }
    }
    return 1;
}

#
# GBK file test -r expr
#
sub Char::Egbk::r(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -r (Char::Egbk::r)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-r _,@_) : -r _;
    }

    # P.908 32.39. Symbol
    # in Chapter 32: Standard Modules
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.326 Prototypes
    # in Chapter 7: Subroutines
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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

            # Even if ${^WIN32_SLOPPY_STAT} is set to a true value, Char::Egbk::*()
            # on Windows opens the file for the path which has 5c at end.
            # (and so on)

            my $fh = gensym();
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::w(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -w (Char::Egbk::w)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-w _,@_) : -w _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_a($fh, $_)) {
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
sub Char::Egbk::x(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -x (Char::Egbk::x)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-x _,@_) : -x _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::o(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -o (Char::Egbk::o)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-o _,@_) : -o _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::R(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -R (Char::Egbk::R)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-R _,@_) : -R _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::W(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -W (Char::Egbk::W)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-W _,@_) : -W _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_a($fh, $_)) {
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
sub Char::Egbk::X(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -X (Char::Egbk::X)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-X _,@_) : -X _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::O(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -O (Char::Egbk::O)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-O _,@_) : -O _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::e(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -e (Char::Egbk::e)' if @_ and not wantarray;

    local $^W = 0;

    my $fh = qualify_to_ref $_;
    if ($_ eq '_') {
        return wantarray ? (-e _,@_) : -e _;
    }

    # return false if directory handle
    elsif (defined Char::Egbk::telldir($fh)) {
        return wantarray ? ('',@_) : '';
    }

    # return true if file handle
    elsif (defined fileno $fh) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::z(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -z (Char::Egbk::z)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-z _,@_) : -z _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::s(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -s (Char::Egbk::s)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-s _,@_) : -s _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::f(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -f (Char::Egbk::f)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-f _,@_) : -f _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::d(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -d (Char::Egbk::d)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-d _,@_) : -d _;
    }

    # return false if file handle or directory handle
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
sub Char::Egbk::l(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -l (Char::Egbk::l)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-l _,@_) : -l _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::p(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -p (Char::Egbk::p)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-p _,@_) : -p _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::S(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -S (Char::Egbk::S)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-S _,@_) : -S _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::b(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -b (Char::Egbk::b)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-b _,@_) : -b _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::c(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -c (Char::Egbk::c)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-c _,@_) : -c _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::u(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -u (Char::Egbk::u)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-u _,@_) : -u _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::g(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -g (Char::Egbk::g)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-g _,@_) : -g _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::k(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -k (Char::Egbk::k)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? ('',@_) : '';
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? ('',@_) : '';
    }
    elsif ($] =~ /^5\.008/oxms) {
        return wantarray ? ('',@_) : '';
    }
    return wantarray ? ($_,@_) : $_;
}

#
# GBK file test -T expr
#
sub Char::Egbk::T(;*@) {

    local $_ = shift if @_;

    # Use of croak without parentheses makes die on Strawberry Perl 5.008 and 5.010, like:
    #     croak 'Too many arguments for -T (Char::Egbk::T)';
    # Must be used by parentheses like:
    #     croak('Too many arguments for -T (Char::Egbk::T)');

    if (@_ and not wantarray) {
        croak('Too many arguments for -T (Char::Egbk::T)');
    }

    my $T = 1;

    my $fh = qualify_to_ref $_;
    if (defined fileno $fh) {

        if (defined Char::Egbk::telldir($fh)) {
            return wantarray ? (undef,@_) : undef;
        }

        # P.813 29.2.176. tell
        # in Chapter 29: Functions
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.970 tell
        # in Chapter 27: Functions
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

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

        my $dummy_for_underline_cache = -T $fh;
        sysseek $fh, $systell, 0;
    }
    else {
        if (-d $_ or -d "$_/.") {
            return wantarray ? (undef,@_) : undef;
        }

        $fh = gensym();
        if (_open_r($fh, $_)) {
        }
        else {
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
        my $dummy_for_underline_cache = -T $fh;
        close $fh;
    }

    return wantarray ? ($T,@_) : $T;
}

#
# GBK file test -B expr
#
sub Char::Egbk::B(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -B (Char::Egbk::B)' if @_ and not wantarray;
    my $B = '';

    my $fh = qualify_to_ref $_;
    if (defined fileno $fh) {

        if (defined Char::Egbk::telldir($fh)) {
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

        my $dummy_for_underline_cache = -B $fh;
        sysseek $fh, $systell, 0;
    }
    else {
        if (-d $_ or -d "$_/.") {
            return wantarray ? (undef,@_) : undef;
        }

        $fh = gensym();
        if (_open_r($fh, $_)) {
        }
        else {
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
        my $dummy_for_underline_cache = -B $fh;
        close $fh;
    }

    return wantarray ? ($B,@_) : $B;
}

#
# GBK file test -M expr
#
sub Char::Egbk::M(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -M (Char::Egbk::M)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-M _,@_) : -M _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::A(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -A (Char::Egbk::A)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-A _,@_) : -A _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::C(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -C (Char::Egbk::C)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-C _,@_) : -C _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
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
            if (_open_r($fh, $_)) {
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
sub Char::Egbk::filetest_ {

    my $filetest = substr(pop @_, 1);

    unless (eval qq{Char::Egbk::${filetest}_}) {
        return '';
    }
    for my $filetest (CORE::reverse @_) {
        unless (eval qq{ $filetest _ }) {
            return '';
        }
    }
    return 1;
}

#
# GBK file test -r $_
#
sub Char::Egbk::r_() {

    if (-e $_) {
        return -r _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -r _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $r = -r $fh;
                close $fh;
                return $r ? 1 : '';
            }
        }
    }

# 2010-01-26 The difference of "return;" and "return undef;"
# http://d.hatena.ne.jp/gfx/20100126/1264474754
#
# "Perl Best Practices" recommends to use "return;"*1 to return nothing, but
# it might be wrong in some cases. If you use this idiom for those functions
# which are expected to return a scalar value, e.g. searching functions, the
# user of those functions will be surprised at what they return in list
# context, an empty list - note that many functions and all the methods
# evaluate their arguments in list context. You'd better to use "return undef;"
# for such scalar functions.
#
#     sub search_something {
#         my($arg) = @_;
#         # search_something...
#         if(defined $found){
#             return $found;
#         }
#         return; # XXX: you'd better to "return undef;"
#     }
#
#     # ...
#
#     # you'll get what you want, but ...
#     my $something = search_something($source);
#
#     # you won't get what you want here.
#     # @_ for doit() is (-foo => $opt), not (undef, -foo => $opt).
#     $obj->doit(search_something($source), -option=> $optval);
#
#     # you have to use the "scalar" operator in such a case.
#     $obj->doit(scalar search_something($source), ...);
#
# *1: it returns an empty list in list context, or returns undef in scalar
#     context
#
# (and so on)

    return undef;
}

#
# GBK file test -w $_
#
sub Char::Egbk::w_() {

    if (-e $_) {
        return -w _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -w _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_a($fh, $_)) {
                my $w = -w $fh;
                close $fh;
                return $w ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -x $_
#
sub Char::Egbk::x_() {

    if (-e $_) {
        return -x _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -x _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $dummy_for_underline_cache = -x $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return '';
        }
    }
    return undef;
}

#
# GBK file test -o $_
#
sub Char::Egbk::o_() {

    if (-e $_) {
        return -o _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -o _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $o = -o $fh;
                close $fh;
                return $o ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -R $_
#
sub Char::Egbk::R_() {

    if (-e $_) {
        return -R _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -R _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $R = -R $fh;
                close $fh;
                return $R ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -W $_
#
sub Char::Egbk::W_() {

    if (-e $_) {
        return -W _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -W _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_a($fh, $_)) {
                my $W = -W $fh;
                close $fh;
                return $W ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -X $_
#
sub Char::Egbk::X_() {

    if (-e $_) {
        return -X _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -X _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $dummy_for_underline_cache = -X $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return '';
        }
    }
    return undef;
}

#
# GBK file test -O $_
#
sub Char::Egbk::O_() {

    if (-e $_) {
        return -O _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -O _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $O = -O $fh;
                close $fh;
                return $O ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -e $_
#
sub Char::Egbk::e_() {

    if (-e $_) {
        return 1;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return 1;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $e = -e $fh;
                close $fh;
                return $e ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -z $_
#
sub Char::Egbk::z_() {

    if (-e $_) {
        return -z _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -z _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $z = -z $fh;
                close $fh;
                return $z ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -s $_
#
sub Char::Egbk::s_() {

    if (-e $_) {
        return -s _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -s _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $s = -s $fh;
                close $fh;
                return $s;
            }
        }
    }
    return undef;
}

#
# GBK file test -f $_
#
sub Char::Egbk::f_() {

    if (-e $_) {
        return -f _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $f = -f $fh;
                close $fh;
                return $f ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -d $_
#
sub Char::Egbk::d_() {

    if (-e $_) {
        return -d _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        return -d "$_/." ? 1 : '';
    }
    return undef;
}

#
# GBK file test -l $_
#
sub Char::Egbk::l_() {

    if (-e $_) {
        return -l _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -l _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $l = -l $fh;
                close $fh;
                return $l ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -p $_
#
sub Char::Egbk::p_() {

    if (-e $_) {
        return -p _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -p _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $p = -p $fh;
                close $fh;
                return $p ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -S $_
#
sub Char::Egbk::S_() {

    if (-e $_) {
        return -S _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -S _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $S = -S $fh;
                close $fh;
                return $S ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -b $_
#
sub Char::Egbk::b_() {

    if (-e $_) {
        return -b _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -b _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $b = -b $fh;
                close $fh;
                return $b ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -c $_
#
sub Char::Egbk::c_() {

    if (-e $_) {
        return -c _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -c _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $c = -c $fh;
                close $fh;
                return $c ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -u $_
#
sub Char::Egbk::u_() {

    if (-e $_) {
        return -u _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -u _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $u = -u $fh;
                close $fh;
                return $u ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -g $_
#
sub Char::Egbk::g_() {

    if (-e $_) {
        return -g _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -g _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $g = -g $fh;
                close $fh;
                return $g ? 1 : '';
            }
        }
    }
    return undef;
}

#
# GBK file test -k $_
#
sub Char::Egbk::k_() {

    if ($] =~ /^5\.008/oxms) {
        return wantarray ? ('',@_) : '';
    }
    return wantarray ? ($_,@_) : $_;
}

#
# GBK file test -T $_
#
sub Char::Egbk::T_() {

    my $T = 1;

    if (-d $_ or -d "$_/.") {
        return undef;
    }
    my $fh = gensym();
    if (_open_r($fh, $_)) {
    }
    else {
        return undef;
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
    my $dummy_for_underline_cache = -T $fh;
    close $fh;

    return $T;
}

#
# GBK file test -B $_
#
sub Char::Egbk::B_() {

    my $B = '';

    if (-d $_ or -d "$_/.") {
        return undef;
    }
    my $fh = gensym();
    if (_open_r($fh, $_)) {
    }
    else {
        return undef;
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
    my $dummy_for_underline_cache = -B $fh;
    close $fh;

    return $B;
}

#
# GBK file test -M $_
#
sub Char::Egbk::M_() {

    if (-e $_) {
        return -M _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -M _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $M = ($^T - $mtime) / (24*60*60);
                return $M;
            }
        }
    }
    return undef;
}

#
# GBK file test -A $_
#
sub Char::Egbk::A_() {

    if (-e $_) {
        return -A _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -A _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $A = ($^T - $atime) / (24*60*60);
                return $A;
            }
        }
    }
    return undef;
}

#
# GBK file test -C $_
#
sub Char::Egbk::C_() {

    if (-e $_) {
        return -C _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -C _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $C = ($^T - $ctime) / (24*60*60);
                return $C;
            }
        }
    }
    return undef;
}

#
# GBK path globbing (with parameter)
#
sub Char::Egbk::glob($) {

    if (wantarray) {
        my @glob = _DOS_like_glob(@_);
        for my $glob (@glob) {
            $glob =~ s{ \A (?:\./)+ }{}oxms;
        }
        return @glob;
    }
    else {
        my $glob = _DOS_like_glob(@_);
        $glob =~ s{ \A (?:\./)+ }{}oxms;
        return $glob;
    }
}

#
# GBK path globbing (without parameter)
#
sub Char::Egbk::glob_() {

    if (wantarray) {
        my @glob = _DOS_like_glob();
        for my $glob (@glob) {
            $glob =~ s{ \A (?:\./)+ }{}oxms;
        }
        return @glob;
    }
    else {
        my $glob = _DOS_like_glob();
        $glob =~ s{ \A (?:\./)+ }{}oxms;
        return $glob;
    }
}

#
# GBK path globbing via File::DosGlob 1.10
#
# Often I confuse "_dosglob" and "_doglob".
# So, I renamed "_dosglob" to "_DOS_like_glob".
#
my %iter;
my %entries;
sub _DOS_like_glob {

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
                  { my_home_MSWin32() }oxmse;
    }

    # UNIX-like system
    else {
        $expr =~ s{ \A ~ ( (?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE/])* ) }
                  { $1 ? (eval(q{(getpwnam($1))[7]})||my_home()) : my_home() }oxmse;
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
    my $fix_drive_relative_paths = 0;

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
        if ($expr =~ /\A " ((?:$q_char)*) " \z/oxms) {
            $expr = $1;
            if ($cond eq 'd') {
                if (Char::Egbk::d $expr) {
                    push @glob, $expr;
                }
            }
            else {
                if (Char::Egbk::e $expr) {
                    push @glob, $expr;
                }
            }
            next OUTER;
        }

        # wildcards with a drive prefix such as h:*.pm must be changed
        # to h:./*.pm to expand correctly
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            if ($expr =~ s# \A ((?:[A-Za-z]:)?) ([\x81-\xFE][\x00-\xFF]|[^\x81-\xFE/\\]) #$1./$2#oxms) {
                $fix_drive_relative_paths = 1;
            }
        }

        if (($head, $tail) = _parse_path($expr,$pathsep)) {
            if ($tail eq '') {
                push @glob, $expr;
                next OUTER;
            }
            if ($head =~ / \A (?:$q_char)*? [*?] /oxms) {
                if (@globdir = _do_glob('d', $head)) {
                    push @glob, _do_glob($cond, map {"$_$pathsep$tail"} @globdir);
                    next OUTER;
                }
            }
            if ($head eq '' or $head =~ /\A [A-Za-z]: \z/oxms) {
                $head .= $pathsep;
            }
            $expr = $tail;
        }

        # If file component has no wildcards, we can avoid opendir
        if ($expr !~ / \A (?:$q_char)*? [*?] /oxms) {
            if ($head eq '.') {
                $head = '';
            }
            if ($head ne '' and ($head =~ / \G ($q_char) /oxmsg)[-1] ne $pathsep) {
                $head .= $pathsep;
            }
            $head .= $expr;
            if ($cond eq 'd') {
                if (Char::Egbk::d $head) {
                    push @glob, $head;
                }
            }
            else {
                if (Char::Egbk::e $head) {
                    push @glob, $head;
                }
            }
            next OUTER;
        }
        Char::Egbk::opendir(*DIR, $head) or next OUTER;
        my @leaf = readdir DIR;
        closedir DIR;

        if ($head eq '.') {
            $head = '';
        }
        if ($head ne '' and ($head =~ / \G ($q_char) /oxmsg)[-1] ne $pathsep) {
            $head .= $pathsep;
        }

        my $pattern = '';
        while ($expr =~ / \G ($q_char) /oxgc) {
            my $char = $1;
            if ($char eq '*') {
                $pattern .= "(?:$your_char)*",
            }
            elsif ($char eq '?') {
                $pattern .= "(?:$your_char)?",  # DOS style
#               $pattern .= "(?:$your_char)",   # UNIX style
            }
            elsif ((my $fc = Char::Egbk::fc($char)) ne $char) {
                $pattern .= $fc;
            }
            else {
                $pattern .= quotemeta $char;
            }
        }
        my $matchsub = sub { Char::Egbk::fc($_[0]) =~ /\A $pattern \z/xms };

#       if ($@) {
#           print STDERR "$0: $@\n";
#           next OUTER;
#       }

INNER:
        for my $leaf (@leaf) {
            if ($leaf eq '.' or $leaf eq '..') {
                next INNER;
            }
            if ($cond eq 'd' and not Char::Egbk::d "$head$leaf") {
                next INNER;
            }

            if (&$matchsub($leaf)) {
                push @matched, "$head$leaf";
                next INNER;
            }

            # [DOS compatibility special case]
            # Failed, add a trailing dot and try again, but only...

            if (Char::Egbk::index($leaf,'.') == -1 and   # if name does not have a dot in it *and*
                CORE::length($leaf) <= 8 and        # name is shorter than or equal to 8 chars *and*
                Char::Egbk::index($pattern,'\\.') != -1  # pattern has a dot.
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
    if ($fix_drive_relative_paths) {
        for my $glob (@glob) {
            $glob =~ s# \A ([A-Za-z]:) \./ #$1#oxms;
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
    while ($line =~ /
        " ( (?: [\x81-\xFE][\x00-\xFF]|[^\x81-\xFE"]   )*  ) " \s+ |
          ( (?: [\x81-\xFE][\x00-\xFF]|[^\x81-\xFE"\s] )*  )   \s+
        /oxmsg
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
    while ($path =~ /
        ((?: [\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\/\\] )+?) [\/\\]
        /oxmsg
    ) {
        push @subpath, $1;
    }

    my $tail = pop @subpath;
    my $head = join $pathsep, @subpath;
    return $head, $tail;
}

#
# via File::HomeDir::Windows 1.00
#
sub my_home_MSWin32 {

    # A lot of unix people and unix-derived tools rely on
    # the ability to overload HOME. We will support it too
    # so that they can replace raw HOME calls with File::HomeDir.
    if (exists $ENV{'HOME'} and $ENV{'HOME'}) {
        return $ENV{'HOME'};
    }

    # Do we have a user profile?
    elsif (exists $ENV{'USERPROFILE'} and $ENV{'USERPROFILE'}) {
        return $ENV{'USERPROFILE'};
    }

    # Some Windows use something like $ENV{'HOME'}
    elsif (exists $ENV{'HOMEDRIVE'} and exists $ENV{'HOMEPATH'} and $ENV{'HOMEDRIVE'} and $ENV{'HOMEPATH'}) {
        return join '', $ENV{'HOMEDRIVE'}, $ENV{'HOMEPATH'};
    }

    return undef;
}

#
# via File::HomeDir::Unix 1.00
#
sub my_home {
    my $home;

    if (exists $ENV{'HOME'} and defined $ENV{'HOME'}) {
        $home = $ENV{'HOME'};
    }

    # This is from the original code, but I'm guessing
    # it means "login directory" and exists on some Unixes.
    elsif (exists $ENV{'LOGDIR'} and $ENV{'LOGDIR'}) {
        $home = $ENV{'LOGDIR'};
    }

    ### More-desperate methods

    # Light desperation on any (Unixish) platform
    else {
        $home = eval q{ (getpwuid($<))[7] };
    }

    # On Unix in general, a non-existant home means "no home"
    # For example, "nobody"-like users might use /nonexistant
    if (defined $home and ! Char::Egbk::d($home)) {
        $home = undef;
    }
    return $home;
}

#
# GBK file lstat (with parameter)
#
sub Char::Egbk::lstat(*) {

    local $_ = shift if @_;

    if (-e $_) {
        return CORE::lstat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {

        # Even if ${^WIN32_SLOPPY_STAT} is set to a true value, Char::Egbk::lstat()
        # on Windows opens the file for the path which has 5c at end.
        # (and so on)

        my $fh = gensym();
        if (wantarray) {
            if (_open_r($fh, $_)) {
                my @lstat = CORE::stat $fh; # not CORE::lstat
                close $fh;
                return @lstat;
            }
        }
        else {
            if (_open_r($fh, $_)) {
                my $lstat = CORE::stat $fh; # not CORE::lstat
                close $fh;
                return $lstat;
            }
        }
    }
    return wantarray ? () : undef;
}

#
# GBK file lstat (without parameter)
#
sub Char::Egbk::lstat_() {

    if (-e $_) {
        return CORE::lstat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = gensym();
        if (wantarray) {
            if (_open_r($fh, $_)) {
                my @lstat = CORE::stat $fh; # not CORE::lstat
                close $fh;
                return @lstat;
            }
        }
        else {
            if (_open_r($fh, $_)) {
                my $lstat = CORE::stat $fh; # not CORE::lstat
                close $fh;
                return $lstat;
            }
        }
    }
    return wantarray ? () : undef;
}

#
# GBK path opendir
#
sub Char::Egbk::opendir(*$) {

    my $dh = qualify_to_ref $_[0];
    if (CORE::opendir $dh, $_[1]) {
        return 1;
    }
    elsif (_MSWin32_5Cended_path($_[1])) {
        if (CORE::opendir $dh, "$_[1]/.") {
            return 1;
        }
    }
    return undef;
}

#
# GBK file stat (with parameter)
#
sub Char::Egbk::stat(*) {

    local $_ = shift if @_;

    my $fh = qualify_to_ref $_;
    if (defined fileno $fh) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {

        # Even if ${^WIN32_SLOPPY_STAT} is set to a true value, Char::Egbk::stat()
        # on Windows opens the file for the path which has 5c at end.
        # (and so on)

        my $fh = gensym();
        if (wantarray) {
            if (_open_r($fh, $_)) {
                my @stat = CORE::stat $fh;
                close $fh;
                return @stat;
            }
        }
        else {
            if (_open_r($fh, $_)) {
                my $stat = CORE::stat $fh;
                close $fh;
                return $stat;
            }
        }
    }
    return wantarray ? () : undef;
}

#
# GBK file stat (without parameter)
#
sub Char::Egbk::stat_() {

    my $fh = qualify_to_ref $_;
    if (defined fileno $fh) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = gensym();
        if (wantarray) {
            if (_open_r($fh, $_)) {
                my @stat = CORE::stat $fh;
                close $fh;
                return @stat;
            }
        }
        else {
            if (_open_r($fh, $_)) {
                my $stat = CORE::stat $fh;
                close $fh;
                return $stat;
            }
        }
    }
    return wantarray ? () : undef;
}

#
# GBK path unlink
#
sub Char::Egbk::unlink(@) {

    local @_ = ($_) unless @_;

    my $unlink = 0;
    for (@_) {
        if (CORE::unlink) {
            $unlink++;
        }
        elsif (Char::Egbk::d($_)) {
        }
        elsif (_MSWin32_5Cended_path($_)) {
            my @char = /\G ($q_char) /oxmsg;
            my $file = join '', map {{'/' => '\\'}->{$_} || $_} @char;
            if ($file =~ / \A (?:$q_char)*? [ ] /oxms) {
                $file = qq{"$file"};
            }
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                close $fh;

                # cmd.exe on Windows NT, Windows 2000, Windows XP, Windows 2003 or later
                if ($ENV{'OS'} eq 'Windows_NT') {
                    CORE::system 'DEL', '/F', $file, '2>NUL';
                }

                # Win95Cmd.exe on any Windows (when SET PERL5SHELL=Win95Cmd.exe /c, `var` returns "Windows 2000")
                elsif (qx{ver} =~ /\b(?:Windows 2000)\b/oms) {
                    CORE::system 'DEL', '/F', $file, '2>NUL';
                }

                # COMMAND.COM on Windows 95, Windows 98, Windows 98 Second Edition, Windows Millennium Edition
                # command.com can not "2>NUL"
                else {
                    CORE::system 'ATTRIB', '-R', $file; # clears Read-only file attribute
                    CORE::system 'DEL',          $file;
                }

                if (_open_r($fh, $_)) {
                    close $fh;
                }
                else {
                    $unlink++;
                }
            }
        }
    }
    return $unlink;
}

#
# GBK chdir
#
sub Char::Egbk::chdir(;$) {

    if (@_ == 0) {
        return CORE::chdir;
    }

    my($dir) = @_;

    if (_MSWin32_5Cended_path($dir)) {
        if (not Char::Egbk::d $dir) {
            return 0;
        }

        if ($] =~ /^5\.005/oxms) {
            return CORE::chdir $dir;
        }
        elsif (($] =~ /^(?:5\.006|5\.008000)/oxms) and ($^O eq 'MSWin32')) {
            local $@;
            my $chdir = eval q{
                CORE::require 'jacode.pl';

                # P.676 ${^WIDE_SYSTEM_CALLS}
                # in Chapter 28: Special Names
                # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                # P.790 ${^WIDE_SYSTEM_CALLS}
                # in Chapter 25: Special Names
                # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

                local ${^WIDE_SYSTEM_CALLS} = 1;
                return CORE::chdir jcode::utf8($dir,'sjis');
            };
            if (not $@) {
                return $chdir;
            }
        }

        # old idea (Win32 module required)
        elsif (0) {
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
                my @char = $dir =~ /\G ($q_char) /oxmsg;
                while ($char[-1] eq "\x5C") {
                    pop @char;
                }
                $dir = join '', @char;
                croak "Perl$] can't chdir to $dir (chr(0x5C) ended path), Win32.pm module may help you";
            }
            elsif ($shortdir eq $dir) {
                my @char = $dir =~ /\G ($q_char) /oxmsg;
                while ($char[-1] eq "\x5C") {
                    pop @char;
                }
                $dir = join '', @char;
                croak "Perl$] can't chdir to $dir (chr(0x5C) ended path)";
            }
            return $chdir;
        }

        # rejected idea ...
        elsif (0) {

            # MSDN SetCurrentDirectory function
            # http://msdn.microsoft.com/ja-jp/library/windows/desktop/aa365530(v=vs.85).aspx
            #
            # Data Execution Prevention (DEP)
            # http://vlaurie.com/computers2/Articles/dep.htm
            #
            # Learning x86 assembler with Perl -- Shibuya.pm#11
            # http://developer.cybozu.co.jp/takesako/2009/06/perl-x86-shibuy.html
            #
            # Introduction to Win32::API programming in Perl
            # http://d.hatena.ne.jp/TAKESAKO/20090324/1237879559
            #
            # DynaLoader - Dynamically load C libraries into Perl code
            # http://perldoc.perl.org/DynaLoader.html
            #
            # Basic knowledge of DynaLoader
            # http://blog.64p.org/entry/20090313/1236934042

            if (($] =~ /^5\.006/oxms)                     and
                ($^O eq 'MSWin32')                        and
                ($ENV{'PROCESSOR_ARCHITECTURE'} eq 'x86') and
                eval(q{CORE::require 'Dyna'.'Loader'})
            ) {
                my $x86 = join('',

                    # PUSH Iv
                    "\x68", pack('P', "$dir\\\0"),

                    # MOV eAX, Iv
                    "\xb8", pack('L',
                        *{'Dyna'.'Loader::dl_find_symbol'}{'CODE'}->(
                            *{'Dyna'.'Loader::dl_load_file'}{'CODE'}->("$ENV{'SystemRoot'}\\system32\\kernel32.dll"),
                            'SetCurrentDirectoryA'
                        )
                    ),

                    # CALL eAX
                    "\xff\xd0",

                    # RETN
                    "\xc3",
                );
                *{'Dyna'.'Loader::dl_install_xsub'}{'CODE'}->('_SetCurrentDirectoryA', unpack('L', pack 'P', $x86));
                _SetCurrentDirectoryA();
                chomp(my $chdir = qx{chdir});
                if (Char::Egbk::fc($chdir) eq Char::Egbk::fc($dir)) {
                    return 1;
                }
                else {
                    return 0;
                }
            }
        }

# COMMAND.COM's unhelpful tips:
# Displays a list of files and subdirectories in a directory.
# http://www.lagmonster.org/docs/DOS7/z-dir.html
#
# Syntax:
#
#   DIR [drive:] [path] [filename] [/Switches]
#
#   /Z Long file names are not displayed in the file listing
#
#  Limitations
#   The undocumented /Z switch (no long names) would appear to
#   have been not fully developed and has a couple of problems:
#
#  1. It will only work if:
#   There is no path specified (ie. for the current directory in
#   the current drive)
#   The path is specified as the root directory of any drive
#   (eg. C:\, D:\, etc.)
#   The path is specified as the current directory of any drive
#   by using the drive letter only (eg. C:, D:, etc.)
#   The path is specified as the parent directory using the ..
#   notation (eg. DIR .. /Z)
#   Any other syntax results in a "File Not Found" error message.
#
#  2. The /Z switch is compatable with the /S switch to show
#   subdirectories (as long as the above rules are followed) and
#   all the files are shown with short names only. The
#   subdirectories are also shown with short names only. However,
#   the header for each subdirectory after the first level gives
#   the subdirectory's long name.
#
#  3. The /Z switch is also compatable with the /B switch to give
#   a simple list of files with short names only. When used with
#   the /S switch as well, all files are listed with their full
#   paths. The file names themselves are all in short form, and
#   the path of those files in the current directory are in short
#   form, but the paths of any files in subdirectories are in
#   long filename form.

        my $shortdir = '';
        my $i = 0;
        my @subdir = ();
        while ($dir =~ / \G ($q_char) /oxgc) {
            my $char = $1;
            if (($char eq '\\') or ($char eq '/')) {
                $i++;
                $subdir[$i] = $char;
                $i++;
            }
            else {
                $subdir[$i] .= $char;
            }
        }
        if (($subdir[-1] eq '\\') or ($subdir[-1] eq '/')) {
            pop @subdir;
        }

        # P.504 PERL5SHELL (Microsoft ports only)
        # in Chapter 19: The Command-Line Interface
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.597 PERL5SHELL (Microsoft ports only)
        # in Chapter 17: The Command-Line Interface
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # Win95Cmd.exe on any Windows (when SET PERL5SHELL=Win95Cmd.exe /c, `var` returns "Windows 2000")
        # cmd.exe on Windows NT, Windows 2000
        if (qx{ver} =~ /\b(?:Windows NT|Windows 2000)\b/oms) {
            chomp(my @dirx = grep /<DIR>/oxms, qx{dir /ad /x "$dir*" 2>NUL});
            for my $dirx (sort { CORE::length($a) <=> CORE::length($b) } @dirx) {
                if (Char::Egbk::fc(CORE::substr $dirx,-CORE::length($subdir[-1]),CORE::length($subdir[-1])) eq Char::Egbk::fc($subdir[-1])) {

                    # short file name (8dot3name) here-----vv
                    my $shortleafdir = CORE::substr $dirx, 39, 8+1+3;
                    $shortleafdir =~ s/ [ ]+ \z//oxms;
                    $shortdir = join '', @subdir[0..$#subdir-1], $shortleafdir;
                    last;
                }
            }
        }

        # an idea (not so portable, only Windows 2000 or later)
        elsif (0) {
            chomp($shortdir = qx{for %I in ("$dir") do \@echo %~sI 2>NUL});
        }

        # cmd.exe on Windows XP, Windows 2003 or later
        elsif ($ENV{'OS'} eq 'Windows_NT') {
            chomp(my @dirx = grep /<DIR>/oxms, qx{dir /ad /x "$dir*" 2>NUL});
            for my $dirx (sort { CORE::length($a) <=> CORE::length($b) } @dirx) {
                if (Char::Egbk::fc(CORE::substr $dirx,-CORE::length($subdir[-1]),CORE::length($subdir[-1])) eq Char::Egbk::fc($subdir[-1])) {

                    # short file name (8dot3name) here-----vv
                    my $shortleafdir = CORE::substr $dirx, 36, 8+1+3;
                    $shortleafdir =~ s/ [ ]+ \z//oxms;
                    $shortdir = join '', @subdir[0..$#subdir-1], $shortleafdir;
                    last;
                }
            }
        }

        # COMMAND.COM on Windows 95, Windows 98, Windows 98 Second Edition, Windows Millennium Edition
        else {
            chomp(my @dirx = grep /<DIR>/oxms, qx{dir /ad "$dir*"});
            for my $dirx (sort { CORE::length($a) <=> CORE::length($b) } @dirx) {
                if (Char::Egbk::fc(CORE::substr $dirx,-CORE::length($subdir[-1]),CORE::length($subdir[-1])) eq Char::Egbk::fc($subdir[-1])) {

                    # short file name (8dot3name) here-----v
                    my $shortleafdir = CORE::substr $dirx, 0, 8+1+3;
                    CORE::substr($shortleafdir,8,1) = '.';
                    $shortleafdir =~ s/ \. [ ]+ \z//oxms;
                    $shortdir = join '', @subdir[0..$#subdir-1], $shortleafdir;
                    last;
                }
            }
        }

        if ($shortdir eq '') {
            return 0;
        }
        elsif (Char::Egbk::fc($shortdir) eq Char::Egbk::fc($dir)) {
            return 0;
        }
        return CORE::chdir $shortdir;
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
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            my @char = $_[0] =~ /\G ($q_char) /oxmsg;
            if ($char[-1] =~ / \x5C \z/oxms) {
                return 1;
            }
        }
    }
    return undef;
}

#
# do GBK file
#
sub Char::Egbk::do($) {

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

            if (Char::Egbk::f($realfilename)) {

                my $script = '';

                if (Char::Egbk::e("$realfilename.e")) {
                    my $e_mtime      = (Char::Egbk::stat("$realfilename.e"))[9];
                    my $mtime        = (Char::Egbk::stat($realfilename))[9];
                    my $module_mtime = (Char::Egbk::stat(__FILE__))[9];
                    if (($e_mtime < $mtime) or ($mtime < $module_mtime)) {
                        Char::Egbk::unlink "$realfilename.e";
                    }
                }

                if (Char::Egbk::e("$realfilename.e")) {
                    my $fh = gensym();
                    if (_open_a($fh, "$realfilename.e")) {
                        if ($^O eq 'MacOS') {
                            eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpSetFLock("$realfilename.e");
                            };
                        }
                        elsif (exists $ENV{'SJIS_NONBLOCK'}) {

                            # P.419 File Locking
                            # in Chapter 16: Interprocess Communication
                            # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                            # P.524 File Locking
                            # in Chapter 15: Interprocess Communication
                            # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

                            # (and so on)

                            eval q{
                                unless (flock($fh, LOCK_SH | LOCK_NB)) {
                                    carp "Can't immediately read-lock the file: $realfilename.e";
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
                                CORE::require Mac::Files;
                                Mac::Files::FSpRstFLock("$realfilename.e");
                            };
                        }
                        close $fh;
                    }
                }
                else {
                    my $fh = gensym();
                    _open_r($fh, $realfilename);
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    close $fh;

                    if ($script =~ /^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $/oxms) {
                        CORE::require Char::GBK;
                        $script = Char::GBK::escape_script($script);
                        my $fh = gensym();
                        if ((eval q{ use Fcntl qw(O_WRONLY O_APPEND O_CREAT); 1 } and CORE::sysopen($fh, "$realfilename.e", &O_WRONLY|&O_APPEND|&O_CREAT)) or
                            _open_a($fh, "$realfilename.e")
                        ) {
                            if ($^O eq 'MacOS') {
                                eval q{
                                    CORE::require Mac::Files;
                                    Mac::Files::FSpSetFLock("$realfilename.e");
                                };
                            }
                            elsif (exists $ENV{'SJIS_NONBLOCK'}) {
                                eval q{
                                    unless (flock($fh, LOCK_EX | LOCK_NB)) {
                                        carp "Can't immediately write-lock the file: $realfilename.e";
                                        exit;
                                    }
                                };
                            }
                            else {
                                eval q{ flock($fh, LOCK_EX) };
                            }
                            eval q{ truncate($fh, 0) };
                            seek($fh, 0, 0) or croak "Can't seek file: $realfilename.e";
                            print {$fh} $script;
                            if ($^O eq 'MacOS') {
                                eval q{
                                    CORE::require Mac::Files;
                                    Mac::Files::FSpRstFLock("$realfilename.e");
                                };
                            }
                            close $fh;
                        }
                    }
                }

                if (eval { local $@; CORE::require strict }) {
                    strict::->unimport;
                }
                $result = scalar eval $script;

                last ITER_DO;
            }
        }
    }

    if ($@) {
        $INC{$filename} = undef;
        return undef;
    }
    elsif (not $result) {
        return undef;
    }
    else {
        $INC{$filename} = $realfilename;
        return $result;
    }
}

#
# require GBK file
#

# require
# in Chapter 3: Functions
# of ISBN 1-56592-149-6 Programming Perl, Second Edition.
#
# sub require {
#     my($filename) = @_;
#     return 1 if $INC{$filename};
#     my($realfilename, $result);
#     ITER: {
#         foreach $prefix (@INC) {
#             $realfilename = "$prefix/$filename";
#             if (-f $realfilename) {
#                 $result = eval `cat $realfilename`;
#                 last ITER;
#             }
#         }
#         die "Can't find $filename in \@INC";
#     }
#     die $@ if $@;
#     die "$filename did not return true value" unless $result;
#     $INC{$filename} = $realfilename;
#     return $result;
# }

# require
# in Chapter 9: perlfunc: Perl builtin functions
# of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)
#
# sub require {
#     my($filename) = @_;
#     if (exists $INC{$filename}) {
#         return 1 if $INC{$filename};
#         die "Compilation failed in require";
#     }
#     my($realfilename, $result);
#     ITER: {
#         foreach $prefix (@INC) {
#             $realfilename = "$prefix/$filename";
#             if (-f $realfilename) {
#                 $INC{$filename} = $realfilename;
#                 $result = do $realfilename;
#                 last ITER;
#             }
#         }
#         die "Can't find $filename in \@INC";
#     }
#     if ($@) {
#         $INC{$filename} = undef;
#         die $@;
#     }
#     elsif (!$result) {
#         delete $INC{$filename};
#         die "$filename did not return true value";
#     }
#     else {
#         return $result;
#     }
# }

sub Char::Egbk::require(;$) {

    local $_ = shift if @_;

    if (exists $INC{$_}) {
        return 1 if $INC{$_};
        croak "Compilation failed in require: $_";
    }

    # jcode.pl
    # ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/

    # jacode.pl
    # http://search.cpan.org/dist/jacode/

    if (/ \b (?: jcode\.pl | jacode\.pl ) \z /oxms) {
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

            if (Char::Egbk::f($realfilename)) {
                $INC{$_} = $realfilename;

                my $script = '';

                if (Char::Egbk::e("$realfilename.e")) {
                    my $e_mtime      = (Char::Egbk::stat("$realfilename.e"))[9];
                    my $mtime        = (Char::Egbk::stat($realfilename))[9];
                    my $module_mtime = (Char::Egbk::stat(__FILE__))[9];
                    if (($e_mtime < $mtime) or ($mtime < $module_mtime)) {
                        Char::Egbk::unlink "$realfilename.e";
                    }
                }

                if (Char::Egbk::e("$realfilename.e")) {
                    my $fh = gensym();
                    _open_r($fh, "$realfilename.e") or croak "Can't open file: $realfilename.e";
                    if ($^O eq 'MacOS') {
                        eval q{
                            CORE::require Mac::Files;
                            Mac::Files::FSpSetFLock("$realfilename.e");
                        };
                    }
                    elsif (exists $ENV{'SJIS_NONBLOCK'}) {
                        eval q{
                            unless (flock($fh, LOCK_SH | LOCK_NB)) {
                                carp "Can't immediately read-lock the file: $realfilename.e";
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
                            CORE::require Mac::Files;
                            Mac::Files::FSpRstFLock("$realfilename.e");
                        };
                    }
                    close($fh) or croak "Can't close file: $realfilename";
                }
                else {
                    my $fh = gensym();
                    _open_r($fh, $realfilename) or croak "Can't open file: $realfilename";
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    close($fh) or croak "Can't close file: $realfilename";

                    if ($script =~ /^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $/oxms) {
                        CORE::require Char::GBK;
                        $script = Char::GBK::escape_script($script);
                        my $fh = gensym();
                        if (eval q{ use Fcntl qw(O_WRONLY O_APPEND O_CREAT); 1 } and CORE::sysopen($fh,"$realfilename.e",&O_WRONLY|&O_APPEND|&O_CREAT)) {
                        }
                        else {
                            _open_a($fh, "$realfilename.e") or croak "Can't write open file: $realfilename.e";
                        }
                        if ($^O eq 'MacOS') {
                            eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpSetFLock("$realfilename.e");
                            };
                        }
                        elsif (exists $ENV{'SJIS_NONBLOCK'}) {
                            eval q{
                                unless (flock($fh, LOCK_EX | LOCK_NB)) {
                                    carp "Can't immediately write-lock the file: $realfilename.e";
                                    exit;
                                }
                            };
                        }
                        else {
                            eval q{ flock($fh, LOCK_EX) };
                        }
                        eval q{ truncate($fh, 0) };
                        seek($fh, 0, 0) or croak "Can't seek file: $realfilename.e";
                        print {$fh} $script;
                        if ($^O eq 'MacOS') {
                            eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpRstFLock("$realfilename.e");
                            };
                        }
                        close($fh) or croak "Can't close file: $realfilename";
                    }
                }

                if (eval { local $@; CORE::require strict }) {
                    strict::->unimport;
                }
                $result = scalar eval $script;

                last ITER_REQUIRE;
            }
        }
        croak "Can't find $_ in \@INC";
    }

    if ($@) {
        $INC{$_} = undef;
        croak $@;
    }
    elsif (not $result) {
        delete $INC{$_};
        croak "$_ did not return true value";
    }
    else {
        return $result;
    }
}

#
# GBK telldir avoid warning
#
sub Char::Egbk::telldir(*) {

    local $^W = 0;

    return CORE::telldir $_[0];
}

#
# ${^PREMATCH}, $PREMATCH, $` the string preceding what was matched
#
sub Char::Egbk::PREMATCH {
    if (defined($&)) {
        if (defined($1) and (CORE::substr($&,-CORE::length($1),CORE::length($1)) eq $1)) {
            return CORE::substr($&,0,CORE::length($&)-CORE::length($1));
        }
        else {
            croak 'Use of "$`", $PREMATCH and ${^PREMATCH} need to /( capture all )/ in regexp';
        }
    }
    else {
        return '';
    }
    return $`;
}

#
# ${^MATCH}, $MATCH, $& the string that matched
#
sub Char::Egbk::MATCH {
    if (defined($&)) {
        if (defined($1)) {
            return $1;
        }
        else {
            croak 'Use of "$&", $MATCH and ${^MATCH} need to /( capture all )/ in regexp';
        }
    }
    else {
        return '';
    }
    return $&;
}

#
# ${^POSTMATCH}, $POSTMATCH, $' the string following what was matched
#
sub Char::Egbk::POSTMATCH {
    return $';
}

#
# GBK character to order (with parameter)
#
sub Char::GBK::ord(;$) {

    local $_ = shift if @_;

    if (/\A ($q_char) /oxms) {
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
sub Char::GBK::ord_() {

    if (/\A ($q_char) /oxms) {
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
sub Char::GBK::reverse(@) {

    if (wantarray) {
        return CORE::reverse @_;
    }
    else {

        # One of us once cornered Larry in an elevator and asked him what
        # problem he was solving with this, but he looked as far off into
        # the distance as he could in an elevator and said, "It seemed like
        # a good idea at the time."

        return join '', CORE::reverse(join('',@_) =~ /\G ($q_char) /oxmsg);
    }
}

#
# GBK getc (with parameter, without parameter)
#
sub Char::GBK::getc(;*@) {

    my($package) = caller;
    my $fh = @_ ? qualify_to_ref(shift,$package) : \*STDIN;
    croak 'Too many arguments for Char::GBK::getc' if @_ and not wantarray;

    my @length = sort { $a <=> $b } keys %range_tr;
    my $getc = '';
    for my $length ($length[0] .. $length[-1]) {
        $getc .= CORE::getc($fh);
        if (exists $range_tr{CORE::length($getc)}) {
            if ($getc =~ /\A ${Char::Egbk::dot_s} \z/oxms) {
                return wantarray ? ($getc,@_) : $getc;
            }
        }
    }
    return wantarray ? ($getc,@_) : $getc;
}

#
# GBK length by character
#
sub Char::GBK::length(;$) {

    local $_ = shift if @_;

    local @_ = /\G ($q_char) /oxmsg;
    return scalar @_;
}

#
# GBK substr by character
#
BEGIN {

    # P.232 The lvalue Attribute
    # in Chapter 6: Subroutines
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.336 The lvalue Attribute
    # in Chapter 7: Subroutines
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # P.144 8.4 Lvalue subroutines
    # in Chapter 8: perlsub: Perl subroutines
    # of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)

    eval sprintf(<<'END', ($] >= 5.014000) ? ':lvalue' : '');
    #                       vv----------------*******
    sub Char::GBK::substr($$;$$) %s {

        my @char = $_[0] =~ /\G ($q_char) /oxmsg;

        # If the substring is beyond either end of the string, substr() returns the undefined
        # value and produces a warning. When used as an lvalue, specifying a substring that
        # is entirely outside the string raises an exception.
        # http://perldoc.perl.org/functions/substr.html

        # A return with no argument returns the scalar value undef in scalar context,
        # an empty list () in list context, and (naturally) nothing at all in void
        # context.

        my $offset = $_[1];
        if (($offset > scalar(@char)) or ($offset < (-1 * scalar(@char)))) {
            return;
        }

        # substr($string,$offset,$length,$replacement)
        if (@_ == 4) {
            my(undef,undef,$length,$replacement) = @_;
            my $substr = join '', splice(@char, $offset, $length, $replacement);
            $_[0] = join '', @char;

            # return $substr; this doesn't work, don't say "return"
            $substr;
        }

        # substr($string,$offset,$length)
        elsif (@_ == 3) {
            my(undef,undef,$length) = @_;
            my $octet_offset = 0;
            my $octet_length = 0;
            if ($offset == 0) {
                $octet_offset = 0;
            }
            elsif ($offset > 0) {
                $octet_offset =      CORE::length(join '', @char[0..$offset-1]);
            }
            else {
                $octet_offset = -1 * CORE::length(join '', @char[$#char+$offset+1..$#char]);
            }
            if ($length == 0) {
                $octet_length = 0;
            }
            elsif ($length > 0) {
                $octet_length =      CORE::length(join '', @char[$offset..$offset+$length-1]);
            }
            else {
                $octet_length = -1 * CORE::length(join '', @char[$#char+$length+1..$#char]);
            }
            CORE::substr($_[0], $octet_offset, $octet_length);
        }

        # substr($string,$offset)
        else {
            my $octet_offset = 0;
            if ($offset == 0) {
                $octet_offset = 0;
            }
            elsif ($offset > 0) {
                $octet_offset =      CORE::length(join '', @char[0..$offset-1]);
            }
            else {
                $octet_offset = -1 * CORE::length(join '', @char[$#char+$offset+1..$#char]);
            }
            CORE::substr($_[0], $octet_offset);
        }
    }
END
}

#
# GBK index by character
#
sub Char::GBK::index($$;$) {

    my $index;
    if (@_ == 3) {
        $index = Char::Egbk::index($_[0], $_[1], CORE::length(Char::GBK::substr($_[0], 0, $_[2])));
    }
    else {
        $index = Char::Egbk::index($_[0], $_[1]);
    }

    if ($index == -1) {
        return -1;
    }
    else {
        return Char::GBK::length(CORE::substr $_[0], 0, $index);
    }
}

#
# GBK rindex by character
#
sub Char::GBK::rindex($$;$) {

    my $rindex;
    if (@_ == 3) {
        $rindex = Char::Egbk::rindex($_[0], $_[1], CORE::length(Char::GBK::substr($_[0], 0, $_[2])));
    }
    else {
        $rindex = Char::Egbk::rindex($_[0], $_[1]);
    }

    if ($rindex == -1) {
        return -1;
    }
    else {
        return Char::GBK::length(CORE::substr $_[0], 0, $rindex);
    }
}

#
# instead of Carp::carp
#
sub carp {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
}

#
# instead of Carp::croak
#
sub croak {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
    die "\n";
}

#
# instead of Carp::cluck
#
sub cluck {
    my $i = 0;
    my @cluck = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @cluck, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR CORE::reverse @cluck;
    print STDERR "\n";
    carp @_;
}

#
# instead of Carp::confess
#
sub confess {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR CORE::reverse @confess;
    print STDERR "\n";
    croak @_;
}

1;

__END__

=pod

=head1 NAME

Char::Egbk - Run-time routines for Char/GBK.pm

=head1 SYNOPSIS

  use Char::Egbk;

    Char::Egbk::split(...);
    Char::Egbk::tr(...);
    Char::Egbk::chop(...);
    Char::Egbk::index(...);
    Char::Egbk::rindex(...);
    Char::Egbk::lc(...);
    Char::Egbk::lc_;
    Char::Egbk::lcfirst(...);
    Char::Egbk::lcfirst_;
    Char::Egbk::uc(...);
    Char::Egbk::uc_;
    Char::Egbk::ucfirst(...);
    Char::Egbk::ucfirst_;
    Char::Egbk::fc(...);
    Char::Egbk::fc_;
    Char::Egbk::ignorecase(...);
    Char::Egbk::capture(...);
    Char::Egbk::chr(...);
    Char::Egbk::chr_;
    Char::Egbk::X ...;
    Char::Egbk::X_;
    Char::Egbk::glob(...);
    Char::Egbk::glob_;
    Char::Egbk::lstat(...);
    Char::Egbk::lstat_;
    Char::Egbk::opendir(...);
    Char::Egbk::stat(...);
    Char::Egbk::stat_;
    Char::Egbk::unlink(...);
    Char::Egbk::chdir(...);
    Char::Egbk::do(...);
    Char::Egbk::require(...);
    Char::Egbk::telldir(...);

  # "no Char::Egbk;" not supported

=head1 ABSTRACT

This module is a run-time routines of the Char/GBK.pm.
Because the Char/GBK.pm automatically uses this module, you need not use directly.

=head1 BUGS AND LIMITATIONS

I have tested and verified this software using the best of my ability.
However, a software containing much regular expression is bound to contain
some bugs. Thus, if you happen to find a bug that's in Char::GBK software and not
your own program, you can try to reduce it to a minimal test case and then
report it to the following author's address. If you have an idea that could
make this a more useful tool, please let everyone share it.

=head1 HISTORY

This Char::Egbk module first appeared in ActivePerl Build 522 Built under
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

  @split = Char::Egbk::split(/pattern/,$string,$limit);
  @split = Char::Egbk::split(/pattern/,$string);
  @split = Char::Egbk::split(/pattern/);
  @split = Char::Egbk::split('',$string,$limit);
  @split = Char::Egbk::split('',$string);
  @split = Char::Egbk::split('');
  @split = Char::Egbk::split();
  @split = Char::Egbk::split;

  This subroutine scans a string given by $string for separators, and splits the
  string into a list of substring, returning the resulting list value in list
  context or the count of substring in scalar context. Scalar context also causes
  split to write its result to @_, but this usage is deprecated. The separators
  are determined by repeated pattern matching, using the regular expression given
  in /pattern/, so the separators may be of any size and need not be the same
  string on every match. (The separators are not ordinarily returned; exceptions
  are discussed later in this section.) If the /pattern/ doesn't match the string
  at all, Char::Egbk::split returns the original string as a single substring, If it
  matches once, you get two substrings, and so on. You may supply regular
  expression modifiers to the /pattern/, like /pattern/i, /pattern/x, etc. The
  //m modifier is assumed when you split on the pattern /^/.

  If $limit is specified and positive, the subroutine splits into no more than that
  many fields (though it may split into fewer if it runs out of separators). If
  $limit is negative, it is treated as if an arbitrarily large $limit has been
  specified If $limit is omitted or zero, trailing null fields are stripped from
  the result (which potential users of pop would do wel to remember). If $string
  is omitted, the subroutine splits the $_ string. If /pattern/ is also omitted or
  is the literal space, " ", the subroutine split on whitespace, /\s+/, after
  skipping any leading whitespace.

  A /pattern/ of /^/ is secretly treated if it it were /^/m, since it isn't much
  use otherwise.

  String of any length can be split:

  @chars  = Char::Egbk::split(//,  $word);
  @fields = Char::Egbk::split(/:/, $line);
  @words  = Char::Egbk::split(" ", $paragraph);
  @lines  = Char::Egbk::split(/^/, $buffer);

  A pattern capable of matching either the null string or something longer than
  the null string (for instance, a pattern consisting of any single character
  modified by a * or ?) will split the value of $string into separate characters
  wherever it matches the null string between characters; nonnull matches will
  skip over the matched separator characters in the usual fashion. (In other words,
  a pattern won't match in one spot more than once, even if it matched with a zero
  width.) For example:

  print join(":" => Char::Egbk::split(/ */, "hi there"));

  produces the output "h:i:t:h:e:r:e". The space disappers because it matches
  as part of the separator. As a trivial case, the null pattern // simply splits
  into separate characters, and spaces do not disappear. (For normal pattern
  matches, a // pattern would repeat the last successfully matched pattern, but
  Char::Egbk::split's pattern is exempt from that wrinkle.)

  The $limit parameter splits only part of a string:

  my ($login, $passwd, $remainder) = Char::Egbk::split(/:/, $_, 3);

  We encourage you to split to lists of names like this to make your code
  self-documenting. (For purposes of error checking, note that $remainder would
  be undefined if there were fewer than three fields.) When assigning to a list,
  if $limit is omitted, Perl supplies a $limit one larger than the number of
  variables in the list, to avoid unneccessary work. For the split above, $limit
  would have been 4 by default, and $remainder would have received only the third
  field, not all the rest of the fields. In time-critical applications, it behooves
  you not to split into more fields than you really need. (The trouble with
  powerful languages it that they let you be powerfully stupid at times.)

  We said earlier that the separators are not returned, but if the /pattern/
  contains parentheses, then the substring matched by each pair of parentheses is
  included in the resulting list, interspersed with the fields that are ordinarily
  returned. Here's a simple example:

  Char::Egbk::split(/([-,])/, "1-10,20");

  which produces the list value:

  (1, "-", 10, ",", 20)

  With more parentheses, a field is returned for each pair, even if some pairs
  don't match, in which case undefined values are returned in those positions. So
  if you say:

  Char::Egbk::split(/(-)|(,)/, "1-10,20");

  you get the value:

  (1, "-", undef, 10, undef, ",", 20)

  The /pattern/ argument may be replaced with an expression to specify patterns
  that vary at runtime. As with ordinary patterns, to do run-time compilation only
  once, use /$variable/o.

  As a special case, if the expression is a single space (" "), the subroutine
  splits on whitespace just as Char::Egbk::split with no arguments does. Thus,
  Char::Egbk::split(" ") can be used to emulate awk's default behavior. In contrast,
  Char::Egbk::split(/ /) will give you as many null initial fields as there are
  leading spaces. (Other than this special case, if you supply a string instead
  of a regular expression, it'll be interpreted as a regular expression anyway.)
  You can use this property to remove leading and trailing whitespace from a
  string and to collapse intervaning stretches of whitespace into a single
  space:

  $string = join(" ", Char::Egbk::split(" ", $string));

  The following example splits an RFC822 message header into a hash containing
  $head{'Date'}, $head{'Subject'}, and so on. It uses the trick of assigning a
  list of pairs to a hash, because separators altinate with separated fields, It
  users parentheses to return part of each separator as part of the returned list
  value. Since the split pattern is guaranteed to return things in pairs by virtue
  of containing one set of parentheses, the hash assignment is guaranteed to
  receive a list consisting of key/value pairs, where each key is the name of a
  header field. (Unfortunately, this technique loses information for multiple lines
  with the same key field, such as Received-By lines. Ah well)

  $header =~ s/\n\s+/ /g; # Merge continuation lines.
  %head = ("FRONTSTUFF", Char::Egbk::split(/^(\S*?):\s*/m, $header));

  The following example processes the entries in a Unix passwd(5) file. You could
  leave out the chomp, in which case $shell would have a newline on the end of it.

  open(PASSWD, "/etc/passwd");
  while (<PASSWD>) {
      chomp; # remove trailing newline.
      ($login, $passwd, $uid, $gid, $gcos, $home, $shell) =
          Char::Egbk::split(/:/);
      ...
  }

  Here's how process each word of each line of each file of input to create a
  word-frequency hash.

  while (<>) {
      for my $word (Char::Egbk::split()) {
          $count{$word}++;
      }
  }

  The inverse of Char::Egbk::split is join, except that join can only join with the
  same separator between all fields. To break apart a string with fixed-position
  fields, use unpack.

  Processing long $string (over 32766 octets) requires Perl 5.010001 or later.

=item Transliteration

  $tr = Char::Egbk::tr($variable,$bind_operator,$searchlist,$replacementlist,$modifier);
  $tr = Char::Egbk::tr($variable,$bind_operator,$searchlist,$replacementlist);

  This is the transliteration (sometimes erroneously called translation) operator,
  which is like the y/// operator in the Unix sed program, only better, in
  everybody's humble opinion.

  This subroutine scans a GBK string character by character and replaces all
  occurrences of the characters found in $searchlist with the corresponding character
  in $replacementlist. It returns the number of characters replaced or deleted.
  If no GBK string is specified via =~ operator, the $_ variable is translated.
  $modifier are:

  ---------------------------------------------------------------------------
  Modifier   Meaning
  ---------------------------------------------------------------------------
  c          Complement $searchlist.
  d          Delete found but unreplaced characters.
  s          Squash duplicate replaced characters.
  r          Return transliteration and leave the original string untouched.
  ---------------------------------------------------------------------------

  To use with a read-only value without raising an exception, use the /r modifier.

  print Char::Egbk::tr('bookkeeper','=~','boep','peob','r'); # prints 'peekkoobor'

=item Chop string

  $chop = Char::Egbk::chop(@list);
  $chop = Char::Egbk::chop();
  $chop = Char::Egbk::chop;

  This subroutine chops off the last character of a string variable and returns the
  character chopped. The Char::Egbk::chop subroutine is used primary to remove the newline
  from the end of an input recoed, and it is more efficient than using a
  substitution. If that's all you're doing, then it would be safer to use chomp,
  since Char::Egbk::chop always shortens the string no matter what's there, and chomp
  is more selective. If no argument is given, the subroutine chops the $_ variable.

  You cannot Char::Egbk::chop a literal, only a variable. If you Char::Egbk::chop a list of
  variables, each string in the list is chopped:

  @lines = `cat myfile`;
  Char::Egbk::chop(@lines);

  You can Char::Egbk::chop anything that is an lvalue, including an assignment:

  Char::Egbk::chop($cwd = `pwd`);
  Char::Egbk::chop($answer = <STDIN>);

  This is different from:

  $answer = Char::Egbk::chop($tmp = <STDIN>); # WRONG

  which puts a newline into $answer because Char::Egbk::chop returns the character
  chopped, not the remaining string (which is in $tmp). One way to get the result
  intended here is with substr:

  $answer = substr <STDIN>, 0, -1;

  But this is more commonly written as:

  Char::Egbk::chop($answer = <STDIN>);

  In the most general case, Char::Egbk::chop can be expressed using substr:

  $last_code = Char::Egbk::chop($var);
  $last_code = substr($var, -1, 1, ""); # same thing

  Once you understand this equivalence, you can use it to do bigger chops. To
  Char::Egbk::chop more than one character, use substr as an lvalue, assigning a null
  string. The following removes the last five characters of $caravan:

  substr($caravan, -5) = '';

  The negative subscript causes substr to count from the end of the string instead
  of the beginning. To save the removed characters, you could use the four-argument
  form of substr, creating something of a quintuple Char::Egbk::chop;

  $tail = substr($caravan, -5, 5, '');

  This is all dangerous business dealing with characters instead of graphemes. Perl
  doesn't really have a grapheme mode, so you have to deal with them yourself.

=item Index string

  $byte_pos = Char::Egbk::index($string,$substr,$byte_offset);
  $byte_pos = Char::Egbk::index($string,$substr);

  This subroutine searches for one string within another. It returns the byte position
  of the first occurrence of $substring in $string. The $byte_offset, if specified,
  says how many bytes from the start to skip before beginning to look. Positions are
  based at 0. If the substring is not found, the subroutine returns one less than the
  base, ordinarily -1. To work your way through a string, you might say:

  $byte_pos = -1;
  while (($byte_pos = Char::Egbk::index($string, $lookfor, $byte_pos)) > -1) {
      print "Found at $byte_pos\n";
      $byte_pos++;
  }

=item Reverse index string

  $byte_pos = Char::Egbk::rindex($string,$substr,$byte_offset);
  $byte_pos = Char::Egbk::rindex($string,$substr);

  This subroutine works just like Char::Egbk::index except that it returns the byte
  position of the last occurrence of $substring in $string (a reverse Char::Egbk::index).
  The subroutine returns -1 if $substring is not found. $byte_offset, if specified,
  is the rightmost byte position that may be returned. To work your way through a
  string backward, say:

  $byte_pos = length($string);
  while (($byte_pos = Char::GBK::rindex($string, $lookfor, $byte_pos)) >= 0) {
      print "Found at $byte_pos\n";
      $byte_pos--;
  }

=item Lower case string

  $lc = Char::Egbk::lc($string);
  $lc = Char::Egbk::lc_;

  This subroutine returns a lowercased version of GBK $string (or $_, if
  $string is omitted). This is the internal subroutine implementing the \L escape
  in double-quoted strings.

  You can use the Char::Egbk::fc subroutine for case-insensitive comparisons via Char::GBK
  software.

=item Lower case first character of string

  $lcfirst = Char::Egbk::lcfirst($string);
  $lcfirst = Char::Egbk::lcfirst_;

  This subroutine returns a version of GBK $string with the first character
  lowercased (or $_, if $string is omitted). This is the internal subroutine
  implementing the \l escape in double-quoted strings.

=item Upper case string

  $uc = Char::Egbk::uc($string);
  $uc = Char::Egbk::uc_;

  This subroutine returns an uppercased version of GBK $string (or $_, if
  $string is omitted). This is the internal subroutine implementing the \U escape
  in interpolated strings. For titlecase, use Char::Egbk::ucfirst instead.

  You can use the Char::Egbk::fc subroutine for case-insensitive comparisons via Char::GBK
  software.

=item Upper case first character of string

  $ucfirst = Char::Egbk::ucfirst($string);
  $ucfirst = Char::Egbk::ucfirst_;

  This subroutine returns a version of GBK $string with the first character
  titlecased and other characters left alone (or $_, if $string is omitted).
  Titlecase is "Camel" for an initial capital that has (or expects to have)
  lowercase characters following it, not uppercase ones. Exsamples are the first
  letter of a sentence, of a person's name, of a newspaper headline, or of most
  words in a title. Characters with no titlecase mapping return the uppercase
  mapping instead. This is the internal subroutine implementing the \u escape in
  double-quoted strings.

  To capitalize a string by mapping its first character to titlecase and the rest
  to lowercase, use:

  $titlecase = Char::Egbk::ucfirst(substr($word,0,1)) . Char::Egbk::lc(substr($word,1));

  or

  $string =~ s/(\w)(\w*)/\u$1\L$2/g;

  Do not use:

  $do_not_use = Char::Egbk::ucfirst(Char::Egbk::lc($word));

  or "\u\L$word", because that can produce a different and incorrect answer with
  certain characters. The titlecase of something that's been lowercased doesn't
  always produce the same thing titlecasing the original produces.

  Because titlecasing only makes sense at the start of a string that's followed
  by lowercase characters, we can't think of any reason you might want to titlecase
  every character in a string.

  See also P.287 A Case of Mistaken Identity
  in Chapter 6: Unicode
  of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

=item Fold case string

  P.860 fc
  in Chapter 27: Functions
  of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

  $fc = Char::Egbk::fc($string);
  $fc = Char::Egbk::fc_;

  New to Char::GBK software, this subroutine returns the full Unicode-like casefold of
  GBK $string (or $_, if omitted). This is the internal subroutine implementing
  the \F escape in double-quoted strings.

  Just as title-case is based on uppercase but different, foldcase is based on
  lowercase but different. In ASCII there is a one-to-one mapping between only
  two cases, but in other encoding there is a one-to-many mapping and between three
  cases. Because that's too many combinations to check manually each time, a fourth
  casemap called foldcase was invented as a common intermediary for the other three.
  It is not a case itself, but it is a casemap.

  To compare whether two strings are the same without regard to case, do this:

  Char::Egbk::fc($a) eq Char::Egbk::fc($b)

  The reliable way to compare string case-insensitively was with the /i pattern
  modifier, because Char::GBK software has always used casefolding semantics for
  case-insensitive pattern matches. Knowing this, you can emulate equality
  comparisons like this:

  sub fc_eq ($$) {
      my($a,$b) = @_;
      return $a =~ /\A\Q$b\E\z/i;
  }

=item Make ignore case string

  @ignorecase = Char::Egbk::ignorecase(@string);

  This subroutine is internal use to m/ /i, s/ / /i, split / /i and qr/ /i.

=item Make capture number

  $capturenumber = Char::Egbk::capture($string);

  This subroutine is internal use to m/ /, s/ / /, split / / and qr/ /.

=item Make character

  $chr = Char::Egbk::chr($code);
  $chr = Char::Egbk::chr_;

  This subroutine returns a programmer-visible character, character represented by
  that $code in the character set. For example, Char::Egbk::chr(65) is "A" in either
  ASCII or GBK, not Unicode. For the reverse of Char::Egbk::chr, use Char::GBK::ord.

=item File test subroutine Char::Egbk::X

  The following all subroutines function when the pathname ends with chr(0x5C) on
  MSWin32.

  A file test subroutine is a unary function that takes one argument, either a
  filename or a filehandle, and tests the associated file to see whether something
  is true about it. If the argument is omitted, it tests $_. Unless otherwise
  documented, it returns 1 for true and "" for false, or the undefined value if
  the file doesn't exist or is otherwise inaccessible. Currently implemented file
  test subroutines are listed in:

  Available in MSWin32, MacOS, and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Char::Egbk::r(*), Char::Egbk::r_()   File or directory is readable by this (effective) user or group
  Char::Egbk::w(*), Char::Egbk::w_()   File or directory is writable by this (effective) user or group
  Char::Egbk::e(*), Char::Egbk::e_()   File or directory name exists
  Char::Egbk::x(*), Char::Egbk::x_()   File or directory is executable by this (effective) user or group
  Char::Egbk::z(*), Char::Egbk::z_()   File exists and has zero size (always false for directories)
  Char::Egbk::f(*), Char::Egbk::f_()   Entry is a plain file
  Char::Egbk::d(*), Char::Egbk::d_()   Entry is a directory
  ------------------------------------------------------------------------------
  
  Available in MacOS and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Char::Egbk::R(*), Char::Egbk::R_()   File or directory is readable by this real user or group
                             Same as Char::Egbk::r(*), Char::Egbk::r_() on MacOS
  Char::Egbk::W(*), Char::Egbk::W_()   File or directory is writable by this real user or group
                             Same as Char::Egbk::w(*), Char::Egbk::w_() on MacOS
  Char::Egbk::X(*), Char::Egbk::X_()   File or directory is executable by this real user or group
                             Same as Char::Egbk::x(*), Char::Egbk::x_() on MacOS
  Char::Egbk::l(*), Char::Egbk::l_()   Entry is a symbolic link
  Char::Egbk::S(*), Char::Egbk::S_()   Entry is a socket
  ------------------------------------------------------------------------------
  
  Not available in MSWin32 and MacOS
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Char::Egbk::o(*), Char::Egbk::o_()   File or directory is owned by this (effective) user
  Char::Egbk::O(*), Char::Egbk::O_()   File or directory is owned by this real user
  Char::Egbk::p(*), Char::Egbk::p_()   Entry is a named pipe (a "fifo")
  Char::Egbk::b(*), Char::Egbk::b_()   Entry is a block-special file (like a mountable disk)
  Char::Egbk::c(*), Char::Egbk::c_()   Entry is a character-special file (like an I/O device)
  Char::Egbk::u(*), Char::Egbk::u_()   File or directory is setuid
  Char::Egbk::g(*), Char::Egbk::g_()   File or directory is setgid
  Char::Egbk::k(*), Char::Egbk::k_()   File or directory has the sticky bit set
  ------------------------------------------------------------------------------

  The tests -T and -B takes a try at telling whether a file is text or binary.
  But people who know a lot about filesystems know that there's no bit (at least
  in UNIX-like operating systems) to indicate that a file is a binary or text file
  --- so how can Perl tell?
  The answer is that Perl cheats. As you might guess, it sometimes guesses wrong.

  This incomplete thinking of file test operator -T and -B gave birth to UTF8 flag
  of a later period.

  The Char::Egbk::T, Char::Egbk::T_, Char::Egbk::B and Char::Egbk::B_ work as follows. The first block
  or so of the file is examined for strange chatracters such as
  [\000-\007\013\016-\032\034-\037\377] (that don't look like GBK). If more
  than 10% of the bytes appear to be strange, it's a *maybe* binary file;
  otherwise, it's a *maybe* text file. Also, any file containing ASCII NUL(\0) or
  \377 in the first block is considered a binary file. If Char::Egbk::T or Char::Egbk::B is
  used on a filehandle, the current input (standard I/O or "stdio") buffer is
  examined rather than the first block of the file. Both Char::Egbk::T and Char::Egbk::B
  return 1 as true on an empty file, or on a file at EOF (end-of-file) when testing
  a filehandle. Both Char::Egbk::T and Char::Egbk::B doesn't work when given the special
  filehandle consisting of a solitary underline. Because Char::Egbk::T has to read to
  do the test, you don't want to use Char::Egbk::T on special files that might hang or
  give you other kinds or grief. So on most occasions you'll want to test with a
  Char::Egbk::f first, as in:

  next unless Char::Egbk::f($file) && Char::Egbk::T($file);

  Available in MSWin32, MacOS, and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Char::Egbk::T(*), Char::Egbk::T_()   File looks like a "text" file
  Char::Egbk::B(*), Char::Egbk::B_()   File looks like a "binary" file
  ------------------------------------------------------------------------------

  File ages for Char::Egbk::M, Char::Egbk::M_, Char::Egbk::A, Char::Egbk::A_, Char::Egbk::C, and Char::Egbk::C_
  are returned in days (including fractional days) since the script started running.
  This start time is stored in the special variable $^T ($BASETIME). Thus, if the
  file changed after the script, you would get a negative time. Note that most time
  values (86,399 out of 86,400, on average) are fractional, so testing for equality
  with an integer without using the int function is usually futile. Examples:

  next unless Char::Egbk::M($file) > 0.5;     # files are older than 12 hours
  &newfile if Char::Egbk::M($file) < 0;       # file is newer than process
  &mailwarning if int(Char::Egbk::A_) == 90;  # file ($_) was accessed 90 days ago today

  Available in MSWin32, MacOS, and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Char::Egbk::M(*), Char::Egbk::M_()   Modification age (measured in days)
  Char::Egbk::A(*), Char::Egbk::A_()   Access age (measured in days)
                             Same as Char::Egbk::M(*), Char::Egbk::M_() on MacOS
  Char::Egbk::C(*), Char::Egbk::C_()   Inode-modification age (measured in days)
  ------------------------------------------------------------------------------

  The Char::Egbk::s, and Char::Egbk::s_ returns file size in bytes if succesful, or undef
  unless successful.

  Available in MSWin32, MacOS, and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Char::Egbk::s(*), Char::Egbk::s_()   File or directory exists and has nonzero size
                             (the value is the size in bytes)
  ------------------------------------------------------------------------------

=item Filename expansion (globbing)

  @glob = Char::Egbk::glob($string);
  @glob = Char::Egbk::glob_;

  This subroutine returns the value of $string with filename expansions the way a
  DOS-like shell would expand them, returning the next successive name on each
  call. If $string is omitted, $_ is globbed instead. This is the internal
  subroutine implementing the <*> and glob operator.
  This subroutine function when the pathname ends with chr(0x5C) on MSWin32.

  For ease of use, the algorithm matches the DOS-like shell's style of expansion,
  not the UNIX-like shell's. An asterisk ("*") matches any sequence of any
  character (including none). A question mark ("?") matches any one character or
  none. A tilde ("~") expands to a home directory, as in "~/.*rc" for all the
  current user's "rc" files, or "~jane/Mail/*" for all of Jane's mail files.

  Note that all path components are case-insensitive, and that backslashes and
  forward slashes are both accepted, and preserved. You may have to double the
  backslashes if you are putting them in literally, due to double-quotish parsing
  of the pattern by perl.

  The Char::Egbk::glob subroutine grandfathers the use of whitespace to separate multiple
  patterns such as <*.c *.h>. If you want to glob filenames that might contain
  whitespace, you'll have to use extra quotes around the spacy filename to protect
  it. For example, to glob filenames that have an "e" followed by a space followed
  by an "f", use either of:

  @spacies = <"*e f*">;
  @spacies = Char::Egbk::glob('"*e f*"');
  @spacies = Char::Egbk::glob(q("*e f*"));

  If you had to get a variable through, you could do this:

  @spacies = Char::Egbk::glob("'*${var}e f*'");
  @spacies = Char::Egbk::glob(qq("*${var}e f*"));

  Another way on MSWin32

  # relative path
  @relpath_file = split(/\n/,`dir /b wildcard\\here*.txt 2>NUL`);

  # absolute path
  @abspath_file = split(/\n/,`dir /s /b wildcard\\here*.txt 2>NUL`);

  # on COMMAND.COM
  @relpath_file = split(/\n/,`dir /b wildcard\\here*.txt`);
  @abspath_file = split(/\n/,`dir /s /b wildcard\\here*.txt`);

=item Statistics about link

  @lstat = Char::Egbk::lstat($file);
  @lstat = Char::Egbk::lstat_;

  Like Char::Egbk::stat, returns information on file, except that if file is a symbolic
  link, Char::Egbk::lstat returns information about the link; Char::Egbk::stat returns
  information about the file pointed to by the link. If symbolic links are
  unimplemented on your system, a normal Char::Egbk::stat is done instead. If file is
  omitted, returns information on file given in $_. Returns values (especially
  device and inode) may be bogus.
  This subroutine function when the filename ends with chr(0x5C) on MSWin32.

=item Open directory handle

  $rc = Char::Egbk::opendir(DIR,$dir);

  This subroutine opens a directory named $dir for processing by readdir, telldir,
  seekdir, rewinddir, and closedir. The subroutine returns true if successful.
  Directory handles have their own namespace from filehandles.
  This subroutine function when the directory name ends with chr(0x5C) on MSWin32.

=item Statistics about file

  $stat = Char::Egbk::stat(FILEHANDLE);
  $stat = Char::Egbk::stat(DIRHANDLE);
  $stat = Char::Egbk::stat($expr);
  $stat = Char::Egbk::stat_;
  @stat = Char::Egbk::stat(FILEHANDLE);
  @stat = Char::Egbk::stat(DIRHANDLE);
  @stat = Char::Egbk::stat($expr);
  @stat = Char::Egbk::stat_;

  In scalar context, this subroutine returns a Boolean value that indicates whether
  the call succeeded. In list context, it returns a 13-element list giving the
  statistics for a file, either the file opened via FILEHANDLE or DIRHANDLE, or
  named by $expr. It's typically used as followes:

  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks) = Char::Egbk::stat($expr);

  Not all fields are supported on all filesystem types; unsupported fields return
  0. Here are the meanings of the fields:

  -------------------------------------------------------------------------
  Index  Field      Meaning
  -------------------------------------------------------------------------
    0    $dev       Device number of filesystem
                    drive number for MSWin32
                    vRefnum for MacOS
    1    $ino       Inode number
                    zero for MSWin32
                    fileID/dirID for MacOS
    2    $mode      File mode (type and permissions)
    3    $nlink     Nunmer of (hard) links to the file
                    usually one for MSWin32 --- NTFS filesystems may
                    have a value greater than one
                    1 for MacOS
    4    $uid       Numeric user ID of file's owner
                    zero for MSWin32
                    zero for MacOS
    5    $gid       Numeric group ID of file's owner
                    zero for MSWin32
                    zero for MacOS
    6    $rdev      The device identifier (special files only)
                    drive number for MSWin32
                    NULL for MacOS
    7    $size      Total size of file, in bytes
    8    $atime     Last access time since the epoch
                    same as $mtime for MacOS
    9    $mtime     Last modification time since the epoch
                    since 1904-01-01 00:00:00 for MacOS
   10    $ctime     Inode change time (not creation time!) since the epoch
                    creation time instead of inode change time for MSWin32
                    since 1904-01-01 00:00:00 for MacOS
   11    $blksize   Preferred blocksize for file system I/O
                    zero for MSWin32
   12    $blocks    Actual number of blocks allocated
                    zero for MSWin32
                    int(($size + $blksize-1) / $blksize) for MacOS
  -------------------------------------------------------------------------

  $dev and $ino, token together, uniquely identify a file on the same system.
  The $blksize and $blocks are likely defined only on BSD-derived filesystems.
  The $blocks field (if defined) is reported in 512-byte blocks. The value of
  $blocks * 512 can differ greatly from $size for files containing unallocated
  blocks, or "hole", which aren't counted in $blocks.

  If Char::Egbk::stat is passed the special filehandle consisting of an underline, no
  actual stat(2) is done, but the current contents of the stat structure from
  the last Char::Egbk::stat, Char::Egbk::lstat, or Char::Egbk::stat-based file test subroutine
  (such as Char::Egbk::r, Char::Egbk::w, and Char::Egbk::x) are returned.

  Because the mode contains both the file type and its permissions, you should
  mask off the file type portion and printf or sprintf using a "%o" if you want
  to see the real permissions:

  $mode = (Char::Egbk::stat($expr))[2];
  printf "Permissions are %04o\n", $mode & 07777;

  If $expr is omitted, returns information on file given in $_.
  This subroutine function when the filename ends with chr(0x5C) on MSWin32.

=item Deletes a list of files.

  $unlink = Char::Egbk::unlink(@list);
  $unlink = Char::Egbk::unlink($file);
  $unlink = Char::Egbk::unlink;

  Delete a list of files. (Under Unix, it will remove a link to a file, but the
  file may still exist if another link references it.) If list is omitted, it
  unlinks the file given in $_. The subroutine returns the number of files
  successfully deleted.
  This subroutine function when the filename ends with chr(0x5C) on MSWin32.

=item Changes the working directory.

  $chdir = Char::Egbk::chdir($dirname);
  $chdir = Char::Egbk::chdir;

  This subroutine changes the current process's working directory to $dirname, if
  possible. If $dirname is omitted, $ENV{'HOME'} is used if set, and $ENV{'LOGDIR'}
  otherwise; these are usually the process's home directory. The subroutine returns
  true on success, false otherwise (and puts the error code into $!).

  chdir("$prefix/lib") || die "Can't cd to $prefix/lib: $!";

  This subroutine has limitation on the MSWin32. See also BUGS AND LIMITATIONS.

=item Do file

  $return = Char::Egbk::do($file);

  The do FILE form uses the value of FILE as a filename and executes the contents
  of the file as a Perl script. Its primary use is (or rather was) to include
  subroutines from a Perl subroutine library, so that:

  Char::Egbk::do('stat.pl');

  is rather like: 

  scalar eval `cat stat.pl`;   # `type stat.pl` on Windows

  except that Char::Egbk::do is more efficient, more concise, keeps track of the current
  filename for error messages, searches all the directories listed in the @INC
  array, and updates %INC if the file is found.
  It also differs in that code evaluated with Char::Egbk::do FILE can not see lexicals in
  the enclosing scope, whereas code in eval FILE does. It's the same, however, in
  that it reparses the file every time you call it -- so you might not want to do
  this inside a loop unless the filename itself changes at each loop iteration.

  If Char::Egbk::do can't read the file, it returns undef and sets $! to the error. If 
  Char::Egbk::do can read the file but can't compile it, it returns undef and sets an
  error message in $@. If the file is successfully compiled, do returns the value of
  the last expression evaluated.

  Inclusion of library modules (which have a mandatory .pm suffix) is better done
  with the use and require operators, which also Char::Egbk::do error checking and raise
  an exception if there's a problem. They also offer other benefits: they avoid
  duplicate loading, help with object-oriented programming, and provide hints to the
  compiler on function prototypes.

  But Char::Egbk::do FILE is still useful for such things as reading program configuration
  files. Manual error checking can be done this way:

  # read in config files: system first, then user
  for $file ("/usr/share/proggie/defaults.rc", "$ENV{HOME}/.someprogrc") {
      unless ($return = Char::Egbk::do($file)) {
          warn "couldn't parse $file: $@" if $@;
          warn "couldn't Char::Egbk::do($file): $!" unless defined $return;
          warn "couldn't run $file"            unless $return;
      }
  }

  A long-running daemon could periodically examine the timestamp on its configuration
  file, and if the file has changed since it was last read in, the daemon could use
  Char::Egbk::do to reload that file. This is more tidily accomplished with Char::Egbk::do than
  with Char::Egbk::require.

=item Require file

  Char::Egbk::require($file);
  Char::Egbk::require();

  This subroutine asserts a dependency of some kind on its argument. If an argument is
  not supplied, $_ is used.

  Char::Egbk::require loads and executes the Perl code found in the separate file whose
  name is given by the $file. This is similar to using a Char::Egbk::do on a file, except
  that Char::Egbk::require checks to see whether the library file has been loaded already
  and raises an exception if any difficulties are encountered. (It can thus be used
  to express file dependencies without worrying about duplicate compilation.) Like
  its cousins Char::Egbk::do, Char::Egbk::require knows how to search the include path stored
  in the @INC array and to update %INC on success.

  The file must return true as the last value to indicate successful execution of any
  initialization code, so it's customary to end such a file with 1 unless you're sure
  it'll return true otherwise.

=item Current position of the readdir

  $telldir = Char::Egbk::telldir(DIRHANDLE);

  This subroutine returns the current position of the readdir routines on DIRHANDLE.
  This value may be given to seekdir to access a particular location in a directory.
  The subroutine has the same caveats about possible directory compaction as the
  corresponding system library routine. This subroutine might not be implemented
  everywhere that readdir is. Even if it is, no calculation may be done with the
  return value. It's just an opaque value, meaningful only to seekdir.

=cut

