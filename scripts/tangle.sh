#!/bin/bash
# scripts/tangle.sh
# Tangle files from README.org with proper Makefile formatting

set -euo pipefail

echo "Creating elisp config..."
cat > /tmp/tangle-tokenviz.el << 'EOF'
(require 'org)
(require 'ob-tangle)
(setq org-src-preserve-indentation t)
(setq org-babel-tangle-use-relative-file-links t)
(find-file "README.org")
(org-babel-tangle)
(kill-emacs)
EOF

echo "Running emacs tangle..."
emacs --batch -Q \
    --load /tmp/tangle-tokenviz.el \
    2>/dev/null

echo "Checking Makefile indentation..."
if [ -f Makefile ]; then
    echo "Before fixing tabs:"
    head -n 30 Makefile | cat -A  # Show special characters

    echo "Fixing Makefile tabs..."
    # More aggressive tab fixing
    awk '
    /^[[:space:]]/ { sub(/^[[:space:]]+/, "\t") }
    { print }
    ' Makefile > Makefile.tmp && mv Makefile.tmp Makefile

    echo "After fixing tabs:"
    head -n 30 Makefile | cat -A  # Show special characters
fi

echo "Tangled files from README.org with proper formatting"
