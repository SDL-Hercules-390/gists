<h1 align=center>gists</h1>

<h2 align=center>Helpful scripts and code snippets</h2>

&nbsp;
This is a collection of helpful scripts and code snippets associated with the [SoftDevLabs](http://www.softdevlabs.com) version of the [Hercules 4.x (Hyperion) System/370, ESA/390, and z/Architecture Emulator](https://github.com/SDL-Hercules-390/hyperion).

<h2 align=center>extpkgs</h2>

The one and only script at this time is the _**extpkgs**_ script which automates the cloning, updating and building of the emulator's External Package static libraries that are required in order to build the emulator.

The _manual_ method for building the External Packages is documented in both the [README.EXTPKG](https://github.com/SDL-Hercules-390/hyperion/blob/master/readme/README.EXTPKG.md) document that comes with the emulator itself, as well as the individual [README](https://github.com/SDL-Hercules-390/crypto/blob/master/README.md) documents that come delivered with each external package's repository.

<h3 align=center>The extpkgs script is designed to make things even easier</h3>

Simply create a directory somewhere (e.g. `extpkgs`), switch to that directory, and then enter the `extpkgs` command (or on Linux, `extpkgs.sh`) to have each external package cloned or updated and built within that same directory:


````
cmdline = extpkgs.sh clone c d s t

action         =  CLONE
crypto_repo    = "./repos/crypto-0"
decnumber_repo = "./repos/decNumber-0"
softfloat_repo = "./repos/SoftFloat-0"
telnet_repo    = "./repos/telnet-0"
install_dir    = "/home/fish/hercules/extpkgs/."
cpu            = "x86"
Initialized empty Git repository in /home/fish/hercules/extpkgs/repos/crypto-0/.git/
remote: Enumerating objects: 198, done.
remote: Total 198 (delta 0), reused 0 (delta 0), pack-reused 198
Receiving objects: 100% (198/198), 151.07 KiB, done.
Resolving deltas: 100% (115/115), done.
Initialized empty Git repository in /home/fish/hercules/extpkgs/repos/decNumber-0/.git/
remote: Enumerating objects: 479, done.
remote: Total 479 (delta 0), reused 0 (delta 0), pack-reused 479
Receiving objects: 100% (479/479), 1.07 MiB, done.
Resolving deltas: 100% (301/301), done.
Initialized empty Git repository in /home/fish/hercules/extpkgs/repos/SoftFloat-0/.git/
remote: Enumerating objects: 1612, done.
remote: Total 1612 (delta 0), reused 0 (delta 0), pack-reused 1612
Receiving objects: 100% (1612/1612), 703.37 KiB, done.
Resolving deltas: 100% (1388/1388), done.
Initialized empty Git repository in /home/fish/hercules/extpkgs/repos/telnet-0/.git/
remote: Enumerating objects: 235, done.
remote: Total 235 (delta 0), reused 0 (delta 0), pack-reused 235
Receiving objects: 100% (235/235), 131.29 KiB, done.
Resolving deltas: 100% (143/143), done.

All External Packages SUCCESSFULLY cloned!  :))

crypto ...
  64-bit Debug ...
  SUCCESS!
  64-bit Release ...
  SUCCESS!
  32-bit Debug ...
  SUCCESS!
  32-bit Release ...
  SUCCESS!
decNumber ...
  64-bit Debug ...
  SUCCESS!
  64-bit Release ...
  SUCCESS!
  32-bit Debug ...
  SUCCESS!
  32-bit Release ...
  SUCCESS!
SoftFloat ...
  64-bit Debug ...
  SUCCESS!
  64-bit Release ...
  SUCCESS!
  32-bit Debug ...
  SUCCESS!
  32-bit Release ...
  SUCCESS!
telnet ...
  64-bit Debug ...
  SUCCESS!
  64-bit Release ...
  SUCCESS!
  32-bit Debug ...
  SUCCESS!
  32-bit Release ...
  SUCCESS!

All External Packages SUCCESSFULLY built!  :))
````

&nbsp;

Then, to build Hercules, all you need to do is either:

1. Point your `LIB` and `INCLUDE` environment variables to the `lib` and `include` subdirectories of your `extpkgs` directory (for Linux it would be the `LIBRARY_PATH` and `CPATH` environment variables), or

2. Specify the `--enable-extpkgs=<dir>` option on your `./configure` command. (For Windows it would be the `-extpkg "dir"` option on your `makefile.bat` command)

&nbsp;
What follows below is the `--help` information that is displayed for the Windows `ExtPkgs.cmd` batch file, but the help information for the Linux `extpkgs.sh` bash script is essentially identical:

&nbsp;

````
cmdline = ExtPkgs.cmd --help


    NAME

        ExtPkgs.cmd  --  Build and install Hercules External Package(s)

    SYNOPSIS

        ExtPkgs.cmd      { [CLONE | UPDATE]   [C]  [D]  [S]  [T] }

    DESCRIPTION

        ExtPkgs performs a full build and install of each specified
        Hercules External Package.  It is used to automate the
        cloning, updating and/or building and installing of all
        selected External Packages with one simple command (rather
        than having to perform each of the builds individually)
        and ensures that each of them are built the same way.

    ARGUMENTS

        CLONE      Indicates the specified package repositories do
                   not exist yet and need to be git cloned before
                   building.  This option, if specified, must come
                   before the C|D|S|T option(s).

        UPDATE     Indicates the specified package repositories
                   should be git updated before building.  This
                   option, if specified, must come before the
                   C|D|S|T option(s).

        C|D|S|T    Corresponds to which external package(s) you
                   wish to clone, update and/or build and install
                   (crypto, decNumber, SoftFloat and/or telnet,
                   or all four, or any combination thereof)

    EXIT STATUS

        0   Success    All specified external packages successfully
                       cloned, updated and/or built and installed.

        1   Failure    The clone, update, build or install of one
                       or more specified packages has failed.

    NOTES

       The required "ExtPkgs.cmd.ini" control file identifies the
       fixed parameters needed by the script, and is expected to
       exist somewhere in your search PATH.

       The control file must contain statements that identify the
       directory of each external package's repository, as well
       as the common installation directory where each package
       will be installed into.

       The format of the statements is very simple:

            cpu             =  aarch64|arm|i686|mips|ppc|s390x|sparc|xscale|x86|unknown
            install_dir     =  <dir>
            crypto_repo     =  <dir>
            decnumber_repo  =  <dir>
            softfloat_repo  =  <dir>
            telnet_repo     =  <dir>

       The specified directory may be either relative or absolute.
       Blank lines and lines beginning with "*", "#" or ";" are
       ignored.

    AUTHOR

        "Fish" (David B. Trout)

    VERSION

        1.3  (April 2, 2019)
````

&nbsp;

If you have any questions or problems with this script, create a [GitHub Issue](https://github.com/SDL-Hercules-390/gists/issues) and we will look into your problem right away.

Thank you!

The SDL Hercules 4.x Hyperion development team
