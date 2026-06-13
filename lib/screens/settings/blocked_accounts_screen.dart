import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _blockNewUser(GeneralSettingsProvider provider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Simulate blocking a user
    final username = text.replaceAll(' ', '_').toLowerCase();
    provider.blockAccount(text, username, 'https://i.pravatar.cc/150?u=$username');
    _controller.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('@$username has been blocked.'),
        backgroundColor: const Color(0xFF1E824C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Blocked Accounts',
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
      body: Consumer<GeneralSettingsProvider>(
        builder: (context, provider, _) {
          final blocked = provider.blockedAccounts;
          return Column(
            children: [
              // Search & Block Input Panel
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Enter name or @username to block...',
                          hintStyle: GoogleFonts.outfit(color: Colors.black38, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        style: GoogleFonts.outfit(fontSize: 14),
                        onSubmitted: (_) => _blockNewUser(provider),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _blockNewUser(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: Text(
                        'Block',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // Blocked users list
              Expanded(
                child: blocked.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.block, size: 60, color: Colors.black26),
                            const SizedBox(height: 16),
                            Text(
                              'No blocked accounts',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: blocked.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F1F1)),
                        itemBuilder: (context, index) {
                          final user = blocked[index];
                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(user['avatar']!),
                                  backgroundColor: Colors.grey[200],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['name']!,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '@${user['username']!}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    provider.unblockAccount(user['id']!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Unblocked @${user['username']}'),
                                        backgroundColor: const Color(0xFF1E824C),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  child: Text(
                                    'Unblock',
                                    style: GoogleFonts.outfit(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
