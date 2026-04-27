import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand colors ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE8FF00);      // electric yellow-green
  static const Color background = Color(0xFF0A0A0A);   // near black
  static const Color surface = Color(0xFF141414);      // card background
  static const Color surfaceAlt = Color(0xFF1E1E1E);   // slightly lighter
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF00E676);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          surface: surface,
          error: error,
        ),
        useMaterial3: true,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),

        // Cards
cardTheme: CardThemeData(
  color: surface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
),

        // Elevated buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Text buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          prefixIconColor: textSecondary,
        ),

        // Bottom nav
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // Text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w900, fontSize: 32),
          headlineMedium: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w800, fontSize: 26),
          titleLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
          titleMedium: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
          bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        ),
      );
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    // ✅ Get controller from Provider — never instantiate directly
    final controller = context.read<AuthController>();

    final success = await controller.register(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // main.dart StreamBuilder handles navigation automatically
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Signup failed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch() so the button disables while loading
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
            const SizedBox(height: 24),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Error message from controller
            if (controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),

            const SizedBox(height: 8),

            // Sign up button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 12),

            // Back to login
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/bookings/bookings_controller.dart';
import 'features/home/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: MaterialApp(
        title: 'Gym Reserve',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark, // ← dark gym theme applied globally
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }

            final user = snapshot.data;

            if (user == null) return const LoginScreen();

            // Inject BookingsController with real Firebase userId
            return ChangeNotifierProvider(
              create: (_) => BookingsController(userId: user.uid),
              child: const HomeScreen(),
            );
          },
        ),
      ),
    );
  }
}


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthState { idle, loading, success, error }

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthState _state = AuthState.idle;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Current logged-in user
  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign In ──────────────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading);

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _setState(AuthState.success);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    } catch (e) {
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading);
  
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _setState(AuthState.success);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    } catch (e) {
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    _setState(AuthState.idle);
  }

  void clearError() {
    _errorMessage = null;
    _state = AuthState.idle;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setState(AuthState state) {
    _state = state;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = AuthState.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<void> login(String trim, String trim2) async {}
}


import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, waitlisted }

class Booking {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String instructor;
  final DateTime classDateTime;
  final DateTime bookedAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.instructor,
    required this.classDateTime,
    required this.bookedAt,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      classDateTime: (data['classDateTime'] as Timestamp).toDate(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'classId': classId,
        'className': className,
        'instructor': instructor,
        'classDateTime': Timestamp.fromDate(classDateTime),
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status.name,
      };

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        userId: userId,
        classId: classId,
        className: className,
        instructor: instructor,
        classDateTime: classDateTime,
        bookedAt: bookedAt,
        status: status ?? this.status,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/gym_class_model.dart';

/// All direct Firestore calls live here — no Firebase logic leaks to other layers.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get _classes => _db.collection('classes');
  CollectionReference get _bookings => _db.collection('bookings');

  // ── Classes ────────────────────────────────────────────────────────────────

  /// Stream of upcoming classes (next 30 days), ordered by dateTime.
Stream<List<GymClass>> streamUpcomingClasses() {
  final now = DateTime.now().subtract(const Duration(hours: 1)); // small buffer
  final monthAhead = now.add(const Duration(days: 30));
  return _classes
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(monthAhead))
      .orderBy('dateTime')
      .snapshots()
      .map((snap) => snap.docs.map(GymClass.fromFirestore).toList());
}

  // ── Bookings ───────────────────────────────────────────────────────────────

  /// Stream of all bookings for a given user.
  /// Stream of all confirmed bookings for a given user.
Stream<List<Booking>> streamUserBookings(String userId) {
  return _bookings
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.confirmed.name)
      .snapshots()
      .map((snap) {
        final bookings = snap.docs.map(Booking.fromFirestore).toList();
        // Sort in Dart to avoid needing a Firestore composite index
        bookings.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
        return bookings;
      });
}

  /// Returns true if the user already has a confirmed booking for [classId].
  Future<bool> hasBooking(String userId, String classId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Books a class using a Firestore transaction to prevent overbooking.
  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) async {
    late Booking newBooking;

    await _db.runTransaction((transaction) async {
      final classRef = _classes.doc(gymClass.id);
      final classSnap = await transaction.get(classRef);

      if (!classSnap.exists) throw Exception('Class not found.');

      final current = (classSnap.data() as Map<String, dynamic>)['currentBookings'] as int;
      final max = (classSnap.data() as Map<String, dynamic>)['maxCapacity'] as int;

      if (current >= max) throw Exception('Class is fully booked.');

      // Create a new booking document reference
      final bookingRef = _bookings.doc();
      newBooking = Booking(
        id: bookingRef.id,
        userId: userId,
        classId: gymClass.id,
        className: gymClass.title,
        instructor: gymClass.instructor,
        classDateTime: gymClass.dateTime,
        bookedAt: DateTime.now(),
        status: BookingStatus.confirmed,
      );

      // Atomic: write booking + increment counter
      transaction.set(bookingRef, newBooking.toMap());
      transaction.update(classRef, {'currentBookings': FieldValue.increment(1)});
    });

    return newBooking;
  }

  /// Cancels a booking and decrements the class counter atomically.
  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _bookings.doc(bookingId);
      final classRef = _classes.doc(classId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) throw Exception('Booking not found.');

      transaction.update(bookingRef, {'status': BookingStatus.cancelled.name});
      transaction.update(classRef, {'currentBookings': FieldValue.increment(-1)});
    });
  }
}

