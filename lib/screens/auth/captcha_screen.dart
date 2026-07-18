import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CaptchaScreen
//
//  isSignup = false → Easy mode  : 3 math MCQ questions
//  isSignup = true  → Normal mode: emoji grid category selection
// ─────────────────────────────────────────────────────────────────────────────
class CaptchaScreen extends StatefulWidget {
  final bool isSignup;
  final VoidCallback onPass;

  const CaptchaScreen({
    super.key,
    required this.isSignup,
    required this.onPass,
  });

  @override
  State<CaptchaScreen> createState() => _CaptchaScreenState();
}

class _CaptchaScreenState extends State<CaptchaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() => _shakeController.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // 1. Base auth bg image
          Positioned.fill(
            child: Opacity(
              opacity: 0.65,
              child: Image.asset('assets/auth_bg.png', fit: BoxFit.cover),
            ),
          ),

          // 2. Animated premium ambient light blobs
          const Positioned.fill(child: _AnimatedBackgroundBlobs()),

          // 3. Dark/Light theme safety overlay
          Positioned.fill(
            child: Container(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.4) 
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),

          // 4. Content
          SafeArea(
            child: Column(
              children: [
                // Premium Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      _CircleBack(onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isSignup ? 'Security Check' : 'Quick Check',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.isSignup
                                  ? 'Solve to create account securely'
                                  : 'A fast check before logging in',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (ctx, child) {
                      final offset = sin(_shakeAnim.value * pi * 6) * 10;
                      return Transform.translate(
                          offset: Offset(offset, 0), child: child);
                    },
                    child: widget.isSignup
                        ? _GridCaptcha(onPass: widget.onPass, onFail: _shake)
                        : _MathCaptcha(onPass: widget.onPass, onFail: _shake),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Ambient Blobs Widget (Next-Gen UI feel)
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedBackgroundBlobs extends StatefulWidget {
  const _AnimatedBackgroundBlobs();

  @override
  State<_AnimatedBackgroundBlobs> createState() => _AnimatedBackgroundBlobsState();
}

class _AnimatedBackgroundBlobsState extends State<_AnimatedBackgroundBlobs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value * 2 * pi;
        return Stack(
          children: [
            // Soft Green Blob 1
            Positioned(
              top: 120 + sin(val) * 50,
              left: -60 + cos(val) * 40,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E824C).withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
            // Soft Mint Blob 2
            Positioned(
              bottom: 100 + cos(val) * 60,
              right: -80 + sin(val) * 40,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
            // Soft Tech Blue Blob 3
            Positioned(
              top: 320 + cos(val + pi) * 60,
              right: 20 + sin(val + pi) * 50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A365D).withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Pressable Interactive Option widget
// ─────────────────────────────────────────────────────────────────────────────
class _PressableOption extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;

  const _PressableOption({
    required this.child,
    required this.onTap,
    this.isSelected = false,
    this.isCorrect = false,
    this.isWrong = false,
  });

  @override
  State<_PressableOption> createState() => _PressableOptionState();
}

class _PressableOptionState extends State<_PressableOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    Color bg;
    Color border;
    if (widget.isCorrect) {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFF10B981);
    } else if (widget.isWrong) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFEF4444);
    } else if (widget.isSelected) {
      bg = isDark 
          ? const Color(0xFF1E824C).withValues(alpha: 0.25)
          : const Color(0xFFE8F8F0);
      border = const Color(0xFF1E824C);
    } else {
      bg = isDark 
          ? const Color(0xFF1E293B).withValues(alpha: 0.6)
          : const Color(0xFFF8FAFC);
      border = isDark 
          ? const Color(0xFF334155).withValues(alpha: 0.8)
          : const Color(0xFFE2E8F0);
    }

    return GestureDetector(
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) {
        _animController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animController.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: widget.isSelected ? 2.2 : 1.2),
            boxShadow: [
              if (widget.isSelected && !widget.isCorrect && !widget.isWrong)
                BoxShadow(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else if (!widget.isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
            ],
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Easy Mode: Math MCQ — 3 questions all must be correct
// ─────────────────────────────────────────────────────────────────────────────
class _MathCaptcha extends StatefulWidget {
  final VoidCallback onPass;
  final VoidCallback onFail;
  const _MathCaptcha({required this.onPass, required this.onFail});

  @override
  State<_MathCaptcha> createState() => _MathCaptchaState();
}

class _MathCaptchaState extends State<_MathCaptcha> {
  final _rng = Random();
  late List<_MathQ> _questions;
  late List<int?> _selected;
  int _currentQ = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _questions = List.generate(3, (_) => _MathQ.generate(_rng));
    _selected = [null, null, null];
    _currentQ = 0;
  }

  void _pick(int optionIndex) {
    final q = _questions[_currentQ];
    setState(() => _selected[_currentQ] = optionIndex);

    if (q.options[optionIndex] == q.answer) {
      if (_currentQ < 2) {
        Future.delayed(const Duration(milliseconds: 350),
            () { if (mounted) setState(() => _currentQ++); });
      } else {
        Future.delayed(const Duration(milliseconds: 300),
            () { if (mounted) widget.onPass(); });
      }
    } else {
      widget.onFail();
      Future.delayed(const Duration(milliseconds: 700),
          () { if (mounted) setState(() => _reset()); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQ];
    final isDark = context.isDarkMode;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: _CaptchaCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shield icon with pulsing color bg
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined,
                    color: Color(0xFF1E824C), size: 34),
              ),
              const SizedBox(height: 16),

              // Smooth stretched step dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _currentQ;
                  final done = i < _currentQ;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: done 
                          ? const Color(0xFF1E824C)
                          : active 
                              ? const Color(0xFF1E824C)
                              : isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Verification progress: ${_currentQ + 1} of 3',
                style: GoogleFonts.inter(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Premium styled Math equation box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFFF1F5F9), const Color(0xFFF8FAFC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1E824C).withValues(alpha: 0.16),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'SOLVE THE EQUATION',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: const Color(0xFF1E824C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      q.question,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Tactile options
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: List.generate(q.options.length, (i) {
                  final sel = _selected[_currentQ] == i;
                  return _PressableOption(
                    isSelected: sel,
                    onTap: () => _pick(i),
                    child: Text(
                      '${q.options[i]}',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: sel 
                            ? (isDark ? Colors.white : const Color(0xFF1E824C)) 
                            : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Pick the right answer above to proceed',
                style: GoogleFonts.inter(
                  fontSize: 11.5, 
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Normal Mode: Emoji Grid category selection
// ─────────────────────────────────────────────────────────────────────────────
class _GridCaptcha extends StatefulWidget {
  final VoidCallback onPass;
  final VoidCallback onFail;
  const _GridCaptcha({required this.onPass, required this.onFail});

  @override
  State<_GridCaptcha> createState() => _GridCaptchaState();
}

class _GridCaptchaState extends State<_GridCaptcha> {
  late _GridQ _question;
  late Set<int> _selected;
  bool _submitted = false;
  bool _result = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _question = _GridQ.generate(Random());
    _selected = {};
    _submitted = false;
    _result = false;
  }

  void _toggle(int i) {
    if (_submitted) return;
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
      } else {
        _selected.add(i);
      }
    });
  }

  void _submit() {
    if (_selected.isEmpty) return;
    final correct = _selected.length == _question.correctIndices.length &&
        _selected.containsAll(_question.correctIndices);
    setState(() {
      _submitted = true;
      _result = correct;
    });
    if (correct) {
      Future.delayed(const Duration(milliseconds: 600),
          () { if (mounted) widget.onPass(); });
    } else {
      widget.onFail();
      Future.delayed(const Duration(milliseconds: 900),
          () { if (mounted) setState(() => _load()); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: _CaptchaCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: Color(0xFF1E824C), size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                'Select all categories matching:',
                style: GoogleFonts.inter(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),

              // Category Label tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E824C), Color(0xFF2ECC71)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E824C).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  _question.categoryLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap all matching items, then press Verify',
                style: GoogleFonts.inter(
                  fontSize: 11.5, 
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Grid items using _PressableOption for premium visual clicks
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: List.generate(_question.items.length, (i) {
                  final sel = _selected.contains(i);
                  final isCorrect = _submitted && _question.correctIndices.contains(i);
                  final isWrong = _submitted && _selected.contains(i) && !_question.correctIndices.contains(i);

                  return _PressableOption(
                    isSelected: sel,
                    isCorrect: isCorrect,
                    isWrong: isWrong,
                    onTap: () => _toggle(i),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(_question.items[i],
                            style: const TextStyle(fontSize: 34)),
                        if (sel && !_submitted)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF1E824C),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Verify button with glowing emerald colors
              if (!_submitted) ...[
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selected.isNotEmpty 
                          ? [const Color(0xFF1E824C), const Color(0xFF2ECC71)]
                          : [Colors.grey[400]!, Colors.grey[400]!],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: _selected.isNotEmpty ? [
                      BoxShadow(
                        color: const Color(0xFF1E824C).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ] : [],
                  ),
                  child: ElevatedButton(
                    onPressed: _selected.isNotEmpty ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      'Verify',
                      style: GoogleFonts.outfit(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _result 
                        ? const Color(0xFFE8F8F0) 
                        : const Color(0xFFFEECEB),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _result ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _result ? const Color(0xFF1E824C) : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result ? 'Success! Proceeding...' : 'Incorrect! Loading new challenge...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _result ? const Color(0xFF1E824C) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared premium glassmorphic adaptive card container
// ─────────────────────────────────────────────────────────────────────────────
class _CaptchaCard extends StatelessWidget {
  final Widget child;
  const _CaptchaCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B).withValues(alpha: 0.90) 
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.09)
              : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular back button
// ─────────────────────────────────────────────────────────────────────────────
class _CircleBack extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBack({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.25), width: 1.2),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model: Math question
// ─────────────────────────────────────────────────────────────────────────────
class _MathQ {
  final String question;
  final List<int> options;
  final int answer;

  _MathQ(this.question, this.options, this.answer);

  factory _MathQ.generate(Random rng) {
    final type = rng.nextInt(3);
    int a, b, ans;
    String op;

    switch (type) {
      case 0:
        a = rng.nextInt(18) + 2;
        b = rng.nextInt(18) + 2;
        ans = a + b;
        op = '+';
        break;
      case 1:
        a = rng.nextInt(20) + 10;
        b = rng.nextInt(9) + 1;
        ans = a - b;
        op = '−';
        break;
      default:
        a = rng.nextInt(9) + 2;
        b = rng.nextInt(9) + 2;
        ans = a * b;
        op = '×';
    }

    final wrongs = <int>{};
    while (wrongs.length < 3) {
      final offset = rng.nextInt(10) + 1;
      final candidate = rng.nextBool() ? ans + offset : ans - offset;
      if (candidate != ans && candidate > 0) wrongs.add(candidate);
    }

    final opts = [ans, ...wrongs]..shuffle(rng);
    return _MathQ('$a  $op  $b  =  ?', opts, ans);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model: Emoji grid question
// ─────────────────────────────────────────────────────────────────────────────
typedef _Cat = ({
  String label,
  List<String> correct,
  List<String> distractors
});

class _GridQ {
  final String categoryLabel;
  final List<String> items;
  final Set<int> correctIndices;

  _GridQ(this.categoryLabel, this.items, this.correctIndices);

  factory _GridQ.generate(Random rng) {
    const List<_Cat> pool = [
      (
        label: 'ANIMALS 🐶',
        correct: ['🐶', '🐱', '🐭', '🐰', '🦊', '🐻', '🐼', '🦁', '🐯'],
        distractors: ['🌲', '🍕', '✈️', '🚗', '🏠', '📱', '⚽', '🎸', '🌺']
      ),
      (
        label: 'FRUITS 🍎',
        correct: ['🍎', '🍊', '🍋', '🍇', '🍓', '🍑', '🍒', '🥝', '🍌'],
        distractors: ['🐶', '🚗', '✈️', '🏠', '📱', '⚽', '🌲', '🎸', '💎']
      ),
      (
        label: 'VEHICLES 🚗',
        correct: ['🚗', '🚕', '🚌', '🚑', '✈️', '🚀', '🚂', '🚢', '🏍'],
        distractors: ['🍎', '🐶', '🌲', '🏠', '📱', '⚽', '🎸', '💎', '🍕']
      ),
      (
        label: 'SPORTS ⚽',
        correct: ['⚽', '🏀', '🎾', '🏈', '⚾', '🏐', '🎱', '🏸', '🥊'],
        distractors: ['🐶', '🚗', '✈️', '🍎', '📱', '🌲', '🎸', '💎', '🏠']
      ),
      (
        label: 'FOOD 🍔',
        correct: ['🍕', '🍔', '🌮', '🍜', '🍣', '🍰', '🍩', '🥗', '🌯'],
        distractors: ['🐶', '🚗', '✈️', '⚽', '🌲', '📱', '🎸', '💎', '🏠']
      ),
      (
        label: 'MUSICAL INSTRUMENTS 🎸',
        correct: ['🎸', '🎺', '🎻', '🥁', '🎷', '🎹', '🎤', '🪗', '🪘'],
        distractors: ['🐶', '🚗', '✈️', '🍎', '⚽', '🌲', '📱', '💎', '🏠']
      ),
    ];

    final cat = pool[rng.nextInt(pool.length)];
    final correctPool = List<String>.from(cat.correct)..shuffle(rng);
    final numCorrect = 4 + rng.nextInt(2);
    final pickedCorrect =
        correctPool.take(min(numCorrect, correctPool.length)).toList();
    final distractorPool = List<String>.from(cat.distractors)..shuffle(rng);
    final numDistractors = 12 - pickedCorrect.length;
    final pickedDistractors =
        distractorPool.take(min(numDistractors, distractorPool.length)).toList();
    final all = [...pickedCorrect, ...pickedDistractors]..shuffle(rng);
    while (all.length < 12) {
      all.add('❓');
    }
    final correctSet = <int>{};
    for (var i = 0; i < all.length; i++) {
      if (pickedCorrect.contains(all[i])) correctSet.add(i);
    }
    return _GridQ(cat.label, all.take(12).toList(), correctSet);
  }
}
