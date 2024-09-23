import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth/auth_gate.dart';
import 'services/notifications/notification_service.dart';
import 'theme/theme_provider.dart';


void main() async {


  // setup firebase
  WidgetsFlutterBinding.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){  await Firebase.initializeApp(options: FirebaseOptions(  apiKey: "AIzaSyAaZ7p1AzLSi6nRggzvOUf7ejmeWimgU18",
  authDomain: "flutter-chat-app-76e99.firebaseapp.com",
  projectId: "flutter-chat-app-76e99",
  storageBucket: "flutter-chat-app-76e99.appspot.com",
  messagingSenderId: "396777131620",
  appId: "1:396777131620:web:88f50098fbb0f6567b9971",
  measurementId: "G-4T3ZMCT1Z5"));}
  else{
    await Firebase.initializeApp();
  }


  // setup notification background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // request notification permission
  final noti = NotificationService();
  await noti.requestPermission();
  noti.setupInteractions();

  // run app
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// NOTIFICATION BACKGROUND HANDLER
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
  print("Message notification: ${message.notification?.title}");
  print("Message notification: ${message.notification?.body}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: const AuthGate(),
      theme: Provider.of<ThemeProvider>(context).themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
      },
    );
  }
}
