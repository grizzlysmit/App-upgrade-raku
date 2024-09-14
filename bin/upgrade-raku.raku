#!/usr/bin/env raku
use v6;

my %*SUB-MAIN-OPTS;
%*SUB-MAIN-OPTS«named-anywhere» = True;
#%*SUB-MAIN-OPTS<bundling>       = True;

use Terminal::ANSI::OO :t;
use Terminal::Width;
use Terminal::WCWidth;
use ECMA262Regex;
#use Usage::Utils;
use Display::Listings;
#use File::Utils;

=begin pod

=head1 App::upgrade-raku

=begin head2

Table of Contents

=end head2

=item1 L<NAME|#name>
=item1 L<AUTHOR|#author>
=item1 L<VERSION|#version>
=item1 L<TITLE|#title>
=item1 L<SUBTITLE|#subtitle>
=item1 L<COPYRIGHT|#copyright>
=item1 # L<Introduction|#introduction>
=item2 # L<upgrade-raku build|#upgrade-raku-build>
=item2 # L<upgrade-raku download|#upgrade-raku-download>
=item2 # L<upgrade-raku dl|#upgrade-raku-dl>
=item2 # L<upgrade-raku add zef|#upgrade-raku-add-zef>
=item2 # L<upgrade-raku add apt|#upgrade-raku-add-apt>
=item2 # L<upgrade-raku list zef|#upgrade-raku-list-zef>
=item2 # L<upgrade-raku list apt|#upgrade-raku-list-apt>
=item2 # L<upgrade-raku download|#upgrade-raku-download>
=item2 # L<upgrade-raku download|#upgrade-raku-download>
=item2 # L<upgrade-raku download|#upgrade-raku-download>

=NAME App::upgrade-raku 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION 0.1.2
=TITLE App::upgrade-raku
=SUBTITLE A B<Raku> application for updating/upgrading the local B<Raku> install. It also installs and upgrades the packages and any system packages.

=COPYRIGHT
LGPL V3.0+ L<LICENSE|https://github.com/grizzlysmit/GUI-Editors/blob/main/LICENSE>

L<Top of Document|#table-of-contents>

=head1 Introduction

 A B<Raku> application for updating/upgrading the local B<Raku> install. It also installs and upgrades the packages and any system packages. 

B<NB: I only support the moar backend for now. And for now I only support the apt command as I use Ubuntu,
I will give supporting other package managing software some thought>.

b<Note: uses I<rakubrew> under the hood for the actual I<Raku> install/upgrade,  will check for a new version etc.>

=end pod

my Str:D $config = "$*HOME/.local/share/upgrade-raku";

$config.IO.mkdir unless $config.IO ~~ :f;

"$config/zef-packages".IO.spurt('') unless "$config/zef-packages".IO ~~ :f;

"$config/apt-packages".IO.spurt('') unless "$config/apt-packages".IO ~~ :f;

my @zef-packages = "$config/zef-packages".IO.slurp().split(rx/\n/).grep({ !rx/ [ ^^ \h* '#' .* $$ || ^^ \s* $$ ] / }).map( -> Str:D $ln { ($ln ~~ rx/ ^ \s* $<pkg> = [ \w+ [ [ '-' || '::' ]+ \w+ ]* ] \h* $<opt> = [ '--force-test' ]? \h* [ '#' \h* $<comment> = [ .* ] ]?  $ /) ?? ( { type => 'valid', package => (~$<pkg>).trim, opt => ~$<opt>, comment => ($<comment> ?? ~$<comment> !! Str), }) !! { line => $ln, type => 'bad line.' } }).grep: -> %row { %row«type» eq 'valid' };

my @apt-packages = "$config/apt-packages".IO.slurp().split(rx/\n/).grep({ !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / }).map( -> Str:D $ln { ($ln ~~ rx/ ^ \s* $<pkg> = [ \w+ [ [ '-' || '::' ]+ \w+ ]* ] \s* [ '#' \s* $<comment> = [ .* ] ]?  $ /) ?? ( { type => 'valid', package => (~$<pkg>).trim, comment => ($<comment> ?? ~$<comment> !! Str), }) !! { line => $ln, type => 'bad line.' } }).grep: -> %row { %row«type» eq 'valid' };

