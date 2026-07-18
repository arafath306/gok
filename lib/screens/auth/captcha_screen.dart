import 'dart:math';
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
        vsync: this, duration: const Duration(milliseconds: 420));
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
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.85,
              child: Image.asset('assets/auth_bg.png', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.08)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _CircleBack(onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isSignup
                                  ? 'Security Verification'
                                  : 'Quick Check',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.isSignup
                                  ? 'Prove you\'re human to create an account'
                                  : 'Just a quick check before you log in',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.70),
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _CaptchaCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined,
                    color: Color(0xFF1E824C), size: 36),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  Color c;
                  if (i < _currentQ) {
                    c = const Color(0xFF1E824C);
                  } else if (i == _currentQ) {
                    c = const Color(0xFF1E824C).withValues(alpha: 0.5);
                  } else {
                    c = const Color(0xFFE2E8F0);
                  }
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentQ ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: c, borderRadius: BorderRadius.circular(5)),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text('Question ${_currentQ + 1} of 3',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF1E824C).withValues(alpha: 0.18)),
                ),
                child: Text(
                  q.question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: List.generate(q.options.length, (i) {
                  final sel = _selected[_currentQ] == i;
                  return GestureDetector(
                    onTap: () => _pick(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1E824C)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF1E824C)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${q.options[i]}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Text('Select the correct answer',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF94A3B8))),
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _CaptchaCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: Color(0xFF1E824C), size: 36),
              ),
              const SizedBox(height: 14),
              Text('Select all the',
                  style: GoogleFonts.inter(
                      fontSize: 15, color: const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF1E824C).withValues(alpha: 0.25)),
                ),
                child: Text(
                  _question.categoryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E824C),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap all matching items, then press Verify',
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(_question.items.length, (i) {
                  final sel = _selected.contains(i);
                  final isCorrect =
                      _submitted && _question.correctIndices.contains(i);
                  final isWrong = _submitted &&
                      _selected.contains(i) &&
                      !_question.correctIndices.contains(i);

                  Color border;
                  Color bg;
                  if (_submitted) {
                    if (isCorrect) {
                      bg = const Color(0xFF1E824C).withValues(alpha: 0.18);
                      border = const Color(0xFF1E824C);
                    } else if (isWrong) {
                      bg = Colors.red.withValues(alpha: 0.12);
                      border = Colors.red;
                    } else {
                      bg = const Color(0xFFF8FAFC);
                      border = const Color(0xFFE2E8F0);
                    }
                  } else {
                    bg = sel
                        ? const Color(0xFF1E824C).withValues(alpha: 0.14)
                        : const Color(0xFFF8FAFC);
                    border = sel
                        ? const Color(0xFF1E824C)
                        : const Color(0xFFE2E8F0);
                  }

                  return GestureDetector(
                    onTap: () => _toggle(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border, width: 1.8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(_question.items[i],
                              style: const TextStyle(fontSize: 30)),
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
                                    color: Colors.white, size: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (!_submitted) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _selected.isNotEmpty ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF1E824C).withValues(alpha: 0.35),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Verify',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _result ? Icons.check_circle : Icons.cancel,
                      color: _result ? const Color(0xFF1E824C) : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _result ? 'Correct! Loading...' : 'Wrong! Retrying...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _result ? const Color(0xFF1E824C) : Colors.red,
                      ),
                    ),
                  ],
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
// Shared white card container
// ─────────────────────────────────────────────────────────────────────────────
class _CaptchaCard extends StatelessWidget {
  final Widget child;
  const _CaptchaCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.30), width: 1),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: Colors.white, size: 20),
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
        label: 'ANIMALS',
        correct: ['🐶', '🐱', '🐭', '🐰', '🦊', '🐻', '🐼', '🦁', '🐯'],
        distractors: ['🌲', '🍕', '✈️', '🚗', '🏠', '📱', '⚽', '🎸', '🌺']
      ),
      (
        label: 'FRUITS',
        correct: ['🍎', '🍊', '🍋', '🍇', '🍓', '🍑', '🍒', '🥝', '🍌'],
        distractors: ['🐶', '🚗', '✈️', '🏠', '📱', '⚽', '🌲', '🎸', '💎']
      ),
      (
        label: 'VEHICLES',
        correct: ['🚗', '🚕', '🚌', '🚑', '✈️', '🚀', '🚂', '🚢', '🏍'],
        distractors: ['🍎', '🐶', '🌲', '🏠', '📱', '⚽', '🎸', '💎', '🍕']
      ),
      (
        label: 'SPORTS',
        correct: ['⚽', '🏀', '🎾', '🏈', '⚾', '🏐', '🎱', '🏸', '🥊'],
        distractors: ['🐶', '🚗', '✈️', '🍎', '📱', '🌲', '🎸', '💎', '🏠']
      ),
      (
        label: 'FOOD',
        correct: ['🍕', '🍔', '🌮', '🍜', '🍣', '🍰', '🍩', '🥗', '🌯'],
        distractors: ['🐶', '🚗', '✈️', '⚽', '🌲', '📱', '🎸', '💎', '🏠']
      ),
      (
        label: 'MUSICAL INSTRUMENTS',
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
