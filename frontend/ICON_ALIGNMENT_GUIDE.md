# Icon Alignment Guide

## Current Icon Alignment Specifications

All form field prefix icons in the Flutter app are now consistently aligned using the following specifications:

### Icon Positioning
```dart
prefixIcon: Padding(
  padding: const EdgeInsets.only(left: 16, right: 12),
  child: Icon(IconData, color: primaryColor, size: 20),
),
prefixIconConstraints: const BoxConstraints(
  minWidth: 48,
  minHeight: 48,
),
```

### Key Changes Made:
1. **Padding**: Changed from `symmetric(horizontal: 12)` to `only(left: 16, right: 12)`
   - This aligns the icon properly with the text field's content padding
   - Left padding of 16 matches the text field's horizontal content padding
   - Right padding of 12 provides proper spacing between icon and text

2. **Icon Constraints**: Increased from 44x44 to 48x48
   - Provides better touch target area
   - Ensures consistent icon container size across all form fields

3. **Widget Type**: Changed from `Container` to `Padding`
   - More semantic and performant for simple padding operations
   - Eliminates unnecessary container overhead

### Applied To:
- ✅ Login Screen: Email and Password fields
- ✅ Signup Screen: First Name, Last Name, Email, Password, and Confirm Password fields

### Visual Result:
- Perfect vertical alignment of icons within text fields
- Consistent spacing between icons and text labels
- Professional appearance matching modern Material Design standards
- No visual "div differences" or misalignment issues

### Performance Benefits:
- Reduced UI rendering overhead
- Eliminated layout shifts during rendering
- Smoother animation performance
- Better overall app responsiveness
