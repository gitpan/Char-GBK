package Char::GBK;
######################################################################
#
# Char::GBK - Source code filter to escape GBK script
#
# Copyright (c) 2008, 2009, 2010, 2011, 2012 INABA Hitoshi <ina@cpan.org>
#
######################################################################

use 5.00503;

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

# 12.3. Delaying use Until Runtime
# in Chapter 12. Packages, Libraries, and Modules
# of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
# (and so on)

BEGIN { eval q{ use vars qw($VERSION) } }
$VERSION = sprintf '%d.%02d', q$Revision: 0.83 $ =~ /(\d+)/oxmsg;

use Char::Egbk;

# poor Symbol.pm - substitute of real Symbol.pm
BEGIN {
    my $genpkg = "Symbol::";
    my $genseq = 0;
    sub gensym () {
        my $name = "GEN" . $genseq++;

        # here, no strict qw(refs); if strict.pm exists

        my $ref = \*{$genpkg . $name};
        delete $$genpkg{$name};
        $ref;
    }
}

# use strict; if strict.pm exists
BEGIN {
    if (eval {CORE::require strict}) {
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

# P.707 29.2.33. exec
# in Chapter 29: Functions
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# P.855 exec
# in Chapter 27: Functions
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

$| = 1;

sub import() {}
sub unimport() {}
sub Char::GBK::escape_script;

# regexp of character
my $your_char = q{[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]};
my $qq_char   = qr/\\c[\x40-\x5F]|\\?(?:$your_char)/oxms;
my  $q_char   = qr/$your_char/oxms;

# P.1023 Appendix W.9 Multibyte Anchoring
# of ISBN 1-56592-224-7 CJKV Information Processing

my $anchor = '';
$anchor = q{${Char::Egbk::anchor}};

BEGIN { eval q{ use vars qw($nest) } }

# regexp of nested parens in qqXX

# P.340 Matching Nested Constructs with Embedded Code
# in Chapter 7: Perl
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

my $qq_paren   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] |
                    \\? [\x81-\xFE][\x00-\xFF] |
                    \\ [\x00-\xFF] |
                    [^()] |
                             \(  (?{$nest++}) |
                             \)  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_brace   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] |
                    \\? [\x81-\xFE][\x00-\xFF] |
                    \\ [\x00-\xFF] |
                    [^{}] |
                             \{  (?{$nest++}) |
                             \}  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_bracket = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] |
                    \\? [\x81-\xFE][\x00-\xFF] |
                    \\ [\x00-\xFF] |
                    [^[\]] |
                             \[  (?{$nest++}) |
                             \]  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_angle   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] |
                    \\? [\x81-\xFE][\x00-\xFF] |
                    \\ [\x00-\xFF] |
                    [^<>] |
                             \<  (?{$nest++}) |
                             \>  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_scalar  = qr{(?: \{ (?:$qq_brace)*? \} |
                       (?: ::)? (?:
                             [a-zA-Z_][a-zA-Z_0-9]*
                       (?: ::[a-zA-Z_][a-zA-Z_0-9]* )* (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} )*
                                         (?: (?: -> )? (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} ) )*
                   ))
                 }xms;
my $qq_variable = qr{(?: \{ (?:$qq_brace)*? \}                    |
                        (?: ::)? (?:
                              [0-9]+                              |
                              [^\x81-\xFEa-zA-Z_0-9\[\]] |
                              ^[A-Z]                              |
                              [a-zA-Z_][a-zA-Z_0-9]*
                        (?: ::[a-zA-Z_][a-zA-Z_0-9]* )* (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} )*
                                          (?: (?: -> )? (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} ) )*
                    ))
                  }xms;

