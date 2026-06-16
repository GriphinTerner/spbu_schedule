#!/bin/bash

# Fix double const keywords
find lib -name "*.dart" -exec sed -i '' 's/const const /const /g' {} \;

# Fix specific patterns that might have been broken
find lib -name "*.dart" -exec sed -i '' 's/const EdgeInsets\./EdgeInsets./g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/const TextStyle(/TextStyle(/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/const BorderRadius\./BorderRadius./g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/const Duration(/Duration(/g' {} \;

echo "Fixed const issues"
