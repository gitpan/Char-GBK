# This file is encoded in Char::GBK.
die "This file is not encoded in Char::GBK.\n" if q{��} ne "\x82\xa0";

use Char::GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

# �C���q C<i>, C<I> ����� C<j> �́AC<\p{}>, C<\P{}>, POSIX C<[: :]>.
# (�Ⴆ�� C<\p{IsLower}>, C<[:lower:]> �Ȃ�) �ɂ͍�p���܂���B
# ���̂��߁AC<re('\p{Lower}', 'iI')> �̑����
# C<re('\p{Alpha}')> ���g�p���Ă��������B

# Char::GBK �\�t�g�E�F�A�� C<\p{}>, C<\P{}>, POSIX C<[: :]> �̋@�\�����Ƃ��Ƒ��݂��Ȃ��B

print "ok - 1 $^X $__FILE__ (NULL)\n";

__END__

