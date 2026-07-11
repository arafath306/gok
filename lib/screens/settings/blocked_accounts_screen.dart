import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  final _controller = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GeneralSettingsProvider>(context, listen: false).fetchSettings();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _searchQuery = trimmed;
      _isSearching = true;
    });

    final provider = Provider.of<GeneralSettingsProvider>(context, listen: false);
    final results = await provider.searchProfiles(trimmed);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Blocked Accounts',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: Consumer<GeneralSettingsProvider>(
        builder: (context, provider, _) {
          final blocked = provider.blockedAccounts;
          return Column(
            children: [
              // Search Input Panel
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  border: Border(bottom: BorderSide(color: context.border)),
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search user to block...',
                    hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: Icon(Icons.search_rounded, color: context.textMuted, size: 20),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: context.textMuted, size: 18),
                            onPressed: () {
                              _controller.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                  ),
                  style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                  onChanged: _performSearch,
                ),
              ),

              // Search results or current blocked users list
              Expanded(
                child: _isSearching
                    ? Center(
                        child: CircularProgressIndicator(
                          color: context.primaryAccent,
                        ),
                      )
                    : _searchQuery.isNotEmpty
                        ? _searchResults.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 60, color: context.textMuted),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No users found matching "$_searchQuery"',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  final isBlocked = provider.blockedAccounts.any((a) => a['id'] == user['id']);

                                  return Container(
                                    color: context.cardBg,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: user['avatar']!.isNotEmpty
                                              ? CachedNetworkImageProvider(user['avatar']!)
                                              : null,
                                          backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
                                          child: user['avatar']!.isEmpty
                                              ? Icon(Icons.person, color: context.textMuted, size: 20)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name']!,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.5,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                '@${user['username']!}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5,
                                                  color: context.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        isBlocked
                                            ? OutlinedButton(
                                                onPressed: () async {
                                                  await provider.unblockAccount(user['id']!);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Unblocked @${user['username']}'),
                                                        backgroundColor: context.primaryAccent,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: context.border),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                                  minimumSize: const Size(0, 32),
                                                ),
                                                child: Text(
                                                  'Unblock',
                                                  style: GoogleFonts.inter(
                                                    color: context.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              )
                                            : ElevatedButton(
                                                onPressed: () async {
                                                  try {
                                                    await provider.blockUserById(user['id']!);
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Blocked @${user['username']}'),
                                                          backgroundColor: context.primaryAccent,
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(e.toString().replaceAll('Exception:', '').trim()),
                                                          backgroundColor: Colors.redAccent,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                                  minimumSize: const Size(0, 32),
                                                ),
                                                child: Text(
                                                  'Block',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                      ],
                                    ),
                                  );
                                },
                              )
                        : provider.isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: context.primaryAccent,
                                ),
                              )
                            : blocked.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.block, size: 60, color: context.textMuted),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No blocked accounts',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: blocked.length,
                                    separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
                                    itemBuilder: (context, index) {
                                      final user = blocked[index];
                                      return Container(
                                        color: context.cardBg,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundImage: user['avatar']!.isNotEmpty
                                                  ? CachedNetworkImageProvider(user['avatar']!)
                                                  : null,
                                              backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
                                              child: user['avatar']!.isEmpty
                                                  ? Icon(Icons.person, color: context.textMuted, size: 20)
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user['name']!,
                                                    style: GoogleFonts.inter(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14.5,
                                                      color: context.textPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    '@${user['username']!}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.5,
                                                      color: context.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            OutlinedButton(
                                              onPressed: () async {
                                                await provider.unblockAccount(user['id']!);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Unblocked @${user['username']}'),
                                                      backgroundColor: context.primaryAccent,
                                                    ),
                                                  );
                                                }
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(color: context.border),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                                minimumSize: const Size(0, 32),
                                              ),
                                              child: Text(
                                                'Unblock',
                                                style: GoogleFonts.inter(
                                                  color: context.textPrimary,
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
