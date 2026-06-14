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

for f in files:
    if not os.path.exists(f):
        print(f'SKIP (not found): {f}')
        continue
    with open(f, 'r', encoding='utf-8') as fh:
        content = fh.read()

    modified = False

    # 1. Add app_theme import if missing
    if 'app_theme.dart' not in content:
        content = re.sub(
            r"(import 'package:flutter/material\.dart';)",
            r"\1\nimport '../../utils/app_theme.dart';",
            content, count=1
        )
        modified = True

    print(f'Processed: {f}')
    with open(f, 'w', encoding='utf-8') as fh:
        fh.write(content)

print('Done.')
