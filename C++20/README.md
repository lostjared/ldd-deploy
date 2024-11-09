# mingw-deploy

This program, named mingw-deploy, is designed to automate the process of copying required DLL files for a MinGW-compiled executable to a specified output directory. This can be especially useful when deploying applications on Windows, as it ensures all necessary dependencies are bundled for distribution.

Here's a breakdown of what the program does and how to use it:

Purpose of the Program
mingw-deploy helps identify and copy all the DLLs that an executable depends on by running a system command (ldd) to find its dependencies. It parses the output of ldd, extracts the paths of the required DLL files, and copies each one to the designated output directory.

Command-Line Arguments
The program uses the following command-line arguments to determine the input executable file and output directory for DLL copying:

-i or --input: Specifies the path to the input executable file whose dependencies you want to copy. This argument is required; if it’s not provided, the program will output an error and display help information.

-o or --output: Specifies the output directory where DLL files should be copied. If omitted, the default output directory is the current directory (.).

-h: Displays help information detailing available options.

Explanation of the Program Flow
Argument Parsing:

The program uses the argz library to parse command-line arguments.
It sets up options for the input file (-i or --input), output directory (-o or --output), and help (-h).
If the -h flag is provided, it outputs the help message and exits.
If the input executable path is not specified, it throws an error, shows help, and exits.
Dependency Identification:

The program constructs a command (ldd) to list the dependencies of the provided executable file.
It uses popen (or _popen on Windows) to execute this command and capture the output, excluding any lines related to windows libraries.
Parsing Dependencies:

Each line of the command output is read, and the function extractFilename is used to extract the file path for each DLL.
extractFilename parses each line to find the path between => and (.
Copying DLL Files:

For each extracted DLL filename, the program constructs a cp (copy) command to copy the DLL to the specified output directory.
It then executes this command using system, effectively copying each DLL required by the executable.
Error Handling:

If any errors occur during command execution or file copying, the program outputs a relevant message.
Example Usage
To use mingw-deploy:

```bash
mingw-deploy -i path/to/your.exe -o /desired/output/directory
```
-i: Specifies the path to the compiled executable file (your.exe) for which you want to gather DLLs.
-o: Specifies the directory where all required DLLs should be copied (/desired/output/directory).

# Summary
In essence, mingw-deploy automates the process of gathering dependencies for a MinGW-compiled executable, simplifying deployment by copying all necessary DLLs to a single directory for easy distribution.
