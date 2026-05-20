import 'package:flutter/material.dart';
import 'login_screen.dart'; // ✅ Make sure this file exists

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, String>> data = [
    {
      "image": "assets/images/onboard1.png",
      "title": "Smart Tracking\nwith RFID",
      "desc":
          "Instantly scan assets with an RFID reader and get real-time details including ID, name, and status."
    },
    {
      "image": "assets/images/onboard2.png",
      "title": "Effortless Requests\n& Approvals",
      "desc":
          "Submit requests and get notified instantly. Approve or reject with full transparency."
    },
    {
      "image": "assets/images/onboard3.png",
      "title": "Reported Issues &\nReal-time Alerts",
      "desc":
          "Report damaged or missing items instantly and get real-time alerts."
    },
  ];

  void nextPage() {
    if (currentIndex < data.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // ✅ Navigate to Login Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: currentIndex == index ? 24 : 8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  void skip() {
    // ✅ Skip directly to login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A6FE2), Color(0xFF1C3FAA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// 🔹 Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: skip,
                      child: const Text(
                        "Skip",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),

              /// 🔹 PageView
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: data.length,
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// IMAGE
                          Image.asset(
                            data[index]["image"]!,
                            height: 220,
                          ),

                          const SizedBox(height: 40),

                          /// TITLE
                          Text(
                            data[index]["title"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// DESCRIPTION
                          Text(
                            data[index]["desc"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              /// 🔹 DOT INDICATOR
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    List.generate(data.length, (index) => buildDot(index)),
              ),

              const SizedBox(height: 30),

              /// 🔹 BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    currentIndex == data.length - 1
                        ? "Get Started"
                        : "Continue",
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
