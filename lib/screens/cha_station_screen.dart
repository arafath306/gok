import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';

class ChaStationScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ChaStationScreen({super.key, required this.onBack});

  @override
  State<ChaStationScreen> createState() => _ChaStationScreenState();
}

class _ChaStationScreenState extends State<ChaStationScreen> {
  String _selectedFilter = "সবাই";
  final List<String> _filters = ["সবাই", "আজকের", "জনপ্রিয়", "নতুন"];

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    // Filter posts that contain images (representing tea station media posts)
    final imagePosts = dbService.feed.where((post) => post.imageUrls != null && post.imageUrls!.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "চা-স্টেশন",
              style: GoogleFonts.hindSiliguri(
                color: const Color(0xFF1E824C),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "হাতের কাছে আপনার টং গাড়ী",
              style: GoogleFonts.hindSiliguri(
                color: Colors.black45,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.local_cafe, color: Color(0xFF1E824C)),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF1E824C),
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.camera_alt),
        label: Text(
          "ডাক পোস্ট করুন",
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E824C) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: GoogleFonts.hindSiliguri(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Image Posts List
          Expanded(
            child: imagePosts.isEmpty
                ? Center(
                    child: Text(
                      "চা-স্টেশনে কোন ছবি পোস্ট করা হয়নি।",
                      style: GoogleFonts.hindSiliguri(color: Colors.black45),
                    ),
                  )
                : ListView.separated(
                    itemCount: imagePosts.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                    itemBuilder: (context, index) {
                      return CustomThreadCard(post: imagePosts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
