import 'package:captsone_ui/Screens/Homescreen.dart';
import 'package:captsone_ui/Screens/LoginScreen.dart';
import 'package:captsone_ui/Screens/Phonescreen.dart';
import 'package:captsone_ui/Screens/SignupEmail.dart';
import 'package:captsone_ui/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:captsone_ui/Screens/Homepage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Capstone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(),
      routes: {
        EmailPasswordSignup.routeName: (context) => const EmailPasswordSignup(),
        EmailPasswordLogin.routeName: (context) => const EmailPasswordLogin(),
        PhoneScreen.routeName: (context) => const PhoneScreen(),
      },
    );
  }
}
