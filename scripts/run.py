#!/usr/bin/env python3
# Terraform wrapper that exports AWS credentials. Usage: python run.py [init|plan|apply|destroy]
import os
import sys
import subprocess


def get_aws_credentials():
    result = subprocess.run(
        ["aws", "configure", "export-credentials", "--format", "env"],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        return None
    
    credentials = {}
    for line in result.stdout.strip().split('\n'):
        line = line.replace('export ', '')
        if '=' in line:
            key, value = line.split('=', 1)
            credentials[key] = value.strip('"').strip("'")
    
    return credentials


def run_terraform(args):
    creds = get_aws_credentials()
    
    if not creds:
        print("ERROR: Could not get AWS credentials.")
        print("Run 'aws login' or 'aws configure' first.")
        return 1
    
    env = os.environ.copy()
    env.update(creds)
    
    terraform_dir = os.path.join(
        os.path.dirname(__file__), 
        '..', 'terraform', 'envs', 'dev'
    )
    
    cmd = ['terraform'] + args
    
    if args and args[0] in ['apply', 'destroy'] and '-auto-approve' not in args:
        cmd.append('-auto-approve')
    
    print(f"Running: {' '.join(cmd)}\n")
    
    result = subprocess.run(cmd, cwd=terraform_dir, env=env)
    return result.returncode


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/run.py <command> [args]")
        print("Commands: init, plan, apply, destroy")
        sys.exit(1)
    
    sys.exit(run_terraform(sys.argv[1:]))
