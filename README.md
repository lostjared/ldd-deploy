# ldd-deploy for MSYS2 Mingw64

![image](https://github.com/user-attachments/assets/39176b37-1a6e-4bf2-af1c-e3aeaffdb4bf)

`ldd-deploy` is a simple Bash script designed to help package dynamically linked libraries (DLLs) and shared object dependencies required by an executable. The script uses `ldd` to identify all linked libraries and then copies each one to a specified output directory, making it easier to deploy or distribute applications with all necessary dependencies.

## Features
- Identifies DLLs and shared libraries required by an executable.
- Copies dependencies to a user-specified output directory.
- Filters out Windows-specific dependencies (useful for cross-platform compatibility).

## Usage
```bash
./ldd-deploy.sh -i <path/to/executable> [-o <path/to/output_directory>]
```

### Arguments
- `-i` or `--input`: Path to the input executable. **(Required)**
- `-o` or `--output`: Path to the directory where dependencies will be copied. *(Optional; defaults to the current directory)*

### Example
```bash
./ldd-deploy.sh -i ./myapp -o ./deploy-libs
```

In this example, all dependencies required by `myapp` will be copied into the `deploy-libs` directory.

## Dependencies
- **Bash**: This script requires a Bash shell to run.
- **ldd**: The `ldd` command is used to identify shared libraries.

## Notes
- Ensure you have the necessary permissions to read the executable's dependencies and write to the output directory.
- This script is especially useful when packaging applications for distribution or deployment on systems that may not have all required libraries pre-installed.
- Contains implementations in Rust, C++, and Bash.