sub install-pkgs(Bool:D $upgrade-the-packages --> Num:D) {
    my Str:D $action = $upgrade-the-packages ?? 'upgrade' !! 'install';
    my Int:D $total = @zef-packages.elems + @apt-packages.elems;
    my Int:D $cnt = 0;
    for @zef-packages -> %row {
        my Str:D $pkg = %row«package»;
        my Str   $opt = %row«opt»;
        my       @cmd = qqww[zef $action];
        with $opt {
            qq[zef $action $opt $pkg].say;
            @cmd.push: $opt;
        } else {
            qq[zef $action $pkg].say;
        }
        @cmd.push: $pkg;
        my Proc $p = run @cmd;
        $cnt++ if $p.exitcode != 0;
    }
    dd @apt-packages;
    for @apt-packages -> %row {
        my Str:D $pkg = %row«package»;
        qq[sudo apt $action $pkg].say;
        my Proc $p = run 'sudo', 'apt',  $action, $pkg;
        $cnt++ if $p.exitcode != 0;
    }
    return $cnt.Num / $total.Num * 100.Num;
}

multi sub MAIN('install', 'pkgs',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False  --> Int:D) {
    my Num:D $success = install-pkgs($upgrade-the-packages);
    qq[$success% of packages upgraded successfully].say; 
    exit 0
}

=begin pod

=head3 upgrade-raku build

Upgrade B<Raku> using the B<rakubrew build moar> method.

=begin code :lang<raku>

multi sub MAIN('build',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D) 

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('build',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D) {
    if $upgrade-the-packages {
        my Num:D $success = install-pkgs($upgrade-the-packages);
        qq[$success% of packages upgraded successfully].say; 
        exit 0
    }
    'rakubrew self-upgrade'.say;
    my @cmd0 = qw[bash -lc];
    @cmd0.push: 'rakubrew self-upgrade';
    my Str:D $content = '';
    my Proc  $p0    = run @cmd0;
    {
        'rakubrew list-available'.say;
        my @cmd1 = qw[bash -lc];
        @cmd1.push: 'rakubrew list-available';
        my Proc  $p1    = run @cmd1, :out;
        $content = $p1.out.slurp: :close if $p1.exitcode == 0;
        say $content;
        CATCH {
            default { .say, .^name; }
        }
    }
    my       @content = $content.split(rx/\n/).grep( { rx/ ^ '*'? \h* 'D'? \h+ \d ** 4 '.' \d ** 2 [ '.' \d+ ]? \h* $ / });
    my Str:D $last    = (@content.elems == 0) ?? '' !! @content.pop;
    my       @last    = $last.split(rx/ ' '+ /);
    if $last ~~ rx/ ^ '*' \h* 'D'? \h+ \d ** 4 '.' \d ** 2 [ '.' \d+ ]? \h* $ / {
        qq[Already up to date Nothing to do].say;
        exit 0;
    } elsif @last.elems == 0 || $last !~~ rx/ ^ \h+ 'D'? \h+ \d ** 4 '.' \d ** 2 [ '.' \d+ ]? \h* $ / {
        $*ERR.say: "rakubrew list-available Failed";
        exit 1;
    }
    my Str:D $version = @last.pop;
    my @cmd2 = qqww[bash -lc];
    my Str:D $cmd2 = qq[rakubrew build moar];
    $cmd2.say;
    @cmd2.push: $cmd2;
    my Proc $p2 = run @cmd2, :out;
    unless $p2.exitcode == 0 {
        $*ERR.say: qq[$cmd2 Failed exitcode = {$p2.exitcode}.];
        exit 2;
    }
    my Str:D $output = $p2.out.slurp: :close;
    my @output = $output.split(rx/\n/);
    my Str:D $_last = @output.pop;
    my @_last = $_last.split(rx/ \h+ /);
    my $done = @_last[0];
    unless $done eq 'Done,' {
        $*ERR.say: qq[something went wrong bailing.];
        exit 3;
    }
    my $ver  = @_last[1];
    unless $ver eq $version {
        $*ERR.say: qq[something went wrong version mismatch bailing.];
        exit 4;
    }
    qq[rakubrew build-zef].say;
    my @cmd3 = qw[bash -lc];
    @cmd3.push: 'rakubrew build-zef';
    my Proc $p3 = run @cmd3;
    unless $p3.exitcode == 0 {
        $*ERR.say: "build-zef Failed";
        exit 5;
    }
    if $version ~~ rx/ ^ \d ** 4 '.' \d ** 2 [ '.' \d+ ]? $ / {
        qq[rakubrew switch "$version"].say;
        my @cmd2 = qqww[bash -lc];
        @cmd2.push: "rakubrew switch '$version'";
        my Proc $p0 = run @cmd2;
        unless $p0.exitcode == 0 {
            $*ERR.say: "switch Failed";
            exit 6;
        }
        my Num:D $success = install-pkgs($upgrade-the-packages);
       qq[$success% of packages installed successfully].say; 
       my Proc $p1 = shell q[raku -e '"Installed!!! This is $*RAKU - specifically: { ($*RAKU, $*VM, $*DISTRO).map({ $_.gist })}".say;'];
    } else {
        $*ERR.say: "unknown version: $version";
        exit 7;
    }
} #`««« multi sub MAIN('build',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D) »»»

