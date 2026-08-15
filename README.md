# ldd-deploy for MSYS2 UCRT64

`ucrt_ldd_deploy.sh` collects the runtime DLL dependencies of an MSYS2 UCRT64
executable into a deployment directory. This is useful when an application runs
inside MSYS2 but fails on another Windows machine because MinGW/UCRT64 libraries
such as `libstdc++-6.dll`, `libgcc_s_seh-1.dll`, or third-party library DLLs are
not installed there.

The script does not modify the executable or create an installer. It builds the
application's DLL directory so that the executable and its non-system runtime
dependencies can be distributed together.

## Requirements

Run the script from an **MSYS2 UCRT64 shell**. It uses:

- Bash
- MSYS2's `ldd`
- `grep`, `awk`, and `xargs`
- `cygpath` when `ldd` reports a Windows-style path
- `cp`

The executable must already be built, and all of its dependencies must be
installed and discoverable in the current MSYS2 environment.

## Usage

```bash
./ucrt_ldd_deploy.sh -i <executable> [-o <output-directory>] [-u <ucrt-bin-directory>]
```

| Option | Meaning | Default |
| --- | --- | --- |
| `-i`, `--input` | Executable whose DLLs should be collected; required | none |
| `-o`, `--output` | Directory into which the DLLs are copied | current directory (`.`) |
| `-u`, `--ucrt-dir` | MSYS2 UCRT `bin` directory containing runtime DLLs | `$MINGW_PREFIX/bin`, or `/ucrt64/bin` if `MINGW_PREFIX` is unset |

For example:

```bash
./ucrt_ldd_deploy.sh \
  --input ./build/myapp.exe \
  --output ./package
```

To make a directory that can be copied directly to another Windows machine,
first put the executable in it and then collect its DLLs into the same directory:

```bash
mkdir -p ./package
cp ./build/myapp.exe ./package/
./ucrt_ldd_deploy.sh -i ./build/myapp.exe -o ./package
```

The resulting layout is similar to:

```text
package/
|-- myapp.exe
|-- libgcc_s_seh-1.dll
|-- libstdc++-6.dll
|-- libwinpthread-1.dll
`-- <other project dependencies>.dll
```

The exact DLL list depends on the compiler, packages, and libraries used by the
project.

If the UCRT64 installation is in a nonstandard location, override its `bin`
directory explicitly:

```bash
./ucrt_ldd_deploy.sh \
  -i ./build/myapp.exe \
  -o ./package \
  -u /c/tools/msys64/ucrt64/bin
```

## How the script works

1. It parses the input, output, and optional UCRT `bin` directory arguments.
2. It creates the output directory with `mkdir -p`.
3. It runs `ldd` on the input executable. `ldd` asks the MSYS2 loader to report
   the DLLs required by the executable and its linked libraries.
4. It removes dependency lines containing `windows` (case-insensitive). These
   normally point into the Windows system directory and should be supplied by
   Windows, not bundled with the application.
5. For each remaining `name => path` mapping, it extracts the DLL name and the
   resolved source path.
6. It first looks for that name in the selected UCRT64 `bin` directory. If it is
   not there, it uses the path reported by `ldd`. If that path is in Windows
   form, such as `C:\\msys64\\ucrt64\\bin\\example.dll`, `cygpath -u` converts
   it to an MSYS2 path before the file is checked.
7. It copies the DLL to the output directory with `cp -u`. An existing
   destination file is replaced only when the source is newer, and each
   successful copy is printed.

Searching the configured UCRT64 `bin` directory first is important: it selects
the DLL built for the active UCRT64 toolchain when a similarly named DLL is also
available in another MSYS2 environment such as MINGW64 or CLANG64.

## Collecting DLLs for an MSYS2 project

Build and deploy from the same UCRT64 environment so that `ldd`,
`$MINGW_PREFIX`, and the installed DLLs all refer to the same toolchain. A common
workflow is:

```bash
# Run these commands in the MSYS2 UCRT64 shell.
cmake -S . -B build -G Ninja
cmake --build build

mkdir -p package
cp build/myapp.exe package/
./ucrt_ldd_deploy.sh -i build/myapp.exe -o package
```

If the project produces several executables, run the script once for each one
and use the same output directory. Because the script uses `cp -u`, shared DLLs
do not needlessly get recopied:

```bash
./ucrt_ldd_deploy.sh -i build/myapp.exe -o package
./ucrt_ldd_deploy.sh -i build/myhelper.exe -o package
```

Test the package from a normal Windows terminal, preferably on a machine or VM
without MSYS2 on `PATH`. That confirms the application is loading the packaged
DLLs instead of silently finding DLLs in the development environment.

## Limitations and notes

- The script only sees libraries reported by `ldd`. Plugins and DLLs loaded at
  runtime with `LoadLibrary`, `dlopen`, configuration, or user actions may need
  to be copied separately.
- Windows system DLLs are intentionally excluded. Do not redistribute DLLs from
  the Windows system directory as application dependencies.
- A missing dependency cannot be copied. Run `ldd ./path/to/app.exe` directly if
  a required DLL does not appear in the package, then install or locate the
  matching UCRT64 package.
- DLL redistribution may be governed by the dependency's license. Review the
  licenses of third-party libraries before publishing a package.
- Paths containing spaces should be quoted when invoking the script.

The repository also contains alternative Bash and C++ implementations; this
document focuses on `ucrt_ldd_deploy.sh` and the MSYS2 UCRT64 workflow.
