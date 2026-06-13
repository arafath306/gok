import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';
import 'chat_screen.dart';

class MemberSearchSheet extends StatefulWidget {
  const MemberSearchSheet({super.key});

  @override
  State<MemberSearchSheet> createState() => _MemberSearchSheetState();
}

class _MemberSearchSheetState extends State<MemberSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Profile> _searchResults = [];
  bool _isSearching = false;
  
  // Track sent follow request user UIDs
  final Set<String> _sentRequests = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, DatabaseService db) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    // Call the database search query we added
    final results = await db.searchProfiles(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  // Simulated permission check logic:
  // Returns true if the user allows direct messages, false if it requires a follow request
  bool _allowsDirectMessage(Profile profile) {
    // 1. Current user doesn't chat with themselves
    // 2. Mock rule: Users with 'tanzir' or 'dak' or even IDs containing odd numbers allow DM,
    // others require follow requests (simulates RLS or backend settings).
    final idHash = profile.id.hashCode;
    return idHash % 3 != 0; // 66% allow DM, 33% require follow request
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Chat',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F4),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  hintText: "নাম বা ইউজারনেম দিয়ে খুঁজুন...",
                  hintStyle: GoogleFonts.hindSiliguri(color: Colors.black38, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: GoogleFonts.hindSiliguri(fontSize: 14.5),
                onChanged: (val) => _onSearchChanged(val, db),
              ),
            ),
          ),

          // Search Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? "মেম্বার খুঁজতে টাইপ করুন"
                              : "কোনো মেম্বার পাওয়া যায়নি",
                          style: GoogleFonts.hindSiliguri(color: Colors.black38, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          
                          // Avoid displaying current user in search
                          if (user.id == db.myProfile?.id) {
                            return const SizedBox.shrink();
                          }

                          final canDM = _allowsDirectMessage(user);
                          final hasSentRequest = _sentRequests.contains(user.id);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : const NetworkImage("https://i.pravatar.cc/150"),
                            ),
                            title: Text(
                              user.fullName,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              "@${user.username}",
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: Colors.black45,
                              ),
                            ),
                            trailing: canDM
                                ? ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Close search
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(otherUser: user),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0085FF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      elevation: 0,
                                      minimumSize: Size.zero,
                                    ),
                                    child: Text(
                                      "Message",
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: hasSentRequest
                                        ? null
                                        : () {
                                            setState(() {
                                              _sentRequests.add(user.id);
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${user.fullName} কে ফলো রিকোয়েস্ট পাঠানো হয়েছে।',
                                                  style: GoogleFonts.hindSiliguri(),
                                                ),
                                              ),
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasSentRequest ? Colors.grey[200] : const Color(0xFF1E824C),
                                      foregroundColor: hasSentRequest ? Colors.black38 : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      elevation: 0,
                                      minimumSize: Size.zero,
                                    ),
                                    child: Text(
                                      hasSentRequest ? "Requested" : "Follow Request",
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
