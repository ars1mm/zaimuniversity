import 'package:flutter/material.dart';

void main() => runApp(const CampusInfoSystemApp());

class CampusInfoSystemApp extends StatelessWidget {
  const CampusInfoSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Information System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _passwordVisible = false;
  final TextEditingController _emailController =
      TextEditingController(text: "b30724109@std.izu.edu.tr");
  final TextEditingController _passwordController =
      TextEditingController(text: "••••••••");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // University Logo
                Image.network(
                  'https://www.izu.edu.tr/images/default-source/logo-galeri/1.jpg?sfvrsn=18698650_2',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),

                // Campus Information System Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, color: Colors.grey[700], size: 22),
                    const SizedBox(width: 5),
                    Text(
                      'Campus Information System',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Divider Line
                Container(
                  height: 2,
                  color: Colors.blue[700],
                ),

                // White Space
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Enter Your Login Information',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Input
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            prefixIcon:
                                Icon(Icons.person, color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Password Input
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            prefixIcon:
                                Icon(Icons.lock, color: Colors.grey[400]),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Login Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Login - Sign In',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.arrow_forward,
                                    size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Create Account Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Create account',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'I forgot my password',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                // Graduate Student Login
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Graduate student login',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),

                // Course Enrollment Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498db),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Click for course enrollment and advisor approval',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          '.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