import '../models/booking_model.dart';
import '../models/gym_class_model.dart';
import '../services/booking_service.dart';

/// Repository mediates between controllers and the raw service.
/// Add caching, error mapping, or offline logic here as the app grows.
class BookingRepository {
  final BookingService _service;

  BookingRepository({BookingService? service})
      : _service = service ?? BookingService();

  Stream<List<GymClass>> getUpcomingClasses() =>
      _service.streamUpcomingClasses();

  Stream<List<Booking>> getUserBookings(String userId) =>
      _service.streamUserBookings(userId);

  Future<bool> hasBooking(String userId, String classId) =>
      _service.hasBooking(userId, classId);

  Future<Booking> bookClass({
    required String userId,
    required GymClass gymClass,
  }) =>
      _service.bookClass(userId: userId, gymClass: gymClass);

  Future<void> cancelBooking({
    required String bookingId,
    required String classId,
  }) =>
      _service.cancelBooking(bookingId: bookingId, classId: classId);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gym_class_model.dart';
//import '../../../core/theme/app_theme.dart';

class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBooked;
  final bool isLoading;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBooked,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = gymClass.isFull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                _CategoryBadge(category: gymClass.category),
                const Spacer(),
                _CapacityIndicator(gymClass: gymClass),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title & instructor ───────────────────────────────────────────
            Text(gymClass.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('with ${gymClass.instructor}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 12),

            // ── Time & duration ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gymClass.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${gymClass.durationMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _BookButton(
                isBooked: isBooked,
                isFull: isFull,
                isLoading: isLoading,
                onBook: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _colors = {
    'yoga': Color(0xFF6C63FF),
    'hiit': Color(0xFFFF6B6B),
    'spin': Color(0xFF43BCCD),
    'pilates': Color(0xFFF7C59F),
    'boxing': Color(0xFF1A1A2E),
    'general': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.toLowerCase()] ?? _colors['general']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final GymClass gymClass;
  const _CapacityIndicator({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    final pct = gymClass.currentBookings / gymClass.maxCapacity;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          gymClass.isFull ? 'Full' : '${gymClass.spotsLeft} left',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final bool isLoading;
  final VoidCallback onBook;

  const _BookButton({
    required this.isBooked,
    required this.isFull,
    required this.isLoading,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Booked'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isFull || isLoading ? null : onBook,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(isFull ? 'Class Full' : 'Book Now'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gym_class_model.dart';
import '../bookings_controller.dart';
import '../widgets/class_card.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GymClass>>(
        stream: controller.upcomingClasses,
        builder: (context, classSnap) {
          if (classSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnap.hasError) {
            return _ErrorView(message: classSnap.error.toString());
          }

          final classes = classSnap.data ?? [];
          if (classes.isEmpty) {
            return const _EmptyView(
              icon: Icons.event_busy,
              message: 'No upcoming classes this week.',
            );
          }

          return StreamBuilder(
            stream: controller.userBookings,
            builder: (context, bookingSnap) {
              final bookedClassIds =
                  (bookingSnap.data ?? []).map((b) => b.classId).toSet();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: classes.length,
                itemBuilder: (context, i) {
                  final gymClass = classes[i];
                  return ClassCard(
                    gymClass: gymClass,
                    isBooked: bookedClassIds.contains(gymClass.id),
                    isLoading: controller.isBookingClass(gymClass.id),
                    onBook: () => _handleBook(context, controller, gymClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    BookingsController controller,
    GymClass gymClass,
  ) async {
    final success = await controller.bookClass(gymClass);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Booked "${gymClass.title}" successfully!'
            : controller.errorMessage ?? 'Booking failed.'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!success) controller.clearError();
  }
}

// ── Local helper widgets ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.red)),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = booking.classDateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isPast ? Colors.grey.shade200 : Colors.indigo.shade50,
          child: Icon(
            isPast ? Icons.history : Icons.fitness_center,
            color: isPast ? Colors.grey : Colors.indigo,
          ),
        ),
        title: Text(booking.className,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('with ${booking.instructor}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(booking.classDateTime),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        trailing: isPast
            ? _StatusChip(label: 'Completed', color: Colors.grey)
            : isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correct way — get controller from Provider, not AuthController()
    final controller = context.watch<AuthController>();
    final isLoading = controller.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Gym Reserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (controller.errorMessage != null)
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: () {
                  controller.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign In'
                      : 'No account? Create one',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegisterMode) {
      await controller.register(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }
    // main.dart's StreamBuilder handles navigation automatically on success
  }
}









