import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/notification_settings_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEEEEEE), height: 1.0),
        ),
      ),
      body: Consumer<NotificationSettingsProvider>(
        builder: (context, provider, _) {
          final items = provider.settingsList;
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return _NotifSettingTile(item: item, provider: provider);
            },
          );
        },
      ),
    );
  }
}

class _NotifSettingTile extends StatelessWidget {
  final NotificationSettingItem item;
  final NotificationSettingsProvider provider;

  const _NotifSettingTile({required this.item, required this.provider});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // In-app toggle
                  _buildToggleRow(
                    ctx,
                    label: 'In-app',
                    value: item.inApp,
                    onChanged: (val) {
                      setModalState(() {});
                      provider.updateSetting(id: item.id, inApp: val);
                    },
                  ),
                  // Push toggle
                  _buildToggleRow(
                    ctx,
                    label: 'Push',
                    value: item.push,
                    onChanged: (val) {
                      setModalState(() {});
                      provider.updateSetting(id: item.id, push: val);
                    },
                  ),
                  if (item.hasFromOption) ...[
                    const SizedBox(height: 12),
                    Text(
                      'From',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFromOption(ctx, setModalState, 'everyone', 'Everyone'),
                    _buildFromOption(ctx, setModalState, 'people_you_follow', 'People you follow'),
                    _buildFromOption(ctx, setModalState, 'off', 'Off'),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToggleRow(BuildContext context,
      {required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.black87,
            activeTrackColor: Colors.black87,
            inactiveTrackColor: Colors.black12,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildFromOption(BuildContext ctx, StateSetter setModalState, String value, String label) {
    final isSelected = item.from == value;
    return InkWell(
      onTap: () {
        setModalState(() {});
        provider.updateSetting(id: item.id, from: value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.black87, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, color: Colors.black87, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtext,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
