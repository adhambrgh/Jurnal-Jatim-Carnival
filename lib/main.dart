import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'pages/splash_screen.dart';
import 'pages/profil_page.dart';
import 'admin/pages/admin_login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    runApp(const AdminApp());
  } else {
    // ✅ MOBILE = USER APP
    runApp(const MyApp());
  }
}

// =======================
// ADMIN WEB
// =======================

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminLoginPage(),
    );
  }
}

// =======================
// MOBILE APP
// =======================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  void _handleDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      _navigateFromLink(uri);
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _navigateFromLink(uri);
    });
  }

  void _navigateFromLink(Uri uri) {
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'post') {
      final postId = uri.pathSegments[1];

      debugPrint('🔗 Deep link postId: $postId');

      _openPostById(postId);
    }
  }

  Future<void> _openPostById(String postId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('post')
          .doc(postId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => PostDetailFromFirestore(postData: data),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error open post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
