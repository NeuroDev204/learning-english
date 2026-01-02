"""
Script tự động convert toàn bộ Flutter app sang dark mode support
Chuyển đổi tất cả hardcoded colors sang Theme.of(context)
"""
import os
import re

def convert_to_theme_aware(content):
    """Convert hardcoded colors to theme-aware colors"""
    
    # Skip if already converted
    if 'Theme.of(context).colorScheme' in content and content.count('Theme.of(context).colorScheme') > 5:
        return content
    
    replacements = [
        # === BACKGROUNDS ===
        (r'backgroundColor:\s*Colors\.white(?!\w)', 
         'backgroundColor: Theme.of(context).colorScheme.surface'),
        (r'backgroundColor:\s*AppTheme\.paleBlue', 
         'backgroundColor: Theme.of(context).colorScheme.background'),
        
        # === SCAFFOLD ===
        (r'Scaffold\s*\(\s*backgroundColor:\s*AppTheme\.paleBlue',
         'Scaffold(\n      backgroundColor: Theme.of(context).colorScheme.background'),
        
        # === SURFACE/CONTAINER COLORS ===
        (r'(?<!\.with)color:\s*Colors\.white,',
         'color: Theme.of(context).colorScheme.surface,'),
        
        # === TEXT COLORS ===
        (r'color:\s*AppTheme\.textDark', 
         'color: Theme.of(context).colorScheme.onSurface'),
        (r'color:\s*AppTheme\.textGrey', 
         'color: Theme.of(context).textTheme.bodyMedium?.color'),
        (r'(?<!\.with)color:\s*Colors\.black,', 
         'color: Theme.of(context).colorScheme.onSurface,'),
        
        # === TEXT STYLES ===
        (r'TextStyle\(\s*color:\s*AppTheme\.textDark\s*\)',
         'TextStyle(color: Theme.of(context).colorScheme.onSurface)'),
        (r'TextStyle\(\s*color:\s*AppTheme\.textGrey\s*\)',
         'TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)'),
        
        # === APPBAR ===
        (r'AppBar\s*\(\s*backgroundColor:\s*Colors\.white,',
         'AppBar(\n        backgroundColor: Theme.of(context).colorScheme.surface,'),
        
        # === CARD ===
        (r'Card\s*\(\s*color:\s*Colors\.white,',
         'Card(\n          color: Theme.of(context).colorScheme.surface,'),
        
        # === CONTAINER WITH COLOR WHITE ===
        (r'Container\s*\(\s*color:\s*Colors\.white,',
         'Container(\n          color: Theme.of(context).colorScheme.surface,'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    return content

def should_skip_file(filepath):
    """Check if file should be skipped"""
    skip_patterns = [
        'firebase_options.dart',
        '/models/',
        '/services/',
        '/repositories/',
        '/datasources/',
        '/entities/',
        '/domain/',
        '_test.dart',
        'test/',
    ]
    
    for pattern in skip_patterns:
        if pattern in filepath:
            return True
    return False

def process_file(filepath):
    """Process a single Dart file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            original_content = f.read()
        
        # Skip if file should not be converted
        if should_skip_file(filepath):
            return False, "Skipped (not a UI file)"
        
        # Convert content
        new_content = convert_to_theme_aware(original_content)
        
        # Check if anything changed
        if new_content == original_content:
            return False, "No changes needed"
        
        # Write back
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        # Count changes
        changes = len([1 for a, b in zip(original_content.split('\n'), new_content.split('\n')) if a != b])
        
        return True, f"{changes} lines changed"
        
    except Exception as e:
        return False, f"Error: {str(e)}"

def main():
    """Main conversion process"""
    print("=" * 70)
    print("🎨 DARK MODE CONVERSION - FULL APP")
    print("=" * 70)
    print()
    
    # Statistics
    total_files = 0
    converted_files = 0
    skipped_files = 0
    error_files = 0
    
    # Target directories (UI files only)
    target_dirs = [
        'lib/screens',
        'lib/features',
    ]
    
    converted_list = []
    
    for target_dir in target_dirs:
        if not os.path.exists(target_dir):
            continue
            
        print(f"\n📂 Processing {target_dir}/...")
        print("-" * 70)
        
        for root, dirs, files in os.walk(target_dir):
            # Skip non-UI directories
            if any(skip in root for skip in ['models', 'services', 'repositories', 'domain', 'data']):
                continue
                
            for file in files:
                if not file.endswith('.dart'):
                    continue
                
                total_files += 1
                filepath = os.path.join(root, file)
                relative_path = filepath.replace('lib\\', '').replace('lib/', '')
                
                success, message = process_file(filepath)
                
                if success:
                    converted_files += 1
                    converted_list.append(relative_path)
                    print(f"✅ {relative_path:<50} {message}")
                elif "Error" in message:
                    error_files += 1
                    print(f"❌ {relative_path:<50} {message}")
                else:
                    skipped_files += 1
    
    # Summary
    print()
    print("=" * 70)
    print("📊 CONVERSION SUMMARY")
    print("=" * 70)
    print(f"Total UI files scanned:    {total_files}")
    print(f"✅ Successfully converted: {converted_files}")
    print(f"⏭️  Skipped:                {skipped_files}")
    print(f"❌ Errors:                 {error_files}")
    print("=" * 70)
    
    if converted_list:
        print()
        print("📝 Converted files:")
        for f in converted_list:
            print(f"   - {f}")
    
    print()
    print("🎉 Next Steps:")
    print("   1. Test the app with: flutter run")
    print("   2. Toggle dark mode in Settings")
    print("   3. Check all screens for any visual issues")
    print("   4. Fix any remaining hardcoded colors manually")
    print()

if __name__ == '__main__':
    main()
