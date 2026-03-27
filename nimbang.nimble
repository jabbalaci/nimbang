# Package

version       = "0.4.3"
author        = "Peter Munch-Ellingsen, Laszlo Szathmary"
description   = "This is a fork of PMunch/nimcr with some modifications. This simple program allows you to use the shebang `#!/usr/bin/env nimbang` in your Nim files. It will automatically compile the file to an executable in a cache folder as long as the file doesn\'t already exist and is younger than (i.e. created after the last modification of) the script file. If it is younger, it will simply run the executable saving you from compiling the script each time it is run. The output of the compiler is also ignored if the compilation is succesfull and only the output of the program is used. If the compilation fails, the output will be written to stderr and the return code will match that of the compiler."
license       = "MIT"

# Dependencies

requires "nim >= 0.16.0"


# Examples

skipDirs = @["examples"]

# Binary package

bin = @["nimbang"]
skipExt = @["nim"]
