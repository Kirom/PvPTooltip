#!/bin/bash

# Script to validate GitHub Actions workflows
set -e

echo "🔍 Validating GitHub Actions workflows..."

# Check if workflows directory exists
if [ ! -d ".github/workflows" ]; then
    echo "❌ .github/workflows directory not found"
    exit 1
fi

# Validate each workflow file
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        echo "Validating $workflow..."
        
        # Basic YAML syntax check using Python
        if command -v python3 &> /dev/null; then
            python3 -c "
import yaml
import sys
try:
    with open('$workflow', 'r') as f:
        yaml.safe_load(f)
    print('✅ $workflow syntax is valid')
except Exception as e:
    print('❌ $workflow has YAML syntax error:', e)
    sys.exit(1)
"
        else
            echo "⚠️  Python3 not available, skipping YAML validation for $workflow"
        fi
        
        # Check for required fields
        if ! grep -q "^name:" "$workflow"; then
            echo "❌ $workflow missing 'name' field"
            exit 1
        fi
        
        if ! grep -q "^on:" "$workflow"; then
            echo "❌ $workflow missing 'on' field"
            exit 1
        fi
        
        if ! grep -q "^jobs:" "$workflow"; then
            echo "❌ $workflow missing 'jobs' field"
            exit 1
        fi
        
        echo "✅ $workflow structure validation passed"
    fi
done

echo ""
echo "🎉 All workflow validations passed!"
echo ""
echo "Available workflows:"
ls -la .github/workflows/*.yml | awk '{print "  - " $9}' | sed 's|.github/workflows/||g'