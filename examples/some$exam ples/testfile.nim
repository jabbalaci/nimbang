#!/usr/bin/env nimbang
echo "Hello World!"

import os
import osproc

var args = commandLineParams()
if args.len == 0:
  args = @["examples/some$exam ples/", "examples/some$exam ples/testfile.nim"]
let command = quoteShellCommand(@["file"] & args)
let (output, exitCode) = execCmdEx(command)
echo output
