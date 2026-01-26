import argparse
import os
import yaml
import zipfile
import sys

def validate_skill(skill_path):
    print(f"Validating skill at {skill_path}...")
    
    # 1. Check SKILL.md exists
    skill_md_path = os.path.join(skill_path, "SKILL.md")
    if not os.path.exists(skill_md_path):
        print("Error: SKILL.md not found.", file=sys.stderr)
        return False

    # 2. Validate Frontmatter
    try:
        with open(skill_md_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # Extract frontmatter between first two ---
            parts = content.split('---')
            if len(parts) < 3:
                print("Error: Invalid SKILL.md format. Missing YAML frontmatter.", file=sys.stderr)
                return False
            
            frontmatter = yaml.safe_load(parts[1])
            
            if not frontmatter.get('name'):
                print("Error: Missing 'name' in frontmatter.", file=sys.stderr)
                return False
            if not frontmatter.get('description'):
                print("Error: Missing 'description' in frontmatter.", file=sys.stderr)
                return False
            
            if len(frontmatter['name']) > 64:
                print("Error: 'name' exceeds 64 characters.", file=sys.stderr)
                return False
            if len(frontmatter['description']) > 1024:
                print("Error: 'description' exceeds 1024 characters.", file=sys.stderr)
                return False
                
    except Exception as e:
        print(f"Error parsing YAML: {e}", file=sys.stderr)
        return False

    print("Validation passed.")
    return True

def package_skill(skill_path, output_dir):
    skill_name = os.path.basename(os.path.normpath(skill_path))
    output_filename = os.path.join(output_dir, f"{skill_name}.skill")
    
    print(f"Packaging {skill_name} to {output_filename}...")
    
    try:
        with zipfile.ZipFile(output_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(skill_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, skill_path)
                    zipf.write(file_path, arcname)
        print(f"Successfully packaged: {output_filename}")
    except Exception as e:
        print(f"Error packaging skill: {e}", file=sys.stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Package an Aurora Skill")
    parser.add_argument("skill_path", help="Path to the skill directory")
    parser.add_argument("output_dir", nargs='?', default=".", help="Output directory (default: current dir)")
    
    args = parser.parse_args()
    
    if validate_skill(args.skill_path):
        package_skill(args.skill_path, args.output_dir)
    else:
        sys.exit(1)
