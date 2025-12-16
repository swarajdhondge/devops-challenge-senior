#!/usr/bin/env python3
# Generates backend.hcl for remote state. Usage: python setup.py dev
import os
import sys
import subprocess
import argparse
import platform
from pathlib import Path

# Fix Windows console encoding
if platform.system() == "Windows":
    try:
        import io
        if hasattr(sys.stdout, 'buffer') and not isinstance(sys.stdout, io.TextIOWrapper):
            sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
        if hasattr(sys.stderr, 'buffer') and not isinstance(sys.stderr, io.TextIOWrapper):
            sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
    except (AttributeError, ValueError):
        pass


def verify_credentials():
    """Verify AWS credentials are valid."""
    try:
        result = subprocess.run(
            ["aws", "sts", "get-caller-identity"],
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.returncode == 0
    except Exception:
        return False


def get_account_id():
    """Get AWS account ID directly from AWS CLI."""
    try:
        result = subprocess.run(
            ["aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text"],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception:
        pass
    
    return None


def export_credentials_if_needed():
    """Export AWS credentials if not already set."""
    if os.environ.get('AWS_ACCESS_KEY_ID'):
        return True
    
    # Try to import and use export_creds module
    script_dir = Path(__file__).parent
    sys.path.insert(0, str(script_dir))
    
    try:
        # Import functions from export_creds
        import importlib.util
        spec = importlib.util.spec_from_file_location("export_creds", script_dir / "export_creds.py")
        export_creds = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(export_creds)
        
        return export_creds.export_credentials_if_needed()
    except Exception:
        return True  # Assume credentials are already set


def generate_backend_hcl(environment, account_id, project_root):
    """Generate backend.hcl from backend.hcl.template."""
    env_dir = project_root / "terraform" / "envs" / environment
    template_file = env_dir / "backend.hcl.template"
    output_file = env_dir / "backend.hcl"
    
    if not template_file.exists():
        print(f"ERROR: Template file not found: {template_file}")
        return False
    
    try:
        with open(template_file, 'r') as f:
            content = f.read()
        
        content = content.replace("REPLACE_WITH_ACCOUNT_ID", account_id)
        
        with open(output_file, 'w') as f:
            f.write(content)
        
        print(f"Generated: {output_file}")
        return True
    except Exception as e:
        print(f"ERROR: Failed to generate backend.hcl: {e}")
        return False


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Setup Terraform remote state backend"
    )
    parser.add_argument(
        "environment",
        choices=["dev", "stage", "prod"],
        help="Environment name (dev, stage, prod)"
    )
    
    args = parser.parse_args()
    environment = args.environment
    
    # Get project root
    project_root = Path(__file__).parent.parent
    
    print("=" * 60)
    print(f"Terraform Remote State Setup - {environment.upper()}")
    print("=" * 60)
    
    # Export credentials if needed
    print("\n1. Checking AWS credentials...")
    if not export_credentials_if_needed():
        print("ERROR: Failed to export AWS credentials")
        return 1
    
    # Verify credentials
    if not verify_credentials():
        print("ERROR: AWS credentials are invalid or expired")
        print("Please run: aws login  (or aws sso login)")
        return 1
    
    print("   Credentials verified")
    
    # Get account ID
    print("\n2. Getting AWS account ID...")
    account_id = get_account_id()
    
    if not account_id:
        print("ERROR: Could not get AWS account ID")
        print("Please ensure AWS credentials are configured")
        return 1
    
    print(f"   Account ID: {account_id}")
    
    # Generate backend.hcl
    print("\n3. Generating backend configuration...")
    bucket_name = f"prtcl-{environment}-{account_id}-tfstate"
    
    if not generate_backend_hcl(environment, account_id, project_root):
        return 1
    
    print(f"   Bucket: {bucket_name}")
    
    # Success
    print("\n" + "=" * 60)
    print("Setup complete!")
    print("=" * 60)
    print("\nNext steps:")
    print(f"  1. Ensure bootstrap is complete:")
    print(f"     cd terraform/bootstrap && terraform apply")
    print(f"  2. Switch to remote state backend:")
    print(f"     cd terraform/envs/{environment}")
    print(f"     cp backend-remote.tf.example backend.tf")
    print(f"  3. Initialize with remote state:")
    print(f"     terraform init -backend-config=backend.hcl")
    print(f"  4. Deploy infrastructure:")
    print(f"     terraform plan")
    print(f"     terraform apply")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())