=begin pod

=head3 upgrade-raku download

Upgrade B<Raku> using the B<rakubrew download> method.

=begin code :lang<raku>

multi sub MAIN('download',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D) 

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('download',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D) {
    if $upgrade-the-packages {
        my Num:D $success = install-pkgs($upgrade-the-packages);
        qq[$success% of packages upgraded successfully].say; 
        exit 0
    }
    'rakubrew self-upgrade'.say;
    my @cmd0 = qw[bash -lc];
    @cmd0.push: 'rakubrew self-upgrade';
    my Str:D $content = '';
    my Proc  $p0    = run @cmd0;
    {
        'rakubrew download'.say;
        my @cmd1 = qw[bash -lc];
        @cmd1.push: 'rakubrew download';
        my Proc  $p1    = run @cmd1, :out;
        $content = $p1.out.slurp: :close if $p1.exitcode == 0;
        CATCH {
            default { .say, .^name; }
        }
    }
    my       @content = $content.split(rx/\n/);
    my Str:D $last    = (@content.elems == 0) ?? '' !! @content.pop;
    my       @last    = $last.split(rx/ ' '+ /);
    if $last ~~ rx/ ^ 'moar-' \d ** 4 '.' \d ** 2 \s+ 'is already installed.' $/ {
        $content.say;
        exit 0;
    } elsif @last.elems == 0 || @last[0] ne 'Done,' {
        $*ERR.say: "rakubrew download failed";
        exit 1;
    }
    my Str:D $version = @last[1];
    if $version ~~ rx/ ^ 'moar-' \d ** 4 '.' \d ** 2 [ '.' \d+ ]? $ / {
        qq[rakubrew switch "$version"].say;
        my @cmd2 = qqww[bash -lc];
        @cmd2.push: "rakubrew switch '$version'";
        my Proc $p0 = run @cmd2;
        unless $p0.exitcode == 0 {
            $*ERR.say: "switch Failed";
            exit 3;
        }
        #`«««
        #»»»
        my Num:D $success = install-pkgs($upgrade-the-packages);
       qq[$success% of packages installed successfully].say; 
       my Proc $p1 = shell q[raku -e '"Installed!!! This is $*RAKU - specifically: { ($*RAKU, $*VM, $*DISTRO).map({ $_.gist })}".say;'];
    } else {
        $*ERR.say: "unknown version: $version";
        exit 2;
    }
} #`««« multi sub MAIN('download',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D) »»»

