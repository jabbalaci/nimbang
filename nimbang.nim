import hashes
import os
import osproc
import strutils

const
  nimArgsPrefix = "#nimbang-args "
  nimbangSettingsPrefix = "#nimbang-settings "

# Inspect command line parameters
let args =  commandLineParams()

if args.len == 0:
  stderr.write "Usage on the command line: nimbang filename [arguments to program]\n"
  stderr.write "Usage in a script:\n"
  stderr.write "    [1] add `#!/usr/bin/env nimbang` to your script as first line\n"
  stderr.write "    [2] (optional) add `#nimbang-args [arguments for nim compiler]` to your script as second line\n"
  stderr.write "    [3] (optional) add `#nimbang-settings [settings for nimbang]` to your script as third line\n"
  quit(-1)

let
  filename = args[0].expandFilename
  baseCacheDir =
    when defined(windows):
      getTempDir() / "nimbang"
    else:
      getHomeDir() / ".cache" / "nimbang"
  nimCacheDir = baseCacheDir / ("nimcache-" & filename.hash.toHex)

if not dirExists(baseCacheDir):
  try:
    createDir(baseCacheDir)
  except OSError:
    echo "Failed to create directory: ", getCurrentExceptionMsg()
    quit(1)

# Split the file path and make a new one which is a hidden file on Linux, Windows file hiding comes later
let
  splitName = filename.splitfile
  ext =
    when defined(windows):
      ".exe"
    else:
      ""
  exeName = nimCacheDir / ("." & splitName.name & ext)

# Compilation of script if target doesn't exist
var
  buildStatus = 0
  output = ""
  command = ""

if not exeName.fileExists or filename.fileNewer(exeName):
  var
    nimArgs = "c"  # default: debug build
    nimbangSettings: seq[string] = @[]  # supported settings: hidedebuginfo
    showDebugInfo = true
  # Get extra arguments for nim compiler from the second line (it must start with #nimbang-args [args] )
  block:
    for line in filename.lines:
      if line.len == 0 or line[0] != '#':
        break
      if line.startsWith(nimArgsPrefix):
        nimArgs = line[nimArgsPrefix.len .. ^1]
      if line.startsWith(nimbangSettingsPrefix):
        nimbangSettings = line[nimbangSettingsPrefix.len .. ^1].strip.toLower.split
        if "hidedebuginfo" in nimbangSettings: showDebugInfo = false
        break

  exeName.removeFile
  command = "nim " & nimArgs & " --colors:on --nimcache:" &
    nimCacheDir &
    " --out:\"" & exeName & "\" \"" & filename & "\""  # dxbb's patch
  if showDebugInfo:
    stderr.write "# " & command & "\n"
    stderr.write "# ---\n"

  (output, buildStatus) = execCmdEx(command)
  # Windows file hiding (hopefully, not tested)
  when defined(windows):
    discard execShellCmd("attrib +H " & exeName)

# Run the target, or show an error
if buildStatus == 0:
  let p = startProcess(exeName,  args=args[args.low+1 .. ^1],
                       options={poStdErrToStdOut, poParentStreams, poUsePath})
  let res = p.waitForExit()
  p.close()
  quit(res)
else:
  stderr.write "(nimbang) Error on build running command: " & command & "\n"
  stderr.write output
  quit(buildStatus)