# regexp of nested parens in qXX
my $q_paren    = qr{(?{local $nest=0}) (?>(?:
                    [\x81-\xFE][\x00-\xFF] |
                    [^()] |
                             \(  (?{$nest++}) |
                             \)  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_brace    = qr{(?{local $nest=0}) (?>(?:
                    [\x81-\xFE][\x00-\xFF] |
                    [^{}] |
                             \{  (?{$nest++}) |
                             \}  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_bracket  = qr{(?{local $nest=0}) (?>(?:
                    [\x81-\xFE][\x00-\xFF] |
                    [^[\]] |
                             \[  (?{$nest++}) |
                             \]  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_angle    = qr{(?{local $nest=0}) (?>(?:
                    [\x81-\xFE][\x00-\xFF] |
                    [^<>] |
                             \<  (?{$nest++}) |
                             \>  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;

# P.854 31.17. use re
# in Chapter 31. Pragmatic Modules
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# P.1026 re
# in Chapter 29. Pragmatic Modules
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

my $matched     = '';
my $s_matched   = '';
$matched        = q{$Char::Egbk::matched};
$s_matched      = q{ Char::Egbk::s_matched();};

my $tr_variable   = '';   # variable of tr///
my $sub_variable  = '';   # variable of s///
my $bind_operator = '';   # =~ or !~
BEGIN { eval q{ use vars qw($slash) } }
                          # when 'm//', '/' means regexp match 'm//' and '?' means regexp match '??'
                          # when 'div', '/' means division operator and '?' means conditional operator (condition ? then : else)
my @heredoc = ();         # here document
my @heredoc_delimiter = ();
my $here_script = '';     # here script
my $function_ord;         # ord()   to ord()   or Char::GBK::ord()
my $function_ord_;        # ord     to ord     or Char::GBK::ord_
my $function_reverse;     # reverse to reverse or Char::GBK::reverse

my $ignore_modules = join('|', qw(
    utf8
    bytes
    charnames
    I18N::Japanese
    I18N::Collate
    I18N::JExt
    File::DosGlob
    Wild
    Wildcard
    Japanese
));

# in Chapter 8: Standard Modules
# of ISBN 0-596-00241-6 Perl in a Nutshell, Second Edition

# when this script is main program
if ($0 eq __FILE__) {

    # show usage
    unless (@ARGV) {
        die <<END;
$0: usage

perl $0 GBK_script.pl > Escaped_script.pl.e
END
    }

    print Char::GBK::escape_script($ARGV[0]);
    exit 0;
}

my($package,$filename,$line,$subroutine,$hasargs,$wantarray,$evaltext,$is_require,$hints,$bitmask) = caller 0;

# called any package not main
if ($package ne 'main') {
    die <<END;
@{[__FILE__]}: escape by manually command '$^X @{[__FILE__]} "$filename" > "@{[__PACKAGE__]}::$filename"'
and rewrite "use $package;" to "use @{[__PACKAGE__]}::$package;" of script "$0".
END
}

if (Char::Egbk::e("$filename.e")) {
    if (exists $ENV{'SJIS_DEBUG'}) {
        Char::Egbk::unlink "$filename.e";
    }
    elsif (Char::Egbk::z("$filename.e")) {
        Char::Egbk::unlink "$filename.e";
    }
    else {
        my $e_mtime   = (Char::Egbk::stat("$filename.e"))[9];
        my $mtime     = (Char::Egbk::stat($filename))[9];
        my $__mtime__ = (Char::Egbk::stat(__FILE__))[9];
        if (($e_mtime < $mtime) or ($mtime < $__mtime__)) {
            Char::Egbk::unlink "$filename.e";
        }
    }
}

if (not Char::Egbk::e("$filename.e")) {
    my $fh = gensym();

    if (eval q{ use Fcntl qw(O_WRONLY O_APPEND O_CREAT); 1 } and CORE::sysopen($fh,"$filename.e",&O_WRONLY|&O_APPEND|&O_CREAT)) {
    }
    else {
        open($fh, ">>$filename.e") or die __FILE__, ": Can't write open file: $filename.e";
    }

    if (0) {
    }
    elsif (exists $ENV{'SJIS_NONBLOCK'}) {

        # P.419 File Locking
        # in Chapter 16: Interprocess Communication
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.524 File Locking
        # in Chapter 15: Interprocess Communication
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # P.571 Handling Race Conditions
        # in Chapter 23: Security
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.663 Handling Race Conditions
        # in Chapter 20: Security
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # (and so on)

        eval q{
            unless (flock($fh, LOCK_EX | LOCK_NB)) {
                warn __FILE__, ": Can't immediately write-lock the file: $filename.e";
                exit;
            }
        };
    }
    else {
        eval q{ flock($fh, LOCK_EX) };
    }

    truncate($fh, 0) or die __FILE__, ": Can't truncate file: $filename.e";
    seek($fh, 0, 0)  or die __FILE__, ": Can't seek file: $filename.e";

    my $e_script = Char::GBK::escape_script($filename);
    print {$fh} $e_script;

    my $mode = (Char::Egbk::stat($filename))[2] & 0777;
    chmod $mode, "$filename.e";

    close($fh) or die __FILE__, ": Can't close file: $filename.e";
}

# P.565 23.1.2. Cleaning Up Your Environment
# in Chapter 23: Security
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# P.656 Cleaning Up Your Environment
# in Chapter 20: Security
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

# local $ENV{'PATH'} = '.';
local @ENV{qw(IFS CDPATH ENV BASH_ENV)}; # Make %ENV safer

my $fh = gensym();
open($fh, "$filename.e") or die __FILE__, ": Can't read open file: $filename.e";

if (0) {
}
elsif (exists $ENV{'SJIS_NONBLOCK'}) {
    eval q{
        unless (flock($fh, LOCK_SH | LOCK_NB)) {
            warn __FILE__, ": Can't immediately read-lock the file: $filename.e";
            exit;
        }
    };
}
else {
    eval q{ flock($fh, LOCK_SH) };
}

my @switch = ();
if ($^W) {
    push @switch, '-w';
}

# P.489 #! and Quoting on Non-Unix Systems
# in Chapter 19: The Command-Line Interface
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# P.578 #! and Quoting on Non-Unix Systems
# in Chapter 17: The Command-Line Interface
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

# DOS-like system
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    exit system
        _escapeshellcmd_MSWin32($^X),

# -I switch can not treat space included path
#       (map { '-I' . _escapeshellcmd_MSWin32($_) } @INC),
        (map { '-I' .                         $_  } @INC),

        @switch,
        '--',
        map { _escapeshellcmd_MSWin32($_) } "$filename.e", @ARGV;
}

# UNIX-like system
else {
    exit system
        _escapeshellcmd($^X),
        (map { '-I' . _escapeshellcmd($_) } @INC),
        @switch,
        '--',
        map { _escapeshellcmd($_) } "$filename.e", @ARGV;
}

# escape shell command line on DOS-like system
sub _escapeshellcmd_MSWin32 {
    my($word) = @_;
    if ($word =~ / $anchor [ ] /oxms) {
        return qq{"$word"};
    }
    else {
        return $word;
    }
}

# escape shell command line on UNIX-like system
sub _escapeshellcmd {
    my($word) = @_;
    $word =~ s/([\t\n\r\x20!"#\$%&'()*+;<=>?\[\\\]^`{|}~\x7F\xFF])/\\$1/g;
    return $word;
}

# P.619 Source Filters
# in Chapter 24: Common Practices
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# P.718 Source Filters
# in Chapter 21: Common Practices
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

# escape GBK script
sub Char::GBK::escape_script {
    my($script) = @_;
    my $e_script = '';

    # read GBK script
    my $fh = gensym();
    open($fh, $script) or die __FILE__, ": Can't open file: $script";
    local $/ = undef; # slurp mode
    $_ = <$fh>;
    close($fh) or die __FILE__, ": Can't close file: $script";

    if (/^ use Char::Egbk(?:\s+[0-9\.]*)?\s*; $/oxms) {
        return $_;
    }
    else {

        # #! shebang line
        if (s/\A(#!.+?\n)//oms) {
            my $head = $1;
            $head =~ s/\bjperl\b/perl/gi;
            $e_script .= $head;
        }

        # DOS-like system header
        if (s/\A(\@rem\s*=\s*'.*?'\s*;\s*\n)//oms) {
            my $head = $1;
            $head =~ s/\bjperl\b/perl/gi;
            $e_script .= $head;
        }

        # P.618 Generating Perl in Other Languages
        # in Chapter 24: Common Practices
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.717 Generating Perl in Other Languages
        # in Chapter 21: Common Practices
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        if (s/(.*^#\s*line\s+\d+(?:\s+"(?:$q_char)+?")?\s*\n)//oms) {
            my $head = $1;
            $head =~ s/\bjperl\b/perl/gi;
            $e_script .= $head;
        }

        # P.210 5.10.3.3. Match-time code evaluation
        # in Chapter 5: Pattern Matching
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.255 Match-time code evaluation
        # in Chapter 5: Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        $e_script .= sprintf("use Char::Egbk %s;\n", $Char::GBK::VERSION); # require run-time routines version

        # use Char::GBK version qw(ord reverse);
        $function_ord     = 'ord';
        $function_ord_    = 'ord';
        $function_reverse = 'reverse';
        if (s/^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $//oxms) {

            # require version
            my $list = $1;
            if ($list =~ s/\A ([0-9]+\.[0-9]+) \.0 \s* //oxms) {
                my $version = $1;
                if ($version ne $Char::GBK::VERSION) {
                    my @file = grep -e, map {qq{$_/Char/GBK.pm}} @INC;
                    my %file = map { $_ => 1 } @file;
                    if (scalar(keys %file) >= 2) {
                        my $file = join "\n", sort keys %file;
                        warn <<END;
****************************************************
                   C A U T I O N

              CONFLICT Char/GBK.pm FILE

$file
****************************************************

END
                    }
                    die "Script $0 expects Char/GBK.pm $version, but @{[__FILE__]} is version $Char::GBK::VERSION\n";
                }
                $e_script .= qq{die "Script \$0 expects Char/Egbk.pm $version, but \\\$Char::Egbk::VERSION is \$Char::Egbk::VERSION" if \$Char::Egbk::VERSION ne '$version';\n};
            }
            elsif ($list =~ s/\A ([0-9]+(?:\.[0-9]*)) \s* //oxms) {
                my $version = $1;
                if ($version > $Char::GBK::VERSION) {
                    die "Script $0 required Char/GBK.pm $version, but @{[__FILE__]} is only version $Char::GBK::VERSION\n";
                }
            }

            # demand ord and reverse
            if ($list !~ /\A \s* \z/oxms) {
                local $@;
                my @list = eval $list;
                for (@list) {
                    $function_ord     = 'Char::GBK::ord'     if /\A ord \z/oxms;
                    $function_ord_    = 'Char::GBK::ord_'    if /\A ord \z/oxms;
                    $function_reverse = 'Char::GBK::reverse' if /\A reverse \z/oxms;
                }
            }
        }
    }

    $slash = 'm//';

    # Yes, I studied study yesterday.

    # P.359 The Study Function
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    study $_;

    # while all script

    # one member of Tag-team
    #
    # P.315 "Tag-team" matching with /gc
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    while (not /\G \z/oxgc) { # member
        $e_script .= escape();
    }

    return $e_script;
}

# escape GBK part of script
sub escape {

# \n output here document

    # another member of Tag-team
    #
    # P.315 "Tag-team" matching with /gc
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    if (/\G ( \n ) /oxgc) { # another member (and so on)
        my $heredoc = '';
        if (scalar(@heredoc_delimiter) >= 1) {
            $slash = 'm//';

            $heredoc = join '', @heredoc;
            @heredoc = ();

            # skip here document
            for my $heredoc_delimiter (@heredoc_delimiter) {
                /\G .*? \n $heredoc_delimiter \n/xmsgc;
            }
            @heredoc_delimiter = ();

            $here_script = '';
        }
        return "\n" . $heredoc;
    }

# ignore space, comment
    elsif (/\G (\s+|\#.*) /oxgc) { return $1; }

# if (, elsif (, unless (, while (, until (, given ( and when (

    # given, when

    # P.225 The given Statement
    # in Chapter 15: Smart Matching and given-when
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.133 The given Statement
    # in Chapter 4: Statements and Declarations
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    elsif (/\G ( (?: if | elsif | unless | while | until | given | when ) \s* \( ) /oxgc) {
        $slash = 'm//';
        return $1;
    }

# scalar variable ($scalar = ...) =~ tr///;
# scalar variable ($scalar = ...) =~ s///;

    # state

    # P.68 Persistent, Private Variables
    # in Chapter 4: Subroutines
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.160 Persistent Lexically Scoped Variables: state
    # in Chapter 4: Statements and Declarations
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    elsif (/\G ( \( \s* (?: local \b | my \b | our \b | state \b )? \s* \$ $qq_scalar ) /oxgc) {
        my $e_string = e_string($1);

        if (/\G ( \s* = $qq_paren \) ) ( \s* (?: =~ | !~ ) \s* ) (?= (?: tr|y) \b ) /oxgc) {
            $tr_variable = $e_string . e_string($1);
            $bind_operator = $2;
            $slash = 'm//';
            return '';
        }
        elsif (/\G ( \s* = $qq_paren \) ) ( \s* (?: =~ | !~ ) \s* ) (?= s \b ) /oxgc) {
            $sub_variable = $e_string . e_string($1);
            $bind_operator = $2;
            $slash = 'm//';
            return '';
        }
        else {
            $slash = 'div';
            return $e_string;
        }
    }

# $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Char::Egbk::PREMATCH()
    elsif (/\G ( \$` | \$\{`\} | \$ \s* PREMATCH  \b | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  ) /oxmsgc) {
        $slash = 'div';
        return q{Char::Egbk::PREMATCH()};
    }

# $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Char::Egbk::MATCH()
    elsif (/\G ( \$& | \$\{&\} | \$ \s* MATCH     \b | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     ) /oxmsgc) {
        $slash = 'div';
        return q{Char::Egbk::MATCH()};
    }

# $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Char::Egbk::POSTMATCH()
    elsif (/\G (                 \$ \s* POSTMATCH \b | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} ) /oxmsgc) {
        $slash = 'div';
        return q{Char::Egbk::POSTMATCH()};
    }

# scalar variable $scalar =~ tr///;
# scalar variable $scalar =~ s///;
    elsif (/\G ( \$ $qq_scalar ) /oxgc) {
        my $scalar = e_string($1);

        if (/\G ( \s* (?: =~ | !~ ) \s* ) (?= (?: tr|y) \b ) /oxgc) {
            $tr_variable = $scalar;
            $bind_operator = $1;
            $slash = 'm//';
            return '';
        }
        elsif (/\G ( \s* (?: =~ | !~ ) \s* ) (?= s \b ) /oxgc) {
            $sub_variable = $scalar;
            $bind_operator = $1;
            $slash = 'm//';
            return '';
        }
        else {
            $slash = 'div';
            return $scalar;
        }
    }

    # end of statement
    elsif (/\G ( [,;] ) /oxgc) {
        $slash = 'm//';

        # clear tr/// variable
        $tr_variable  = '';

        # clear s/// variable
        $sub_variable  = '';

        $bind_operator = '';

        return $1;
    }

# bareword
    elsif (/\G ( \{ \s* (?: tr|index|rindex|reverse) \s* \} ) /oxmsgc) {
        return $1;
    }

# $0 --> $0
    elsif (/\G ( \$ 0 ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }
    elsif (/\G ( \$ \{ \s* 0 \s* \} ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# $$ --> $$
    elsif (/\G ( \$ \$ ) (?![\w\{]) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# $1, $2, $3 --> $2, $3, $4 (only when multibyte anchoring is enable)
    elsif (/\G \$ ([1-9][0-9]*) /oxmsgc) {
        $slash = 'div';
        return e_capture($1);
    }
    elsif (/\G \$ \{ \s* ([1-9][0-9]*) \s* \} /oxmsgc) {
        $slash = 'div';
        return e_capture($1);
    }

# $$foo[ ... ] --> $ $foo->[ ... ]
    elsif (/\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ .+? \] ) /oxmsgc) {
        $slash = 'div';
        return e_capture($1.'->'.$2);
    }

# $$foo{ ... } --> $ $foo->{ ... }
    elsif (/\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ .+? \} ) /oxmsgc) {
        $slash = 'div';
        return e_capture($1.'->'.$2);
    }

# $$foo
    elsif (/\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) /oxmsgc) {
        $slash = 'div';
        return e_capture($1);
    }

# ${ foo }
    elsif (/\G \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} /oxmsgc) {
        $slash = 'div';
        return '${' . $1 . '}';
    }

# ${ ... }
    elsif (/\G \$ \s* \{ \s* ( $qq_brace ) \s* \} /oxmsgc) {
        $slash = 'div';
        return e_capture($1);
    }

# variable or function
    #                  $ @ % & *     $ #
    elsif (/\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) \s* (?: split|chop|index|rindex|lc|uc|fc|chr|ord|reverse|tr|y|q|qq|qx|qw|m|s|qr|glob|lstat|opendir|stat|unlink|chdir) ) \b /oxmsgc) {
        $slash = 'div';
        return $1;
    }
    #                $ $ $ $ $ $ $ $ $ $ $ $ $ $
    #                $ @ # \ ' " / ? ( ) [ ] < >
    elsif (/\G ( \$[\$\@\#\\\'\"\/\?\(\)\[\]\<\>] ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# while (<FILEHANDLE>)
    elsif (/\G \b (while \s* \( \s* <[\$]?[A-Za-z_][A-Za-z_0-9]*> \s* \)) \b /oxgc) {
        return $1;
    }

# while (<WILDCARD>) --- glob

    # avoid "Error: Runtime exception" of perl version 5.005_03

    elsif (/\G \b while \s* \( \s* < ((?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE>\0\a\e\f\n\r\t])+?) > \s* \) \b /oxgc) {
        return 'while ($_ = Char::Egbk::glob("' . $1 . '"))';
    }

# while (glob)
    elsif (/\G \b while \s* \( \s* glob \s* \) /oxgc) {
        return 'while ($_ = Char::Egbk::glob_)';
    }

# while (glob(WILDCARD))
    elsif (/\G \b while \s* \( \s* glob \b /oxgc) {
        return 'while ($_ = Char::Egbk::glob';
    }

# doit if, doit unless, doit while, doit until, doit for, doit when
    elsif (/\G \b ( if | unless | while | until | for | when ) \b /oxgc) { $slash = 'm//'; return $1; }

# functions of package Char::Egbk
    elsif (/\G \b (CORE:: | ->[ ]* (?: atan2 | [a-z]{2,})) \b  /oxgc) { $slash = 'm//'; return $1;                    }
    elsif (/\G \b bytes::substr \b (?! \s* => )                /oxgc) { $slash = 'm//'; return 'substr';              }
    elsif (/\G \b chop \b          (?! \s* => )                /oxgc) { $slash = 'm//'; return 'Char::Egbk::chop';         }
    elsif (/\G \b bytes::index \b  (?! \s* => )                /oxgc) { $slash = 'm//'; return 'index';               }
    elsif (/\G \b Char::GBK::index \b   (?! \s* => )                /oxgc) { $slash = 'm//'; return 'Char::GBK::index';         }
    elsif (/\G \b index \b         (?! \s* => )                /oxgc) { $slash = 'm//'; return 'Char::Egbk::index';        }
    elsif (/\G \b bytes::rindex \b (?! \s* => )                /oxgc) { $slash = 'm//'; return 'rindex';              }
    elsif (/\G \b Char::GBK::rindex \b  (?! \s* => )                /oxgc) { $slash = 'm//'; return 'Char::GBK::rindex';        }
    elsif (/\G \b rindex \b        (?! \s* => )                /oxgc) { $slash = 'm//'; return 'Char::Egbk::rindex';       }
    elsif (/\G \b lc      (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::lc';           }
    elsif (/\G \b lcfirst (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::lcfirst';      }
    elsif (/\G \b uc      (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::uc';           }
    elsif (/\G \b ucfirst (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::ucfirst';      }
    elsif (/\G \b fc      (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::fc';           }

    # stacked file test operators

    # P.179 File Test Operators
    # in Chapter 12: File Tests
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.106 Named Unary and File Test Operators
    # in Chapter 3: Unary and Binary Operators
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    elsif (/\G (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+)
                                                          \s* (\") ((?:$qq_char)+?)            (\") /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_qq('',  $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\#) ((?:$qq_char)+?)             (\#) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\() ((?:$qq_paren)+?)            (\)) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\{) ((?:$qq_brace)+?)            (\}) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\[) ((?:$qq_bracket)+?)          (\]) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\<) ((?:$qq_angle)+?)            (\>) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\S) ((?:$qq_char)+?)             (\3) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }

    elsif (/\G (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+)
                                                          \s* (\') ((?:\\\1|\\\\|$q_char)+?)   (\') /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_q ('',  $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }

    elsif (/\G (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+) (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                           { $slash = 'm//'; return "Char::Egbk::filetest(qw($1),$2)"; }
    elsif (/\G (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+) \( ((?:$qq_paren)*?) \) /oxgc)
                                                                                                           { $slash = 'm//'; return "Char::Egbk::filetest(qw($1),$2)"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) (?= [a-z]+) /oxgc)                                   { $slash = 'm//'; return "Char::Egbk::filetest qw($1),";    }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) (\w+) /oxgc)                                         { $slash = 'm//'; return "Char::Egbk::filetest(qw($1),$2)"; }

    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+    \s* (\") ((?:$qq_char)+?)             (\") /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_qq('',  $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\#) ((?:$qq_char)+?)             (\#) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\() ((?:$qq_paren)+?)            (\)) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\{) ((?:$qq_brace)+?)            (\}) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\[) ((?:$qq_bracket)+?)          (\]) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\<) ((?:$qq_angle)+?)            (\>) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\S) ((?:$qq_char)+?)             (\3) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; }

    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+    \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_q ('',  $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) /oxgc)    { $slash = 'm//'; return "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; }

    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s* (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                           { $slash = 'm//'; return "Char::Egbk::$1($2)";      }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s* \( ((?:$qq_paren)*?) \) /oxgc)                          { $slash = 'm//'; return "Char::Egbk::$1($2)";      }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?= \s+ [a-z]+) /oxgc)                                      { $slash = 'm//'; return "Char::Egbk::$1";          }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ (\w+) /oxgc)                                            { $slash = 'm//'; return "Char::Egbk::$1(::"."$2)"; }
    elsif (/\G -(t)                            \s+ (\w+) /oxgc)                                            { $slash = 'm//'; return "-t $2";              }
    elsif (/\G \b lstat         (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::lstat';             }
    elsif (/\G \b stat          (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::stat';              }

    # "-s '' ..." means file test "-s 'filename' ..." (not means "- s/// ...")
    elsif (/\G -s                               \s+    \s* (\") ((?:$qq_char)+?)             (\") /oxgc)   { $slash = 'm//'; return '-s ' . e_qq('',  $1,$3,$2); }
    elsif (/\G -s                               \s+ qq \s* (\#) ((?:$qq_char)+?)             (\#) /oxgc)   { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               \s+ qq \s* (\() ((?:$qq_paren)+?)            (\)) /oxgc)   { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               \s+ qq \s* (\{) ((?:$qq_brace)+?)            (\}) /oxgc)   { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               \s+ qq \s* (\[) ((?:$qq_bracket)+?)          (\]) /oxgc)   { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               \s+ qq \s* (\<) ((?:$qq_angle)+?)            (\>) /oxgc)   { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               \s+ qq \s* (\S) ((?:$qq_char)+?)             (\3) /oxgc)   { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }

    elsif (/\G -s                               \s+    \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') /oxgc)   { $slash = 'm//'; return '-s ' . e_q ('',  $1,$3,$2); }
    elsif (/\G -s                               \s+ q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) /oxgc)   { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               \s+ q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) /oxgc)   { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               \s+ q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) /oxgc)   { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               \s+ q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) /oxgc)   { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               \s+ q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) /oxgc)   { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               \s+ q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) /oxgc)   { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }

    elsif (/\G -s                               \s* (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                           { $slash = 'm//'; return "-s $1";   }
    elsif (/\G -s                               \s* \( ((?:$qq_paren)*?) \) /oxgc)                         { $slash = 'm//'; return "-s ($1)"; }
    elsif (/\G -s                               (?= \s+ [a-z]+) /oxgc)                                     { $slash = 'm//'; return '-s';      }
    elsif (/\G -s                               \s+ (\w+) /oxgc)                                           { $slash = 'm//'; return "-s $1";   }

    elsif (/\G \b bytes::length (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'length';                   }
    elsif (/\G \b bytes::chr    (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'chr';                      }
    elsif (/\G \b chr           (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::chr';               }
    elsif (/\G \b bytes::ord    (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'div'; return 'ord';                      }
    elsif (/\G \b ord           (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'div'; return $function_ord;              }
    elsif (/\G \b glob          (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Char::Egbk::glob';              }
    elsif (/\G \b lc \b         (?! \s* => )                         /oxgc) { $slash = 'm//'; return 'Char::Egbk::lc_';               }
    elsif (/\G \b lcfirst \b    (?! \s* => )                         /oxgc) { $slash = 'm//'; return 'Char::Egbk::lcfirst_';          }
    elsif (/\G \b uc \b         (?! \s* => )                         /oxgc) { $slash = 'm//'; return 'Char::Egbk::uc_';               }
    elsif (/\G \b ucfirst \b    (?! \s* => )                         /oxgc) { $slash = 'm//'; return 'Char::Egbk::ucfirst_';          }
    elsif (/\G \b fc \b         (?! \s* => )                         /oxgc) { $slash = 'm//'; return 'Char::Egbk::fc_';               }
    elsif (/\G    (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+)
                           \b    (?! \s* => )                        /oxgc) { $slash = 'm//'; return "Char::Egbk::filetest_(qw($1))"; }
    elsif (/\G    -([rwxoRWXOezsfdlpSbcugkTBMAC])
                           \b    (?! \s* => )                        /oxgc) { $slash = 'm//'; return "Char::Egbk::${1}_";             }
    elsif (/\G \b lstat \b      (?! \s* => )                         /oxgc) { $slash = 'm//'; return 'Char::Egbk::lstat_';            }
    elsif (/\G \b stat \b       (?! \s* => )                         /oxgc) { $slash = 'm//'; return 'Char::Egbk::stat_';             }
    elsif (/\G    -s \b         (?! \s* => )                         /oxgc) { $slash = 'm//'; return '-s ';                      }

    elsif (/\G \b bytes::length \b (?! \s* => )                      /oxgc) { $slash = 'm//'; return 'length';                   }
    elsif (/\G \b bytes::chr \b    (?! \s* => )                      /oxgc) { $slash = 'm//'; return 'chr';                      }
    elsif (/\G \b chr \b           (?! \s* => )                      /oxgc) { $slash = 'm//'; return 'Char::Egbk::chr_';              }
    elsif (/\G \b bytes::ord \b    (?! \s* => )                      /oxgc) { $slash = 'div'; return 'ord';                      }
    elsif (/\G \b ord \b           (?! \s* => )                      /oxgc) { $slash = 'div'; return $function_ord_;             }
    elsif (/\G \b glob \b          (?! \s* => )                      /oxgc) { $slash = 'm//'; return 'Char::Egbk::glob_';             }
    elsif (/\G \b reverse \b       (?! \s* => )                      /oxgc) { $slash = 'm//'; return $function_reverse;          }
    elsif (/\G \b opendir (\s* \( \s*) (?=[A-Za-z_])                 /oxgc) { $slash = 'm//'; return "Char::Egbk::opendir$1*";        }
    elsif (/\G \b opendir (\s+)        (?=[A-Za-z_])                 /oxgc) { $slash = 'm//'; return "Char::Egbk::opendir$1*";        }
    elsif (/\G \b unlink \b     (?! \s* => )                         /oxgc) { $slash = 'm//'; return 'Char::Egbk::unlink';            }

# chdir
    elsif (/\G \b (chdir) \b    (?! \s* => ) /oxgc) {
        $slash = 'm//';

        my $e = 'Char::Egbk::chdir';

        while (/\G ( \s+ | \( | \#.* ) /oxgc) {
            $e .= $1;
        }

# end of chdir
        if    (/\G (?= [,;\)\}\]] )          /oxgc) { return $e;                 }

# chdir scalar value
        elsif (/\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { return $e . e_string($1);  }

# chdir qq//
        elsif (/\G \b (qq) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                        { return $e . e_chdir('qq',$1,$3,$2);   } # qq# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                             /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq ( ) --> qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq { } --> qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq [ ] --> qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq < > --> qr < >
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_chdir('qq','{','}',$2); } # qq | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq * * --> qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# chdir q//
        elsif (/\G \b (q) \b /oxgc) {
            if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { return $e . e_chdir_q('q',$1,$3,$2);   } # q# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                    elsif (/\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q ( ) --> qr ( )
                    elsif (/\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q { } --> qr { }
                    elsif (/\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q [ ] --> qr [ ]
                    elsif (/\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q < > --> qr < >
                    elsif (/\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { return $e . e_chdir_q('q','{','}',$2); } # q | | --> qr { }
                    elsif (/\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q * * --> qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# chdir ''
        elsif (/\G (\') /oxgc) {
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1; }
                elsif (/\G (\\\')    /oxgc) { $q_string .= $1; }
                elsif (/\G \'        /oxgc)                                       { return $e . e_chdir_q('',"'","'",$q_string); }
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1; }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }

# chdir ""
        elsif (/\G (\") /oxgc) {
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $qq_string .= $1; }
                elsif (/\G (\\\")    /oxgc) { $qq_string .= $1; }
                elsif (/\G \"        /oxgc)                                       { return $e . e_chdir('','"','"',$qq_string); }
                elsif (/\G ($q_char) /oxgc) { $qq_string .= $1; }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }
    }

# split
    elsif (/\G \b (split) \b (?! \s* => ) /oxgc) {
        $slash = 'm//';

        my $e = '';
        while (/\G ( \s+ | \( | \#.* ) /oxgc) {
            $e .= $1;
        }

# end of split
        if    (/\G (?= [,;\)\}\]] )          /oxgc) { return 'Char::Egbk::split' . $e;                 }

# split scalar value
        elsif (/\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { return 'Char::Egbk::split' . $e . e_string($1);  }

# split literal space
        elsif (/\G \b qq       (\#) [ ] (\#) /oxgc) { return 'Char::Egbk::split' . $e . qq  {qq$1 $2}; }
        elsif (/\G \b qq (\s*) (\() [ ] (\)) /oxgc) { return 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq (\s*) (\{) [ ] (\}) /oxgc) { return 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq (\s*) (\[) [ ] (\]) /oxgc) { return 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq (\s*) (\<) [ ] (\>) /oxgc) { return 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq (\s*) (\S) [ ] (\2) /oxgc) { return 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b q        (\#) [ ] (\#) /oxgc) { return 'Char::Egbk::split' . $e . qq   {q$1 $2}; }
        elsif (/\G \b q  (\s*) (\() [ ] (\)) /oxgc) { return 'Char::Egbk::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  (\s*) (\{) [ ] (\}) /oxgc) { return 'Char::Egbk::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  (\s*) (\[) [ ] (\]) /oxgc) { return 'Char::Egbk::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  (\s*) (\<) [ ] (\>) /oxgc) { return 'Char::Egbk::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  (\s*) (\S) [ ] (\2) /oxgc) { return 'Char::Egbk::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G                ' [ ] '    /oxgc) { return 'Char::Egbk::split' . $e . qq     {' '};  }
        elsif (/\G                " [ ] "    /oxgc) { return 'Char::Egbk::split' . $e . qq     {" "};  }

# split qq//
        elsif (/\G \b (qq) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                        { return e_split($e.'qr',$1,$3,$2,'');   } # qq# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                             /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq ( ) --> qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq { } --> qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq [ ] --> qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq < > --> qr < >
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc) { return e_split($e.'qr','{','}',$2,''); } # qq | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq * * --> qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# split qr//
        elsif (/\G \b (qr) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) ([imosxpadlubB]*) /oxgc)                        { return e_split  ($e.'qr',$1,$3,$2,$4);   } # qr# #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                                               /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr < >
                    elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([imosxpadlubB]*) /oxgc) { return e_split_q($e.'qr',$1, $3, $2,$4); } # qr ' '
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxpadlubB]*) /oxgc) { return e_split  ($e.'qr','{','}',$2,$4); } # qr | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# split q//
        elsif (/\G \b (q) \b /oxgc) {
            if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { return e_split_q($e.'qr',$1,$3,$2,'');   } # q# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                    elsif (/\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q ( ) --> qr ( )
                    elsif (/\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q { } --> qr { }
                    elsif (/\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q [ ] --> qr [ ]
                    elsif (/\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q < > --> qr < >
                    elsif (/\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { return e_split_q($e.'qr','{','}',$2,''); } # q | | --> qr { }
                    elsif (/\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q * * --> qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# split m//
        elsif (/\G \b (m) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxpadlubB]*) /oxgc)                        { return e_split  ($e.'qr',$1,$3,$2,$4);   } # m# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G (\s+|\#.*)                                                 /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([cgimosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m ( ) --> qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([cgimosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m { } --> qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([cgimosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m [ ] --> qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([cgimosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m < > --> qr < >
                    elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([cgimosxpadlubB]*) /oxgc) { return e_split_q($e.'qr',$1, $3, $2,$4); } # m ' ' --> qr ' '
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxpadlubB]*) /oxgc) { return e_split  ($e.'qr','{','}',$2,$4); } # m | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([cgimosxpadlubB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m * * --> qr * *
                }
                die __FILE__, ": Search pattern not terminated";
            }
        }

# split ''
        elsif (/\G (\') /oxgc) {
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1; }
                elsif (/\G (\\\')    /oxgc) { $q_string .= $1; }                               # splitqr'' --> split qr''
                elsif (/\G \'        /oxgc)                                                    { return e_split_q($e.q{ qr},"'","'",$q_string,''); } # ' ' --> qr ' '
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1; }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }

# split ""
        elsif (/\G (\") /oxgc) {
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $qq_string .= $1; }
                elsif (/\G (\\\")    /oxgc) { $qq_string .= $1; }                              # splitqr"" --> split qr""
                elsif (/\G \"        /oxgc)                                                    { return e_split($e.q{ qr},'"','"',$qq_string,''); } # " " --> qr " "
                elsif (/\G ($q_char) /oxgc) { $qq_string .= $1; }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }

# split //
        elsif (/\G (\/) /oxgc) {
            my $regexp = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)                 /oxgc) { $regexp .= $1; }
                elsif (/\G (\\\/)                 /oxgc) { $regexp .= $1; }                    # splitqr// --> split qr//
                elsif (/\G \/ ([cgimosxpadlubB]*) /oxgc)                                       { return e_split($e.q{ qr}, '/','/',$regexp,$1); } # / / --> qr / /
                elsif (/\G ($q_char)              /oxgc) { $regexp .= $1; }
            }
            die __FILE__, ": Search pattern not terminated";
        }
    }

# tr/// or y///

    # about [cdsrbB]* (/B modifier)
    #
    # P.559 appendix C
    # of ISBN 4-89052-384-7 Programming perl
    # (Japanese title is: Perl puroguramingu)

    elsif (/\G \b (tr|y) \b /oxgc) {
        my $ope = $1;

        #        $1   $2               $3   $4               $5   $6
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([cdsrbB]*) /oxgc) { # tr# # #
            my @tr = ($tr_variable,$2);
            return e_tr(@tr,'',$4,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                  /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) * *
                    }
                    die __FILE__, ": Transliteration replacement not terminated";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } * *
                    }
                    die __FILE__, ": Transliteration replacement not terminated";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] * *
                    }
                    die __FILE__, ": Transliteration replacement not terminated";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > * *
                    }
                    die __FILE__, ": Transliteration replacement not terminated";
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cdsrbB]*) /oxgc) { # tr * * *
                    my @tr = ($tr_variable,$2);
                    return e_tr(@tr,'',$4,$6);
                }
            }
            die __FILE__, ": Transliteration pattern not terminated";
        }
    }

# qq//
    elsif (/\G \b (qq) \b /oxgc) {
        my $ope = $1;

#       if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { return e_qq($ope,$1,$3,$2); } # qq# #
        if (/\G (\#) /oxgc) {                                                     # qq# #
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                     }
                elsif (/\G (\\\#)     /oxgc) { $qq_string .= $1;                     }
                elsif (/\G (\#)       /oxgc) { return e_qq($ope,'#','#',$qq_string); }
                elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                     }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }

        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                  /oxgc) { $e .= $1; }

#               elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq ( )
                elsif (/\G (\() /oxgc) {                                                           # qq ( )
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\))     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\()       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\))       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'(',')',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq { }
                elsif (/\G (\{) /oxgc) {                                                           # qq { }
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\})     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\{)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\})       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'{','}',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq [ ]
                elsif (/\G (\[) /oxgc) {                                                             # qq [ ]
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\])     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\[)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\])       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'[',']',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq < >
                elsif (/\G (\<) /oxgc) {                                                           # qq < >
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\>)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\<)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\>)       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'<','>',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\S) ((?:$qq_char)*?) (\1) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq * *
                elsif (/\G (\S) /oxgc) {                                                          # qq * *
                    my $delimiter = $1;
                    my $qq_string = '';
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)             /oxgc) { $qq_string .= $1;                                        }
                        elsif (/\G (\\\Q$delimiter\E) /oxgc) { $qq_string .= $1;                                        }
                        elsif (/\G (\Q$delimiter\E)   /oxgc) { return $e . e_qq($ope,$delimiter,$delimiter,$qq_string); }
                        elsif (/\G ($qq_char)         /oxgc) { $qq_string .= $1;                                        }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }
    }

# qr//
    elsif (/\G \b (qr) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([imosxpadlubB]*) /oxgc) { # qr# # #
            return e_qr($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                                               /oxgc) { $e .= $1; }
                elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr ( )
                elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr { }
                elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr [ ]
                elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr < >
                elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([imosxpadlubB]*) /oxgc) { return $e . e_qr_q($ope,$1, $3, $2,$4); } # qr ' '
                elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,'{','}',$2,$4); } # qr | | --> qr { }
                elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr * *
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }
    }

# qw//
    elsif (/\G \b (qw) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) (.*?) (\#) /oxmsgc) { # qw# #
            return e_qw($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                            /oxgc)   { $e .= $1; }

                elsif (/\G (\()          ([^(]*?)           (\)) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw ( )
                elsif (/\G (\()          ((?:$q_paren)*?)   (\)) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw ( )

                elsif (/\G (\{)          ([^{]*?)           (\}) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw { }
                elsif (/\G (\{)          ((?:$q_brace)*?)   (\}) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw { }

                elsif (/\G (\[)          ([^[]*?)           (\]) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw [ ]
                elsif (/\G (\[)          ((?:$q_bracket)*?) (\]) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw [ ]

                elsif (/\G (\<)          ([^<]*?)           (\>) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw < >
                elsif (/\G (\<)          ((?:$q_angle)*?)   (\>) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw < >

                elsif (/\G ([\x21-\x3F]) (.*?)              (\1) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw * *
                elsif (/\G (\S)          ((?:$q_char)*?)    (\1) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw * *
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }
    }

# qx//
    elsif (/\G \b (qx) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qx# #
            return e_qq($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx ( )
                elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx { }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx [ ]
                elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx < >
                elsif (/\G (\') ((?:$qq_char)*?)    (\') /oxgc) { return $e . e_q ($ope,$1,$3,$2); } # qx ' '
                elsif (/\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx * *
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }
    }

# q//
    elsif (/\G \b (q) \b /oxgc) {
        my $ope = $1;

#       if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) { return e_q($ope,$1,$3,$2); } # q# #

        # avoid "Error: Runtime exception" of perl version 5.005_03
        # (and so on)

        if (/\G (\#) /oxgc) {                                                             # q# #
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                    }
                elsif (/\G (\\\#)    /oxgc) { $q_string .= $1;                    }
                elsif (/\G (\#)      /oxgc) { return e_q($ope,'#','#',$q_string); }
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                    }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }

        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                           /oxgc) { $e .= $1; }

#               elsif (/\G (\() ((?:\\\)|\\\\|$q_paren)*?) (\)) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q ( )
                elsif (/\G (\() /oxgc) {                                                                   # q ( )
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\))    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\()    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\()      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\))      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'(',')',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\{) ((?:\\\}|\\\\|$q_brace)*?) (\}) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q { }
                elsif (/\G (\{) /oxgc) {                                                                   # q { }
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\})    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\{)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\{)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\})      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'{','}',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\[) ((?:\\\]|\\\\|$q_bracket)*?) (\]) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q [ ]
                elsif (/\G (\[) /oxgc) {                                                                     # q [ ]
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\])    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\[)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\[)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\])      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'[',']',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\<) ((?:\\\>|\\\\|$q_angle)*?) (\>) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q < >
                elsif (/\G (\<) /oxgc) {                                                                   # q < >
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\>)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\<)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\<)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\>)      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'<','>',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\S) ((?:\\\1|\\\\|$q_char)*?) (\1) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q * *
                elsif (/\G (\S) /oxgc) {                                                                  # q * *
                    my $delimiter = $1;
                    my $q_string = '';
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)             /oxgc) { $q_string .= $1;                                       }
                        elsif (/\G (\\\Q$delimiter\E) /oxgc) { $q_string .= $1;                                       }
                        elsif (/\G (\Q$delimiter\E)   /oxgc) { return $e . e_q($ope,$delimiter,$delimiter,$q_string); }
                        elsif (/\G ($q_char)          /oxgc) { $q_string .= $1;                                       }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF";
        }
    }

# m//
    elsif (/\G \b (m) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxpadlubB]*) /oxgc) { # m# #
            return e_qr($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                                                /oxgc) { $e .= $1; }
                elsif (/\G (\()         ((?:$qq_paren)*?)   (\)) ([cgimosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m ( )
                elsif (/\G (\{)         ((?:$qq_brace)*?)   (\}) ([cgimosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m { }
                elsif (/\G (\[)         ((?:$qq_bracket)*?) (\]) ([cgimosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m [ ]
                elsif (/\G (\<)         ((?:$qq_angle)*?)   (\>) ([cgimosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m < >
                elsif (/\G (\?)         ((?:$qq_char)*?)    (\?) ([cgimosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m ? ?
                elsif (/\G (\')         ((?:$qq_char)*?)    (\') ([cgimosxpadlubB]*) /oxgc) { return $e . e_qr_q($ope,$1, $3, $2,$4); } # m ' '
                elsif (/\G ([*\-:\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,'{','}',$2,$4); } # m | | --> m { }
                elsif (/\G (\S)         ((?:$qq_char)*?)    (\1) ([cgimosxpadlubB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m * *
            }
            die __FILE__, ": Search pattern not terminated";
        }
    }

# s///

    # about [cegimosxpradlubB]* (/cg modifier)
    #
    # P.67 Pattern-Matching Operators
    # of ISBN 0-596-00241-6 Perl in a Nutshell, Second Edition.

    elsif (/\G \b (s) \b /oxgc) {
        my $ope = $1;

        #        $1   $2               $3   $4               $5   $6
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([cegimosxpradlubB]*) /oxgc) { # s# # #
            return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                          /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    die __FILE__, ": Substitution replacement not terminated";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                          /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    die __FILE__, ": Substitution replacement not terminated";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                          /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    die __FILE__, ": Substitution replacement not terminated";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                          /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxpradlubB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    die __FILE__, ": Substitution replacement not terminated";
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\') ((?:$qq_char)*?) (\') ((?:$qq_char)*?) (\') ([cegimosxpradlubB]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
                #           $1            $2               $3   $4               $5   $6
                elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxpradlubB]*) /oxgc) {
                    return e_sub($sub_variable,'{',$2,'}','{',$4,'}',$6); # s | | | --> s { } { }
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\$) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxpradlubB]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxpradlubB]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
            }
            die __FILE__, ": Substitution pattern not terminated";
        }
    }

# do
    elsif (/\G \b do (?= \s* \{ )                    /oxmsgc)                                  { return 'do';                }
    elsif (/\G \b do (?= \s+ (?: q|qq|qx) \b)        /oxmsgc)                                  { return 'Char::Egbk::do';         }
    elsif (/\G \b do (?= \s+ \w+)                    /oxmsgc)                                  { return 'do';                }
    elsif (/\G \b do (?= \s* \$ \w+ (?: ::\w+)* \( ) /oxmsgc)                                  { return 'do';                }
    elsif (/\G \b do \b                              /oxmsgc)                                  { return 'Char::Egbk::do';         }

# require ignore module
    elsif (/\G \b require (\s+ (?:$ignore_modules) .*? ;) ([ \t]* [#\n])                  /oxmsgc) { return "# require$1$2";   }
    elsif (/\G \b require (\s+ (?:$ignore_modules) .*? ;) ([ \t]* [^\x81-\xFE#]) /oxmsgc) { return "# require$1\n$2"; }
    elsif (/\G \b require (\s+ (?:$ignore_modules)) \b                                    /oxmsgc) { return "# require$1";     }

# require version number
    elsif (/\G \b require \s+ (0[0-7_]*)                    \s* ; /oxmsgc)                     { return "require $1;";       }
    elsif (/\G \b require \s+ ([1-9][0-9_]*(?:\.[0-9_]+)*)  \s* ; /oxmsgc)                     { return "require $1;";       }
    elsif (/\G \b require \s+ (v[0-9][0-9_]*(?:\.[0-9_]+)*) \s* ; /oxmsgc)                     { return "require $1;";       }

# require bare package name
    elsif (/\G \b require \s+ ([A-Za-z_]\w* (?: :: [A-Za-z_]\w*)*) \s* ; /oxmsgc)              { return "require $1;";       }

# require else
    elsif (/\G \b require                                   \s* ; /oxmsgc)                     { return 'Char::Egbk::require;';   }
    elsif (/\G \b require \b                                      /oxmsgc)                     { return 'Char::Egbk::require';    }

# use strict; --> use strict; no strict qw(refs);
    elsif (/\G \b use (\s+ strict .*? ;) ([ \t]* [#\n])                  /oxmsgc)              { return "use$1 no strict qw(refs);$2";   }
    elsif (/\G \b use (\s+ strict .*? ;) ([ \t]* [^\x81-\xFE#]) /oxmsgc)              { return "use$1 no strict qw(refs);\n$2"; }
    elsif (/\G \b use (\s+ strict) \b                                    /oxmsgc)              { return "use$1; no strict qw(refs)";     }

# use 5.12.0; --> use 5.12.0; no strict qw(refs);
    elsif (/\G \b use \s+ (([1-9][0-9_]*)(?:\.([0-9_]+))*)  \s* ;        /oxmsgc)              {
        if (($2 >= 6) or (($2 == 5) and ($3 >= 12))) {
            return "use$1 no strict qw(refs);";
        }
        else {
            return "use$1";
        }
    }
    elsif (/\G \b use \s+ (v([0-9][0-9_]*)(?:\.([0-9_]+))*) \s* ;        /oxmsgc)              {
        if (($2 >= 6) or (($2 == 5) and ($3 >= 12))) {
            return "use$1 no strict qw(refs);";
        }
        else {
            return "use$1";
        }
    }

# ignore use module
    elsif (/\G \b use (\s+ (?:$ignore_modules) .*? ;) ([ \t]* [#\n])                  /oxmsgc) { return "# use$1$2";         }
    elsif (/\G \b use (\s+ (?:$ignore_modules) .*? ;) ([ \t]* [^\x81-\xFE#]) /oxmsgc) { return "# use$1\n$2";       }
    elsif (/\G \b use (\s+ (?:$ignore_modules)) \b                                    /oxmsgc) { return "# use$1";           }

# ignore no module
    elsif (/\G \b no  (\s+ (?:$ignore_modules) .*? ;) ([ \t]* [#\n])                  /oxmsgc) { return "# no$1$2";          }
    elsif (/\G \b no  (\s+ (?:$ignore_modules) .*? ;) ([ \t]* [^\x81-\xFE#]) /oxmsgc) { return "# no$1\n$2";        }
    elsif (/\G \b no  (\s+ (?:$ignore_modules)) \b                                    /oxmsgc) { return "# no$1";            }

# use without import
    elsif (/\G \b use \s+ (0[0-7_]*)                                            \s* ; /oxmsgc) { return "use $1;";           }
    elsif (/\G \b use \s+ ([1-9][0-9_]*(?:\.[0-9_]+)*)                          \s* ; /oxmsgc) { return "use $1;";           }
    elsif (/\G \b use \s+ (v[0-9][0-9_]*(?:\.[0-9_]+)*)                         \s* ; /oxmsgc) { return "use $1;";           }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s*        (\()          \s* \) \s* ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\()          \s* \) \s* ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\{)          \s* \} \s* ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\[)          \s* \] \s* ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\<)          \s* \> \s* ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* ([\x21-\x3F]) \s* \2 \s* ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\S)          \s* \2 \s* ; /oxmsgc) { return e_use_noimport($1);  }

# use with import no parameter
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*)                                 \s* ; /oxmsgc) { return e_use_noparam($1);   }

# use with import parameters
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\()          [^\x81-\xFE)]* \)) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\')          [^\x81-\xFE']* \') \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\")          [^\x81-\xFE"]* \") \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\()          [^\x81-\xFE)]* \)) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\{)          (?:$q_char)*?           \}) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\[)          (?:$q_char)*?           \]) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\<)          [^\x81-\xFE>]* \>) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* ([\x21-\x3F]) .*?                     \3) \s* ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\S)          (?:$q_char)*?           \3) \s* ; /oxmsgc) { return e_use($1,$2); }

# no without unimport
    elsif (/\G \b no  \s+ (0[0-7_]*)                                            \s* ; /oxmsgc) { return "no $1;";            }
    elsif (/\G \b no  \s+ ([1-9][0-9_]*(?:\.[0-9_]+)*)                          \s* ; /oxmsgc) { return "no $1;";            }
    elsif (/\G \b no  \s+ (v[0-9][0-9_]*(?:\.[0-9_]+)*)                         \s* ; /oxmsgc) { return "no $1;";            }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s*        (\()          \s* \) \s* ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\()          \s* \) \s* ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\{)          \s* \} \s* ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\[)          \s* \] \s* ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\<)          \s* \> \s* ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* ([\x21-\x3F]) \s* \2 \s* ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ qw \s* (\S)          \s* \2 \s* ; /oxmsgc) { return e_no_nounimport($1); }

# no with unimport no parameter
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*)                                 \s* ; /oxmsgc) { return e_no_noparam($1);    }

# no with unimport parameters
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\()          [^\x81-\xFE)]* \)) \s* ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\')          [^\x81-\xFE']* \') \s* ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s* (                (\")          [^\x81-\xFE"]* \") \s* ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\()          [^\x81-\xFE)]* \)) \s* ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\{)          (?:$q_char)*?           \}) \s* ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\[)          (?:$q_char)*?           \]) \s* ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\<)          [^\x81-\xFE>]* \>) \s* ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* ([\x21-\x3F]) .*?                     \3) \s* ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  \s+ ([A-Z]\w*(?: ::\w+)*) \s+ ((?:q|qq|qw) \s* (\S)          (?:$q_char)*?           \3) \s* ; /oxmsgc) { return e_no($1,$2);  }

# use else
    elsif (/\G \b use \b                                                              /oxmsgc) { return "use";               }

# use else
    elsif (/\G \b no  \b                                                              /oxmsgc) { return "no";                }

# ''
    elsif (/\G (?<![\w\$\@\%\&\*]) (\') /oxgc) {
        my $q_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)              { $q_string .= $1;                   }
            elsif (/\G (\\\')    /oxgc)              { $q_string .= $1;                   }
            elsif (/\G \'        /oxgc)              { return e_q('', "'","'",$q_string); }
            elsif (/\G ($q_char) /oxgc)              { $q_string .= $1;                   }
        }
        die __FILE__, ": Can't find string terminator anywhere before EOF";
    }

# ""
    elsif (/\G (\") /oxgc) {
        my $qq_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)              { $qq_string .= $1;                    }
            elsif (/\G (\\\")    /oxgc)              { $qq_string .= $1;                    }
            elsif (/\G \"        /oxgc)              { return e_qq('', '"','"',$qq_string); }
            elsif (/\G ($q_char) /oxgc)              { $qq_string .= $1;                    }
        }
        die __FILE__, ": Can't find string terminator anywhere before EOF";
    }

# ``
    elsif (/\G (\`) /oxgc) {
        my $qx_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)              { $qx_string .= $1;                    }
            elsif (/\G (\\\`)    /oxgc)              { $qx_string .= $1;                    }
            elsif (/\G \`        /oxgc)              { return e_qq('', '`','`',$qx_string); }
            elsif (/\G ($q_char) /oxgc)              { $qx_string .= $1;                    }
        }
        die __FILE__, ": Can't find string terminator anywhere before EOF";
    }

# //   --- not divide operator (num / num), not defined-or
    elsif (($slash eq 'm//') and /\G (\/) /oxgc) {
        my $regexp = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)                 /oxgc) { $regexp .= $1;                       }
            elsif (/\G (\\\/)                 /oxgc) { $regexp .= $1;                       }
            elsif (/\G \/ ([cgimosxpadlubB]*) /oxgc) { return e_qr('', '/','/',$regexp,$1); }
            elsif (/\G ($q_char)              /oxgc) { $regexp .= $1;                       }
        }
        die __FILE__, ": Search pattern not terminated";
    }

# ??   --- not conditional operator (condition ? then : else)
    elsif (($slash eq 'm//') and /\G (\?) /oxgc) {
        my $regexp = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)                 /oxgc) { $regexp .= $1;                       }
            elsif (/\G (\\\?)                 /oxgc) { $regexp .= $1;                       }
            elsif (/\G \? ([cgimosxpadlubB]*) /oxgc) { return e_qr('m','?','?',$regexp,$1); }
            elsif (/\G ($q_char)              /oxgc) { $regexp .= $1;                       }
        }
        die __FILE__, ": Search pattern not terminated";
    }

# << (bit shift)   --- not here document
    elsif (/\G ( << \s* ) (?= [0-9\$\@\&] ) /oxgc)   { $slash = 'm//'; return $1;           }

# <<'HEREDOC'
    elsif (/\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, $1 . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<\HEREDOC

    # P.66 2.6.6. "Here" Documents
    # in Chapter 2: Bits and Pieces
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.73 "Here" Documents
    # in Chapter 2: Bits and Pieces
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    elsif (/\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, $1 . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<"HEREDOC"
    elsif (/\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<HEREDOC
    elsif (/\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<`HEREDOC`
    elsif (/\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<= <=> <= < operator
    elsif (/\G (<<=|<=>|<=|<) (?= \s* [A-Za-z_0-9'"`\$\@\&\*\(\+\-] )/oxgc) {
        return $1;
    }

# <FILEHANDLE>
    elsif (/\G (<[\$]?[A-Za-z_][A-Za-z_0-9]*>) /oxgc) {
        return $1;
    }

# <WILDCARD> --- glob

    # avoid "Error: Runtime exception" of perl version 5.005_03

    elsif (/\G < ((?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE>\0\a\e\f\n\r\t])+?) > /oxgc) {
        return 'Char::Egbk::glob("' . $1 . '")';
    }

# __DATA__
    elsif (/\G ^ ( __DATA__ \n .*) \z /oxmsgc) { return $1; }

# __END__
    elsif (/\G ^ ( __END__  \n .*) \z /oxmsgc) { return $1; }

# \cD Control-D

    # P.68 2.6.8. Other Literal Tokens
    # in Chapter 2: Bits and Pieces
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.76 Other Literal Tokens
    # in Chapter 2: Bits and Pieces
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    elsif (/\G   ( \cD         .*) \z /oxmsgc) { return $1; }

# \cZ Control-Z
    elsif (/\G   ( \cZ         .*) \z /oxmsgc) { return $1; }

    # any operator before div
    elsif (/\G (
            -- | \+\+ |
            [\)\}\]]

            ) /oxgc) { $slash = 'div'; return $1; }

    # any operator before m//

    # //, //= (defined-or)

    # P.164 Logical Operators
    # in Chapter 10: More Control Structures
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.119 C-Style Logical (Short-Circuit) Operators
    # in Chapter 3: Unary and Binary Operators
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    # ~~

    # P.221 The Smart Match Operator
    # in Chapter 15: Smart Matching and given-when
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.112 Smartmatch Operator
    # in Chapter 3: Unary and Binary Operators
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    elsif (/\G (

            !~~ | !~ | != | ! |
            %= | % |
            &&= | && | &= | & |
            -= | -> | - |
            :\s*= |
            : |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+= | \+ |
            \.\.\. | \.\. | \.= | \. |
            \/\/= | \/\/ |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \| |
            ~~ | ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |
            \b(?: print )\b |

            [,;\(\{\[]

            ) /oxgc) { $slash = 'm//'; return $1; }

    # other any character
    elsif (/\G ($q_char) /oxgc) { $slash = 'div'; return $1; }

    # system error
    else {
        die __FILE__, ": Oops, this shouldn't happen!";
    }
}

# escape GBK string
sub e_string {
    my($string) = @_;
    my $e_string = '';

    local $slash = 'm//';

    # P.1024 Appendix W.10 Multibyte Processing
    # of ISBN 1-56592-224-7 CJKV Information Processing
    # (and so on)

    my @char = $string =~ / \G (\\?(?:$q_char)) /oxmsg;

    # without { ... }
    if (not (grep(/\A \{ \z/xms, @char) and grep(/\A \} \z/xms, @char))) {
        if ($string !~ /<</oxms) {
            return $string;
        }
    }

E_STRING_LOOP:
    while ($string !~ /\G \z/oxgc) {
        if (0) {
        }

# $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> @{[Char::Egbk::PREMATCH()]}
        elsif ($string =~ /\G ( \$` | \$\{`\} | \$ \s* PREMATCH  \b | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  ) /oxmsgc) {
            $e_string .= q{Char::Egbk::PREMATCH()};
            $slash = 'div';
        }

# $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> @{[Char::Egbk::MATCH()]}
        elsif ($string =~ /\G ( \$& | \$\{&\} | \$ \s* MATCH     \b | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     ) /oxmsgc) {
            $e_string .= q{Char::Egbk::MATCH()};
            $slash = 'div';
        }

# $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> @{[Char::Egbk::POSTMATCH()]}
        elsif ($string =~ /\G (                 \$ \s* POSTMATCH \b | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} ) /oxmsgc) {
            $e_string .= q{Char::Egbk::POSTMATCH()};
            $slash = 'div';
        }

# bareword
        elsif ($string =~ /\G ( \{ \s* (?: tr|index|rindex|reverse) \s* \} ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $0 --> $0
        elsif ($string =~ /\G ( \$ 0 ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }
        elsif ($string =~ /\G ( \$ \{ \s* 0 \s* \} ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $$ --> $$
        elsif ($string =~ /\G ( \$ \$ ) (?![\w\{]) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $1, $2, $3 --> $2, $3, $4 (only when multibyte anchoring is enable)
        elsif ($string =~ /\G \$ ([1-9][0-9]*) /oxmsgc) {
            $e_string .= e_capture($1);
            $slash = 'div';
        }
        elsif ($string =~ /\G \$ \{ \s* ([1-9][0-9]*) \s* \} /oxmsgc) {
            $e_string .= e_capture($1);
            $slash = 'div';
        }

# $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($string =~ /\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ .+? \] ) /oxmsgc) {
            $e_string .= e_capture($1.'->'.$2);
            $slash = 'div';
        }

# $$foo{ ... } --> $ $foo->{ ... }
        elsif ($string =~ /\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ .+? \} ) /oxmsgc) {
            $e_string .= e_capture($1.'->'.$2);
            $slash = 'div';
        }

# $$foo
        elsif ($string =~ /\G \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) /oxmsgc) {
            $e_string .= e_capture($1);
            $slash = 'div';
        }

# ${ foo }
        elsif ($string =~ /\G \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} /oxmsgc) {
            $e_string .= '${' . $1 . '}';
            $slash = 'div';
        }

# ${ ... }
        elsif ($string =~ /\G \$ \s* \{ \s* ( $qq_brace ) \s* \} /oxmsgc) {
            $e_string .= e_capture($1);
            $slash = 'div';
        }

# variable or function
        #                             $ @ % & *     $ #
        elsif ($string =~ /\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) \s* (?: split|chop|index|rindex|lc|uc|fc|chr|ord|reverse|tr|y|q|qq|qx|qw|m|s|qr|glob|lstat|opendir|stat|unlink|chdir) ) \b /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }
        #                           $ $ $ $ $ $ $ $ $ $ $ $ $ $
        #                           $ @ # \ ' " / ? ( ) [ ] < >
        elsif ($string =~ /\G ( \$[\$\@\#\\\'\"\/\?\(\)\[\]\<\>] ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# functions of package Char::Egbk
        elsif ($string =~ /\G \b (CORE:: | ->[ ]* (?: atan2 | [a-z]{2,})) \b  /oxgc) { $e_string .= $1;               $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::substr \b                             /oxgc) { $e_string .= 'substr';         $slash = 'm//'; }
        elsif ($string =~ /\G \b chop \b                                      /oxgc) { $e_string .= 'Char::Egbk::chop';    $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::index \b                              /oxgc) { $e_string .= 'index';          $slash = 'm//'; }
        elsif ($string =~ /\G \b Char::GBK::index \b                               /oxgc) { $e_string .= 'Char::GBK::index';    $slash = 'm//'; }
        elsif ($string =~ /\G \b index \b                                     /oxgc) { $e_string .= 'Char::Egbk::index';   $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::rindex \b                             /oxgc) { $e_string .= 'rindex';         $slash = 'm//'; }
        elsif ($string =~ /\G \b Char::GBK::rindex \b                              /oxgc) { $e_string .= 'Char::GBK::rindex';   $slash = 'm//'; }
        elsif ($string =~ /\G \b rindex \b                                    /oxgc) { $e_string .= 'Char::Egbk::rindex';  $slash = 'm//'; }
        elsif ($string =~ /\G \b lc      (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::lc';      $slash = 'm//'; }
        elsif ($string =~ /\G \b lcfirst (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::lcfirst'; $slash = 'm//'; }
        elsif ($string =~ /\G \b uc      (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::uc';      $slash = 'm//'; }
        elsif ($string =~ /\G \b ucfirst (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::ucfirst'; $slash = 'm//'; }
        elsif ($string =~ /\G \b fc      (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::fc';      $slash = 'm//'; }
        elsif ($string =~ /\G (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+)
                                                                        \s* (\") ((?:$qq_char)+?)             (\") /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_qq('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\#) ((?:$qq_char)+?)             (\#) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\() ((?:$qq_paren)+?)            (\)) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\{) ((?:$qq_brace)+?)            (\}) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\[) ((?:$qq_bracket)+?)          (\]) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\<) ((?:$qq_angle)+?)            (\>) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) qq \s* (\S) ((?:$qq_char)+?)             (\3) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ /\G (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+)
                                                                        \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_q ('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) /oxgc) { $e_string .= "Char::Egbk::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ /\G (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+) (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                                          { $e_string .= "Char::Egbk::filetest(qw($1),$2)"; $slash = 'm//'; }
        elsif ($string =~ /\G (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+) \( ((?:$qq_paren)*?) \) /oxgc)
                                                                                                                          { $e_string .= "Char::Egbk::filetest(qw($1),$2)"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) (?= [a-z]+) /oxgc)                                   { $e_string .= "Char::Egbk::filetest qw($1),";    $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB]\s+){2,}) (\w+) /oxgc)                                         { $e_string .= "Char::Egbk::filetest(qw($1),$2)"; $slash = 'm//'; }

        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+    \s* (\") ((?:$qq_char)+?)             (\") /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_qq('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\#) ((?:$qq_char)+?)             (\#) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\() ((?:$qq_paren)+?)            (\)) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\{) ((?:$qq_brace)+?)            (\}) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\[) ((?:$qq_bracket)+?)          (\]) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\<) ((?:$qq_angle)+?)            (\>) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ qq \s* (\S) ((?:$qq_char)+?)             (\3) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+    \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_q ('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) /oxgc)    { $e_string .= "Char::Egbk::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s* (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                                          { $e_string .= "Char::Egbk::$1($2)";      $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s* \( ((?:$qq_paren)*?) \) /oxgc)                          { $e_string .= "Char::Egbk::$1($2)";      $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?= \s+ [a-z]+) /oxgc)                                      { $e_string .= "Char::Egbk::$1";          $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) \s+ (\w+) /oxgc)                                            { $e_string .= "Char::Egbk::$1(::"."$2)"; $slash = 'm//'; }
        elsif ($string =~ /\G -(t)                            \s+ (\w+) /oxgc)                                            { $e_string .= "-t $2";              $slash = 'm//'; }
        elsif ($string =~ /\G \b lstat         (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::lstat';             $slash = 'm//'; }
        elsif ($string =~ /\G \b stat          (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::stat';              $slash = 'm//'; }

        # "-s '' ..." means file test "-s 'filename' ..." (not means "- s/// ...")
        elsif ($string =~ /\G -s                               \s+    \s* (\") ((?:$qq_char)+?)             (\") /oxgc)    { $e_string .= '-s ' . e_qq('',  $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ qq \s* (\#) ((?:$qq_char)+?)             (\#) /oxgc)    { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ qq \s* (\() ((?:$qq_paren)+?)            (\)) /oxgc)    { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ qq \s* (\{) ((?:$qq_brace)+?)            (\}) /oxgc)    { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ qq \s* (\[) ((?:$qq_bracket)+?)          (\]) /oxgc)    { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ qq \s* (\<) ((?:$qq_angle)+?)            (\>) /oxgc)    { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ qq \s* (\S) ((?:$qq_char)+?)             (\3) /oxgc)    { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }

        elsif ($string =~ /\G -s                               \s+    \s* (\') ((?:\\\1|\\\\|$q_char)+?)    (\') /oxgc)    { $e_string .= '-s ' . e_q ('',  $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ q  \s* (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) /oxgc)    { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ q  \s* (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) /oxgc)    { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ q  \s* (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) /oxgc)    { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ q  \s* (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) /oxgc)    { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ q  \s* (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) /oxgc)    { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ q  \s* (\S) ((?:\\\1|\\\\|$q_char)+?)    (\3) /oxgc)    { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }

        elsif ($string =~ /\G -s                               \s* (\$ \w+(?: ::\w+)* (?: (?: ->)? (?: \( (?:$qq_paren)*? \) | \{ (?:$qq_brace)+? \} | \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                                           { $e_string .= "-s $1";   $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s* \( ((?:$qq_paren)*?) \) /oxgc)                          { $e_string .= "-s ($1)"; $slash = 'm//'; }
        elsif ($string =~ /\G -s                               (?= \s+ [a-z]+) /oxgc)                                      { $e_string .= '-s';      $slash = 'm//'; }
        elsif ($string =~ /\G -s                               \s+ (\w+) /oxgc)                                            { $e_string .= "-s $1";   $slash = 'm//'; }

        elsif ($string =~ /\G \b bytes::length (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'length';                   $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::chr    (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'chr';                      $slash = 'm//'; }
        elsif ($string =~ /\G \b chr           (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::chr';               $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::ord    (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'ord';                      $slash = 'div'; }
        elsif ($string =~ /\G \b ord           (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= $function_ord;              $slash = 'div'; }
        elsif ($string =~ /\G \b glob          (?= \s+[A-Za-z_]|\s*['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Char::Egbk::glob';              $slash = 'm//'; }
        elsif ($string =~ /\G \b lc \b                                              /oxgc) { $e_string .= 'Char::Egbk::lc_';               $slash = 'm//'; }
        elsif ($string =~ /\G \b lcfirst \b                                         /oxgc) { $e_string .= 'Char::Egbk::lcfirst_';          $slash = 'm//'; }
        elsif ($string =~ /\G \b uc \b                                              /oxgc) { $e_string .= 'Char::Egbk::uc_';               $slash = 'm//'; }
        elsif ($string =~ /\G \b ucfirst \b                                         /oxgc) { $e_string .= 'Char::Egbk::ucfirst_';          $slash = 'm//'; }
        elsif ($string =~ /\G \b fc \b                                              /oxgc) { $e_string .= 'Char::Egbk::fc_';               $slash = 'm//'; }
        elsif ($string =~ /\G    (-[rwxoRWXOezfdlpSbcugkTB](?:\s+-[rwxoRWXOezfdlpSbcugkTB])+)
                                                                 \b                 /oxgc) { $e_string .= "Char::Egbk::filetest_(qw($1))"; $slash = 'm//'; }
        elsif ($string =~ /\G    -([rwxoRWXOezsfdlpSbcugkTBMAC]) \b                 /oxgc) { $e_string .= "Char::Egbk::${1}_";             $slash = 'm//'; }
        elsif ($string =~ /\G \b lstat \b                                           /oxgc) { $e_string .= 'Char::Egbk::lstat_';            $slash = 'm//'; }
        elsif ($string =~ /\G \b stat \b                                            /oxgc) { $e_string .= 'Char::Egbk::stat_';             $slash = 'm//'; }
        elsif ($string =~ /\G    -s                              \b                 /oxgc) { $e_string .= '-s ';                      $slash = 'm//'; }

        elsif ($string =~ /\G \b bytes::length \b                                   /oxgc) { $e_string .= 'length';                   $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::chr \b                                      /oxgc) { $e_string .= 'chr';                      $slash = 'm//'; }
        elsif ($string =~ /\G \b chr \b                                             /oxgc) { $e_string .= 'Char::Egbk::chr_';              $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::ord \b                                      /oxgc) { $e_string .= 'ord';                      $slash = 'div'; }
        elsif ($string =~ /\G \b ord \b                                             /oxgc) { $e_string .= $function_ord_;             $slash = 'div'; }
        elsif ($string =~ /\G \b glob \b                                            /oxgc) { $e_string .= 'Char::Egbk::glob_';             $slash = 'm//'; }
        elsif ($string =~ /\G \b reverse \b                                         /oxgc) { $e_string .= $function_reverse;          $slash = 'm//'; }
        elsif ($string =~ /\G \b opendir (\s* \( \s*) (?=[A-Za-z_])                 /oxgc) { $e_string .= "Char::Egbk::opendir$1*";        $slash = 'm//'; }
        elsif ($string =~ /\G \b opendir (\s+)        (?=[A-Za-z_])                 /oxgc) { $e_string .= "Char::Egbk::opendir$1*";        $slash = 'm//'; }
        elsif ($string =~ /\G \b unlink \b                                          /oxgc) { $e_string .= 'Char::Egbk::unlink';            $slash = 'm//'; }

# chdir
        elsif ($string =~ /\G \b (chdir) \b (?! \s* => ) /oxgc) {
            $slash = 'm//';

            $e_string .= 'Char::Egbk::chdir';

            while ($string =~ /\G ( \s+ | \( | \#.* ) /oxgc) {
                $e_string .= $1;
            }

# end of chdir
            if    ($string =~ /\G (?= [,;\)\}\]] )          /oxgc) { return $e_string;                               }

# chdir scalar value
            elsif ($string =~ /\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { $e_string .= e_string($1);  next E_STRING_LOOP; }

# chdir qq//
            elsif ($string =~ /\G \b (qq) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                             { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                             /oxgc)      { $e_string .= $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc)      { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq ( ) --> qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc)      { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq { } --> qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc)      { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc)      { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc)      { $e_string .= e_chdir('qq','{','}',$2); next E_STRING_LOOP; } # qq | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc)      { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq * * --> qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }
            }

# chdir q//
            elsif ($string =~ /\G \b (q) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                                  /oxgc) { $e_string .= $1; }
                        elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q ( ) --> qr ( )
                        elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q { } --> qr { }
                        elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { $e_string .= e_chdir_q('q','{','}',$2); next E_STRING_LOOP; } # q | | --> qr { }
                        elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q * * --> qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }
            }

# chdir ''
            elsif ($string =~ /\G (\') /oxgc) {
                my $q_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $q_string .= $1; }
                    elsif ($string =~ /\G (\\\')    /oxgc) { $q_string .= $1; }
                    elsif ($string =~ /\G \'        /oxgc)                                       { $e_string .= e_chdir_q('',"'","'",$q_string); next E_STRING_LOOP; }
                    elsif ($string =~ /\G ($q_char) /oxgc) { $q_string .= $1; }
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }

# chdir ""
            elsif ($string =~ /\G (\") /oxgc) {
                my $qq_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $qq_string .= $1; }
                    elsif ($string =~ /\G (\\\")    /oxgc) { $qq_string .= $1; }
                    elsif ($string =~ /\G \"        /oxgc)                                       { $e_string .= e_chdir('','"','"',$qq_string); next E_STRING_LOOP; }
                    elsif ($string =~ /\G ($q_char) /oxgc) { $qq_string .= $1; }
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# split
        elsif ($string =~ /\G \b (split) \b (?! \s* => ) /oxgc) {
            $slash = 'm//';

            my $e = '';
            while ($string =~ /\G ( \s+ | \( | \#.* ) /oxgc) {
                $e .= $1;
            }

# end of split
            if    ($string =~ /\G (?= [,;\)\}\]] )          /oxgc) { return 'Char::Egbk::split' . $e;                                           }

# split scalar value
            elsif ($string =~ /\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . e_string($1);  next E_STRING_LOOP; }

# split literal space
            elsif ($string =~ /\G \b qq       (\#) [ ] (\#) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq  {qq$1 $2}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\() [ ] (\)) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\{) [ ] (\}) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\[) [ ] (\]) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\<) [ ] (\>) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq (\s*) (\S) [ ] (\2) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q        (\#) [ ] (\#) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq   {q$1 $2}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\() [ ] (\)) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\{) [ ] (\}) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\[) [ ] (\]) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\<) [ ] (\>) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  (\s*) (\S) [ ] (\2) /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G                ' [ ] '    /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq     {' '};  next E_STRING_LOOP; }
            elsif ($string =~ /\G                " [ ] "    /oxgc) { $e_string .= 'Char::Egbk::split' . $e . qq     {" "};  next E_STRING_LOOP; }

# split qq//
            elsif ($string =~ /\G \b (qq) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                        { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                             /oxgc) { $e_string .= $e . $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq ( ) --> qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq { } --> qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= e_split($e.'qr','{','}',$2,''); next E_STRING_LOOP; } # qq | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq * * --> qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }
            }

# split qr//
            elsif ($string =~ /\G \b (qr) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) ([imosxpadlubB]*) /oxgc)                        { $e_string .= e_split  ($e.'qr',$1,$3,$2,$4);   next E_STRING_LOOP; } # qr# #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                                               /oxgc) { $e_string .= $e . $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr < >
                        elsif ($string =~ /\G (\')          ((?:$qq_char)*?)    (\') ([imosxpadlubB]*) /oxgc) { $e_string .= e_split_q($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr ' '
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr','{','}',$2,$4); next E_STRING_LOOP; } # qr | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }
            }

# split q//
            elsif ($string =~ /\G \b (q) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                                  /oxgc) { $e_string .= $e . $1; }
                        elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q ( ) --> qr ( )
                        elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q { } --> qr { }
                        elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { $e_string .= e_split_q($e.'qr','{','}',$2,''); next E_STRING_LOOP; } # q | | --> qr { }
                        elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q * * --> qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF";
                }
            }

# split m//
            elsif ($string =~ /\G \b (m) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxpadlubB]*) /oxgc)                        { $e_string .= e_split  ($e.'qr',$1,$3,$2,$4);   next E_STRING_LOOP; } # m# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G (\s+|\#.*)                                                 /oxgc) { $e_string .= $e . $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) ([cgimosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m ( ) --> qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) ([cgimosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m { } --> qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) ([cgimosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) ([cgimosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m < > --> qr < >
                        elsif ($string =~ /\G (\')          ((?:$qq_char)*?)    (\') ([cgimosxpadlubB]*) /oxgc) { $e_string .= e_split_q($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m ' ' --> qr ' '
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr','{','}',$2,$4); next E_STRING_LOOP; } # m | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) ([cgimosxpadlubB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m * * --> qr * *
                    }
                    die __FILE__, ": Search pattern not terminated";
                }
            }

# split ''
            elsif ($string =~ /\G (\') /oxgc) {
                my $q_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $q_string .= $1; }
                    elsif ($string =~ /\G (\\\')    /oxgc) { $q_string .= $1; } # splitqr'' --> split qr''
                    elsif ($string =~ /\G \'        /oxgc)                      { $e_string .= e_split_q($e.q{ qr},"'","'",$q_string,''); next E_STRING_LOOP; } # ' ' --> qr ' '
                    elsif ($string =~ /\G ($q_char) /oxgc) { $q_string .= $1; }
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }

# split ""
            elsif ($string =~ /\G (\") /oxgc) {
                my $qq_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $qq_string .= $1; }
                    elsif ($string =~ /\G (\\\")    /oxgc) { $qq_string .= $1; } # splitqr"" --> split qr""
                    elsif ($string =~ /\G \"        /oxgc)                       { $e_string .= e_split($e.q{ qr},'"','"',$qq_string,''); next E_STRING_LOOP; } # " " --> qr " "
                    elsif ($string =~ /\G ($q_char) /oxgc) { $qq_string .= $1; }
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }

# split //
            elsif ($string =~ /\G (\/) /oxgc) {
                my $regexp = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)                 /oxgc) { $regexp .= $1; }
                    elsif ($string =~ /\G (\\\/)                 /oxgc) { $regexp .= $1; } # splitqr// --> split qr//
                    elsif ($string =~ /\G \/ ([cgimosxpadlubB]*) /oxgc)                    { $e_string .= e_split($e.q{ qr}, '/','/',$regexp,$1); next E_STRING_LOOP; } # / / --> qr / /
                    elsif ($string =~ /\G ($q_char)              /oxgc) { $regexp .= $1; }
                }
                die __FILE__, ": Search pattern not terminated";
            }
        }

# qq//
        elsif ($string =~ /\G \b (qq) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qq# #
                $e_string .= e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq ( )
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq { }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq [ ]
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq < >
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# qx//
        elsif ($string =~ /\G \b (qx) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qx# #
                $e_string .= e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx ( )
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx { }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx [ ]
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx < >
                    elsif ($string =~ /\G (\') ((?:$qq_char)*?)    (\') /oxgc) { $e_string .= $e . e_q ($ope,$1,$3,$2); next E_STRING_LOOP; } # qx ' '
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# q//
        elsif ($string =~ /\G \b (q) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) { # q# #
                $e_string .= e_q($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q ( )
                    elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q { }
                    elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q [ ]
                    elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q < >
                    elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF";
            }
        }

# ''
        elsif ($string =~ /\G (?<![\w\$\@\%\&\*]) (\') ((?:\\\'|\\\\|$q_char)*?) (\') /oxgc) { $e_string .= e_q('',$1,$3,$2);  }

# ""
        elsif ($string =~ /\G (\") ((?:$qq_char)*?) (\") /oxgc)                              { $e_string .= e_qq('',$1,$3,$2); }

# ``
        elsif ($string =~ /\G (\`) ((?:$qq_char)*?) (\`) /oxgc)                              { $e_string .= e_qq('',$1,$3,$2); }

# <<= <=> <= < operator
        elsif ($string =~ /\G (<<=|<=>|<=|<) (?= \s* [A-Za-z_0-9'"`\$\@\&\*\(\+\-] )/oxgc)   { $e_string .= $1;                }

# <FILEHANDLE>
        elsif ($string =~ /\G (<[\$]?[A-Za-z_][A-Za-z_0-9]*>) /oxgc)                         { $e_string .= $1;                }

# <WILDCARD>   --- glob
        elsif ($string =~ /\G < ((?:$q_char)+?) > /oxgc) {
            $e_string .= 'Char::Egbk::glob("' . $1 . '")';
        }

# << (bit shift)   --- not here document
        elsif ($string =~ /\G ( << \s* ) (?= [0-9\$\@\&] ) /oxgc) { $slash = 'm//'; $e_string .= $1; }

# <<'HEREDOC'
        elsif ($string =~ /\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, $1 . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

# <<\HEREDOC
        elsif ($string =~ /\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, $1 . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

# <<"HEREDOC"
        elsif ($string =~ /\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

# <<HEREDOC
        elsif ($string =~ /\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

# <<`HEREDOC`
        elsif ($string =~ /\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF";
            }
            $e_string .= $here_quote;
        }

        # any operator before div
        elsif ($string =~ /\G (
            -- | \+\+ |
            [\)\}\]]

            ) /oxgc) { $slash = 'div'; $e_string .= $1; }

        # any operator before m//
        elsif ($string =~ /\G (

            !~~ | !~ | != | ! |
            %= | % |
            &&= | && | &= | & |
            -= | -> | - |
            :\s*= |
            : |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+= | \+ |
            \.\.\. | \.\. | \.= | \. |
            \/\/= | \/\/ |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \| |
            ~~ | ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |
            \b(?: print )\b |

            [,;\(\{\[]

            ) /oxgc) { $slash = 'm//'; $e_string .= $1; }

        # other any character
        elsif ($string =~ /\G ($q_char) /oxgc) { $e_string .= $1; }

        # system error
        else {
            die __FILE__, ": Oops, this shouldn't happen!";
        }
    }

    return $e_string;
}

#
# character class
#
sub character_class {
    my($char,$modifier) = @_;

    if ($char eq '.') {
        if ($modifier =~ /s/) {
            return '${Char::Egbk::dot_s}';
        }
        else {
            return '${Char::Egbk::dot}';
        }
    }
    else {
        return Char::Egbk::classic_character_class($char);
    }
}

#
# escape capture ($1, $2, $3, ...)
#
sub e_capture {

    return join '', '${Char::Egbk::capture(', $_[0], ')}';
    return join '', '$',                 $_[0];
}

#
# escape transliteration (tr/// or y///)
#
sub e_tr {
    my($variable,$charclass,$e,$charclass2,$modifier) = @_;
    my $e_tr = '';
    $modifier ||= '';

    $slash = 'div';

    # quote character class 1
    $charclass  = q_tr($charclass);

    # quote character class 2
    $charclass2 = q_tr($charclass2);

    # /b /B modifier
    if ($modifier =~ tr/bB//d) {
        if ($variable eq '') {
            $e_tr = qq{tr$charclass$e$charclass2$modifier};
        }
        else {
            $e_tr = qq{$variable${bind_operator}tr$charclass$e$charclass2$modifier};
        }
    }
    else {
        if ($variable eq '') {
            $e_tr = qq{Char::Egbk::tr(\$_,' =~ ',$charclass,$e$charclass2,'$modifier')};
        }
        else {
            $e_tr = qq{Char::Egbk::tr($variable,'$bind_operator',$charclass,$e$charclass2,'$modifier')};
        }
    }

    # clear tr/// variable
    $tr_variable = '';
    $bind_operator = '';

    return $e_tr;
}

#
# quote for escape transliteration (tr/// or y///)
#
sub q_tr {
    my($charclass) = @_;

    # quote character class
    if ($charclass !~ /'/oxms) {
        return e_q('',  "'", "'", $charclass); # --> q' '
    }
    elsif ($charclass !~ /\//oxms) {
        return e_q('q',  '/', '/', $charclass); # --> q/ /
    }
    elsif ($charclass !~ /\#/oxms) {
        return e_q('q',  '#', '#', $charclass); # --> q# #
    }
    elsif ($charclass !~ /[\<\>]/oxms) {
        return e_q('q', '<', '>', $charclass); # --> q< >
    }
    elsif ($charclass !~ /[\(\)]/oxms) {
        return e_q('q', '(', ')', $charclass); # --> q( )
    }
    elsif ($charclass !~ /[\{\}]/oxms) {
        return e_q('q', '{', '}', $charclass); # --> q{ }
    }
    else {
        for my $char (qw( ! " $ % & * + . : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
            if ($charclass !~ /\Q$char\E/xms) {
                return e_q('q', $char, $char, $charclass);
            }
        }
    }

    return e_q('q', '{', '}', $charclass);
}

#
# escape q string (q//, '')
#
sub e_q {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my @char = $string =~ / \G ($q_char) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape last octet of multiple-octet
        if ($char[$i] =~ /\A ([\x80-\xFF].*) (\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }
        elsif (($char[$i] =~ /\A ([\x80-\xFF].*) (\\) \z/xms) and defined($char[$i+1]) and ($char[$i+1] eq '\\')) {
            $char[$i] = $1 . '\\' . $2;
        }
    }
    if (defined($char[-1]) and ($char[-1] =~ /\A ([\x80-\xFF].*) (\\) \z/xms)) {
        $char[-1] = $1 . '\\' . $2;
    }

    return join '', $ope, $delimiter, @char,   $end_delimiter;
    return join '', $ope, $delimiter, $string, $end_delimiter;
}

#
# escape qq string (qq//, "", qx//, ``)
#
sub e_qq {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ /\G(
        \\o\{ [0-7]+          \}   |
        \\x\{ [0-9A-Fa-f]+    \}   |
        \\N\{ [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     |
                        \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} |
        \$ \s* \d+                 |
        \$ \s* \{ \s* \d+ \s* \}   |
        \$ \$ (?![\w\{])           |
        \$ \s* \$ \s* $qq_variable |
        \\?(?:$q_char)
    )/oxmsg;

    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::hexchr($1);
        }

        # \N{CHARNAME} --> N{CHARNAME}
        elsif ($char[$i] =~ /\A \\ ( N\{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1;
        }

        if (0) {
        }

        # escape last octet of multiple-octet
        # my $metachar = qr/[\@\\\|]/oxms; # '|' is for qx//, ``, open() and system()
        # variable $delimiter and $end_delimiter can be ''
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ([\@\\\|$delimiter$end_delimiter]) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \F
        #
        # P.69 Table 2-6. Translation escapes
        # in Chapter 2: Bits and Pieces
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.
        # (and so on)

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {

            # "STRING @{[ LIST EXPR ]} MORE STRING"

            # P.257 Other Tricks You Can Do with Hard References
            # in Chapter 8: References
            # of ISBN 0-596-00027-8 Programming Perl Third Edition.

            # P.353 Other Tricks You Can Do with Hard References
            # in Chapter 8: References
            # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

            # (and so on)

            $char[$i] = '@{[Char::Egbk::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Char::Egbk::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Char::Egbk::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Char::Egbk::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Char::Egbk::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* 0 \s* \} \z/oxms) {
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = e_capture($1);
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = e_capture($1);
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Char::Egbk::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH \s* \}  | \$ \s* \{\^PREMATCH\}  ) \z/oxmsgc) {
            $char[$i] = '@{[Char::Egbk::PREMATCH()]}';
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Char::Egbk::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     ) \z/oxmsgc) {
            $char[$i] = '@{[Char::Egbk::MATCH()]}';
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Char::Egbk::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} ) \z/oxmsgc) {
            $char[$i] = '@{[Char::Egbk::POSTMATCH()]}';
        }

        # ${ foo } --> ${ foo }
        elsif ($char[$i] =~ /\A \$ \s* \{ \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* \} \z/oxms) {
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    return     join '', $ope, $delimiter, @char,                               $end_delimiter;
}

#
# escape qw string (qw//)
#
sub e_qw {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    # choice again delimiter
    my %octet = map {$_ => 1} ($string =~ /\G ([\x00-\xFF]) /oxmsg);
    if (not $octet{$end_delimiter}) {
        return join '', $ope, $delimiter, $string, $end_delimiter;
    }
    elsif (not $octet{')'}) {
        return join '', $ope, '(',        $string, ')';
    }
    elsif (not $octet{'}'}) {
        return join '', $ope, '{',        $string, '}';
    }
    elsif (not $octet{']'}) {
        return join '', $ope, '[',        $string, ']';
    }
    elsif (not $octet{'>'}) {
        return join '', $ope, '<',        $string, '>';
    }
    else {
        for my $char (qw( ! " $ % & * + - . / : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
            if (not $octet{$char}) {
                return join '', $ope,      $char, $string, $char;
            }
        }
    }

    # qw/AAA BBB C'CC/ --> ('AAA', 'BBB', 'C\'CC')
    my @string = CORE::split(/\s+/, $string);
    for my $string (@string) {
        my @octet = $string =~ /\G ([\x00-\xFF]) /oxmsg;
        for my $octet (@octet) {
            if ($octet =~ /\A (['\\]) \z/oxms) {
                $octet = '\\' . $1;
            }
        }
        $string = join '', @octet;
    }
    return join '', '(', (join ', ', map { "'$_'" } @string), ')';
}

#
# escape here document (<<"HEREDOC", <<HEREDOC, <<`HEREDOC`)
#
sub e_heredoc {
    my($string) = @_;

    $slash = 'm//';

    my $metachar = qr/[\@\\|]/oxms; # '|' is for <<`HEREDOC`

    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ /\G(
        \\o\{ [0-7]+          \}   |
        \\x\{ [0-9A-Fa-f]+    \}   |
        \\N\{ [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     |
                        \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} |
        \$ \s* \d+                 |
        \$ \s* \{ \s* \d+ \s* \}   |
        \$ \$ (?![\w\{])           |
        \$ \s* \$ \s* $qq_variable |
        \\?(?:$q_char)
    )/oxmsg;

    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::hexchr($1);
        }

        # \N{CHARNAME} --> N{CHARNAME}
        elsif ($char[$i] =~ /\A \\ ( N\{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1;
        }

        if (0) {
        }

        # escape character
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {
            $char[$i] = '@{[Char::Egbk::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Char::Egbk::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Char::Egbk::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Char::Egbk::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Char::Egbk::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* 0 \s* \} \z/oxms) {
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = e_capture($1);
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = e_capture($1);
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Char::Egbk::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  ) \z/oxmsgc) {
            $char[$i] = '@{[Char::Egbk::PREMATCH()]}';
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Char::Egbk::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     ) \z/oxmsgc) {
            $char[$i] = '@{[Char::Egbk::MATCH()]}';
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Char::Egbk::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} ) \z/oxmsgc) {
            $char[$i] = '@{[Char::Egbk::POSTMATCH()]}';
        }

        # ${ foo } --> ${ foo }
        elsif ($char[$i] =~ /\A \$ \s* \{ \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* \} \z/oxms) {
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', @char, '>]}' x ($left_e - $right_e);
    }
    return     join '', @char;
}

#
# escape regexp (m//, qr//)
#
sub e_qr {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # literal null string pattern
    if ($string eq '') {
        $modifier =~ tr/bB//d;
        $modifier =~ tr/i//d;
        return join '', $ope, $delimiter, $end_delimiter, $modifier;
    }

    # /b /B modifier
    elsif ($modifier =~ tr/bB//d) {

        # choice again delimiter
        if ($delimiter =~ / [\@:] /oxms) {
            my @char = $string =~ /\G([\x00-\xFF])/oxmsg;
            my %octet = map {$_ => 1} @char;
            if (not $octet{')'}) {
                $delimiter     = '(';
                $end_delimiter = ')';
            }
            elsif (not $octet{'}'}) {
                $delimiter     = '{';
                $end_delimiter = '}';
            }
            elsif (not $octet{']'}) {
                $delimiter     = '[';
                $end_delimiter = ']';
            }
            elsif (not $octet{'>'}) {
                $delimiter     = '<';
                $end_delimiter = '>';
            }
            else {
                for my $char (qw( ! " $ % & * + - . / = ? ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
                    if (not $octet{$char}) {
                        $delimiter     = $char;
                        $end_delimiter = $char;
                        last;
                    }
                }
            }
        }

        if (($ope =~ /\A m? \z/oxms) and ($delimiter eq '?')) {
            return join '', $ope, $delimiter,        $string,      $matched, $end_delimiter, $modifier;
        }
        else {
            return join '', $ope, $delimiter, '(?:', $string, ')', $matched, $end_delimiter, $modifier;
        }
    }

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;
    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ /\G(
        \\o\{ [0-7]+           \}  |
        \\    [0-7]{2,3}           |
        \\x\{ [0-9A-Fa-f]+     \}  |
        \\x   [0-9A-Fa-f]{1,2}     |
        \\c   [\x40-\x5F]          |
        \\N\{ [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\p\{ [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\P\{ [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\  (?:$q_char)            |
        \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     |
                        \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} |
        [\$\@] $qq_variable        |
        \$ \s* \d+                 |
        \$ \s* \{ \s* \d+ \s* \}   |
        \$ \$ (?![\w\{])           |
        \$ \s* \$ \s* $qq_variable |
        \[\:\^ (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] |
        \[\:   (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] |
        \[\^                       |
        \(\?                       |
            (?:$q_char)
    )/oxmsg;

    # choice again delimiter
    if ($delimiter =~ / [\@:] /oxms) {
        my %octet = map {$_ => 1} @char;
        if (not $octet{')'}) {
            $delimiter     = '(';
            $end_delimiter = ')';
        }
        elsif (not $octet{'}'}) {
            $delimiter     = '{';
            $end_delimiter = '}';
        }
        elsif (not $octet{']'}) {
            $delimiter     = '[';
            $end_delimiter = ']';
        }
        elsif (not $octet{'>'}) {
            $delimiter     = '<';
            $end_delimiter = '>';
        }
        else {
            for my $char (qw( ! " $ % & * + - . / = ? ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
                if (not $octet{$char}) {
                    $delimiter     = $char;
                    $end_delimiter = $char;
                    last;
                }
            }
        }
    }

    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::hexchr($1);
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

        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple-octet
        elsif ($char[$i] =~ /\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;

            # [] make die "Unmatched [] in regexp ..."
            # (and so on)

            if ($char[$i+1] eq ']') {
                $i++;
            }

            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Char::Egbk::charlist_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Char::Egbk::charlist_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;

            # [^] make die "Unmatched [] in regexp ..."
            # (and so on)

            if ($char[$i+1] eq ']') {
                $i++;
            }

            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Char::Egbk::charlist_not_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Char::Egbk::charlist_not_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Char::Egbk::uc($char[$i]) ne Char::Egbk::fc($char[$i]))) {
            if (CORE::length(Char::Egbk::fc($char[$i])) == 1) {
                $char[$i] = '['   . Char::Egbk::uc($char[$i])       . Char::Egbk::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Char::Egbk::uc($char[$i]) . '|' . Char::Egbk::fc($char[$i]) . ')';
            }
        }

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A [<>] \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {
            $char[$i] = '@{[Char::Egbk::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Char::Egbk::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Char::Egbk::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Char::Egbk::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Char::Egbk::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* 0 \s* \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Char::Egbk::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::PREMATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::PREMATCH()]}';
            }
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Char::Egbk::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::MATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::MATCH()]}';
            }
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Char::Egbk::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::POSTMATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::POSTMATCH()]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ /\A \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ /\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
            }
            elsif (($ope =~ /\A m? \z/oxms) and ($delimiter eq '?')) {
                my $char = $char[$i-1];
                if ($char[$i] eq '{') {
                    die __FILE__, qq{: "MULTIBYTE{n}" should be "(MULTIBYTE){n}" in m?? (and shift \$1,\$2,\$3,...) ($char){n}};
                }
                else {
                    die __FILE__, qq{: "MULTIBYTE$char[$i]" should be "(MULTIBYTE)$char[$i]" in m?? (and shift \$1,\$2,\$3,...) ($char)$char[$i]};
                }
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        if (($ope =~ /\A m? \z/oxms) and ($delimiter eq '?')) {
            return join '', $ope, $delimiter, $anchor,        @char, '>]}' x ($left_e - $right_e),      $matched, $end_delimiter, $modifier;
        }
        else {
            return join '', $ope, $delimiter, $anchor, '(?:', @char, '>]}' x ($left_e - $right_e), ')', $matched, $end_delimiter, $modifier;
        }
    }
    if (($ope =~ /\A m? \z/oxms) and ($delimiter eq '?')) {
        return     join '', $ope, $delimiter, $anchor,        @char,                                    $matched, $end_delimiter, $modifier;
    }
    else {
        return     join '', $ope, $delimiter, $anchor, '(?:', @char,                               ')', $matched, $end_delimiter, $modifier;
    }
}

#
# double quote stuff
#
sub qq_stuff {
    my($delimiter,$end_delimiter,$stuff) = @_;

    # scalar variable or array variable
    if ($stuff =~ /\A [\$\@] /oxms) {
        return $stuff;
    }

    # quote by delimiter
    my %octet = map {$_ => 1} ($stuff =~ /\G ([\x00-\xFF]) /oxmsg);
    for my $char (qw( ! " $ % & * + - . / : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
        next if $char eq $delimiter;
        next if $char eq $end_delimiter;
        if (not $octet{$char}) {
            return join '', 'qq', $char, $stuff, $char;
        }
    }
    return join '', 'qq', '<', $stuff, '>';
}

#
# escape regexp (m'', qr'' and m''b, qr''b)
#
sub e_qr_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # literal null string pattern
    if ($string eq '') {
        $modifier =~ tr/bB//d;
        $modifier =~ tr/i//d;
        return join '', $ope, $delimiter, $end_delimiter, $modifier;
    }

    # with /b /B modifier
    elsif ($modifier =~ tr/bB//d) {
        return e_qr_qb($ope,$delimiter,$end_delimiter,$string,$modifier);
    }

    # without /b /B modifier
    else {
        return e_qr_qt($ope,$delimiter,$end_delimiter,$string,$modifier);
    }
}

#
# escape regexp (m'', qr'')
#
sub e_qr_qt {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;

    # split regexp
    my @char = $string =~ /\G(
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
        [\$\@\/\\]          |
        \\?    (?:$q_char)
    )/oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Char::Egbk::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Char::Egbk::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Char::Egbk::uc($char[$i]) ne Char::Egbk::fc($char[$i]))) {
            if (CORE::length(Char::Egbk::fc($char[$i])) == 1) {
                $char[$i] = '['   . Char::Egbk::uc($char[$i])       . Char::Egbk::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Char::Egbk::uc($char[$i]) . '|' . Char::Egbk::fc($char[$i]) . ')';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A [\x00-\xFF] \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $delimiter     = '/';
    $end_delimiter = '/';

    $modifier =~ tr/i//d;
    return join '', $ope, $delimiter, $anchor, '(?:', @char, ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (m''b, qr''b)
#
sub e_qr_qb {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;

    # split regexp
    my @char = $string =~ /\G(
        \\\\        |
        [\$\@\/\\]  |
        [\x00-\xFF]
    )/oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # remain \\
        elsif ($char[$i] eq '\\\\') {
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }
    }

    $delimiter     = '/';
    $end_delimiter = '/';
    return join '', $ope, $delimiter, '(?:', @char, ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (s/here//)
#
sub e_s1 {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # literal null string pattern
    if ($string eq '') {
        $modifier =~ tr/bB//d;
        $modifier =~ tr/i//d;
        return join '', $ope, $delimiter, $end_delimiter, $modifier;
    }

    # /b /B modifier
    elsif ($modifier =~ tr/bB//d) {

        # choice again delimiter
        if ($delimiter =~ / [\@:] /oxms) {
            my @char = $string =~ /\G([\x00-\xFF])/oxmsg;
            my %octet = map {$_ => 1} @char;
            if (not $octet{')'}) {
                $delimiter     = '(';
                $end_delimiter = ')';
            }
            elsif (not $octet{'}'}) {
                $delimiter     = '{';
                $end_delimiter = '}';
            }
            elsif (not $octet{']'}) {
                $delimiter     = '[';
                $end_delimiter = ']';
            }
            elsif (not $octet{'>'}) {
                $delimiter     = '<';
                $end_delimiter = '>';
            }
            else {
                for my $char (qw( ! " $ % & * + - . / = ? ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
                    if (not $octet{$char}) {
                        $delimiter     = $char;
                        $end_delimiter = $char;
                        last;
                    }
                }
            }
        }

        my $prematch = '';
        $prematch = q{(\G[\x00-\xFF]*?)};
        return join '', $ope, $delimiter, $prematch, '(?:', $string, ')', $matched, $end_delimiter, $modifier;
    }

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;
    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ /\G(
        \\g \s* \{ \s* - \s* [1-9][0-9]* \s* \} |
        \\g \s* \{ \s*       [1-9][0-9]* \s* \} |
        \\g \s*              [1-9][0-9]*        |
        \\o\{                [0-7]+          \} |
        \\                   [1-9][0-9]*        |
        \\                   [0-7]{2,3}         |
        \\x\{                [0-9A-Fa-f]+    \} |
        \\x                  [0-9A-Fa-f]{1,2}   |
        \\c                  [\x40-\x5F]        |
        \\N\{                [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\p\{                [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\P\{                [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\  (?:$q_char)                         |
        \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     |
                        \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} |
        [\$\@] $qq_variable                     |
        \$ \s* \d+                              |
        \$ \s* \{ \s* \d+ \s* \}                |
        \$ \$ (?![\w\{])                        |
        \$ \s* \$ \s* $qq_variable              |
        \[\:\^ (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] |
        \[\:   (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] |
        \[\^                                    |
        \(\?                                    |
            (?:$q_char)
    )/oxmsg;

    # choice again delimiter
    if ($delimiter =~ / [\@:] /oxms) {
        my %octet = map {$_ => 1} @char;
        if (not $octet{')'}) {
            $delimiter     = '(';
            $end_delimiter = ')';
        }
        elsif (not $octet{'}'}) {
            $delimiter     = '{';
            $end_delimiter = '}';
        }
        elsif (not $octet{']'}) {
            $delimiter     = '[';
            $end_delimiter = ']';
        }
        elsif (not $octet{'>'}) {
            $delimiter     = '<';
            $end_delimiter = '>';
        }
        else {
            for my $char (qw( ! " $ % & * + - . / = ? ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
                if (not $octet{$char}) {
                    $delimiter     = $char;
                    $end_delimiter = $char;
                    last;
                }
            }
        }
    }

    # count '('
    my $parens = grep { $_ eq '(' } @char;

    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::hexchr($1);
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

        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple-octet
        elsif ($char[$i] =~ /\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Char::Egbk::charlist_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Char::Egbk::charlist_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Char::Egbk::charlist_not_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Char::Egbk::charlist_not_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Char::Egbk::uc($char[$i]) ne Char::Egbk::fc($char[$i]))) {
            if (CORE::length(Char::Egbk::fc($char[$i])) == 1) {
                $char[$i] = '['   . Char::Egbk::uc($char[$i])       . Char::Egbk::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Char::Egbk::uc($char[$i]) . '|' . Char::Egbk::fc($char[$i]) . ')';
            }
        }

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A [<>] \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {
            $char[$i] = '@{[Char::Egbk::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Char::Egbk::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Char::Egbk::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Char::Egbk::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Char::Egbk::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # \0 --> \0
        elsif ($char[$i] =~ /\A \\ \s* 0 \z/oxms) {
        }

        # \g{N}, \g{-N}

        # P.108 Using Simple Patterns
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        # P.221 Capturing
        # in Chapter 5: Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # \g{-1}, \g{-2}, \g{-3} --> \g{-1}, \g{-2}, \g{-3}
        elsif ($char[$i] =~ /\A \\g \s* \{ \s* - \s* ([1-9][0-9]*) \s* \} \z/oxms) {
        }

        # \g{1}, \g{2}, \g{3} --> \g{2}, \g{3}, \g{4} (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \\g \s* \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\g{' . ($1 + 1) . '}';
            }
        }

        # \g1, \g2, \g3 --> \g2, \g3, \g4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \\g \s* ([1-9][0-9]*) \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\g' . ($1 + 1);
            }
        }

        # \1, \2, \3 --> \2, \3, \4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \\ \s* ([1-9][0-9]*) \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\' . ($1 + 1);
            }
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* 0 \s* \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Char::Egbk::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::PREMATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::PREMATCH()]}';
            }
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Char::Egbk::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::MATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::MATCH()]}';
            }
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Char::Egbk::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::POSTMATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::POSTMATCH()]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ /\A \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ /\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    my $prematch = '';
    $prematch = "($anchor)";
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, $prematch, '(?:', @char, '>]}' x ($left_e - $right_e), ')', $matched, $end_delimiter, $modifier;
    }
    return     join '', $ope, $delimiter, $prematch, '(?:', @char,                               ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (s'here'' or s'here''b)
#
sub e_s1_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # literal null string pattern
    if ($string eq '') {
        $modifier =~ tr/bB//d;
        $modifier =~ tr/i//d;
        return join '', $ope, $delimiter, $end_delimiter, $modifier;
    }

    # with /b /B modifier
    elsif ($modifier =~ tr/bB//d) {
        return e_s1_qb($ope,$delimiter,$end_delimiter,$string,$modifier);
    }

    # without /b /B modifier
    else {
        return e_s1_qt($ope,$delimiter,$end_delimiter,$string,$modifier);
    }
}

#
# escape regexp (s'here'')
#
sub e_s1_qt {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;

    # split regexp
    my @char = $string =~ /\G(
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
        [\$\@\/\\]         |
        \\?    (?:$q_char)
    )/oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Char::Egbk::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Char::Egbk::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Char::Egbk::uc($char[$i]) ne Char::Egbk::fc($char[$i]))) {
            if (CORE::length(Char::Egbk::fc($char[$i])) == 1) {
                $char[$i] = '['   . Char::Egbk::uc($char[$i])       . Char::Egbk::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Char::Egbk::uc($char[$i]) . '|' . Char::Egbk::fc($char[$i]) . ')';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A [\x00-\xFF] \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $modifier =~ tr/i//d;
    $delimiter     = '/';
    $end_delimiter = '/';
    my $prematch = '';
    $prematch = "($anchor)";
    return join '', $ope, $delimiter, $prematch, '(?:', @char, ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (s'here''b)
#
sub e_s1_qb {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;

    # split regexp
    my @char = $string =~ /\G(
        \\\\        |
        [\$\@\/\\]  |
        [\x00-\xFF]
    )/oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # remain \\
        elsif ($char[$i] eq '\\\\') {
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }
    }

    $delimiter     = '/';
    $end_delimiter = '/';
    my $prematch = '';
    $prematch = q{(\G[\x00-\xFF]*?)};
    return join '', $ope, $delimiter, $prematch, '(?:', @char, ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (s''here')
#
sub e_s2_q {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my @char = $string =~ / \G (\\\\|[\$\@\/\\]|$q_char) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) (\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }
        elsif (($char[$i] =~ /\A ([\x80-\xFF].*) (\\) \z/xms) and defined($char[$i+1]) and ($char[$i+1] eq '\\')) {
            $char[$i] = $1 . '\\' . $2;
        }

        # not escape \\
        elsif ($char[$i] =~ /\A \\\\ \z/oxms) {
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }
    }
    if (defined($char[-1]) and ($char[-1] =~ /\A ([\x80-\xFF].*) (\\) \z/xms)) {
        $char[-1] = $1 . '\\' . $2;
    }

    return join '', $ope, $delimiter, @char,   $end_delimiter;
}

#
# escape regexp (s/here/and here/modifier)
#
sub e_sub {
    my($variable,$delimiter1,$pattern,$end_delimiter1,$delimiter2,$replacement,$end_delimiter2,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    if ($variable eq '') {
        $variable      = '$_';
        $bind_operator = ' =~ ';
    }

    $slash = 'div';

    # P.128 Start of match (or end of previous match): \G
    # in Chapter 3: Overview of Regular Expression Features and Flavors
    # P.312 Iterative Matching: Scalar Context, with /g
    # in Chapter 7: Perl
    # of ISBN 0-596-00272-6 Mastering Regular Expressions, Second edition

    # P.181 Where You Left Off: The \G Assertion
    # in Chapter 5: Pattern Matching
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.220 Where You Left Off: The \G Assertion
    # in Chapter 5: Pattern Matching
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    my $e_modifier = $modifier =~ tr/e//d;
    my $r_modifier = $modifier =~ tr/r//d;

    my $my = '';
    if ($variable =~ s/\A \( \s* ( (?: local \b | my \b | our \b | state \b )? .+ ) \) \z/$1/oxms) {
        $my = $variable;
        $variable =~ s/ (?: local \b | my \b | our \b | state \b ) \s* //oxms;
        $variable =~ s/ = .+ \z//oxms;
    }

    (my $variable_basename = $variable) =~ s/ [\[\{].* \z//oxms;
    $variable_basename =~ s/ \s+ \z//oxms;

    # quote replacement string
    my $e_replacement = '';
    if ($e_modifier >= 1) {
        $e_replacement = e_qq('', '', '', $replacement);
        $e_modifier--;
    }
    else {
        if ($delimiter2 eq "'") {
            $e_replacement = e_s2_q('qq', '/',         '/',             $replacement);
        }
        else {
            $e_replacement = e_qq  ('qq', $delimiter2, $end_delimiter2, $replacement);
        }
    }

    my $local = '';
    if ($variable_basename =~ /::/) {
        $local = 'local';
    }
    else{
        $local = 'my';
    }

    my $sub = '';

    # with /r
    if ($r_modifier) {
        if (0) {
        }

        # s///gr with multibyte anchoring
        elsif ($modifier =~ /g/oxms) {
            $sub = sprintf(
                #      1  2    3   4  5              6       7   8               9  10   11  1213    14      15           16            17      18     19          20         21               22
                q<eval{%s %s_t=%s; %s %s_a=''; while(%s_t =~ %s){%s local $^W=0; %s %s_r=%s; %s%s_t="%s_a${1}%s_r$'"; pos(%s_t)=length "%s_a${1}%s_r"; %s_a=substr(%s_t,0,pos(%s_t)); } return %s_t}>,

                $local,                                                                       #  1
                    $variable_basename,                                                       #  2
                $variable,                                                                    #  3
                $local,                                                                       #  4
                    $variable_basename,                                                       #  5
                    $variable_basename,                                                       #  6
                ($delimiter1 eq "'") ?                                                        #  7
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) :              #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),               #  :
                $s_matched,                                                                   #  8
                $local,                                                                       #  9
                    $variable_basename,                                                       # 10
                $e_replacement,                                                               # 11
                sprintf('%s_r=eval %s_r; ', $variable_basename, $variable_basename) x $e_modifier, # 12
                    $variable_basename,                                                       # 13
                    $variable_basename,                                                       # 14
                    $variable_basename,                                                       # 15
                    $variable_basename,                                                       # 16
                    $variable_basename,                                                       # 17
                    $variable_basename,                                                       # 18
                    $variable_basename,                                                       # 19
                    $variable_basename,                                                       # 20
                    $variable_basename,                                                       # 21
                    $variable_basename,                                                       # 22
            );
        }

        # s///gr without multibyte anchoring
        elsif ($modifier =~ /g/oxms) {
            $sub = sprintf(
                #      1  2    3         4       5   6               7  8    9   1011      12           13              14              15
                q<eval{%s %s_t=%s; while(%s_t =~ %s){%s local $^W=0; %s %s_r=%s; %s%s_t="$`%s_r$'"; pos(%s_t)=length "$`%s_r"; } return %s_t}>,

                $local,                                                                       #  1
                    $variable_basename,                                                       #  2
                $variable,                                                                    #  3
                    $variable_basename,                                                       #  4
                ($delimiter1 eq "'") ?                                                        #  5
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) :              #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),               #  :
                $s_matched,                                                                   #  6
                $local,                                                                       #  7
                    $variable_basename,                                                       #  8
                $e_replacement,                                                               #  9
                sprintf('%s_r=eval %s_r; ', $variable_basename, $variable_basename) x $e_modifier, # 10
                    $variable_basename,                                                       # 11
                    $variable_basename,                                                       # 12
                    $variable_basename,                                                       # 13
                    $variable_basename,                                                       # 14
                    $variable_basename,                                                       # 15
            );
        }

        # s///r
        else {

            my $prematch = q{$`};
            $prematch = q{${1}};

            $sub = sprintf(
                #  1     2          3               4  5    6   7  8 9           10
                q<(%s =~ %s) ? eval{%s local $^W=0; %s %s_r=%s; %s"%s%s_r$'" } : %s>,

                $variable,                                                                    #  1
                ($delimiter1 eq "'") ?                                                        #  2
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) :              #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),               #  :
                $s_matched,                                                                   #  3
                $local,                                                                       #  4
                    $variable_basename,                                                       #  5
                $e_replacement,                                                               #  6
                sprintf('%s_r=eval %s_r; ', $variable_basename, $variable_basename) x $e_modifier, #  7
                $prematch,                                                                    #  8
                    $variable_basename,                                                       #  9
                $variable,                                                                    # 10
            );
        }

        # $var !~ s///r doesn't make sense
        if ($bind_operator =~ / !~ /oxms) {
            $sub = q{die("$0: Using !~ with s///r doesn't make sense"), } . $sub;
        }
    }

    # without /r
    else {
        if (0) {
        }

        # s///g with multibyte anchoring
        elsif ($modifier =~ /g/oxms) {
            $sub = sprintf(
                #      1  2       3  4              5     6   7               8  9    10  1112  13      14           15          16      17     18          19       20    21             2223
                q<eval{%s %s_n=0; %s %s_a=''; while(%s =~ %s){%s local $^W=0; %s %s_r=%s; %s%s="%s_a${1}%s_r$'"; pos(%s)=length "%s_a${1}%s_r"; %s_a=substr(%s,0,pos(%s)); %s_n++} return %s%s_n}>,

                $local,                                                                       #  1
                    $variable_basename,                                                       #  2
                $local,                                                                       #  3
                    $variable_basename,                                                       #  4
                $variable,                                                                    #  5
                ($delimiter1 eq "'") ?                                                        #  6
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) :              #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),               #  :
                $s_matched,                                                                   #  7
                $local,                                                                       #  8
                    $variable_basename,                                                       #  9
                $e_replacement,                                                               # 10
                sprintf('%s_r=eval %s_r; ', $variable_basename, $variable_basename) x $e_modifier, # 11
                $variable,                                                                    # 12
                    $variable_basename,                                                       # 13
                    $variable_basename,                                                       # 14
                $variable,                                                                    # 15
                    $variable_basename,                                                       # 16
                    $variable_basename,                                                       # 17
                    $variable_basename,                                                       # 18
                $variable,                                                                    # 19
                $variable,                                                                    # 20
                    $variable_basename,                                                       # 21
                ($bind_operator =~ / !~ /oxms) ? '!' : '',                                    # 22
                    $variable_basename,                                                       # 23
            );
        }

        # s///g without multibyte anchoring
        elsif ($modifier =~ /g/oxms) {
            $sub = sprintf(
                #      1  2             3     4   5               6  7    8   9 10    11           12            13     14             1516
                q<eval{%s %s_n=0; while(%s =~ %s){%s local $^W=0; %s %s_r=%s; %s%s="$`%s_r$'"; pos(%s)=length "$`%s_r"; %s_n++} return %s%s_n}>,

                $local,                                                                       #  1
                    $variable_basename,                                                       #  2
                $variable,                                                                    #  3
                ($delimiter1 eq "'") ?                                                        #  4
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) :              #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),               #  :
                $s_matched,                                                                   #  5
                $local,                                                                       #  6
                    $variable_basename,                                                       #  7
                $e_replacement,                                                               #  8
                sprintf('%s_r=eval %s_r; ', $variable_basename, $variable_basename) x $e_modifier, #  9
                $variable,                                                                    # 10
                    $variable_basename,                                                       # 11
                $variable,                                                                    # 12
                    $variable_basename,                                                       # 13
                    $variable_basename,                                                       # 14
                ($bind_operator =~ / !~ /oxms) ? '!' : '',                                    # 15
                    $variable_basename,                                                       # 16
            );
        }

        # s///
        else {

            my $prematch = q{$`};
            $prematch = q{${1}};

            $sub = sprintf(

                ($bind_operator =~ / =~ /oxms) ?

                #  1 2 3          4               5  6    7   8 9   1011
                q<(%s%s%s) ? eval{%s local $^W=0; %s %s_r=%s; %s%s="%s%s_r$'"; 1 } : undef> :

                #  1 2 3              4               5  6    7   8 9   1011
                q<(%s%s%s) ? 1 : eval{%s local $^W=0; %s %s_r=%s; %s%s="%s%s_r$'"; undef }>,

                $variable,                                                                    #  1
                $bind_operator,                                                               #  2
                ($delimiter1 eq "'") ?                                                        #  3
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) :              #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),               #  :
                $s_matched,                                                                   #  4
                $local,                                                                       #  5
                    $variable_basename,                                                       #  6
                $e_replacement,                                                               #  7
                sprintf('%s_r=eval %s_r; ', $variable_basename, $variable_basename) x $e_modifier, #  8
                $variable,                                                                    #  9
                $prematch,                                                                    # 10
                    $variable_basename,                                                       # 11
            );
        }
    }

    # (my $foo = $bar) =~ s///   -->   (my $foo = $bar, eval { ... })[1]
    if ($my ne '') {
        $sub = "($my, $sub)[1]";
    }

    # clear s/// variable
    $sub_variable = '';
    $bind_operator = '';

    return $sub;
}

#
# escape chdir (q//, '')
#
sub e_chdir_q {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    if ($^W) {
        if (Char::Egbk::_MSWin32_5Cended_path($string)) {
            if ($] !~ /^5\.005/) {
                warn <<END;
@{[__FILE__]}: Can't chdir to '$string'

chdir does not work with chr(0x5C) at end of path
http://bugs.activestate.com/show_bug.cgi?id=81839
END
            }
        }
    }

    return e_q($ope,$delimiter,$end_delimiter,$string);
}

#
# escape chdir (qq//, "")
#
sub e_chdir {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    if ($^W) {
        if (Char::Egbk::_MSWin32_5Cended_path($string)) {
            if ($] !~ /^5\.005/) {
                warn <<END;
@{[__FILE__]}: Can't chdir to '$string'

chdir does not work with chr(0x5C) at end of path
http://bugs.activestate.com/show_bug.cgi?id=81839
END
            }
        }
    }

    return e_qq($ope,$delimiter,$end_delimiter,$string);
}

#
# escape regexp of split qr//
#
sub e_split {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # /b /B modifier
    if ($modifier =~ tr/bB//d) {
        return join '', 'split', $ope, $delimiter, $string, $end_delimiter, $modifier;
    }

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;
    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ /\G(
        \\o\{ [0-7]+           \}  |
        \\    [0-7]{2,3}           |
        \\x\{ [0-9A-Fa-f]+     \}  |
        \\x   [0-9A-Fa-f]{1,2}     |
        \\c   [\x40-\x5F]          |
        \\N\{ [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\p\{ [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\P\{ [^\x81-\xFE0-9\}][^\x81-\xFE\}]* \} |
        \\  (?:$q_char)            |
        \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     |
                        \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} |
        [\$\@] $qq_variable        |
        \$ \s* \d+                 |
        \$ \s* \{ \s* \d+ \s* \}   |
        \$ \$ (?![\w\{])           |
        \$ \s* \$ \s* $qq_variable |
        \[\:\^ (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] |
        \[\:   (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] |
        \[\^                       |
        \(\?                       |
            (?:$q_char)
    )/oxmsg;

    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Char::Egbk::hexchr($1);
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

        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple-octet
        elsif ($char[$i] =~ /\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Char::Egbk::charlist_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Char::Egbk::charlist_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Char::Egbk::charlist_not_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Char::Egbk::charlist_not_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # P.794 29.2.161. split
        # in Chapter 29: Functions
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.951 split
        # in Chapter 27: Functions
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # said "The //m modifier is assumed when you split on the pattern /^/",
        # but perl5.008 is not so. Therefore, this software adds //m.
        # (and so on)

        # split(m/^/) --> split(m/^/m)
        elsif (($char[$i] eq '^') and ($modifier !~ /m/oxms)) {
            $modifier .= 'm';
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Char::Egbk::uc($char[$i]) ne Char::Egbk::fc($char[$i]))) {
            if (CORE::length(Char::Egbk::fc($char[$i])) == 1) {
                $char[$i] = '['   . Char::Egbk::uc($char[$i])       . Char::Egbk::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Char::Egbk::uc($char[$i]) . '|' . Char::Egbk::fc($char[$i]) . ')';
            }
        }

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {
            $char[$i] = '@{[Char::Egbk::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Char::Egbk::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Char::Egbk::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Char::Egbk::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Char::Egbk::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* 0 \s* \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \$ ([1-9][0-9]*) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ \s* ([1-9][0-9]*) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ( \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Char::Egbk::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ \s* PREMATCH  | \$ \s* \{ \s* PREMATCH  \s* \} | \$ \s* \{\^PREMATCH\}  ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::PREMATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::PREMATCH()]}';
            }
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Char::Egbk::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ \s* MATCH     | \$ \s* \{ \s* MATCH     \s* \} | \$ \s* \{\^MATCH\}     ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::MATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::MATCH()]}';
            }
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Char::Egbk::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ \s* POSTMATCH | \$ \s* \{ \s* POSTMATCH \s* \} | \$ \s* \{\^POSTMATCH\} ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(Char::Egbk::POSTMATCH())]}';
            }
            else {
                $char[$i] = '@{[Char::Egbk::POSTMATCH()]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ /\A \$ \s* \{ ( \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $1 . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ \s* \{ \s* ( .+ ) \s* \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ /\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Char::Egbk::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        return join '', 'Char::Egbk::split', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
    }
    return     join '', 'Char::Egbk::split', $ope, $delimiter, @char,                               $end_delimiter, $modifier;
}

#
# escape regexp of split qr''
#
sub e_split_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # /b /B modifier
    if ($modifier =~ tr/bB//d) {
        return join '', 'split', $ope, $delimiter, $string, $end_delimiter, $modifier;
    }

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;

    # split regexp
    my @char = $string =~ /\G(
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
        \\?    (?:$q_char)
    )/oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Char::Egbk::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Char::Egbk::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # split(m/^/) --> split(m/^/m)
        elsif (($char[$i] eq '^') and ($modifier !~ /m/oxms)) {
            $modifier .= 'm';
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Char::Egbk::uc($char[$i]) ne Char::Egbk::fc($char[$i]))) {
            if (CORE::length(Char::Egbk::fc($char[$i])) == 1) {
                $char[$i] = '['   . Char::Egbk::uc($char[$i])       . Char::Egbk::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Char::Egbk::uc($char[$i]) . '|' . Char::Egbk::fc($char[$i]) . ')';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A [\x00-\xFF] \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $modifier =~ tr/i//d;
    return join '', 'Char::Egbk::split', $ope, $delimiter, @char, $end_delimiter, $modifier;
}

#
# escape use without import
#
sub e_use_noimport {
    my($module) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (open($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename";

            if ($script =~ /^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $/oxms) {
                return qq<BEGIN { Char::Egbk::require '$expr'; }>;
            }
            last;
        }
    }

    return qq<use $module ();>;
}

#
# escape no without unimport
#
sub e_no_nounimport {
    my($module) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (open($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename";

            if ($script =~ /^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $/oxms) {
                return qq<BEGIN { Char::Egbk::require '$expr'; }>;
            }
            last;
        }
    }

    return qq<no $module ();>;
}

#
# escape use with import no parameter
#
sub e_use_noparam {
    my($module) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (open($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename";

            if ($script =~ /^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $/oxms) {

                # P.326 UNIVERSAL: The Ultimate Ancestor Class
                # in Chapter 12: Objects
                # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                # P.435 UNIVERSAL: The Ultimate Ancestor Class
                # in Chapter 12: Objects
                # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

                # (and so on)

                return qq[BEGIN { Char::Egbk::require '$expr'; $module->import() if $module->can('import'); }];
            }
            last;
        }
    }

    return qq<use $module;>;
}

#
# escape no with unimport no parameter
#
sub e_no_noparam {
    my($module) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (open($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename";

            if ($script =~ /^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $/oxms) {
                return qq[BEGIN { Char::Egbk::require '$expr'; $module->unimport() if $module->can('unimport'); }];
            }
            last;
        }
    }

    return qq<no $module;>;
}

#
# escape use with import parameters
#
sub e_use {
    my($module,$list) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (open($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename";

            if ($script =~ /^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $/oxms) {
                return qq[BEGIN { Char::Egbk::require '$expr'; $module->import($list) if $module->can('import'); }];
            }
            last;
        }
    }

    return qq<use $module $list;>;
}

#
# escape no with unimport parameters
#
sub e_no {
    my($module,$list) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (open($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename";

            if ($script =~ /^ \s* use \s+ Char::GBK \s* ([^\x81-\xFE;]*) ; \s* \n? $/oxms) {
                return qq[BEGIN { Char::Egbk::require '$expr'; $module->unimport($list) if $module->can('unimport'); }];
            }
            last;
        }
    }

    return qq<no $module $list;>;
}

#
# file path of module
#
sub _pathof {
    my($expr) = @_;

    if ($^O eq 'MacOS') {
        $expr =~ s#::#:#g;
    }
    else {
        $expr =~ s#::#/#g;
    }
    $expr .= '.pm' if $expr !~ / \.pm \z/oxmsi;

    return $expr;
}

#
# real file name of module
#
sub _realfilename {
    my($expr) = @_;

    if ($^O eq 'MacOS') {
        return map {"$_$expr"} @INC;
    }
    else {
        return map {"$_/$expr"} @INC;
    }
}

1;

__END__

=pod

=head1 NAME

Char::GBK - Source code filter to escape GBK script

=head1 SYNOPSIS

  use Char::GBK;
  use Char::GBK ver.sion;        --- require minimum version
  use Char::GBK ver.sion.0;      --- expects version (match or die)
  use Char::GBK qw(ord reverse); --- demand enhanced feature of ord and reverse
  use Char::GBK ver.sion qw(ord reverse);
  use Char::GBK ver.sion.0 qw(ord reverse);

  # "no Char::GBK;" not supported

  or

  $ perl Char/GBK.pm GBK_script.pl > Escaped_script.pl.e

  then

  $ perl Escaped_script.pl.e

  GBK_script.pl  --- script written in GBK
  Escaped_script.pl.e --- escaped script

  functions:
    Char::GBK::ord(...);
    Char::GBK::reverse(...);
    Char::GBK::length(...);
    Char::GBK::substr(...);
    Char::GBK::index(...);
    Char::GBK::rindex(...);
    CORE::chop(...);
    CORE::ord(...);
    CORE::reverse(...);
    CORE::index(...);
    CORE::rindex(...);

  emulate Perl5.6 on perl5.00503
    use warnings;
    use warnings::register;

  emulate Perl5.16
    use feature qw(fc);

  dummy functions:
    utf8::upgrade(...);
    utf8::downgrade(...);
    utf8::encode(...);
    utf8::decode(...);
    utf8::is_utf8(...);
    utf8::valid(...);
    bytes::chr(...);
    bytes::index(...);
    bytes::length(...);
    bytes::ord(...);
    bytes::rindex(...);
    bytes::substr(...);

=head1 ABSTRACT

Let's start with a bit of history: jperl 4.019+1.3 introduced GBK support.
You could apply chop() and regexps even to complex CJK characters.

JPerl in CPAN Perl Ports (Binary Distributions)

said before,

  As of Perl 5.8.0 it is suggested that instead of JPerl (which is
  based on a quite old release of Perl) you should just use Perl 5.8.0,
  since it can do all that JPerl did, and more.

But was it really so?

In this country, GBK is widely used on mainframe I/O, the personal computer,
and the cellular phone. This software treats GBK directly, but doesn't treat
Latin-1. Therefore, this software doesn't use UTF8 flag.

Shall we escape from the encode problem?

=head1 Yet Another Future Of

JPerl is very useful software. -- Oops, note, this "JPerl" means "Japanized Perl"
or "Japanese Perl". Therefore, it is unrelated to JPerl of the following.

 JPerl is an implementation of Perl written in Java.
 http://www.javainc.com/projects/jperl/
 
 jPerl - Perl on the JVM
 http://www.dzone.com/links/175948.html
 
 Jamie's PERL scripts for bioinformatics
 http://code.google.com/p/jperl/
 
 jperl (Jonathan Perl)
 https://github.com/jperl

Now, the last version of JPerl is 5.005_04 and is not maintained now.

Japanization modifier WATANABE Hirofumi said,

  "Because WATANABE am tired I give over maintaing JPerl."

at Slide #15: "The future of JPerl" of

L<ftp://ftp.oreilly.co.jp/pcjp98/watanabe/jperlconf.ppt>

in The Perl Confernce Japan 1998.

When I heard it, I thought that someone excluding me would maintain JPerl.
And I slept every night hanging a sock. Night and day, I kept having hope.
After 10 years, I noticed that white beard exists in the sock :-)

This software is a source code filter to escape Perl script encoded by GBK
given from STDIN or command line parameter. The character code is never converted
by escaping the script. Neither the value of the character nor the length of the
character string change even if it escapes.

I learned the following things from the successful software.

=over 2

=item * Upper Compatibility like Perl4 to Perl5

=item * Maximum Portability like jcode.pl

=item * Handles Raw GBK, Doesn't use UTF8 flag like JPerl

=item * Remains One Interpreter like Encode module

=item * Code Set Independent like Ruby

=item * There's more than one way to do it like Perl itself

=back

Let's make yet another future by JPerl's future.

=head1 JRE: JPerl Runtime Environment

  +---------------------------------------+
  |        JPerl Application Script       | Your Script
  +---------------------------------------+
  |  Source Code Filter, Runtime Routine  | ex. Char/GBK.pm, Char/Egbk.pm
  +---------------------------------------+
  |          PVM 5.00503 or later         | ex. perl 5.00503
  +---------------------------------------+

A Perl Virtual Machine (PVM) enables a set of computer software programs and
data structures to use a virtual machine model for the execution of other
computer programs and scripts. The model used by a PVM accepts a form of
computer intermediate language commonly referred to as Perl byteorientedcode.
This language conceptually represents the instruction set of a byte-oriented,
capability architecture.

=head1 Basic Idea Of Source Code Filter

I discovered this mail again recently.

[Tokyo.pm] jus Benkyoukai

http://mail.pm.org/pipermail/tokyo-pm/1999-September/001854.html

save as: SJIS.pm

  package SJIS;
  use Filter::Util::Call;
  sub multibyte_filter {
      my $status;
      if (($status = filter_read()) > 0 ) {
          s/([\x81-\x9f\xe0-\xef])([\x40-\x7e\x80-\xfc])/
              sprintf("\\x%02x\\x%02x",ord($1),ord($2))
          /eg;
      }
      $status;
  }
  sub import {
      filter_add(\&multibyte_filter);
  }
  1;

I am glad that I could confirm my idea is not so wrong.

=head1 Software Composition

   Char/GBK.pm               --- source code filter to escape GBK
   Char/Egbk.pm              --- run-time routines for Char/GBK.pm
   perl5.bat             --- find and run perl5    without %PATH% settings
   perl55.bat            --- find and run perl5.5  without %PATH% settings
   perl56.bat            --- find and run perl5.6  without %PATH% settings
   perl58.bat            --- find and run perl5.8  without %PATH% settings
   perl510.bat           --- find and run perl5.10 without %PATH% settings
   perl512.bat           --- find and run perl5.12 without %PATH% settings
   perl514.bat           --- find and run perl5.14 without %PATH% settings
   perl516.bat           --- find and run perl5.16 without %PATH% settings
   perl64.bat            --- find and run perl64   without %PATH% settings
   perl64512.bat         --- find and run perl5.12 (x64) without %PATH% settings
   perl64514.bat         --- find and run perl5.14 (x64) without %PATH% settings
   perl64516.bat         --- find and run perl5.16 (x64) without %PATH% settings
   aperl58.bat           --- find and run ActivePerl 5.8  without %PATH% settings
   aperl510.bat          --- find and run ActivePerl 5.10 without %PATH% settings
   aperl512.bat          --- find and run ActivePerl 5.12 without %PATH% settings
   aperl514.bat          --- find and run ActivePerl 5.14 without %PATH% settings
   aperl516.bat          --- find and run ActivePerl 5.16 without %PATH% settings
   aperl64512.bat        --- find and run ActivePerl 5.12 (x64) without %PATH% settings
   aperl64514.bat        --- find and run ActivePerl 5.14 (x64) without %PATH% settings
   aperl64516.bat        --- find and run ActivePerl 5.16 (x64) without %PATH% settings
   sperl58.bat           --- find and run Strawberry Perl 5.8  without %PATH% settings
   sperl510.bat          --- find and run Strawberry Perl 5.10 without %PATH% settings
   sperl512.bat          --- find and run Strawberry Perl 5.12 without %PATH% settings
   sperl514.bat          --- find and run Strawberry Perl 5.14 without %PATH% settings
   sperl516.bat          --- find and run Strawberry Perl 5.16 without %PATH% settings
   sperl64512.bat        --- find and run Strawberry Perl 5.12 (x64) without %PATH% settings
   sperl64514.bat        --- find and run Strawberry Perl 5.14 (x64) without %PATH% settings
   sperl64516.bat        --- find and run Strawberry Perl 5.16 (x64) without %PATH% settings
   strict.pm_            --- dummy strict.pm
   warnings.pm_          --- poor warnings.pm
   warnings/register.pm_ --- poor warnings/register.pm
   feature.pm_           --- dummy feature.pm

=head1 Upper Compatibility By Escaping

This software adds the function by 'Escaping' it always, and nothing of the
past is broken. Therefore, 'Possible job' never becomes 'Impossible job'.
This approach is effective in the field where the retreat is never permitted.
Modern Perl/perl can not always solve the problem. Often, it means an
incompatible upgrade part to traditional Perl should be rewound.

=head1 Escaping Your Script (You do)

You need write 'use Char::GBK;' in your script.

  ---------------------------------
  Before      You do
  ---------------------------------
  (nothing)   use Char::GBK;
  ---------------------------------

=head1 Escaping Multiple-Octet Code (Char/GBK.pm provides)

Insert chr(0x5c) before  @  [  \  ]  ^  `  {  |  and  }  in multiple-octet of

=over 2

=item * string in single quote ('', q{}, <<'END' and qw{})

=item * string in double quote ("", qq{}, <<END, <<"END", ``, qx{} and <<`END`)

=item * regexp in single quote (m'', s''', split(''), split(m'') and qr'')

=item * regexp in double quote (//, m//, ??, s///, split(//), split(m//) and qr//)

=item * character in tr/// (tr/// and y///)

=back

  ex. Japanese Katakana "SO" like [ `/ ] code is "\x83\x5C" in SJIS
 
                  see     hex dump
  -----------------------------------------
  source script   "`/"    [83 5c]
  -----------------------------------------
 
  Here, use SJIS;
                          hex dump
  -----------------------------------------
  escaped script  "`\/"   [83 [5c] 5c]
  -----------------------------------------
                    ^--- escape by SJIS software
 
  by the by       see     hex dump
  -----------------------------------------
  your eye's      "`/\"   [83 5c] [5c]
  -----------------------------------------
  perl eye's      "`\/"   [83] \[5c]
  -----------------------------------------
 
                          hex dump
  -----------------------------------------
  in the perl     "`/"    [83] [5c]
  -----------------------------------------

=head1 Multiple-Octet Anchoring Of Regular Expression (Char/GBK.pm provides)

Char/GBK.pm applies multiple-octet anchoring at beginning of regular expression.

  --------------------------------------------------------------------------------
  Before                  After
  --------------------------------------------------------------------------------
  m/regexp/               m/${Char::Egbk::anchor}(?:regexp).../
  --------------------------------------------------------------------------------

=head1 Escaping Second Octet (Char/GBK.pm provides)

Char/GBK.pm escapes second octet of multiple-octet character in regular expression.

  --------------------------------------------------------------------------------
  Before                  After
  --------------------------------------------------------------------------------
  m<...`/...>             m<...`/\...>
  --------------------------------------------------------------------------------

=head1 Multiple-Octet Character Regular Expression (Char/GBK.pm provides)

Char/GBK.pm clusters multiple-octet character with quantifier, makes cluster from
multiple-octet custom character classes. And makes multiple-octet version metasymbol
from classic Perl character class shortcuts and POSIX-style character classes.

  --------------------------------------------------------------------------------
  Before                  After
  --------------------------------------------------------------------------------
  m/...MULTIOCT+.../      m/...(?:MULTIOCT)+.../
  m/...[AN-EM].../        m/...(?:A[N-Z]|[B-D][A-Z]|E[A-M]).../
  m/...\D.../             m/...${Char::Egbk::eD}.../
  m/...[[:^digit:]].../   m/...${Char::Egbk::not_digit}.../
  --------------------------------------------------------------------------------

=head1 Calling 'Char::Egbk::ignorecase()' (Char/GBK.pm provides)

Char/GBK.pm applies calling 'Char::Egbk::ignorecase()' instead of /i modifier.

  --------------------------------------------------------------------------------
  Before                  After
  --------------------------------------------------------------------------------
  m/...$var.../i          m/...@{[Char::Egbk::ignorecase($var)]}.../
  --------------------------------------------------------------------------------

=head1 Character-Oriented Regular Expression

Regular expression works as character-oriented that has no /b modifier.

  --------------------------------------------------------------------------------
  Before                  After
  --------------------------------------------------------------------------------
  /regexp/                /ditto$Char::Egbk::matched/
  m/regexp/               m/ditto$Char::Egbk::matched/
  ?regexp?                m?ditto$Char::Egbk::matched?
  m?regexp?               m?ditto$Char::Egbk::matched?
 
  $_ =~                   ($_ =~ m/ditto$Char::Egbk::matched/) ?
  s/regexp/replacement/   eval{ Char::Egbk::s_matched(); local $^W=0; my $__r=qq/replacement/; $_="${1}$__r$'"; 1 } :
                          undef
 
  $_ !~                   ($_ !~ m/ditto$Char::Egbk::matched/) ?
  s/regexp/replacement/   1 :
                          eval{ Char::Egbk::s_matched(); local $^W=0; my $__r=qq/replacement/; $_="${1}$__r$'"; undef }
 
  split(/regexp/)         Char::Egbk::split(qr/regexp/)
  split(m/regexp/)        Char::Egbk::split(qr/regexp/)
  split(qr/regexp/)       Char::Egbk::split(qr/regexp/)
  qr/regexp/              qr/ditto$Char::Egbk::matched/
  --------------------------------------------------------------------------------

=head1 Byte-Oriented Regular Expression

Regular expression works as byte-oriented that has /b modifier.

  --------------------------------------------------------------------------------
  Before                  After
  --------------------------------------------------------------------------------
  /regexp/b               /(?:regexp)$Char::Egbk::matched/
  m/regexp/b              m/(?:regexp)$Char::Egbk::matched/
  ?regexp?b               m?regexp$Char::Egbk::matched?
  m?regexp?b              m?regexp$Char::Egbk::matched?
 
  $_ =~                   ($_ =~ m/(\G[\x00-\xFF]*?)(?:regexp)$Char::Egbk::matched/) ?
  s/regexp/replacement/b  eval{ Char::Egbk::s_matched(); local $^W=0; my $__r=qq/replacement/; $_="${1}$__r$'"; 1 } :
                          undef
 
  $_ !~                   ($_ !~ m/(\G[\x00-\xFF]*?)(?:regexp)$Char::Egbk::matched/) ?
  s/regexp/replacement/b  1 :
                          eval{ Char::Egbk::s_matched(); local $^W=0; my $__r=qq/replacement/; $_="${1}$__r$'"; undef }
 
  split(/regexp/b)        split(qr/regexp/)
  split(m/regexp/b)       split(qr/regexp/)
  split(qr/regexp/b)      split(qr/regexp/)
  qr/regexp/b             qr/(?:regexp)$Char::Egbk::matched/
  --------------------------------------------------------------------------------

=head1 Escaping Character Classes (Char/Egbk.pm provides)

The character classes are redefined as follows to backward compatibility.

  ---------------------------------------------------------------
  Before        After
  ---------------------------------------------------------------
   .            ${Char::Egbk::dot}
                ${Char::Egbk::dot_s}    (/s modifier)
  \d            [0-9]
  \s            [\x09\x0A\x0C\x0D\x20]
  \w            [0-9A-Z_a-z]
  \D            ${Char::Egbk::eD}
  \S            ${Char::Egbk::eS}
  \W            ${Char::Egbk::eW}
  \h            [\x09\x20]
  \v            [\x0A\x0B\x0C\x0D]
  \H            ${Char::Egbk::eH}
  \V            ${Char::Egbk::eV}
  \C            [\x00-\xFF]
  \X            X (so, just 'X')
  \R            ${Char::Egbk::eR}
  \N            ${Char::Egbk::eN}
  ---------------------------------------------------------------

Also POSIX-style character classes.

  ---------------------------------------------------------------
  Before        After
  ---------------------------------------------------------------
  [:alnum:]     [\x30-\x39\x41-\x5A\x61-\x7A]
  [:alpha:]     [\x41-\x5A\x61-\x7A]
  [:ascii:]     [\x00-\x7F]
  [:blank:]     [\x09\x20]
  [:cntrl:]     [\x00-\x1F\x7F]
  [:digit:]     [\x30-\x39]
  [:graph:]     [\x21-\x7F]
  [:lower:]     [\x61-\x7A]
                [\x41-\x5A\x61-\x7A]     (/i modifier)
  [:print:]     [\x20-\x7F]
  [:punct:]     [\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E]
  [:space:]     [\x09\x0A\x0B\x0C\x0D\x20]
  [:upper:]     [\x41-\x5A]
                [\x41-\x5A\x61-\x7A]     (/i modifier)
  [:word:]      [\x30-\x39\x41-\x5A\x5F\x61-\x7A]
  [:xdigit:]    [\x30-\x39\x41-\x46\x61-\x66]
  [:^alnum:]    ${Char::Egbk::not_alnum}
  [:^alpha:]    ${Char::Egbk::not_alpha}
  [:^ascii:]    ${Char::Egbk::not_ascii}
  [:^blank:]    ${Char::Egbk::not_blank}
  [:^cntrl:]    ${Char::Egbk::not_cntrl}
  [:^digit:]    ${Char::Egbk::not_digit}
  [:^graph:]    ${Char::Egbk::not_graph}
  [:^lower:]    ${Char::Egbk::not_lower}
                ${Char::Egbk::not_lower_i}    (/i modifier)
  [:^print:]    ${Char::Egbk::not_print}
  [:^punct:]    ${Char::Egbk::not_punct}
  [:^space:]    ${Char::Egbk::not_space}
  [:^upper:]    ${Char::Egbk::not_upper}
                ${Char::Egbk::not_upper_i}    (/i modifier)
  [:^word:]     ${Char::Egbk::not_word}
  [:^xdigit:]   ${Char::Egbk::not_xdigit}
  ---------------------------------------------------------------

Also \b and \B are redefined as follows to backward compatibility.

  ---------------------------------------------------------------
  Before      After
  ---------------------------------------------------------------
  \b          ${Char::Egbk::eb}
  \B          ${Char::Egbk::eB}
  ---------------------------------------------------------------

Definitions in Char/Egbk.pm.

  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  After                    Definition
  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  ${Char::Egbk::anchor}         qr{\G(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])*?}
  ${Char::Egbk::dot}            qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x0A])}
  ${Char::Egbk::dot_s}          qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])}
  ${Char::Egbk::eD}             qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE0-9])}
  ${Char::Egbk::eS}             qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x09\x0A\x0C\x0D\x20])}
  ${Char::Egbk::eW}             qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE0-9A-Z_a-z])}
  ${Char::Egbk::eH}             qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x09\x20])}
  ${Char::Egbk::eV}             qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x0A\x0B\x0C\x0D])}
  ${Char::Egbk::eR}             qr{(?:\x0D\x0A|[\x0A\x0D])}
  ${Char::Egbk::eN}             qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x0A])}
  ${Char::Egbk::not_alnum}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x30-\x39\x41-\x5A\x61-\x7A])}
  ${Char::Egbk::not_alpha}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x41-\x5A\x61-\x7A])}
  ${Char::Egbk::not_ascii}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x00-\x7F])}
  ${Char::Egbk::not_blank}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x09\x20])}
  ${Char::Egbk::not_cntrl}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x00-\x1F\x7F])}
  ${Char::Egbk::not_digit}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x30-\x39])}
  ${Char::Egbk::not_graph}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x21-\x7F])}
  ${Char::Egbk::not_lower}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x61-\x7A])}
  ${Char::Egbk::not_lower_i}    qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])}
  ${Char::Egbk::not_print}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x20-\x7F])}
  ${Char::Egbk::not_punct}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])}
  ${Char::Egbk::not_space}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x09\x0A\x0B\x0C\x0D\x20])}
  ${Char::Egbk::not_upper}      qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x41-\x5A])}
  ${Char::Egbk::not_upper_i}    qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE])}
  ${Char::Egbk::not_word}       qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x30-\x39\x41-\x5A\x5F\x61-\x7A])}
  ${Char::Egbk::not_xdigit}     qr{(?:[\x81-\xFE][\x00-\xFF]|[^\x81-\xFE\x30-\x39\x41-\x46\x61-\x66])}
  ${Char::Egbk::eb}             qr{(?:\A(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[0-9A-Z_a-z])|(?<=[0-9A-Z_a-z])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]|\z))}
  ${Char::Egbk::eB}             qr{(?:(?<=[0-9A-Z_a-z])(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]))}
  ---------------------------------------------------------------------------------------------------------------------------------------------------------

=head1 Un-Escaping \ Of \N, \p, \P and \X (Char/GBK.pm provides)

Char/GBK.pm removes '\' at head of alphanumeric regexp metasymbols \N, \p, \P
and \X. By this method, you can avoid the trap of the abstraction.

See also,
Deprecate literal unescaped "{" in regexes.
http://perl5.git.perl.org/perl.git/commit/2a53d3314d380af5ab5283758219417c6dfa36e9

  ------------------------------------
  Before           After
  ------------------------------------
  \N{CHARNAME}     N\{CHARNAME}
  \p{L}            p\{L}
  \p{^L}           p\{^L}
  \p{\^L}          p\{\^L}
  \pL              pL
  \P{L}            P\{L}
  \P{^L}           P\{^L}
  \P{\^L}          P\{\^L}
  \PL              PL
  \X               X
  ------------------------------------

=head1 Escaping Built-in Functions (Char/GBK.pm and Char/Egbk.pm provide)

Insert 'Char::Egbk::' at head of function name. Char/Egbk.pm provides your script Char::Egbk::*
functions.

  -------------------------------------------
  Before      After            Works as
  -------------------------------------------
  length      length           Byte
  substr      substr           Byte
  pos         pos              Byte
  split       Char::Egbk::split     Character
  tr///       Char::Egbk::tr        Character
  tr///b      tr///            Byte
  tr///B      tr///            Byte
  y///        Char::Egbk::tr        Character
  y///b       tr///            Byte
  y///B       tr///            Byte
  chop        Char::Egbk::chop      Character
  index       Char::Egbk::index     Character
  rindex      Char::Egbk::rindex    Character
  lc          Char::Egbk::lc        Character
  lcfirst     Char::Egbk::lcfirst   Character
  uc          Char::Egbk::uc        Character
  ucfirst     Char::Egbk::ucfirst   Character
  fc          Char::Egbk::fc        Character
  chr         Char::Egbk::chr       Character
  glob        Char::Egbk::glob      Character
  lstat       Char::Egbk::lstat     Character
  opendir     Char::Egbk::opendir   Character
  stat        Char::Egbk::stat      Character
  unlink      Char::Egbk::unlink    Character
  chdir       Char::Egbk::chdir     Character
  do          Char::Egbk::do        Character
  require     Char::Egbk::require   Character
  -------------------------------------------

  ------------------------------------------------------------------------------------------------------------------------
  Before                   After
  ------------------------------------------------------------------------------------------------------------------------
  use Perl::Module;        BEGIN { Char::Egbk::require 'Perl/Module.pm'; Perl::Module->import() if Perl::Module->can('import'); }
  use Perl::Module @list;  BEGIN { Char::Egbk::require 'Perl/Module.pm'; Perl::Module->import(@list) if Perl::Module->can('import'); }
  use Perl::Module ();     BEGIN { Char::Egbk::require 'Perl/Module.pm'; }
  no Perl::Module;         BEGIN { Char::Egbk::require 'Perl/Module.pm'; Perl::Module->unimport() if Perl::Module->can('unimport'); }
  no Perl::Module @list;   BEGIN { Char::Egbk::require 'Perl/Module.pm'; Perl::Module->unimport(@list) if Perl::Module->can('unimport'); }
  no Perl::Module ();      BEGIN { Char::Egbk::require 'Perl/Module.pm'; }
  ------------------------------------------------------------------------------------------------------------------------

=head1 Escaping File Test Operators (Char/GBK.pm and Char/Egbk.pm provide)

Insert 'Char::Egbk::' instead of '-' of operator.

  --------------------------------------------------------------------------
  Before   After      Meaning
  --------------------------------------------------------------------------
  -r       Char::Egbk::r   File is readable by effective uid/gid
  -w       Char::Egbk::w   File is writable by effective uid/gid
  -x       Char::Egbk::x   File is executable by effective uid/gid
  -o       Char::Egbk::o   File is owned by effective uid
  -R       Char::Egbk::R   File is readable by real uid/gid
  -W       Char::Egbk::W   File is writable by real uid/gid
  -X       Char::Egbk::X   File is executable by real uid/gid
  -O       Char::Egbk::O   File is owned by real uid
  -e       Char::Egbk::e   File exists
  -z       Char::Egbk::z   File has zero size
  -f       Char::Egbk::f   File is a plain file
  -d       Char::Egbk::d   File is a directory
  -l       Char::Egbk::l   File is a symbolic link
  -p       Char::Egbk::p   File is a named pipe (FIFO)
  -S       Char::Egbk::S   File is a socket
  -b       Char::Egbk::b   File is a block special file
  -c       Char::Egbk::c   File is a character special file
  -t       -t         Filehandle is opened to a tty
  -u       Char::Egbk::u   File has setuid bit set
  -g       Char::Egbk::g   File has setgid bit set
  -k       Char::Egbk::k   File has sticky bit set
  -T       Char::Egbk::T   File is a text file
  -B       Char::Egbk::B   File is a binary file (opposite of -T)
  -s       Char::Egbk::s   File has nonzero size (returns size in bytes)
  -M       Char::Egbk::M   Age of file (at startup) in days since modification
  -A       Char::Egbk::A   Age of file (at startup) in days since last access
  -C       Char::Egbk::C   Age of file (at startup) in days since inode change
  --------------------------------------------------------------------------

As of Perl 5.00503, as a form of purely syntactic sugar, you can stack file
test operators, in a way that -w -x $file is equivalent to -x $file && -w _ .

  if ( -w -r $file ) {
      print "The file is both readable and writable!\n";
  }

=head1 Escaping Function Name (You do)

You need write 'Char::GBK::' at head of function name when you want character-
oriented function. See 'Character-Oriented Functions'.

  --------------------------------------------------------
  Function   Character-Oriented   Description
  --------------------------------------------------------
  ord        Char::GBK::ord
  reverse    Char::GBK::reverse
  length     Char::GBK::length
  substr     Char::GBK::substr
  index      Char::GBK::index          See 'About Indexes'
  rindex     Char::GBK::rindex         See 'About Rindexes'
  --------------------------------------------------------

  About Indexes
  -------------------------------------------------------------------------
  Function       Works as    Returns as   Description
  -------------------------------------------------------------------------
  index          Character   Byte         JPerl semantics (most useful)
  (same as Char::Egbk::index)
  Char::GBK::index    Character   Character    Character-oriented semantics
  CORE::index    Byte        Byte         Byte-oriented semantics
  (nothing)      Byte        Character    (most useless)
  -------------------------------------------------------------------------

  About Rindexes
  -------------------------------------------------------------------------
  Function       Works as    Returns as   Description
  -------------------------------------------------------------------------
  rindex         Character   Byte         JPerl semantics (most useful)
  (same as Char::Egbk::rindex)
  Char::GBK::rindex   Character   Character    Character-oriented semantics
  CORE::rindex   Byte        Byte         Byte-oriented semantics
  (nothing)      Byte        Character    (most useless)
  -------------------------------------------------------------------------

=head1 Character-Oriented Functions

=over 2

=item * Order Of Character

  $ord = Char::GBK::ord($string);

  This function returns the numeric value (ASCII or GBK character) of the
  first character of $string, not Unicode. If $string is omitted, it uses $_.
  The return value is always unsigned.

  If you import ord "use Char::GBK qw(ord);", ord of your script will be rewritten in
  Char::GBK::ord. Char::GBK::ord is not compatible with ord of JPerl.

=item * Reverse List Or String

  @reverse = Char::GBK::reverse(@list);
  $reverse = Char::GBK::reverse(@list);

  In list context, this function returns a list value consisting of the elements of
  @list in the opposite order.

  In scalar context, the function concatenates all the elements of @list and then
  returns the reverse of that resulting string, character by character.

  If you import reverse "use Char::GBK qw(reverse);", reverse of your script will be
  rewritten in Char::GBK::reverse. Char::GBK::reverse is not compatible with reverse of
  JPerl.

=item * Length By GBK Character

  $length = Char::GBK::length($string);
  $length = Char::GBK::length();

  This function returns the length in characters (programmer-visible characters) of
  the scalar value $string. If $string is omitted, it returns the Char::GBK::length of
  $_.

  Do not try to use Char::GBK::length to find the size of an array or hash. Use scalar
  @array for the size of an array, and scalar keys %hash for the number of key/value
  pairs in a hash. (The scalar is typically omitted when redundant.)

  To find the length of a string in bytes rather than characters, say simply:

  $bytes = length($string);

=item * Substr By GBK Character

  $substr = Char::GBK::substr($string,$offset,$length,$replacement);
  $substr = Char::GBK::substr($string,$offset,$length);
  $substr = Char::GBK::substr($string,$offset);

  This function extracts a substring out of the string given by $string and returns
  it. The substring is extracted starting at $offset characters from the front of
  the string.
  If $offset is negative, the substring starts that far from the end of the string
  instead. If $length is omitted, everything to the end of the string is returned.
  If $length is negative, the length is calculated to leave that many characters off
  the end of the string. Otherwise, $length indicates the length of the substring to
  extract, which is sort of what you'd expect.

  For bytes, use the substr from built-in Perl functions.

  An alternative to using Char::GBK::substr as an lvalue is to specify the $replacement
  string as the fourth argument. This lets you replace parts of the $string and return
  what was there before in one operation, just as you can with splice. The next
  example also replaces the last character of $var with "Curly" and puts that replaced
  character into $oldstr: 

  $oldstr = Char::GBK::substr($var, -1, 1, "Curly");

  To prepend the string "Larry" to the current value of $var, use:

  Char::GBK::substr($var, 0, 0, "Larry");

  To instead replace the first character of $var with "Moe", use:

  Char::GBK::substr($var, 0, 1, "Moe");

  And, finally, to replace the last character of $var with "Curly", use:

  Char::GBK::substr($var, -1, 1, "Curly");

=item * Index By GBK Character

  $index = Char::GBK::index($string,$substring,$offset);
  $index = Char::GBK::index($string,$substring);

  This function searches for one string within another. It returns the character
  position of the first occurrence of $substring in $string. The $offset, if
  specified, says how many characters from the start to skip before beginning to
  look. Positions are based at 0. If the substring is not found, the function
  returns one less than the base, ordinarily -1. To work your way through a string,
  you might say:

  $pos = -1;
  while (($pos = Char::GBK::index($string, $lookfor, $pos)) > -1) {
      print "Found at $pos\n";
      $pos++;
  }

=item * Rindex By GBK Character

  $rindex = Char::GBK::rindex($string,$substring,$offset);
  $rindex = Char::GBK::rindex($string,$substring);

  This function works just like Char::GBK::index except that it returns the character
  position of the last occurrence of $substring in $string (a reverse Char::GBK::index).
  The function returns -1 if $substring is not found. $offset, if specified, is
  the rightmost character position that may be returned. To work your way through
  a string backward, say:

  $pos = Char::GBK::length($string);
  while (($pos = Char::GBK::rindex($string, $lookfor, $pos)) >= 0) {
      print "Found at $pos\n";
      $pos--;
  }

=back

=head1 Byte-Oriented Functions

=over 2

=item * Chop Byte String

  $byte = CORE::chop($string);
  $byte = CORE::chop(@list);
  $byte = CORE::chop;

  This function chops off the last byte of a string variable and returns the
  byte chopped. The CORE::chop operator is used primarily to remove the newline
  from the end of an input record, and is more efficient than using a
  substitution (s/\n$//). If that's all you're doing, then it would be safer to
  use chomp, since CORE::chop always shortens the string no matter what's there,
  and chomp is more selective.

  You cannot CORE::chop a literal, only a variable.

  If you CORE::chop a @list of variables, each string in the list is chopped:

  @lines = `cat myfile`;
  CORE::chop @lines;

  You can CORE::chop anything that is an lvalue, including an assignment:

  CORE::chop($cwd = `pwd`);
  CORE::chop($answer = <STDIN>);

  This is different from:

  $answer = CORE::chop($temp = <STDIN>); # WRONG

  which puts a newline into $answer because CORE::chop returns the byte chopped,
  not the remaining string (which is in $tmp). One way to get the result
  intended here is with substr:

  $answer = substr <STDIN>, 0, -1;

  But this is more commonly written as:

  CORE::chop($answer = <STDIN>);

  In the most general case, CORE::chop can be expressed in terms of substr:

  $last_byte = CORE::chop($var);
  $last_byte = substr($var, -1, 1, ""); # same thing

  Once you understand this equivalence, you can use it to do bigger chops. To
  CORE::chop more than one byte, use substr as an lvalue, assigning a null
  string. The following removes the last five bytes of $caravan:

  substr($caravan, -5) = "";

  The negative subscript causes substr to count from the end of the string
  instead of the beginning. If you wanted to save the bytes so removed, you
  could use the four-argument form of substr, creating something of a quintuple
  CORE::chop:

  $tail = substr($caravan, -5, 5, "");

  If no argument is given, the function chops the $_ variable.

=item * Order Of Byte

  $ord = CORE::ord($expr);

  This function returns the numeric value of the first byte of $expr, regardless
  of "use Char::GBK qw(ord);" exists or not. If $expr is omitted, it uses $_.
  The return value is always unsigned.

  If you want a signed value, use unpack('c',$expr). If you want all the bytes of
  the string converted to a list of numbers, use unpack('C*',$expr) instead.

=item * Reverse List Or Byte String

  @reverse = CORE::reverse(@list);
  $reverse = CORE::reverse(@list);

  In list context, this function returns a list value consisting of the elements
  of @list in the opposite order.

  In scalar context, the function concatenates all the elements of @list and then
  returns the reverse of that resulting string, byte by byte, regardless of
  "use Char::GBK qw(reverse);" exists or not.

=item * Index By Byte String

  $index = CORE::index($string,$substring,$offset);
  $index = CORE::index($string,$substring);

  This function searches for one byte string within another. It returns the position
  of the first occurrence of $substring in $string. The $offset, if specified, says
  how many bytes from the start to skip before beginning to look. Positions are based
  at 0. If the substring is not found, the function returns one less than the base,
  ordinarily -1. To work your way through a string, you might say:

  $pos = -1;
  while (($pos = CORE::index($string, $lookfor, $pos)) > -1) {
      print "Found at $pos\n";
      $pos++;
  }

=item * Rindex By Byte String

  $rindex = CORE::rindex($string,$substring,$offset);
  $rindex = CORE::rindex($string,$substring);

  This function works just like CORE::index except that it returns the position of
  the last occurrence of $substring in $string (a reverse CORE::index). The function
  returns -1 if not $substring is found. $offset, if specified, is the rightmost
  position that may be returned. To work your way through a string backward, say:

  $pos = CORE::length($string);
  while (($pos = CORE::rindex($string, $lookfor, $pos)) >= 0) {
      print "Found at $pos\n";
      $pos--;
  }

=back

=head1 Un-Escaping bytes::* Functions (Char/GBK.pm provides)

Char/GBK.pm removes 'bytes::' at head of function name.

  ---------------------------------------
  Before           After     Works as
  ---------------------------------------
  bytes::chr       chr       Byte
  bytes::index     index     Byte
  bytes::length    length    Byte
  bytes::ord       ord       Byte
  bytes::rindex    rindex    Byte
  bytes::substr    substr    Byte
  ---------------------------------------

=head1 Escaping Built-in Standard Module (Char/Egbk.pm provides)

Char/Egbk.pm does "BEGIN { unshift @INC, '/Perl/site/lib/Char::GBK' }" at head.
Store the standard module modified for Char::GBK software in this directory to
override built-in standard modules.

=head1 Escaping Standard Module Content (You do)

You need copy built-in standard module to /Perl/site/lib/Char::GBK and change
'use utf8;' to 'use Char::GBK;' in its. You need help yourself for now.

Back to and see 'Escaping Your Script'. Enjoy hacking!!

=head1 Ignore Pragmas And Modules

  -----------------------------------------------------------
  Before                    After
  -----------------------------------------------------------
  use strict;               use strict; no strict qw(refs);
  use 5.12.0;               use 5.12.0; no strict qw(refs);
  require utf8;             # require utf8;
  require bytes;            # require bytes;
  require charnames;        # require charnames;
  require I18N::Japanese;   # require I18N::Japanese;
  require I18N::Collate;    # require I18N::Collate;
  require I18N::JExt;       # require I18N::JExt;
  require File::DosGlob;    # require File::DosGlob;
  require Wild;             # require Wild;
  require Wildcard;         # require Wildcard;
  require Japanese;         # require Japanese;
  use utf8;                 # use utf8;
  use bytes;                # use bytes;
  use charnames;            # use charnames;
  use I18N::Japanese;       # use I18N::Japanese;
  use I18N::Collate;        # use I18N::Collate;
  use I18N::JExt;           # use I18N::JExt;
  use File::DosGlob;        # use File::DosGlob;
  use Wild;                 # use Wild;
  use Wildcard;             # use Wildcard;
  use Japanese;             # use Japanese;
  no utf8;                  # no utf8;
  no bytes;                 # no bytes;
  no charnames;             # no charnames;
  no I18N::Japanese;        # no I18N::Japanese;
  no I18N::Collate;         # no I18N::Collate;
  no I18N::JExt;            # no I18N::JExt;
  no File::DosGlob;         # no File::DosGlob;
  no Wild;                  # no Wild;
  no Wildcard;              # no Wildcard;
  no Japanese;              # no Japanese;
  -----------------------------------------------------------

  Comment out pragma to ignore utf8 environment, and Char/Egbk.pm provides these
  functions.

=over 2

=item * Dummy utf8::upgrade

  $num_octets = utf8::upgrade($string);

  Returns the number of octets necessary to represent the string.

=item * Dummy utf8::downgrade

  $success = utf8::downgrade($string[, FAIL_OK]);

  Returns true always.

=item * Dummy utf8::encode

  utf8::encode($string);

  Returns nothing.

=item * Dummy utf8::decode

  $success = utf8::decode($string);

  Returns true always.

=item * Dummy utf8::is_utf8

  $flag = utf8::is_utf8(STRING);

  Returns false always.

=item * Dummy utf8::valid

  $flag = utf8::valid(STRING);

  Returns true always.

=item * Dummy bytes::chr

  This function is same as chr.

=item * Dummy bytes::index

  This function is same as index.

=item * Dummy bytes::length

  This function is same as length.

=item * Dummy bytes::ord

  This function is same as ord.

=item * Dummy bytes::rindex

  This function is same as rindex.

=item * Dummy bytes::substr

  This function is same as substr.

=back

=head1 Environment Variable

 This software uses the flock function for exclusive control. The execution of the
 program is blocked until it becomes possible to read or write the file.
 You can have it not block in the flock function by defining environment variable
 SJIS_NONBLOCK.
 
 Example:
 
   SET SJIS_NONBLOCK=1
 
 (The value '1' doesn't have the meaning)

=head1 Perl5.6 Emulation On perl5.005

  Using warnings pragma on perl5.00503 by rename files.

  warnings.pm_ --> warnings.pm
  warnings/register.pm_ --> warnings/register.pm

=head1 Perl5.16 Emulation On perl5.005

  Using feature pragma on perl5.00503 by rename files.

  feature.pm_ --> feature.pm

=head1 BUGS AND LIMITATIONS

I have tested and verified this software using the best of my ability.
However, a software containing much regular expression is bound to contain
some bugs. Thus, if you happen to find a bug that's in Char::GBK software and not
your own program, you can try to reduce it to a minimal test case and then
report it to the following author's address. If you have an idea that could
make this a more useful tool, please let everyone share it.

=over 2

=item * format

Function "format" can't handle multiple-octet code same as original Perl.

=item * chdir

Function chdir() can always be executed with perl5.005.

There are the following limitations for DOS-like system(any of MSWin32, NetWare,
symbian, dos).

On perl5.006 or perl5.00800, if path is ended by chr(0x5C), it needs jacode.pl
library.

On perl5.008001 or later, perl5.010, perl5.012, perl5.014, perl5.016, if path is
ended by chr(0x5C), it needs Win32 module. Chdir succeeds when a short path name
can be acquired according to Win32::GetShortPathName(). However, the current
directory is a short path name.

see also,
Bug #81839
chdir does not work with chr(0x5C) at end of path
http://bugs.activestate.com/show_bug.cgi?id=81839

=item * Char::GBK::substr As Lvalue

Char::GBK::substr differs from CORE::substr, and cannot be used as a lvalue.
To change part of a string, you can use the optional fourth argument which is the
replacement string.

Char::GBK::substr($string, 13, 4, "JPerl");

=item * Special Variables $` And $& Need /( Capture All )/

  Because $` and $& use $1.

  -------------------------------------------------------------------------------------------
  Before          After                Works as
  -------------------------------------------------------------------------------------------
  $`              Char::Egbk::PREMATCH()    CORE::substr($&,0,CORE::length($&)-CORE::length($1))
  $PREMATCH       Char::Egbk::PREMATCH()    CORE::substr($&,0,CORE::length($&)-CORE::length($1))
  ${^PREMATCH}    Char::Egbk::PREMATCH()    CORE::substr($&,0,CORE::length($&)-CORE::length($1))
  $&              Char::Egbk::MATCH()       $1
  $MATCH          Char::Egbk::MATCH()       $1
  ${^MATCH}       Char::Egbk::MATCH()       $1
  $'              Char::Egbk::POSTMATCH()   $'
  $POSTMATCH      Char::Egbk::POSTMATCH()   $'
  ${^POSTMATCH}   Char::Egbk::POSTMATCH()   $'
  -------------------------------------------------------------------------------------------

=item * Limitation Of Regular Expression

This software has limitation from \G in multibyte anchoring. On perl5.006,
perl5.008, perl5.010, perl5.012, perl5.014 and perl5.016 it doesn't match in
the place in which it should match at over 32,767 octets. Moreover, at that
time, neither the error nor warning are displayed.

see also,
Bug #89792
\G can't treat over 32,767 octets
http://bugs.activestate.com/show_bug.cgi?id=89792

=item * Empty Variable In Regular Expression

Unlike literal null string, an interpolated variable evaluated to the empty string
can't use the most recent pattern from a previous successful regular expression.

=item * Limitation Of ?? and m??

Multibyte character needs ( ) which is before {n,m} {n,} {n} * and + in ?? or m??.
As a result, you need to rewrite a script about $1,$2,$3,... You cannot use (?: )
? {n,m}? {n,}? and {n}? in ?? and m??, because delimiter of m?? is '?'.

=item * Look-behind Assertion

The look-behind assertion like (?<=[A-Z]) is not prevented from matching trail
octet of the previous multiple-octet code.

=item * Modifier /a /d /l And /u Of Regular Expression

The concept of this software is not to use two or more encoding methods at the
same time. Therefore, modifier /a /d /l and /u are not supported.
\d means [0-9] always.

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 My Goal

P.401 See chapter 15: Unicode
of ISBN 0-596-00027-8 Programming Perl Third Edition.

Before the introduction of Unicode support in perl, The eq operator
just compared the byte-strings represented by two scalars. Beginning
with perl 5.8, eq compares two byte-strings with simultaneous
consideration of the UTF8 flag.

  Information processing model beginning with perl 5.8
 
    +----------------------+---------------------+
    |     Text strings     |                     |
    +----------+-----------|    Binary strings   |
    |   UTF8   |  Latin-1  |                     |
    +----------+-----------+---------------------+
    | UTF8     |            Not UTF8             |
    | Flagged  |            Flagged              |
    +--------------------------------------------+
    http://perl-users.jp/articles/advent-calendar/2010/casual/4
 
    You should memorize this figure.
 
    (Why is only Latin-1 special?)

This change consequentially made a big gap between a past script and
new script. Both scripts cannot re-use the code mutually any longer.
Because a new method puts a strain in the programmer, it will still take
time to replace all the in existence scripts.

The biggest problem of new method is that the UTF8 flag can't synchronize
to real encode of string. Thus you must debug about UTF8 flag, before
your script. How to solve it by returning to a past method, let's drag out
page 402 of the old dusty Programming Perl, 3rd ed. again.

  Information processing model with this software

    +--------------------------------------------+
    |       Text strings as Binary strings       |
    |       Binary strings as Text strings       |
    +--------------------------------------------+
    |              Not UTF8 Flagged              |
    +--------------------------------------------+

Ideally, I'd like to achieve these five Goals:

=over 2

=item * Goal #1:

Old byte-oriented programs should not spontaneously break on the old
byte-oriented data they used to work on.

It has already been achieved by GBK designed for combining with
old byte-oriented ASCII.

=item * Goal #2:

Old byte-oriented programs should magically start working on the new
character-oriented data when appropriate.

Still now, 1 octet is counted with 1 by embedded functions length,
substr, index, rindex and pos that handle length and position of string.
In this part, there is no change. The length of 1 character of 2 octet
code is 2.

On the other hand, the regular expression in the script is added the
multibyte anchoring processing with this software, instead of you.

figure of Goal #1 and Goal #2.

                               GOAL#1  GOAL#2
                        (a)     (b)     (c)     (d)     (e)
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New character-oriented

There is a combination from (a) to (e) in data, script and interpreter
of old and new. Let's add the Encode module and this software did not
exist at time of be written this document and JPerl did exist.

                        (a)     (b)     (c)     (d)     (e)
                                      JPerl           Encode,Char::GBK
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New character-oriented

The reason why JPerl is very excellent is that it is at the position of
(c). That is, it is not necessary to do a special description to the
script to process new character-oriented string.

Contrasting is Encode module and describing "use Char::GBK;" on this software,
in this case, a new description is necessary.

=item * Goal #3:

Programs should run just as fast in the new character-oriented mode
as in the old byte-oriented mode.

It is impossible. Because the following time is necessary.

(1) Time of escape script for old byte-oriented perl.

(2) Time of processing regular expression by escaped script while
    multibyte anchoring.

=item * Goal #4:

Perl should remain one language, rather than forking into a
byte-oriented Perl and a character-oriented Perl.

JPerl remains one Perl language by forking to two interpreters.
However, the Perl core team did not desire fork of the interpreter.
As a result, Perl language forked contrary to goal #4.

A character-oriented perl is not necessary to make it specially,
because a byte-oriented perl can already treat the binary data.
This software is only an application program of byte-oriented Perl,
a filter program.

And you will get support from the Perl community, when you solve the
problem by the Perl script.

=item * Goal #5:

JPerl users will be able to maintain JPerl by Perl.

May the JPerl be with you, always.

=back

Back when Programming Perl, 3rd ed. was written, UTF8 flag was not born
and Perl is designed to make the easy jobs easy. This software provide
programming environment like at that time.

=head1 Words Of Learning Perl

   Some computer scientists (the reductionists, in particular) would
  like to deny it, but people have funny-shaped minds. Mental geography
  is not linear, and cannot be mapped onto a flat surface without
  severe distortion. But for the last score years or so, computer
  reductionists have been first bowing down at the Temple of Orthogonality,
  then rising up to preach their ideas of ascetic rectitude to any who
  would listen.
 
   Their fervent but misguided desire was simply to squash your mind to
  fit their mindset, to smush your patterns of thought into some sort of
  Hyperdimensional Flatland. It's a joyless existence, being smushed.
 
  --- Learning Perl on Win32 Systems
 
  If you think this is a big headache, you're right. No one likes
  this situation, but Perl does the best it can with the input and
  encodings it has to deal with. If only we could reset history and
  not make so many mistakes nest time.
 
  --- Learning Perl 6th Edition

=head1 SEE ALSO

 PERL PUROGURAMINGU
 Larry Wall, Randal L.Schwartz, Yoshiyuki Kondo
 December 1997
 ISBN 4-89052-384-7
 http://www.context.co.jp/~cond/books/old-books.html

 Programming Perl, Second Edition
 By Larry Wall, Tom Christiansen, Randal L. Schwartz
 October 1996
 Pages: 670
 ISBN 10: 1-56592-149-6 | ISBN 13: 9781565921498
 http://shop.oreilly.com/product/9781565921498.do

 Programming Perl, Third Edition
 By Larry Wall, Tom Christiansen, Jon Orwant
 Third Edition  July 2000
 Pages: 1104
 ISBN 10: 0-596-00027-8 | ISBN 13: 9780596000271
 http://shop.oreilly.com/product/9780596000271.do

 The Perl Language Reference Manual (for Perl version 5.12.1)
 by Larry Wall and others
 Paperback (6"x9"), 724 pages
 Retail Price: $39.95 (pound 29.95 in UK)
 ISBN-13: 978-1-906966-02-7
 http://www.network-theory.co.uk/perl/language/

 Perl Pocket Reference, 5th Edition
 By Johan Vromans
 Publisher: O'Reilly Media
 Released: July 2011
 Pages: 102
 http://shop.oreilly.com/product/0636920018476.do

 Programming Perl, 4th Edition
 By: Tom Christiansen, brian d foy, Larry Wall, Jon Orwant
 Publisher: O'Reilly Media
 Formats: Print, Ebook, Safari Books Online
 Released: March 2012
 Pages: 1130
 Print ISBN: 978-0-596-00492-7 | ISBN 10: 0-596-00492-3
 Ebook ISBN: 978-1-4493-9890-3 | ISBN 10: 1-4493-9890-1
 http://shop.oreilly.com/product/9780596004927.do

 Perl Cookbook, Second Edition
 By Tom Christiansen, Nathan Torkington
 Second Edition  August 2003
 Pages: 964
 ISBN 10: 0-596-00313-7 | ISBN 13: 9780596003135
 http://shop.oreilly.com/product/9780596003135.do

 Perl in a Nutshell, Second Edition
 By Stephen Spainhour, Ellen Siever, Nathan Patwardhan
 Second Edition  June 2002
 Pages: 760
 Series: In a Nutshell
 ISBN 10: 0-596-00241-6 | ISBN 13: 9780596002411
 http://shop.oreilly.com/product/9780596002411.do

 Learning Perl on Win32 Systems
 By Randal L. Schwartz, Erik Olson, Tom Christiansen
 August 1997
 Pages: 306
 ISBN 10: 1-56592-324-3 | ISBN 13: 9781565923249
 http://shop.oreilly.com/product/9781565923249.do

 Learning Perl, Fifth Edition
 By Randal L. Schwartz, Tom Phoenix, brian d foy
 June 2008
 Pages: 352
 Print ISBN:978-0-596-52010-6 | ISBN 10: 0-596-52010-7
 Ebook ISBN:978-0-596-10316-3 | ISBN 10: 0-596-10316-6
 http://shop.oreilly.com/product/9780596520113.do

 Learning Perl, 6th Edition
 By Randal L. Schwartz, brian d foy, Tom Phoenix
 June 2011
 Pages: 390
 ISBN-10: 1449303587 | ISBN-13: 978-1449303587
 http://shop.oreilly.com/product/0636920018452.do

 Perl RESOURCE KIT UNIX EDITION
 Futato, Irving, Jepson, Patwardhan, Siever
 ISBN 10: 1-56592-370-7
 http://shop.oreilly.com/product/9781565923706.do

 Understanding Japanese Information Processing
 By Ken Lunde
 January 1900
 Pages: 470
 ISBN 10: 1-56592-043-0 | ISBN 13: 9781565920439
 http://shop.oreilly.com/product/9781565920439.do

 CJKV Information Processing
 Chinese, Japanese, Korean & Vietnamese Computing
 By Ken Lunde
 First Edition  January 1999
 Pages: 1128
 ISBN 10: 1-56592-224-7 | ISBN 13: 9781565922242
 http://shop.oreilly.com/product/9781565922242.do

 Mastering Regular Expressions, Second Edition
 By Jeffrey E. F. Friedl
 Second Edition  July 2002
 Pages: 484
 ISBN 10: 0-596-00289-0 | ISBN 13: 9780596002893
 http://shop.oreilly.com/product/9780596002893.do

 Mastering Regular Expressions, Third Edition
 By Jeffrey E. F. Friedl
 Third Edition  August 2006
 Pages: 542
 ISBN 10: 0-596-52812-4 | ISBN 13:9780596528126
 http://shop.oreilly.com/product/9780596528126.do

 Regular Expressions Cookbook
 By Jan Goyvaerts, Steven Levithan
 May 2009
 Pages: 512
 ISBN 10:0-596-52068-9 | ISBN 13: 978-0-596-52068-7
 http://shop.oreilly.com/product/9780596520694.do

 JIS KANJI JITEN
 Kouji Shibano
 Pages: 1456
 ISBN 4-542-20129-5
 http://www.webstore.jsa.or.jp/lib/lib.asp?fn=/manual/mnl01_12.htm

 UNIX MAGAZINE
 1993 Aug
 Pages: 172
 T1008901080816 ZASSHI 08901-8
 http://ascii.asciimw.jp/books/books/detail/978-4-7561-5008-0.shtml

 MacPerl Power and Ease
 By Vicki Brown, Chris Nandor
 April 1998
 Pages: 350
 ISBN 10: 1881957322 | ISBN 13: 978-1881957324
 http://www.amazon.com/Macperl-Power-Ease-Vicki-Brown/dp/1881957322

 Other Tools
 http://search.cpan.org/dist/jacode/
 http://search.cpan.org/dist/Char/

 BackPAN
 http://backpan.perl.org/authors/id/I/IN/INA/

=head1 ACKNOWLEDGEMENTS

This software was made referring to software and the document that the
following hackers or persons had made. 
I am thankful to all persons.

 Rick Yamashita, Shift_JIS
 ttp://furukawablog.spaces.live.com/Blog/cns!1pmWgsL289nm7Shn7cS0jHzA!2225.entry (dead link)
 ttp://shino.tumblr.com/post/116166805/1981-us-jis
 (add 'h' at head)
 http://www.wdic.org/w/WDIC/%E3%82%B7%E3%83%95%E3%83%88JIS

 Larry Wall, Perl
 http://www.perl.org/

 Kazumasa Utashiro, jcode.pl
 ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/
 http://log.utashiro.com/pub/2006/07/jkondo_a580.html

 Jeffrey E. F. Friedl, Mastering Regular Expressions
 http://regex.info/

 SADAHIRO Tomoyuki, The right way of using Shift_JIS
 http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm

 Yukihiro "Matz" Matsumoto, YAPC::Asia2006 Ruby on Perl(s)
 http://www.rubyist.net/~matz/slides/yapc2006/

 jscripter, For jperl users
 http://homepage1.nifty.com/kazuf/jperl.html

 Bruce., Unicode in Perl
 http://www.rakunet.org/tsnet/TSabc/18/546.html

 Hiroaki Izumi, Perl5.8/Perl5.10 is not useful on the Windows.
 http://www.aritia.jp/hizumi/perl/perlwin.html

 TSUKAMOTO Makio, Perl memo/file path of Windows
 http://digit.que.ne.jp/work/wiki.cgi?Perl%E3%83%A1%E3%83%A2%2FWindows%E3%81%A7%E3%81%AE%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%83%91%E3%82%B9

 chaichanPaPa, Matching Shift_JIS file name
 http://d.hatena.ne.jp/chaichanPaPa/20080802/1217660826

 SUZUKI Norio, Jperl
 http://homepage2.nifty.com/kipp/perl/jperl/

 WATANABE Hirofumi, Jperl
 http://www.cpan.org/src/5.0/jperl/
 http://search.cpan.org/~watanabe/
 ftp://ftp.oreilly.co.jp/pcjp98/watanabe/jperlconf.ppt

 Chuck Houpt, Michiko Nozu, MacJPerl
 http://habilis.net/macjperl/index.j.html

 Kenichi Ishigaki, Pod-PerldocJp, Welcome to modern Perl world
 http://search.cpan.org/dist/Pod-PerldocJp/
 http://gihyo.jp/dev/serial/01/modern-perl/0031
 http://gihyo.jp/dev/serial/01/modern-perl/0032
 http://gihyo.jp/dev/serial/01/modern-perl/0033

 Dan Kogai, Encode module
 http://search.cpan.org/dist/Encode/
 http://www.archive.org/details/YAPCAsia2006TokyoPerl58andUnicodeMythsFactsandChanges (video)
 http://yapc.g.hatena.ne.jp/jkondo/ (audio)

 Juerd, Perl Unicode Advice
 http://juerd.nl/site.plp/perluniadvice

 daily dayflower, 2008-06-25 perluniadvice
 http://d.hatena.ne.jp/dayflower/20080625/1214374293

 Jesse Vincent, Compatibility is a virtue
 http://www.nntp.perl.org/group/perl.perl5.porters/2010/05/msg159825.html

 Tokyo-pm archive
 http://mail.pm.org/pipermail/tokyo-pm/
 http://mail.pm.org/pipermail/tokyo-pm/1999-September/001844.html
 http://mail.pm.org/pipermail/tokyo-pm/1999-September/001854.html

 ruby-list
 http://blade.nagaokaut.ac.jp/ruby/ruby-list/index.shtml
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/2440
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/2446
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/2569
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/9427
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/9431
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/10500
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/10501
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/10502
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/12385
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/12392
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/12393
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/19156

=cut

