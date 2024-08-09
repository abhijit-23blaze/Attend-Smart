// import 'package:flutter/material.dart';
//
// import 'ui/home.dart';
//
// void main() => runApp(const MaterialApp(
//   debugShowCheckedModeBanner: false,
//   title: "Quiz dApp",
//   home: Home(),
// ));

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'attendance_page.dart'; // Import the new attendance page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;
  Future<bool>? _authenticationFuture;

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (bool isSupported) => setState(() => _supportState = isSupported
          ? _SupportState.supported
          : _SupportState.unsupported),
    );
  }

  Future<bool> _authenticateWithBiometrics() async {
    setState(() {
      _isAuthenticating = true;
      _authorized = 'Authenticating';
    });

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint (or face or whatever) to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });
    }

    setState(() {
      _isAuthenticating = false;
      _authorized = authenticated ? 'Authorized' : 'Not Authorized';
    });

    return authenticated;
  }

  @override
  Widget build(BuildContext context) {
    // Define a list of subjects and attendance for demonstration
    final subjects = [
      {'name': 'OS', 'attendance': '90%'},
      {'name': 'ADSA', 'attendance': '85%'},
      {'name': 'RANAC', 'attendance': '80%'},
      {'name': 'DBMS', 'attendance': '95%'},
      {'name': 'OOP', 'attendance': '88%'},
      {'name': 'SEED', 'attendance': '92%'},
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Block Roll'),
          elevation: 8.0, // Add shadow by increasing the elevation
        ),
        body: Center(
          child: FutureBuilder<bool>(
            future: _authenticationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.data == true) {
                return const QRViewExample(); // Navigate to AttendancePage
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Number of cards per row
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        padding: const EdgeInsets.all(16.0),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return Card(
                            elevation: 4.0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    subject['name']!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Attendance: ${subject['attendance']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: ElevatedButton(

                        onPressed: () {
                          setState(() {
                            _authenticationFuture = _authenticateWithBiometrics();
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(_isAuthenticating
                                ? 'Cancel'
                                : 'Authenticate: biometrics only'),
                            const Icon(Icons.fingerprint),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

