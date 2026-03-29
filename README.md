# This is a fork of PMunch/nimcr

This repo is a fork of [PMunch/nimcr](https://github.com/PMunch/nimcr), containing my own modifications. The original nimcr repo seems to be abandoned, so that's
why I decided to make a fork. Thanks to PMunch for
the original nimcr project!

# Running Nim programs as scripts with shebang

Shebangs are a tiny comment at the beginning of a file that tells the operating system what program can be used to run the contents of that file. It is typically seen in bash scripts starting with `#!/usr/bin/env bash` or in Python scripts as `#!/usr/bin/env python3`. Nim however is not an interpreted language, this means that having a program that "runs" Nim files would actually mean compile and run. This was outlined in issue [#66](https://github.com/nim-lang/Nim/issues/66) for Nim but was closed after Araq showed how it could be achieved with flags to the compiler. However, this solution is a bit lacking. Nim, being a compiled language, offers a speed benefit over many other languages. So writing scripts in Nim makes sense if you want to have a lot of scripts running on your machine. But compiling the script every time you want to run it makes no sense at all as it completely negates the speed benefit.

## The solution

This project aims to be a tiny little program to solve the problem of using Nim for scripting. It takes the file passed to it through the shebang and establishes a nimcache directory, then it compiles the script to a hidden file in the nimcache directory. On subsequent runs it checks if the script file is newer than the executable (i.e. been edited after the last compilation) in which case it will compile it again, reusing the same nimcache directory if it exists. This means that the very first run of a script will do the entire compilation process, subsequent runs without changes will only run the executable, and runs where the source is newer than the executable will do the compilation process but use the old nimcache. The sum of this is a great speed-benefit without losing any of the flexibility often associated with scripts in general. Simply mark the script as executable and run it!

## A note on output

To make the output of a script as uniform as possible in order for it to easily pipe to other processes, this program will hide the compilation output. As long as the Nim compiler completes without errors only the output of the script will be written to the terminal. In the case of a compiler failure, the entire Nim compilation output along with the executed command will be written to stderr. This program will then exit with the error code of the compiler.

If nimbang needs to compile the program, then a debug line is printed to stderr showing how the nim compiler is called. If compilation is not necessary, then this debug
line will be hidden.

## How to compile/run your script using nimbang

Make the first line in your nim script read as follows: `#!/usr/bin/env nimbang` and optionally make the script executable.

## Passing options

Command line options can be specified for the nim compiler and for the actual script.

### Options for the script

Options for the script are passed on the command line as you would do with any other program:

``` bash
# Example 1: no command-line switches or arguments are passed to the script
$ ./script-using-nimbang
# Example 2: command-line switches and arguments are passed to the script
$ ./script-using-nimbang -option1 -option2 positional_arg1 positional_arg2
```

The script will be able to access command-line switches and arguments as any other nim program.

### Options for the nim compiler

Options for the nim compiler can be specified by adding a specially formatted comment as second line of the script starting with `#nimbang-args` followed by a space then followed by command-line switches and arguments to the nim compiler.

``` bash
#!/usr/bin/env nimbang
#nimbang-args c -d:release

... rest of the script
```

If `#nimbang-args` is not present as second line of the script, then it defaults to `c`. That is, by default,
the script is compiled in debug mode. This way,
development can be faster. Once the script is stable,
you can switch to a release compilation.

### Options automatically appended by nimbang

In order for nimbang to work and be convenient, some options are added to the execution and will throw an error or give unwanted behaviour when combined with conflicting options. These options are:
```
--colors:on --nimcache:<cache directory> --out:<hidden file in cache directory>
```

# How nimbang differs from nimcr

These are my (Laszlo's) own notes.

Let's see an example:

```
$ cat hello.nim
#!/usr/bin/env nimbang

echo "hello nimbang"

$ chmod u+x hello.nim

$ ./hello.nim
# nim c --colors:on --nimcache:/home/jabba/.cache/nimbang/nimcache-99B454C0298D5236 --out:"/home/jabba/.cache/nimbang/nimcache-99B454C0298D5236/.hello" "/tmp/send/hello.nim"
hello nimbang

$ ./hello.nim
hello nimbang
```

By default, nimbang compiles in debug mode. This is faster
than compiling in release mode, thus during the development it allows a faster iteration.

Under Linux, nimcr created the nimcache directory in `/tmp`. However, when you reboot a Linux machine, the content of `/tmp` is deleted. If you use lots of scripts,
after a reboot you must wait a lot of time until they
re-compile upon their first usage.

nimbang creates the nimcache directory in your HOME directory, in `~/.cache/nimbang/...`. The compiled
executables are also stored here, so the folder that
contains your script won't be littered with a hidden EXE file. And, the EXEs will survive a reboot. After
a reboot the scripts don't have to be recompiled.

If your script is finished, you can switch to release mode. Just add an extra line after the shebang line:

```
$ cat hello.nim
#!/usr/bin/env nimbang
#nimbang-args c -d:release

echo "hello nimbang"

$ ./hello.nim
# nim c -d:release --colors:on --nimcache:/home/jabba/.cache/nimbang/nimcache-99B454C0298D5236 --out:"/home/jabba/.cache/nimbang/nimcache-99B454C0298D5236/.hello" "/tmp/send/hello.nim"
hello nimbang

$ ./hello.nim
hello nimbang
```

I've decided to show a debug line when the script is
compiled. This way you can check how exactly the nim compiler is invoked. As you can see, `-d:release` is
applied this time.

The D programming language has a tool called `rdmd`
that allows running a D program as a script. I took
some ideas from rdmd and applied them in nimbang. rdmd also stores the cache directory and the compiled EXE in a
dedicated folder in the HOME directory, separated from the
script's folder.

## Why to use nimbang when we have `nim r` ?

The nim compiler can do something similar. The command `nim r prg.nim` does the following: it compiles a program if necessary and then it launches the binary. However, if the binary is in the cache and the source hasn't changed, it simply launches the binary.

However, according to my experience, `nim r` launches
an already-compiled EXE quite slowly.

Example:

```
$ time nim r --hints:off --warnings:off hello.nim
308 msec (compile time + launch)

$ time nim r --hints:off --warnings:off hello.nim
102 msec (nothing changed => no compilation, just launch)
```

Let's compare it with nimbang:

```
$ ./hello.nim
258 msec (compile time + launch)

$ ./hello.nim
8 msec (nothing changed => no compilation, just launch)
```

I had a question about it in the forum too ([link](https://forum.nim-lang.org/t/13692)).

## How to switch off the debug info

By default, `nimbang` shows some debug info when the source
code is compiled. In version 0.4.4, I added the possibility to switch it off. For this, you need to
add a third line at the top of the source code:

```
$ cat hello.nim
#!/usr/bin/env nimbang
#off:nimbang-args c -d:release
#nimbang-settings hideDebugInfo

echo "hello nimbang"

$ ./hello.nim
hello nimbang
```

This way, compilation happens silently, i.e. there is no debug info.

Thus, I suggest using the following template:

```
$ cat hello.nim
#!/usr/bin/env nimbang
#off:nimbang-args c -d:release
#off:nimbang-settings hideDebugInfo

echo "hello nimbang"
```

Then, if you want to get rid of the debug info,
just remove the substring "off:" from the third line.

The third line with "nimbang-settings" is reserved
for settings that modify the behaviour of nimbang.
Currently, only the "hideDebugInfo" setting is supported.
Nimbang settings are case-insensitive, thus you
could also write "hidedebuginfo".
