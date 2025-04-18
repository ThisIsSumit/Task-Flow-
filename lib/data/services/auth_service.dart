import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:todo_app/data/models/user_models.dart';
import 'package:todo_app/routes/app_pages.dart';
import 'firestore_service.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  String? _verificationId;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  void _setInitialScreen(User? user) async {
    print('_setInitialScreen called with user: ${user?.uid}');
    if (user != null) {
      // User is logged in
      try {
        print('Fetching user data for ${user.uid}');
        final userData = await _firestoreService.getUserData(user.uid);
        userModel.value = userData;
        print('User data fetched successfully, navigating to HOME');
        Get.offAllNamed(Routes.HOME);
      } catch (e) {
        print('Error fetching user data: $e');
        Get.offAllNamed(Routes.AUTH);
      }
    } else {
      // User is not logged in
      print('No user found, navigating to AUTH');
      Get.offAllNamed(Routes.AUTH);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('Sign in successful');
    } catch (e) {
      print('Sign in error: $e');
      throw e;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      print('Attempting to sign up with email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      print('Firebase user created with uid: ${user.uid}');

      final newUser = UserModel(uid: user.uid, email: user.email!, name: name);

      print('Creating user document in Firestore');
      await _firestoreService.createUser(newUser);
      userModel.value = newUser;
      print('User document created successfully');
    } catch (e) {
      print('Sign up error: $e');
      throw e;
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    print("this is phone no. : " + phoneNumber);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> verifyOtp(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID not found');
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Create or update user in Firestore
      final userData = await _firestoreService.getUserData(user.uid);
      if (userData == null) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: 'User ${user.uid.substring(0, 6)}',
          phoneNumber: user.phoneNumber,
        );
        await _firestoreService.createUser(newUser);
        userModel.value = newUser;
      } else {
        userModel.value = userData;
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      print('Attempting to sign out');
      await _auth.signOut();
      userModel.value = null;
      print('Sign out successful');
    } catch (e) {
      print('Sign out error: $e');
      throw e;
    }
  }

  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  String? getUserId() {
    print('Getting user ID: ${_auth.currentUser?.uid}');
    return _auth.currentUser?.uid;
  }
}
