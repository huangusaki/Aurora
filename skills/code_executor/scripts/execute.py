import argparse
import sys
import io
import contextlib

def execute_code(code):
    # Capture stdout and stderr
    stdout_buffer = io.StringIO()
    stderr_buffer = io.StringIO()

    with contextlib.redirect_stdout(stdout_buffer), contextlib.redirect_stderr(stderr_buffer):
        try:
            # Create a shared execution environment
            exec_globals = {}
            exec(code, exec_globals)
        except Exception as e:
            # Print exception to stderr
            print(f"Error: {e}", file=sys.stderr)

    # Get output
    stdout_val = stdout_buffer.getvalue()
    stderr_val = stderr_buffer.getvalue()

    if stdout_val:
        print(stdout_val)
    
    if stderr_val:
        print(stderr_val, file=sys.stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Execute Python code")
    parser.add_argument("--code", help="Python code to execute")
    parser.add_argument("file", nargs="?", help="Python file to execute")
    
    args = parser.parse_args()
    
    code_to_run = ""
    
    if args.code:
        code_to_run = args.code
    elif args.file:
        try:
            with open(args.file, 'r', encoding='utf-8') as f:
                code_to_run = f.read()
        except FileNotFoundError:
            print(f"File not found: {args.file}", file=sys.stderr)
            sys.exit(1)
    else:
        # Read from stdin
        if not sys.stdin.isatty():
            code_to_run = sys.stdin.read()
    
    if not code_to_run.strip():
        # interactive mode or empty
        print("Usage: python execute.py --code 'print(1)' OR python execute.py script.py", file=sys.stderr)
        sys.exit(1)

    execute_code(code_to_run)
