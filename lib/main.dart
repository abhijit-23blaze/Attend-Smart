import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'attendance_page.dart';

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


  // Method to show the Profile Dialog
  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ListTile(
                leading: Icon(Icons.person, color: Colors.deepPurple),
                title: Text('Abhijit Patil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                subtitle: Text('Student'),
              ),
              ListTile(
                leading: Icon(Icons.confirmation_number, color: Colors.deepPurple),
                title: Text('Roll No.: 20332', style: TextStyle(fontSize: 16)),
              ),
              ListTile(
                leading: Icon(Icons.school, color: Colors.deepPurple),
                title: Text('Department: Electroincs', style: TextStyle(fontSize: 16)),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.deepPurple),
                title: Text('Year: 2nd', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close', style: TextStyle(color: Colors.deepPurple)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = [
      {'name': 'OS', 'attendance': '90%'},
      {'name': 'ADSA', 'attendance': '85%'},
      {'name': 'RANAC', 'attendance': '80%'},
      {'name': 'DBMS', 'attendance': '95%'},
      {'name': 'OOP', 'attendance': '88%'},
      {'name': 'SEED', 'attendance': '92%'},
    ];

    return MaterialApp(

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Attend Smart',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 0,
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.person, size: 28),
                  onPressed: () => _showProfileDialog(context),
                ),
                const SizedBox(width: 10),
              ],
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
                    return const QRViewExample();
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[

                        Expanded(

                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                            ),
                            padding: const EdgeInsets.all(16.0),
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              return Card(
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        subject['name']!,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                      const SizedBox(height: 12.0),
                                      Text(
                                        'Attendance: ${subject['attendance']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
                              textStyle: const TextStyle(fontSize: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _authenticationFuture = _authenticateWithBiometrics();
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  _isAuthenticating ? 'Cancel' : 'Attend',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.fingerprint, size: 28),
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
          );
        },
      ),
    );
  }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}