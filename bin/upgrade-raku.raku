#!/usr/bin/env raku
use v6;

my %*SUB-MAIN-OPTS;
%*SUB-MAIN-OPTS«named-anywhere» = True;
#%*SUB-MAIN-OPTS<bundling>       = True;


my Str:D $config = "$*HOME/.local/share/upgrade-raku";

$config.IO.mkdir unless $config.IO ~~ :f;

"$config/zef-packages".IO.spurt('') unless "$config/zef-packages".IO ~~ :f;

"$config/apt-packages".IO.spurt('') unless "$config/apt-packages".IO ~~ :f;

my @zef-packages = "$config/zef-packages".IO.slurp().split(rx/\n/);

my @apt-packages = "$config/apt-packages".IO.slurp().split(rx/\n/);

sub install-pkgs(Bool:D $upgrade --> Num:D) {
    my Str:D $action = $upgrade ?? 'upgrade' !! 'install';
    my Int:D $total = @zef-packages.elems + @apt-packages.elems;
    my Int:D $cnt = 0;
    for @zef-packages -> $pkg {
        qq[zef $action $pkg].say;
        my Proc $p = run 'zef',  $action, $pkg;
        $cnt++ if $p.exitcode != 0;
    }
    dd @apt-packages;
    for @apt-packages -> $pkg {
        qq[sudo apt $action $pkg].say;
        my Proc $p = run 'sudo', 'apt',  $action, $pkg;
        $cnt++ if $p.exitcode != 0;
    }
    return $cnt.Num / $total.Num * 100.Num;
}

multi sub MAIN('build', Bool:D :u(:$upgrade) = False --> Int:D) {
    if $upgrade {
        my Num:D $success = install-pkgs($upgrade);
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
        CATCH {
            default { .say, .^name; }
        }
    }
    my       @content = $content.split(rx/\n/).grep( { rx/ ^ [ '*' || \h+ ] 'D'? \h+ \d ** 4 '.' \d ** 2 [ '.' \d+ ]? \h+ $ / });
    my Str:D $last    = (@content.elems == 0) ?? '' !! @content.pop;
    my       @last    = $last.split(rx/ ' '+ /);
    if $last ~~ rx/ ^ '*' 'D'? \h+ \d ** 4 '.' \d ** 2 [ '.' \d+ ]? \h+ $ / {
        qq[Already up todate Nothing to do].say;
        exit 0;
    } elsif @last.elems == 0 || $last !~~ rx/ ^ \h+ 'D'? \h+ \d ** 4 '.' \d ** 2 [ '.' \d+ ]? \h+ $ / {
        $*ERR.say: "rakubrew list-available Failed";
        exit 1;
    }
    my Str:D $version = @last.pop;
    my Str:D $build-rev = '01';
    my Str:D $name = "rakudo-$version";
    "$*HOME/rakudo".IO.mkdir;
    qq[curl -o {$name}.tar.gz "https://rakudo.org/dl/rakudo/rakudo-{$version}.tar.gz"].say;
    my Proc $p2 = run 'curl', '-o', "{$name}.tar.gz", "https://rakudo.org/dl/rakudo/rakudo-{$version}.tar.gz";
    unless $p2.exitcode == 0 {
        $*ERR.say: qq[could not download tarball: "{$name}.tar.gz"];
        exit 5;
    }
    qq[tar -xzf {$name}.tar.gz].say;
    my Proc $p3 = run 'tar', '-xzf', "{$name}.tar.gz";
    unless $p3.exitcode == 0 {
        $*ERR.say: qq[extract tarball: "{$name}.tar.gz"];
        exit 6;
    }
    &*chdir($name);
    my @cmd2 = qqww[perl Configure.pl --gen-moar --make-install --prefix="$*HOME/rakudo"];
    @cmd2.join(' ').say;
    my Proc $p4 = run @cmd2;
    unless $p4.exitcode == 0 {
        $*ERR.say: qq[{@cmd2.join(' ')} Failed exitcode = {$p4.exitcode}.];
        exit 7;
    }
    %*ENV«PATH» = "$*HOME/rakudo/bin:$*HOME/rakudo/share/perl6/site/bin:{%*ENV«PATH»}";
    my @cmd3 = qqww[git clone https://github.com/ugexe/zef.git];
    @cmd3.join(' ').say;
    my Proc $p5 = run @cmd3;
    unless $p5.exitcode == 0 {
        $*ERR.say: qq[{@cmd3.join(' ')} Failed exitcode = {$p5.exitcode}.];
        exit 8;
    }
    &*chdir('zef');
    my @cmd4 = qqww[raku -I. bin/zef install .];
    my Proc $p6 = run @cmd4;
    unless $p6.exitcode == 0 {
        $*ERR.say: qq[{@cmd4.join(' ')} Failed exitcode = {$p6.exitcode}.];
        exit 9;
    }
    &*chdir('../..');
    my @cmd5 = qqww[rm -rf {$name}.tar.gz $name];
    @cmd5.join(' ').say;
    my Proc $p7 = run @cmd5;
    unless $p7.exitcode == 0 {
        $*ERR.say: qq[{@cmd5.join(' ')} Failed exitcode = {$p7.exitcode}.];
        exit 10;
    }
    if $version ~~ rx/ ^ \d ** 4 '.' \d ** 2 [ '.' \d+ ]? $ / {
        qq[rakubrew switch "$version"].say;
        my @cmd2 = qqww[bash -lc];
        @cmd2.push: "rakubrew switch '$version'";
        my Proc $p0 = run @cmd2;
        unless $p0.exitcode == 0 {
            $*ERR.say: "switch Failed";
            exit 3;
        }
        my Num:D $success = install-pkgs($upgrade);
       qq[$success% of packages installed successfully].say; 
       my Proc $p1 = shell q[raku -e '"Installed!!! This is $*RAKU - specifically: { ($*RAKU, $*VM, $*DISTRO).map({ $_.gist })}".say;'];
    } else {
        $*ERR.say: "unknown version: $version";
        exit 2;
    }
}

multi sub MAIN('download', Bool:D :u(:$upgrade) = False --> Int:D) {
    if $upgrade {
        my Num:D $success = install-pkgs($upgrade);
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
        qq[rakubrew build-zef].say;
        my @cmd3 = qw[bash -lc];
        @cmd3.push: 'rakubrew build-zef';
        my Proc $p1 = run @cmd3;
        unless $p1.exitcode == 0 {
            $*ERR.say: "build-zef Failed";
            exit 4;
        }
        #»»»
        my Num:D $success = install-pkgs($upgrade);
       qq[$success% of packages installed successfully].say; 
       my Proc $p1 = shell q[raku -e '"Installed!!! This is $*RAKU - specifically: { ($*RAKU, $*VM, $*DISTRO).map({ $_.gist })}".say;'];
    } else {
        $*ERR.say: "unknown version: $version";
        exit 2;
    }
}

multi sub MAIN('dl', Bool:D :u(:$upgrade) = False --> Int:D) {
    MAIN('download', :$upgrade);
}

multi sub MAIN('add', 'zef', Str:D $pkg, *@additional-pkgs is copy --> Int:D) {
    @additional-pkgs.prepend($pkg);
    "$config/zef-packages".IO.spurt(@additional-pkgs.join("\n"), :append);
}

multi sub MAIN('add', 'apt', Str:D $pkg, *@additional-pkgs is copy --> Int:D) {
    @additional-pkgs.prepend($pkg);
    "$config/apt-packages".IO.spurt(@additional-pkgs.join("\n"), :append);
}
