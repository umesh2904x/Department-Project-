import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/reminder_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/notifications_screen.dart';
import 'screens/send_notification_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/timetable_builder_screen.dart';
import 'screens/admin/room_availability_screen.dart';
import 'screens/admin/faculty_availability_screen.dart';
import 'screens/admin/faculty_management_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/lecture_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    debugPrint("Handling a background message: ${message.messageId}");
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase if applicable
  try {
    if (!kIsWeb) {
await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization skipped: $e");
  }

  // Initialize local notifications
  await ReminderService.initializeNotifications();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LectureProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'CSE (Data Science) Timetable',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple.shade100,
                primary: Colors.deepPurple.shade300,
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            home: const InitialAuthResolver(),
            routes: {
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/student': (context) => const StudentDashboard(),
              '/teacher': (context) => const TeacherDashboard(),
              '/admin': (context) => const AdminDashboard(),
              '/admin/timetable_builder': (context) => const TimetableBuilderScreen(),
              '/admin/room_availability': (context) => const RoomAvailabilityScreen(),
              '/admin/faculty_availability': (context) => const FacultyAvailabilityScreen(),
              '/admin/faculty_management': (context) => const FacultyManagementScreen(),
              '/send_notification': (context) => const SendNotificationScreen(),
              '/notifications': (context) => const NotificationsScreen(),
            },
          );
        },
      ),
    );
  }
}

class InitialAuthResolver extends StatelessWidget {
  const InitialAuthResolver({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // If still resolving authentication status, show a clean purple loading screen
    if (auth.isCheckingStatus) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (auth.isLoggedIn) {
      final role = auth.user?.role;
      if (role == 'admin') {
        return const AdminDashboard();
      } else if (role == 'teacher') {
        return const TeacherDashboard();
      } else {
        return const StudentDashboard();
      }
    }
    return const WelcomeScreen();
  }
}