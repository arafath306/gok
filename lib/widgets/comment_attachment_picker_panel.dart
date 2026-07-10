import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class CommentAttachmentPickerPanel extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;
  final ValueChanged<String> onGifSelected;
  final int initialTabIndex;

  const CommentAttachmentPickerPanel({
    super.key,
    required this.onEmojiSelected,
    required this.onGifSelected,
    this.initialTabIndex = 0,
  });

  @override
  State<CommentAttachmentPickerPanel> createState() => _CommentAttachmentPickerPanelState();
}

class _CommentAttachmentPickerPanelState extends State<CommentAttachmentPickerPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _gifSearchController = TextEditingController();
  final FocusNode _gifSearchFocus = FocusNode();
  
  bool _isLoadingGifs = false;
  List<String> _gifUrls = [];
  String _activeCategory = "Smileys";
  double _panelHeight = 280.0;
  
  final ScrollController _emojiScrollController = ScrollController();
  final ScrollController _gifScrollController = ScrollController();
  
  // Category tabs for emoji picker
  final List<Map<String, dynamic>> _emojiCategories = [
    {"label": "Smileys", "icon": "😀"},
    {"label": "Nature", "icon": "🐱"},
    {"label": "Food", "icon": "🍔"},
    {"label": "Activity", "icon": "⚽"},
    {"label": "Travel", "icon": "✈️"},
    {"label": "Objects", "icon": "💡"},
    {"label": "Symbols", "icon": "🔣"},
    {"label": "Flags", "icon": "🏁"},
  ];

  // Curated fallback reaction GIFs list in case Giphy API is limited/offline
  final Map<String, List<String>> _fallbackGifs = {
    "trending": [
      "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2Q4MGJhOWM5NmVlNDlmN2M5MzhiNzg1MThjOTIyNDhiOGExNWJjOCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3NtY188QaxDdC/giphy.gif",
      "https://media.giphy.com/media/26FxGPtJNGrTQLlLO/giphy.gif",
      "https://media.giphy.com/media/l41YcM7254589dGzC/giphy.gif",
      "https://media.giphy.com/media/fnK0ja2iOiVK8/giphy.gif",
      "https://media.giphy.com/media/tfUW8mhiFk8NlJhgEh/giphy.gif",
      "https://media.giphy.com/media/14uVuf0NwVT6Wk/giphy.gif",
      "https://media.giphy.com/media/3o7abKhOpu0NXS3wy4/giphy.gif",
      "https://media.giphy.com/media/9gISqB3tncMmY/giphy.gif",
    ],
    "haha": [
      "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2Q4MGJhOWM5NmVlNDlmN2M5MzhiNzg1MThjOTIyNDhiOGExNWJjOCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3NtY188QaxDdC/giphy.gif",
      "https://media.giphy.com/media/10yIEN8cMn4i9W/giphy.gif",
      "https://media.giphy.com/media/kC8N6D5d6LDcR7FV4f/giphy.gif",
      "https://media.giphy.com/media/l3E6uhENzkOPVOPmW/giphy.gif",
    ],
    "happy": [
      "https://media.giphy.com/media/l41YcM7254589dGzC/giphy.gif",
      "https://media.giphy.com/media/26u4lOM85IbN73Up2/giphy.gif",
      "https://media.giphy.com/media/3o7abKhOpu0NXS3wy4/giphy.gif",
      "https://media.giphy.com/media/l2JHRhAtnJSDNJ2py/giphy.gif",
    ],
    "agree": [
      "https://media.giphy.com/media/26FxGPtJNGrTQLlLO/giphy.gif",
      "https://media.giphy.com/media/3oFzmkkaJ013iX6EUM/giphy.gif",
      "https://media.giphy.com/media/xT0xezQGU5WCDRS9rO/giphy.gif",
      "https://media.giphy.com/media/jErnybNlfE1lm/giphy.gif",
    ],
    "sad": [
      "https://media.giphy.com/media/2WxWfravOPUU0/giphy.gif",
      "https://media.giphy.com/media/1DfZvK2AoI8Gk/giphy.gif",
      "https://media.giphy.com/media/ObXgWWELSBN0A/giphy.gif",
      "https://media.giphy.com/media/9PxJYX3a7cb3oQut4c/giphy.gif",
    ],
    "angry": [
      "https://media.giphy.com/media/11tRgEtjIvBsGY/giphy.gif",
      "https://media.giphy.com/media/3o72FiX39c0hstv4t2/giphy.gif",
      "https://media.giphy.com/media/tJeGxtWqw27zG/giphy.gif",
      "https://media.giphy.com/media/uPfNo0pT2DvMc/giphy.gif",
    ],
    "wow": [
      "https://media.giphy.com/media/tfUW8mhiFk8NlJhgEh/giphy.gif",
      "https://media.giphy.com/media/l0ExhcMhm7S51POWk/giphy.gif",
      "https://media.giphy.com/media/26AHPxxnSw1L9UP5K/giphy.gif",
      "https://media.giphy.com/media/xT9IgusfKiHN9EDSCY/giphy.gif",
    ],
    "dance": [
      "https://media.giphy.com/media/14uVuf0NwVT6Wk/giphy.gif",
      "https://media.giphy.com/media/3ohzdIuqJoo8QdVCpx/giphy.gif",
      "https://media.giphy.com/media/l3V0lsGtTMSB5YNgA/giphy.gif",
      "https://media.giphy.com/media/26gJzYyOBxwCSSkqA/giphy.gif",
    ],
    "applause": [
      "https://media.giphy.com/media/fnK0ja2iOiVK8/giphy.gif",
      "https://media.giphy.com/media/9gISqB3tncMmY/giphy.gif",
      "https://media.giphy.com/media/3o7qDWp7hxhi1N8oF2/giphy.gif",
      "https://media.giphy.com/media/G1VpmXbzm3lyM/giphy.gif",
    ],
  };

  // Curated lists of high-fidelity Unicode emojis by category
  final Map<String, List<String>> _emojiData = {
    "Smileys": [
      "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", 
      "😙", "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", 
      "😕", "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺", "😢", "😭", "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", 
      "😱", "😨", "😰", "😥", "😓", "🤗", "🤔", "🤭", "🤫", "🤥", "😶", "😐", "😑", "😬", "🙄", "😯", "😦", "😧", 
      "😮", "😲", "🥱", "😴", "🤤", "😪", "😵", "🤐", "🥴", "🤢", "🤮", "🤧", "😷", "🤒", "🤕", "🤑", "🤠", "😈", 
      "👿", "👹", "👺", "🤡", "💩", "👻", "💀", "☠️", "👽", "👾", "🤖", "🎃"
    ],
    "Nature": [
      "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐽", "🐸", "🐵", "🙈", "🙉", 
      "🙊", "🐒", "🐔", "🐧", "🐦", "🐤", "🐣", "🐥", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", 
      "🐞", "🐜", "🦟", "🦗", "🕷️", "🕸️", "🦂", "🐢", "🐍", "🦎", "🦖", "🦕", "🐙", "🦑", "🦐", "🦞", "🦀", "🐡", "🐠", "🐟", 
      "🐬", "🐳", "🐋", "🦈", "🐊", "🐅", "🐆", "🦓", "🦍", "🦧", "🐘", "🦛", "🦏", "🐪", "🐫", "🦒", "🦘", "🐃", "🐂", "🐄", 
      "🐎", "🐖", "🐏", "🐑", "🐐", "🦌", "🐕", "🐩", "🐈", "🐓", "🦃", "🦚", "🦜", "🦢", "🕊️", "🐇", "🦝", "🦡", "🐾", 
      "🌵", "🎄", "🌲", "🌳", "🌴", "🌱", "🌿", "☘️", "🍀", "🍁", "🍂", "🍃"
    ],
    "Food": [
      "🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", 
      "🥑", "🥦", "🥬", "🥒", "🌶️", "🌽", "🥕", "🥔", "🍠", "🥐", "🥯", "🍞", "🥖", "🥨", "🧀", "🥚", "🍳", "🥞", 
      "🥓", "🥩", "🍗", "🍖", "🍔", "🍟", "🍕", "🌭", "🥪", "🌮", "🌯", "🥘", "🍲", "🥗", "🍿", "🧈", "🧂", "🥫", 
      "🍱", "🍘", "🍙", "🍚", "🍛", "🍜", "🍝", "🍢", "🍣", "🍤", "🍥", "🦪", "🍡", "🥟", "🥡", "🍦", "🍧", "🍨", 
      "🍩", "🍪", "🎂", "🍰", "🧁", "🥧", "🍫", "🍬", "🍭", "🍮", "🍯", "🍼", "🥛", "☕", "🍵", "🍶", "🍾", "🍷", 
      "🍸", "🍹", "🍺", "🍻", "🥂", "🥃", "🥤", "🧉", "🧊"
    ],
    "Activity": [
      "⚽", "🏀", "🏈", "⚾", "🥎", "🎾", "🏐", "🏉", "🎱", "🏓", "🏸", "🥅", "🏒", "🏑", "🏏", "⛳", "🏹", "🎣", 
      "🤿", "🥊", "🥋", "⛸️", "🎿", "🛷", "🏆", "🥇", "🥈", "🥉", "🏅", "🎖️", "🎫", "🎟️", "🎪", "🎭", "🎨", "🎬", 
      "🎤", "🎧", "🎼", "🎹", "🥁", "🎸", "🎮", "🕹️", "🎰", "🎲", "🧩", "🎳", "🎯", "skateboard", "🛹", "🛼", "🧗", "🤺", "🏇"
    ],
    "Travel": [
      "🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐", "🚚", "🚛", "🚜", "🏍️", "🛵", "🚲", "🛴", "🚨", 
      "🚔", "🚍", "🚘", "🚖", "✈️", "🛫", "🛬", "🛰️", "🚀", "🛸", "🚁", "🛶", "⛵", "🛥️", "🚢", "⚓", "⛽", "🚧", 
      "🗺️", "🗿", "🗽", "🗼", "🏰", "🏯", "🏟️", "🎡", "🎢", "🎠", "⛱️", "🏖️", "🏝️", "🏜️", "🌋", "⛰️", "🏕️", "⛺", 
      "🏠", "🏢", "🏣", "🏥", "🏦", "🏨", "🏪", "🏫", "🏬", "🏭", "💒", "⛪", "🕌", "🕋", "⛩️"
    ],
    "Objects": [
      "⌚", "📱", "💻", "⌨️", "🖥️", "🖨️", "🖱️", "📷", "📸", "📹", "🎥", "📽️", "🎞️", "📞", "☎️", "📟", "📠", 
      "📺", "📻", "🎙️", "🧭", "⏱️", "⏰", "⏳", "⌛", "🔋", "🔌", "💡", "🔦", "🕯️", "🗑️", "💵", "💴", 
      "💶", "💷", "🪙", "💰", "💳", "💎", "⚖️", "🔧", "🔨", "⚒️", "🔩", "⚙️", "🧱", "⛓️", "🧲", "🔫", "💣", "🧨", 
      "🪓", "🔪", "⚔️", "🛡️", "🚬", "⚰️", "🏺", "🔮", "🧴", "🔑", "🔐", "🔒", "🔓", "📢", "🔔", "🔕", 
      "🩹", "🩺", "🧬", "🧪", "🔬", "🔭", "📡", "🧯", "🧹", "🧺", "🧻", "🧼", "🪠", "🧽", "🪣"
    ],
    "Symbols": [
      "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", 
      "💟", "☮️", "✝️", "☪️", "🕉️", "☸️", "☯️", "♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓", 
      "🆔", "⚛️", "🉑", "☢️", "☣️", "📴", "📳", "🈶", "🈚", "🆚", "💮", "🉐", "㊙️", "㊗️", "🅰️", "🅱️", "🆎", "🅾️", 
      "🆘", "❌", "⭕", "🛑", "⛔", "🚫", "💯", "🔕", "🔇", "🔈", "🔉", "🔊", "🔔", "💬", "💭", "🗯️", "🃏", "🌀"
    ],
    "Flags": [
      "🏁", "🚩", "🎌", "🏳️", "🏴", "🏴‍☠️", "🏳️‍🌈", "🏳️‍⚧️", "🇺🇳", "🇦🇫", "🇦🇱", "🇩🇿", "🇦🇸", "🇦🇩", "🇦🇴", "🇦🇮", "🇦🇶", "🇦🇬", 
      "🇦🇷", "🇦🇲", "🇦🇼", "🇦🇺", "🇦🇹", "🇦🇿", "🇧🇸", "🇧🇭", "🇧🇩", "🇧🇧", "🇧🇾", "🇧🇪", "🇧🇿", "🇧🇯", "🇧🇲", "🇧🇹", "🇧🇴", "🇧🇦", 
      "🇧🇼", "🇧🇷", "🇮🇴", "🇻🇬", "🇧🇳", "🇧🇬", "🇧🇫", "🇧🇮", "🇰🇭", "🇨🇲", "🇨🇦", "🇮🇨", "🇨🇻", "🇧☉", "🇰🇾", "🇨🇫", "🇹🇩", "🇨🇱", 
      "🇨🇳", "🇨🇽", "🇨🇨", "🇨☉", "🇰🇲", "🇨🇬", "🇨🇩", "🇨🇰", "🇨🇷", "🇨🇮", "🇭🇷", "🇨🇺", "🇨🇼", "🇨🇾", "🇨🇿", "🇩🇰", "🇩🇯", "🇩🇲", 
      "🇩☉", "🇪🇨", "🇪🇬", "🇸🇻", "🇬🇶", "🇪🇷", "🇪🇪", "🇸🇿", "🇪🇹", "🇪🇺", "🇫🇰", "🇫🇴", "🇫🇯", "🇫🇮", "🇫🇷", "🇬🇫", "🇵🇫", "🇹🇫", 
      "🇬🇦", "🇬🇲", "🇬🇪", "🇩🇪", "🇬🇭", "🇬🇮", "🇬🇷", "🇬🇱", "🇬🇩", "🇬🇵", "🇬🇺", "🇬🇹", "🇬🇬", "🇬🇳", "🇬🇼", "🇬🇾", "🇭🇹", "🇭🇳", 
      "🇭🇰", "🇭🇺", "🇮🇸", "🇮🇳", "🇮🇩", "🇮🇷", "🇮🇶", "🇮🇪", "🇮🇲", "🇮🇱", "🇮🇹", "🇯🇲", "🇯🇵", "🇯🇪", "🇯☉", "🇰🇿", "🇰🇪", "🇰🇮", 
      "🇰🇵", "🇰🇷", "🇽🇰", "🇰🇼", "🇰🇬", "🇱🇦", "🇱🇻", "🇱🇧", "🇱🇸", "🇱🇷", "🇱🇾", "🇱🇮", "🇱🇹", "🇱🇺", "🇲☉", "🇲🇬", "🇲🇼", "🇲🇾", 
      "🇲🇻", "🇲🇱", "🇲🇹", "🇲🇭", "🇲🇶", "🇲🇷", "🇲🇺", "🇾🇹", "🇲🇽", "🇫🇲", "🇲🇩", "🇲🇨", "🇲🇳", "🇲🇪", "🇲🇸", "🇲🇦", "🇲🇿", "🇲🇲", 
      "🇳🇦", "🇳🇷", "🇳🇵", "🇳🇱", "🇳🇨", "🇳🇿", "🇳🇮", "🇳🇪", "🇳🇬", "🇳🇺", "🇳🇫", "🇲🇵", "🇲🇰", "🇳☉", "🇴🇲", "🇵🇰", "🇵🇼", "🇵🇸", 
      "🇵🇦", "🇵🇬", "🇵🇾", "🇵🇪", "🇵🇭", "🇵🇳", "🇵🇱", "🇵🇹", "🇵🇷", "🇶🇦", "🇷🇪", "🇷☉", "🇷🇺", "🇷🇼", "🇼🇸", "🇸🇲", "🇸🇹", "🇸🇦", 
      "🇸🇳", "🇷🇸", "🇸🇨", "🇸🇱", "🇸🇬", "🇸🇽", "🇸🇰", "🇸🇮", "🇬🇧", "🇺🇸", "🇺🇾", "🇺🇿", "🇻🇪", "🇻🇳", "🇼🇫", "🇾🇪", "🇿🇲", "🇿🇼"
    ]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    if (widget.initialTabIndex == 1 && _gifUrls.isEmpty) {
      _fetchGifs("trending");
    }
    _tabController.addListener(() {
      if (_tabController.index == 1 && _gifUrls.isEmpty) {
        _fetchGifs("trending");
      }
    });
  }

  @override
  void didUpdateWidget(covariant CommentAttachmentPickerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
      if (widget.initialTabIndex == 1 && _gifUrls.isEmpty) {
        _fetchGifs("trending");
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gifSearchController.dispose();
    _gifSearchFocus.dispose();
    _emojiScrollController.dispose();
    _gifScrollController.dispose();
    super.dispose();
  }

  // Giphy API query using native HttpClient
  Future<void> _fetchGifs(String query) async {
    setState(() {
      _isLoadingGifs = true;
    });

    final String queryTerm = query.trim().toLowerCase();
    
    // Check if queryTerm corresponds to one of our pre-seeded fallback categories
    final List<String>? localCategoryGifs = _fallbackGifs[queryTerm];

    try {
      final HttpClient client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final Uri uri;
      if (queryTerm == "trending") {
        uri = Uri.parse("https://api.giphy.com/v1/gifs/trending?api_key=urWIAb5RB9P7NpOGNTTx2czRre4E0G4E&limit=16&rating=g");
      } else {
        uri = Uri.parse("https://api.giphy.com/v1/gifs/search?api_key=urWIAb5RB9P7NpOGNTTx2czRre4E0G4E&q=${Uri.encodeComponent(queryTerm)}&limit=16&rating=g");
      }

      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final String body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
        final List<dynamic> data = json['data'] as List<dynamic>;

        final List<String> urls = [];
        for (var gif in data) {
          final images = gif['images'] as Map<String, dynamic>;
          final fixedHeight = images['fixed_height'] as Map<String, dynamic>;
          final url = fixedHeight['url'] as String;
          urls.add(url);
        }

        if (mounted) {
          setState(() {
            _gifUrls = urls;
            _isLoadingGifs = false;
          });
        }
      } else {
        throw Exception("API returned status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Giphy fetch failed: $e, using local fallback");
      if (mounted) {
        setState(() {
          // If search term matches one of our local categories, load it. Otherwise load trending fallback
          _gifUrls = localCategoryGifs ?? _fallbackGifs[queryTerm] ?? _fallbackGifs["trending"]!;
          _isLoadingGifs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _panelHeight,
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          top: BorderSide(color: context.border, width: 0.8),
        ),
      ),
      child: Column(
        children: [
          // Drag handle and Tab bar header
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              setState(() {
                _panelHeight = (_panelHeight - details.delta.dy).clamp(
                  250.0,
                  MediaQuery.of(context).size.height * 0.5,
                );
              });
            },
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Tab bar header
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.border, width: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Theme.of(context).primaryColor,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: context.textSecondary,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          tabs: const [
                            Tab(text: "Emoji"),
                            Tab(text: "GIF"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab body
          Expanded(
            child: Listener(
              onPointerMove: (event) {
                final double maxHeight = MediaQuery.of(context).size.height * 0.5;
                const double minHeight = 250.0;
                final dy = event.delta.dy;
                
                final activeScrollController = _tabController.index == 0 ? _emojiScrollController : _gifScrollController;
                final isAtTop = activeScrollController.hasClients ? activeScrollController.offset <= 0 : true;

                if (dy < 0 && _panelHeight < maxHeight) {
                  setState(() {
                    _panelHeight = (_panelHeight - dy).clamp(minHeight, maxHeight);
                  });
                } else if (dy > 0 && isAtTop && _panelHeight > minHeight) {
                  setState(() {
                    _panelHeight = (_panelHeight - dy).clamp(minHeight, maxHeight);
                  });
                }
              },
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmojiPickerTab(),
                  _buildGifPickerTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Emoji tab UI
  Widget _buildEmojiPickerTab() {
    final List<String> currentCategoryEmojis = _emojiData[_activeCategory] ?? _emojiData["Smileys"]!;
    return Column(
      children: [
        // Category selectors
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.black12 : Colors.grey[50],
            border: Border(bottom: BorderSide(color: context.border, width: 0.5)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _emojiCategories.length,
            itemBuilder: (context, index) {
              final cat = _emojiCategories[index];
              final isSel = _activeCategory == cat["label"];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _activeCategory = cat["label"] as String;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSel ? Theme.of(context).primaryColor.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(cat["icon"] as String, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        cat["label"] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Theme.of(context).primaryColor : context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Grid of emojis
        Expanded(
          child: GridView.builder(
            controller: _emojiScrollController,
            padding: const EdgeInsets.all(8),
            physics: _panelHeight >= MediaQuery.of(context).size.height * 0.49 
                ? const BouncingScrollPhysics() 
                : const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: currentCategoryEmojis.length,
            itemBuilder: (context, index) {
              final String emoji = currentCategoryEmojis[index];
              return InkWell(
                onTap: () => widget.onEmojiSelected(emoji),
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // GIF tab UI
  Widget _buildGifPickerTab() {
    final List<String> trendingTags = ["Haha", "Happy", "Agree", "Sad", "Angry", "Wow", "Dance", "Applause"];
    return Column(
      children: [
        // GIF Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _gifSearchController,
              focusNode: _gifSearchFocus,
              style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
              textInputAction: TextInputAction.search,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _fetchGifs(val.trim());
                }
              },
              decoration: InputDecoration(
                hintText: "Search GIPHY...",
                hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.textMuted),
                suffixIcon: _gifSearchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _gifSearchController.clear();
                          _fetchGifs("trending");
                          setState(() {});
                        },
                        child: Icon(Icons.clear_rounded, size: 16, color: context.textMuted),
                      )
                    : null,
                filled: true,
                fillColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF1F5F9),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: context.border, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.2),
                ),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
        ),

        // Horizonal quick search category pills
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: trendingTags.length,
            itemBuilder: (context, index) {
              final tag = trendingTags[index];
              final isQueryingThis = _gifSearchController.text.trim().toLowerCase() == tag.toLowerCase();
              return GestureDetector(
                onTap: () {
                  _gifSearchController.text = tag;
                  _gifSearchFocus.unfocus();
                  _fetchGifs(tag);
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: isQueryingThis 
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.15) 
                        : (context.isDarkMode ? const Color(0xFF1A1F2C) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isQueryingThis ? Theme.of(context).primaryColor : context.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isQueryingThis ? FontWeight.bold : FontWeight.w500,
                      color: isQueryingThis ? Theme.of(context).primaryColor : context.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Grid of GIFs
        Expanded(
          child: _isLoadingGifs
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Theme.of(context).primaryColor),
                  ),
                )
              : _gifUrls.isEmpty
                  ? Center(
                      child: Text(
                        "No GIFs found",
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                      ),
                    )
                  : GridView.builder(
                      controller: _gifScrollController,
                      padding: const EdgeInsets.all(8),
                      physics: _panelHeight >= MediaQuery.of(context).size.height * 0.49 
                          ? const BouncingScrollPhysics() 
                          : const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.45,
                      ),
                      itemCount: _gifUrls.length,
                      itemBuilder: (context, index) {
                        final String url = _gifUrls[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              GestureDetector(
                                onTap: () => widget.onGifSelected(url),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: context.isDarkMode ? Colors.black12 : Colors.grey[100],
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: context.isDarkMode ? Colors.black12 : Colors.grey[100],
                                    child: Icon(Icons.broken_image_outlined, color: context.textSecondary, size: 16),
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
  }
}
