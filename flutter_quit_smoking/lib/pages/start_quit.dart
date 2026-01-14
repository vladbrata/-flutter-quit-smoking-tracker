import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StartQuit extends StatelessWidget {
  const StartQuit({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Take Back Control',
              style: TextStyle(
                fontSize: 18.0,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(height: 5.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(300, 70),
                backgroundColor: const Color.fromARGB(255, 168, 10, 10),
              ),
              onPressed: () {},
              child: Text(
                'Quit',
                style: TextStyle(
                  fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
                  fontSize: 60.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
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
