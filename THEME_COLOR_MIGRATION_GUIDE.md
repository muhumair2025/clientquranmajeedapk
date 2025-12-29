# Theme Color Migration Guide - Quick Fix

## 🎯 Goal
Replace all hardcoded `AppTheme.primaryGreen` colors with theme-aware colors so theme presets work automatically.

## ✅ Solution: Use Theme Extensions

We created `lib/utils/theme_extensions.dart` with helper methods. Just import and use!

## 📝 Find & Replace Patterns

Use your IDE's **Find & Replace in Files** feature (Ctrl+Shift+H in most IDEs):

### Step 1: Add Import (if not present)
Add this import at the top of each file:
```dart
import '../utils/theme_extensions.dart';
```

### Step 2: Replace Hardcoded Colors

| **Find** | **Replace With** | **Description** |
|----------|-----------------|-----------------|
| `AppTheme.primaryGreen` | `context.primaryColor` | Primary theme color |
| `AppTheme.darkGreen` | `context.primaryColor.darker(0.2)` | Darker variant |
| `AppTheme.lightGreen` | `context.primaryColor.lighter(0.2)` | Lighter variant |
| `AppTheme.accentGreen` | `context.accentColor` | Accent/secondary color |
| `AppTheme.primaryGold` | `context.accentColor` | Gold accent → use accent |
| `AppTheme.lightBackground` | `context.backgroundColor` | Background color |
| `AppTheme.lightSurface` | `context.surfaceColor` | Surface color |
| `AppTheme.lightCardBackground` | `context.cardColor` | Card background |
| `AppTheme.darkBackground` | `context.backgroundColor` | Dark background |
| `AppTheme.darkSurface` | `context.surfaceColor` | Dark surface |
| `AppTheme.darkCardBackground` | `context.cardColor` | Dark card background |
| `AppTheme.lightTextPrimary` | `context.textColor` | Primary text |
| `AppTheme.lightTextSecondary` | `context.secondaryTextColor` | Secondary text |
| `AppTheme.darkTextPrimary` | `context.textColor` | Dark text primary |
| `AppTheme.darkTextSecondary` | `context.secondaryTextColor` | Dark text secondary |
| `Color(0xFF006653)` | `context.primaryColor` | Hardcoded green hex |
| `Theme.of(context).colorScheme.primary` | `context.primaryColor` | Simplify existing |

## 🚀 Quick Steps

### Option 1: Manual Find & Replace (Recommended)
1. Open VS Code / Android Studio
2. Press `Ctrl+Shift+H` (Windows) or `Cmd+Shift+H` (Mac)
3. Enable "Use Regular Expression" if needed
4. Replace one pattern at a time
5. Review changes before saving

### Option 2: Automatic Script (Advanced)
```bash
# Run from project root
# This is a bash script - adjust for your OS

cd lib

# Replace AppTheme.primaryGreen with context.primaryColor
find . -name "*.dart" -type f -exec sed -i 's/AppTheme\.primaryGreen/context.primaryColor/g' {} \;

# Replace other colors
find . -name "*.dart" -type f -exec sed -i 's/AppTheme\.accentGreen/context.accentColor/g' {} \;
find . -name "*.dart" -type f -exec sed -i 's/AppTheme\.lightBackground/context.backgroundColor/g' {} \;
find . -name "*.dart" -type f -exec sed -i 's/AppTheme\.darkBackground/context.backgroundColor/g' {} \;
find . -name "*.dart" -type f -exec sed -i 's/AppTheme\.lightTextPrimary/context.textColor/g' {} \;
find . -name "*.dart" -type f -exec sed -i 's/AppTheme\.darkTextPrimary/context.textColor/g' {} \;
```

### Option 3: Use AI Assistant (Easiest)
Tell your AI assistant:
> "Replace all instances of `AppTheme.primaryGreen` with `context.primaryColor` in all files under lib/screens and lib/widgets. Also replace other AppTheme color constants using the mapping in THEME_COLOR_MIGRATION_GUIDE.md"

## ⚠️ Special Cases

### 1. Static Contexts (No BuildContext available)
If you have a static method or class without `BuildContext`:
```dart
// BEFORE
static Color myColor = AppTheme.primaryGreen;

// AFTER - pass color as parameter
static Color myColor(BuildContext context) => context.primaryColor;
```

### 2. Color with Opacity
```dart
// BEFORE
AppTheme.primaryGreen.withOpacity(0.5)

// AFTER
context.primaryColor.withOpacity(0.5)
// OR
context.primaryColor.withAlpha(0.5)
```

### 3. Conditional Colors (light/dark)
```dart
// BEFORE
final isDark = theme.brightness == Brightness.dark;
final color = isDark ? AppTheme.darkGreen : AppTheme.primaryGreen;

// AFTER
final color = context.primaryColor; // Automatically adjusts!
```

### 4. Gradient Colors
```dart
// BEFORE
LinearGradient(
  colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
)

// AFTER
LinearGradient(
  colors: [context.primaryColor, context.primaryColor.darker(0.3)],
)
```

## 📊 Files to Update (Priority Order)

### High Priority (User-facing screens)
1. ✅ `lib/screens/settings_screen.dart` - Already updated
2. ✅ `lib/widgets/app_drawer.dart` - Already updated
3. `lib/screens/home_screen.dart`
4. `lib/screens/quran_reader_screen.dart`
5. `lib/screens/quran_navigation_screen.dart`
6. `lib/screens/favorites_screen.dart`

### Medium Priority
7. `lib/screens/bulk_audio_player_screen.dart`
8. `lib/screens/prayer_times_screen.dart`
9. `lib/screens/quran_search_screen.dart`
10. `lib/screens/subcategories_screen.dart`
11. `lib/screens/latest_content_screen.dart`

### Low Priority (Widgets)
12. `lib/widgets/media_viewers.dart`
13. `lib/widgets/mushaf_script_modal.dart`
14. `lib/widgets/curved_bottom_nav.dart`
15. Other widget files

## 🧪 Testing

After migration:
1. Run app: `flutter run`
2. Go to Settings → Appearance → Theme Preset
3. Try each theme (Classic Green, Royal Blue, Desert Gold, Night Purple)
4. Navigate through all screens
5. Verify colors change correctly

## 💡 Tips

1. **Do it incrementally** - Fix one screen at a time, test, then move to next
2. **Search for TODO** - Add `// TODO: Update theme color` comments for later
3. **Use Git** - Commit after each file so you can rollback if needed
4. **Test dark mode** - Make sure both light and dark modes look good
5. **Check dialogs** - Don't forget AlertDialogs, BottomSheets, etc.

## 🎨 Example Before/After

### Before (Hardcoded)
```dart
Container(
  color: AppTheme.primaryGreen,
  child: Text(
    'Hello',
    style: TextStyle(color: AppTheme.lightTextPrimary),
  ),
)
```

### After (Theme-Aware)
```dart
Container(
  color: context.primaryColor,
  child: Text(
    'Hello',
    style: TextStyle(color: context.textColor),
  ),
)
```

## ✨ Benefits

After migration:
- ✅ All colors automatically update when theme changes
- ✅ No need to modify individual screens
- ✅ Consistent colors across entire app
- ✅ Dark mode support built-in
- ✅ Easy to add more themes in the future

## 🆘 Need Help?

If you encounter issues:
1. Check if `context` is available (BuildContext)
2. Verify import: `import '../utils/theme_extensions.dart';`
3. For static contexts, pass context as parameter
4. Test with different theme presets

---

**Time Estimate**: 2-3 hours for all 329 instances across 24 files (if done carefully)
**Recommended**: Use AI assistant to automate the replacements!

