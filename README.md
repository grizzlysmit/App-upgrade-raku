App::upgrade-raku
=================

Table of Contents
-----------------

  * [NAME](#name)

  * [AUTHOR](#author)

  * [VERSION](#version)

  * [TITLE](#title)

  * [SUBTITLE](#subtitle)

  * [COPYRIGHT](#copyright)

  * [Introduction](#introduction)

    * [upgrade-raku build](#upgrade-raku-build)

    * [upgrade-raku download](#upgrade-raku-download)

    * [upgrade-raku dl](#upgrade-raku-dl)

    * [upgrade-raku add zef](#upgrade-raku-add-zef)

    * [upgrade-raku add apt](#upgrade-raku-add-apt)

    * [upgrade-raku list zef](#upgrade-raku-list-zef)

    * [upgrade-raku list apt](#upgrade-raku-list-apt)

    * [upgrade-raku download](#upgrade-raku-download)

    * [upgrade-raku download](#upgrade-raku-download)

    * [upgrade-raku download](#upgrade-raku-download)

NAME
====

App::upgrade-raku 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

0.1.0

TITLE
=====

App::upgrade-raku

SUBTITLE
========

A **Raku** application for updating/upgrading the local **Raku** install. It also installs and upgrades the packages and any system packages.

COPYRIGHT
=========

LGPL V3.0+ [LICENSE](https://github.com/grizzlysmit/GUI-Editors/blob/main/LICENSE)

[Top of Document](#table-of-contents)

Introduction
============

    A B<Raku> application for updating/upgrading the local B<Raku> install. It also installs and upgrades the packages and any system packages.

**NB: I only support the moar backend for now. And for now I only support the apt command as I use Ubuntu, I will give supporting other package managing software some thought**.

### upgrade-raku build

Upgrade **Raku** using the **rakubrew build moar** method.

```raku
multi sub MAIN('build',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D)
```

[Top of Document](#table-of-contents)

### upgrade-raku download

Upgrade **Raku** using the **rakubrew download** method.

```raku
multi sub MAIN('download',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D)
```

[Top of Document](#table-of-contents)

### upgrade-raku dl

An alias for [upgrade-raku download](#upgrade-raku-download).

```raku
multi sub MAIN('dl',
                Bool:D :u(:upgrade(:$upgrade-the-packages)) = False --> Int:D)
```

[Top of Document](#table-of-contents)

### upgrade-raku add zef

Add **Raku** packages to be installed with **zef**.

```bash
upgrade-raku add zef --help
Usage:
  upgrade-raku add zef <pkg> [<additional-pkgs> ...] [--force-test] [-c|--comment=<Str>] [--<additional-pkgs-with-comments>=...]
```

  * Where

    * **`pkg`** is a **Raku** package to be installed.

    * **`--force-test`** if present the package **pkg** will be installed with the --force-test option to zef.

      * if you want to **--force-test** multiple packages you'll need to add them separately.

    * **`-c|--comment`** if supplied is a comment to add to **pkg**.

    * **`additional-pkgs`** is an array of packages to add without comments or options.

    * **`--additional-pkgs-with-comments=...`** is a hash of packages and comments to add.

      * looks like this **upgrade-raku add zef ... --pkg1=comment1 --pkg2=comment2 ...**.

[Top of Document](#table-of-contents)

### upgrade-raku add apt

Add system packages to be installed with **apt**.

```bash
upgrade-raku add apt --help
Usage:
  upgrade-raku add apt <pkg> [<additional-pkgs> ...] [-c|--comment=<Str>] [--<additional-pkgs-with-comments>=...]
```

  * Where

    * **`pkg`** is a **Raku** package to be installed.

    * **`-c|--comment`** if supplied is a comment to add to **pkg**.

    * **`additional-pkgs`** is an array of packages to add without comments or options.

    * **`--additional-pkgs-with-comments=...`** is a hash of packages and comments to add.

      * looks like this **upgrade-raku add zef ... --pkg1=comment1 --pkg2=comment2 ...**.

[Top of Document](#table-of-contents)

### upgrade-raku list zef

List the **Raku** packages to be installed with **zef**.

```bash
upgrade-raku list zef --help
Usage:
  upgrade-raku list zef [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
```

  * Where

    * **`prefix`** if present only lines that some field start with **prefix** will be listed.

    * **`-c|--color|--colour`** if present display ANSI coloured text.

    * **`-s|--syntax`** if present display text syntax highlighted.

      * **NB: If both --syntax and --colour are supplied then --syntax wins**.

    * **`-l|--page-length[=Int]`** if present sets the page length (defaults to 30 items).

    * **`-p|--pattern=<Str>`** if present only lines that have fields that match **pattern** are listed.

    * **`-e|--ecma-pattern=<Str>`** if present only lines that have fields that match **pattern** are listed.

      * **If both --pattern and --ecma-pattern are supplied then --pattern wins**.

[Top of Document](#table-of-contents)

### upgrade-raku list apt

List the system packages to be installed with **apt**.

```bash
upgrade-raku list apt --help
Usage:
  upgrade-raku list apt [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
```

  * Where

    * **`prefix`** if present only lines that some field start with **prefix** will be listed.

    * **`-c|--color|--colour`** if present display ANSI coloured text.

    * **`-s|--syntax`** if present display text syntax highlighted.

      * **NB: If both --syntax and --colour are supplied then --syntax wins**.

    * **`-l|--page-length[=Int]`** if present sets the page length (defaults to 30 items).

    * **`-p|--pattern=<Str>`** if present only lines that have fields that match **pattern** are listed.

    * **`-e|--ecma-pattern=<Str>`** if present only lines that have fields that match **pattern** are listed.

      * **If both --pattern and --ecma-pattern are supplied then --pattern wins**.

[Top of Document](#table-of-contents)

