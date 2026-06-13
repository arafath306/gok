import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _villageCtrl;
  late TextEditingController _zipCtrl;

  String? _selectedDivision;
  String? _selectedGender;
  String? _birthdateString;

  bool _isSaving = false;
  String? _errorMsg;

  final List<String> _divisions = [
    "ঢাকা (Dhaka)",
    "চট্টগ্রাম (Chattogram)",
    "রাজশাহী (Rajshahi)",
    "খুলনা (Khulna)",
    "বরিশাল (Barishal)",
    "সিলেট (Sylhet)",
    "রংপুর (Rangpur)",
    "ময়মনসিংহ (Mymensingh)"
  ];

  final List<Map<String, String>> _genders = [
    {"label": "পুরুষ (Male)", "value": "Male"},
    {"label": "নারী (Female)", "value": "Female"},
    {"label": "অন্যান্য (Other)", "value": "Other"}
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.profile['full_name']?.toString() ?? '');
    _usernameCtrl =
        TextEditingController(text: widget.profile['username']?.toString() ?? '');
    _bioCtrl =
        TextEditingController(text: widget.profile['bio']?.toString() ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.profile['phone']?.toString() ?? '');
    _cityCtrl =
        TextEditingController(text: widget.profile['city']?.toString() ?? '');
    _villageCtrl =
        TextEditingController(text: widget.profile['village']?.toString() ?? '');
    _zipCtrl =
        TextEditingController(text: widget.profile['zip']?.toString() ?? '');

    _selectedDivision = widget.profile['division']?.toString();
    if (_selectedDivision != null && !_divisions.contains(_selectedDivision)) {
      _selectedDivision = null;
    }

    _selectedGender = widget.profile['gender']?.toString();
    _birthdateString = widget.profile['birthdate']?.toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _villageCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    DateTime initialDate = DateTime(2000);
    if (_birthdateString != null && _birthdateString!.isNotEmpty) {
      try {
        final parts = _birthdateString!.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          initialDate = DateTime(year, month, day);
        }
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0085FF),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdateString = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty || _usernameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Name and username are required.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    final success = await db.updateProfile(
      fullName: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim().toLowerCase(),
      bio: _bioCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      country: widget.profile['country']?.toString() ?? '',
      division: _selectedDivision,
      city: _cityCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
      zip: _zipCtrl.text.trim(),
      gender: _selectedGender,
      birthdate: _birthdateString,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isSaving = false;
        _errorMsg = 'Failed to save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF0085FF)),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0085FF),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_errorMsg != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFDEDEC),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          _field('Display Name', _nameCtrl),
          const SizedBox(height: 14),
          _field('Username', _usernameCtrl, prefix: '@'),
          const SizedBox(height: 14),
          _field('Bio', _bioCtrl,
              maxLines: 4, hint: 'Write something about yourself...'),
          const SizedBox(height: 14),
          _field('Phone', _phoneCtrl, hint: '+880XXXXXXXXXX'),
          const SizedBox(height: 14),

          // Division Dropdown
          Text('Division',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            value: _selectedDivision,
            hint: Text('Select Division',
                style: GoogleFonts.hindSiliguri(color: Colors.black26)),
            items: _divisions
                .map((div) => DropdownMenuItem(
                    value: div,
                    child: Text(div, style: GoogleFonts.hindSiliguri())))
                .toList(),
            onChanged: (val) => setState(() => _selectedDivision = val),
          ),
          const SizedBox(height: 14),

          _field('City / Town', _cityCtrl, hint: 'e.g. Mirpur, Dhaka'),
          const SizedBox(height: 14),
          _field('Village / Street', _villageCtrl,
              hint: 'e.g. Road 5, Block D'),
          const SizedBox(height: 14),
          _field('ZIP Code', _zipCtrl, hint: 'e.g. 1216'),
          const SizedBox(height: 14),

          // Gender Dropdown
          Text('Gender',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            value: _selectedGender,
            hint: Text('Select Gender',
                style: GoogleFonts.hindSiliguri(color: Colors.black26)),
            items: _genders
                .map((g) => DropdownMenuItem(
                    value: g['value'],
                    child:
                        Text(g['label']!, style: GoogleFonts.hindSiliguri())))
                .toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
          const SizedBox(height: 14),

          // Birthdate
          Text('Birth Date',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _selectBirthdate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: Colors.black54),
                  const SizedBox(width: 10),
                  Text(
                    _birthdateString != null && _birthdateString!.isNotEmpty
                        ? _birthdateString!
                        : 'Select Birth Date',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      color: _birthdateString != null &&
                              _birthdateString!.isNotEmpty
                          ? Colors.black87
                          : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? prefix,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixText: prefix,
            hintText: hint,
            hintStyle: GoogleFonts.hindSiliguri(color: Colors.black26),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}
