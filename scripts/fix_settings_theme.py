import os, re

files = [
    'lib/screens/settings/privacy_settings_screen.dart',
    'lib/screens/settings/security_settings_screen.dart',
    'lib/screens/settings/about_settings_screen.dart',
    'lib/screens/settings/saved_threads_screen.dart',
    'lib/screens/settings/subscription_settings_screen.dart',
    'lib/screens/settings/help_center_screen.dart',
    'lib/screens/settings/blocked_accounts_screen.dart',
    'lib/screens/settings/muted_accounts_screen.dart',
]

# Map of what to inject at the start of build(BuildContext context) {
DYNAMIC_COLORS = """
    final kBg = context.scaffoldBg;
    final kCard = context.cardBg;
    final kCardBorder = context.border;
    final kPrimary = context.primaryAccent;
    final kText = context.textPrimary;
    final kTextSub = context.textSecondary;
    final kDivider = context.border;"""

# Replacements to make in content (old -> new)
REPLACEMENTS = [
    # static consts to remove
    (r'  static const _kBg = Color\(0xFF0D0F1A\);\n', ''),
    (r'  static const _kCard = Color\(0xFF161828\);\n', ''),
    (r'  static const _kCardBorder = Color\(0xFF262840\);\n', ''),
    (r'  static const _kPrimary = Color\(0xFF7C4DFF\);\n', ''),
    (r'  static const _kText = Color\(0xFFEAEBF0\);\n', ''),
    (r'  static const _kTextSub = Color\(0xFF8B8FA8\);\n', ''),
    (r'  static const _kDivider = Color\(0xFF1E2035\);\n', ''),
    (r'  static const _kAccent = Color\(0xFF.*?\);\n', ''),
    # Color references
    ('_kBg', 'kBg'),
    ('_kCard', 'kCard'),
    ('_kCardBorder', 'kCardBorder'),
    ('_kPrimary', 'kPrimary'),
    ('_kText', 'kText'),
    ('_kTextSub', 'kTextSub'),
    ('_kDivider', 'kDivider'),
    # Static Colors.white/black text to dynamic
    ('color: Colors.white,', 'color: kText,'),
    ('color: Colors.white)', 'color: kText)'),
    # Colors.white size references that are text-colored
]

for filepath in files:
    if not os.path.exists(filepath):
        print(f'SKIP: {filepath}')
        continue

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove static const declarations
    for pattern, replacement in REPLACEMENTS:
        if pattern.startswith('_k') or pattern.startswith('color:'):
            content = content.replace(pattern, replacement)
        else:
            content = re.sub(pattern, replacement, content)

    # Inject dynamic color lookups after each "Widget build(BuildContext context) {"
    # Only if not already there
    build_pattern = r'(Widget build\(BuildContext context\) \{)'
    if 'final kBg = context.scaffoldBg' not in content:
        content = re.sub(build_pattern, r'\1' + DYNAMIC_COLORS, content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f'Done: {filepath}')

print('All done.')
