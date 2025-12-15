import 'package:flutter/material.dart';
import 'package:ainme_vault/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isTermsAccepted = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the size of the screen
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      // Use a Stack to layer the background and the content
      body: Stack(
        children: [
          // 1. Purple Header Background (Fixed at Top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.25,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/logban.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // 2. Centered Scrollable Content
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: size.height * 0.25, bottom: 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min, // Wrap content
                    children: [
                      // Title
                      const Text(
                        "Create an Account",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username Field
                      _buildLabel("Username"),
                      const SizedBox(height: 4),
                      _buildTextField(
                        controller: _usernameController,
                        hintText: "@Jean.McGlynn",
                      ),

                      const SizedBox(height: 12),

                      // Email Field
                      _buildLabel("Email"),
                      const SizedBox(height: 4),
                      _buildTextField(
                        controller: _emailController,
                        hintText: "Example@gmail.com",
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 12),

                      // Password Field
                      _buildLabel("Password"),
                      const SizedBox(height: 4),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: "........",
                        obscureText: true,
                      ),

                      const SizedBox(height: 12),

                      // Terms and Conditions checkbox
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _isTermsAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _isTermsAccepted = value ?? false;
                                });
                              },
                              activeColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: "I agree to the ",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Terms & conditions",
                                    style: TextStyle(
                                      color: AppTheme.primary.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Signup Button
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement signup logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // "Or Sign in with"
                      const Text(
                        "Or Sign in with",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Social Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            label: "Google",
                            image:
                                "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png",
                            onTap: () {},
                          ),
                          const SizedBox(width: 20),
                          _buildSocialButton(
                            label: "Apple",
                            image:
                                "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1667px-Apple_logo_black.svg.png",
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String image,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Image.network(
            image,
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error_outline),
          ),
        ),
      ),
    );
  }
}
