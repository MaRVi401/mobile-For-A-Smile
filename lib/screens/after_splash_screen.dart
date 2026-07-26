import 'package:flutter/material.dart';

class AfterSplashScreen extends StatelessWidget {
  const AfterSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            // Header kuning
            Container(
              height: 55,
              width: double.infinity,
              color: const Color(0xFFFDBE00),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Gambar utama
                    SizedBox(
                      width: double.infinity,
                      height: 280,
                      child: Image.asset(
                        'assets/images/after_splash.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Logo
                    Image.asset(
                      'assets/images/fas-logo.png',
                      width: 210,
                    ),

                    const SizedBox(height: 80),

                    // Quote
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: Text(
                        '“Berilah sebagian rezekimu kepada mereka\n'
                        'yang membutuhkan”.\n'
                        'Pantau Donasi mu disini.\n'
                        'Cepat, amanah, dan tepat sasaran.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 90),

                    // Tombol Login
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDBE00),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tombol Register
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDBE00),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Buat akun baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}