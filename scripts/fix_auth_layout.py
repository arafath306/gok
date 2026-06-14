
NEW_BUILD_SECTION = '''          // 3. Main fixed (no-scroll) content
          SafeArea(
            child: Column(
              children: [
                // ── Top: back button + mascot + title ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Back button row (signup steps > 1)
                      if (_isSignUp && _signUpStep > 1 && _signUpStep < 4)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10132A),
                              border: Border.all(color: const Color(0xFF2D3050)),
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                              onPressed: () => setState(() => _signUpStep--),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 4),

                      const SizedBox(height: 4),

                      // HERO: Animated pigeon — compact 130px
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _floatController,
                          _glowController,
                          _sparkleController,
                        ]),
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value * 0.5),
                            child: Center(
                              child: SizedBox(
                                height: 130,
                                width: 130,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer glow
                                    Transform.scale(
                                      scale: _glowAnimation.value,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFF7C3AED).withValues(alpha: 0.32),
                                              const Color(0xFF4F46E5).withValues(alpha: 0.14),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Ring stroke
                                    Transform.scale(
                                      scale: _glowAnimation.value * 0.97,
                                      child: Container(
                                        width: 116,
                                        height: 116,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF9B79FF).withValues(alpha: 0.2),
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Pigeon mascot
                                    Image.asset(
                                      "assets/pigeon_logo.png",
                                      height: 110,
                                      width: 120,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 6),

                      // App name
                      Text(
                        "Piagoan",
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Messages. Moments. Together.",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white60,
                          letterSpacing: 0.4,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Error message
                      if (authService.errorMessage != null && _signUpStep < 4)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.red[900]!.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[700]!.withOpacity(0.5)),
                          ),
                          child: Text(
                            authService.errorMessage!,
                            style: GoogleFonts.outfit(color: Colors.red[100], fontSize: 12),
                          ),
                        ),

                      // Step indicator (signup only)
                      if (_isSignUp && _signUpStep < 4) ...[
                        _buildStepIndicator(),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),

                // ── Bottom: auth card fills remaining space ─────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildGlassCard(
                          child: _isSignUp
                              ? (_signUpStep == 1
                                  ? _buildStep1()
                                  : _signUpStep == 2
                                      ? _buildStep2()
                                      : _signUpStep == 3
                                          ? _buildStep3()
                                          : _buildStep7())
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome back! 👋",
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF9B79FF),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Login to continue your journey",
                                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildDarkTextField(
                                      hint: "Email or Username",
                                      controller: _emailPhoneController,
                                      prefixIcon: Icons.mail_outline_rounded,
                                    ),
                                    _buildDarkTextField(
                                      hint: "Password",
                                      controller: _passwordController,
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: _obscureLoginPassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureLoginPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        child: Text(
                                          "Forgot password?",
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF9B79FF),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildGradientButton(
                                      label: "Login",
                                      icon: Icons.arrow_forward,
                                      isLoading: authService.isLoading,
                                      onPressed: _submitLogin,
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                          child: Text(
                                            "or continue with",
                                            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _buildSocialButtons(),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isSignUp = true;
                                              _signUpStep = 1;
                                            });
                                            authService.clearErrors();
                                          },
                                          child: Text(
                                            "Register >",
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF9B79FF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),

                        // Already have account? (signup)
                        if (_isSignUp && _signUpStep < 4) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSignUp = false;
                                    _signUpStep = 1;
                                  });
                                  authService.clearErrors();
                                },
                                child: Text(
                                  "Login",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF9B79FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
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
'''

with open('lib/screens/auth/auth_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find line 938 (0-indexed: 938) = "          // 3. Main scrollable content"
# Find last line of build method = the closing "  }\n" before "}\n" for the class
# We'll replace from line 939 (0-idx 938) to line 1260 (0-idx 1259)

start_idx = None
end_idx = None

for i, line in enumerate(lines):
    if '// 3. Main scrollable content' in line and start_idx is None:
        start_idx = i
    if i > 1200 and line.strip() == '}' and end_idx is None:
        # check next non-empty line
        for j in range(i+1, min(i+5, len(lines))):
            if lines[j].strip():
                if '/// Animated custom painter' in lines[j] or 'class _Atmospheric' in lines[j]:
                    end_idx = i + 1
                break

print(f"Start: {start_idx+1}, End: {end_idx}")

if start_idx and end_idx:
    new_lines = lines[:start_idx] + [NEW_BUILD_SECTION] + lines[end_idx:]
    with open('lib/screens/auth/auth_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Done!")
else:
    print(f"ERROR: could not find range. start={start_idx}, end={end_idx}")