=begin pod

=head3 upgrade-raku dl

An alias for L<upgrade-raku download|#upgrade-raku-download>.

=begin code :lang<raku>

multi sub MAIN('dl',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D) 

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('dl',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D) {
    MAIN('download', :$upgrade-the-packages);
}

=begin pod

=head3 upgrade-raku add zef

Add B<Raku> packages to be installed with B<zef>.

=begin code :lang<bash>

upgrade-raku add zef --help
Usage:
  upgrade-raku add zef <pkg> [<additional-pkgs> ...] [--force-test] [-c|--comment=<Str>] [--<additional-pkgs-with-comments>=...] 

=end code

=item1 Where
=item2 # B<C<pkg>> is a B<Raku> package to be installed.
=item2 # B<C<--force-test>> if present the package B<pkg> will be installed with the --force-test option to zef.
=item3 # if you want to B<--force-test> multiple packages you'll need to add them separately.
=item2 # B<C<-c|--comment>> if supplied is a comment to add to B<pkg>.
=item2 # B<C<additional-pkgs>> is an array of packages to add without comments or options.
=item2 # B<C<--additional-pkgs-with-comments=...>> is a hash of packages and comments to add.
=item3 # looks like this B<upgrade-raku add zef ... --pkg1=comment1 --pkg2=comment2 ...>.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('add', 'zef',
                Str:D $pkg,
                Bool:D :$force-test = False,
                Str :c(:$comment) = Str,
                *%additional-pkgs-with-comments, 
                *@additional-pkgs is copy --> Int:D) {
    my Str:D $tail = '';
    if $force-test {
        $tail ~= " --force-test ";
    }
    with $comment {
        $tail ~= " # $comment";
    }
    @additional-pkgs.prepend("$pkg$tail");
    my $forcetest = '';
    $forcetest = ' --force-test ' if $force-test;
    for %additional-pkgs-with-comments.kv -> Str:D $pkg, $comment {
        if $comment ~~ List {
            for $comment.list -> Str:D $com {
                @additional-pkgs.push: "$pkg $forcetest  # $com";
            }
        } else {
            @additional-pkgs.push: "$pkg $forcetest  # $comment";
        }
    }
    "$config/zef-packages".IO.spurt(@additional-pkgs.join("\n"), :append);
}

=begin pod

=head3 upgrade-raku add apt

Add system packages to be installed with B<apt>.

=begin code :lang<bash>

upgrade-raku add apt --help
Usage:
  upgrade-raku add apt <pkg> [<additional-pkgs> ...] [-c|--comment=<Str>] [--<additional-pkgs-with-comments>=...] 

=end code

=item1 Where
=item2 # B<C<pkg>> is a B<Raku> package to be installed.
=item2 # B<C<-c|--comment>> if supplied is a comment to add to B<pkg>.
=item2 # B<C<additional-pkgs>> is an array of packages to add without comments or options.
=item2 # B<C<--additional-pkgs-with-comments=...>> is a hash of packages and comments to add.
=item3 # looks like this B<upgrade-raku add apt ... --pkg1=comment1 --pkg2=comment2 ...>.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('add', 'apt',
                Str:D $pkg,
                Str :c(:$comment) = Str,
                *%additional-pkgs-with-comments, 
                *@additional-pkgs is copy --> Int:D) {
    my Str:D $tail = '';
    with $comment {
        $tail ~= " # $comment";
    }
    @additional-pkgs.prepend("$pkg$tail");
    for %additional-pkgs-with-comments.kv -> Str:D $pkg, Str:D $comment {
        @additional-pkgs.push: "$pkg   # $comment";
    }
    "$config/apt-packages".IO.spurt(@additional-pkgs.join("\n"), :append);
}

sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
    my Str:D $result = '';
    given $field {
        when 'package' { $result = $field;     }
        when 'opt'     { $result = $field;     }
        when 'comment' { $result = "# $field"; }
    }
    if $colour {
        if $syntax { 
            return t.color(255, 0, 255) ~ $result;
        } else {
            return t.color(255, 0, 255) ~ $result;
        }
    } else {
        return $result;
    }
}

sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
    my Str:D $val = ~($value // ''); 
    my Str:D $result = '';
    given $field {
        when 'package' { $result = $val;     }
        when 'opt'     { $result = $val;     }
        when 'comment' { $result = "# $val"; }
    }
    if $colour {
        if $syntax { 
            given $field {
                when 'package' { return t.color(255, 0, 255) ~ $result; }
                when 'opt'     { return t.color(255, 0, 0)   ~ $result; }
                when 'comment' { return t.color(0, 0, 255)   ~ $result; }
            }
            return ;
        } else {
            return t.color(0, 0, 255) ~ $result;
        }
    } else {
        return $result;
    }
}

=begin pod

=head3 upgrade-raku list zef

List the B<Raku> packages to be installed with B<zef>.

=begin code :lang<bash>

upgrade-raku list zef --help
Usage:
  upgrade-raku list zef [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]

=end code

=item1 Where
=item2 # B<C<prefix>> if present only lines that some field start with B<prefix> will be listed.
=item2 # B<C<-c|--color|--colour>> if present display ANSI coloured text.
=item2 # B<C<-s|--syntax>> if present display text syntax highlighted.
=item3 # B<NB: If both --syntax and --colour are supplied then --syntax wins>.
=item2 # B<C<-l|--page-length[=Int]>> if present sets the page length (defaults to 30 items).
=item2 # B«C«-p|--pattern=<Str>»» if present only lines that have fields that match B<pattern> are listed.
=item2 # B«C«-e|--ecma-pattern=<Str>»» if present only lines that have fields that match B<pattern> are listed.
=item3 # B«If both --pattern and --ecma-pattern are supplied then --pattern wins».

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('list', 'zef', Str $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Int:D :l(:$page-length) = 30,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str --> Int:D) {
        my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    my Str:D @fields = 'package', 'opt', 'comment';
    my %defaults;
    if list-by($prefix, $colour, $syntax, $page-length,
                  $_pattern, @fields, %defaults, @zef-packages,
                  #:&include-row, 
                  :&head-value, 
                  #:&head-between,
                  :&field-value 
                  #:&between,
                  #:&row-formatting
                  ) {
        exit 0;
    } else {
        exit 1;
    }
}

=begin pod

=head3 upgrade-raku list apt

List the system packages to be installed with B<apt>.

=begin code :lang<bash>

upgrade-raku list apt --help
Usage:
  upgrade-raku list apt [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]

=end code

=item1 Where
=item2 # B<C<prefix>> if present only lines that some field start with B<prefix> will be listed.
=item2 # B<C<-c|--color|--colour>> if present display ANSI coloured text.
=item2 # B<C<-s|--syntax>> if present display text syntax highlighted.
=item3 # B<NB: If both --syntax and --colour are supplied then --syntax wins>.
=item2 # B<C<-l|--page-length[=Int]>> if present sets the page length (defaults to 30 items).
=item2 # B«C«-p|--pattern=<Str>»» if present only lines that have fields that match B<pattern> are listed.
=item2 # B«C«-e|--ecma-pattern=<Str>»» if present only lines that have fields that match B<pattern> are listed.
=item3 # B«If both --pattern and --ecma-pattern are supplied then --pattern wins».

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('list', 'apt', Str $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Int:D :l(:$page-length) = 30,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str --> Int:D) {
        my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    my Str:D @fields = 'package', 'comment';
    my %defaults;
    if list-by($prefix, $colour, $syntax, $page-length,
                  $_pattern, @fields, %defaults, @apt-packages,
                  #:&include-row, 
                  :&head-value, 
                  #:&head-between,
                  :&field-value 
                  #:&between,
                  #:&row-formatting
                  ) {
        exit 0;
    } else {
        exit 1;
    }
}
