#!/bin/bash

# Remove unused import from today_schedule_screen.dart
sed -i '' "/import.*schedule_models.dart/d" lib/screens/today_schedule_screen.dart

# Add const constructors where suggested by analyzer
# This is more complex, so let's focus on the most common patterns

# Fix BorderRadius constructors
find lib -name "*.dart" -exec sed -i '' 's/BorderRadius\.only(/const BorderRadius.only(/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/BorderRadius\.circular(/const BorderRadius.circular(/g' {} \;

# Fix Radius constructors  
find lib -name "*.dart" -exec sed -i '' 's/Radius\.circular(/const Radius.circular(/g' {} \;

# Fix EdgeInsets constructors
find lib -name "*.dart" -exec sed -i '' 's/EdgeInsets\.symmetric(/const EdgeInsets.symmetric(/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/EdgeInsets\.all(/const EdgeInsets.all(/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/EdgeInsets\.only(/const EdgeInsets.only(/g' {} \;

# Fix Duration constructors
find lib -name "*.dart" -exec sed -i '' 's/Duration(days:/const Duration(days:/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/Duration(minutes:/const Duration(minutes:/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/Duration(seconds:/const Duration(seconds:/g' {} \;

echo "Fixed remaining issues"
