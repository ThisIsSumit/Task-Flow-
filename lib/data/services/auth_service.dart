import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  ConfirmationResult? _webConfirmationResult;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  void _setInitialScreen(User? user) async {
    if (user != null) {
      try {
        final userData = await _firestoreService.getUserData(user.uid);
        userModel.value = userData;
        Get.offAllNamed(Routes.HOME);
      } catch (_) {
        try {
          final bootstrappedUser = _buildUserModelFromFirebaseUser(user);
          await _firestoreService.createUser(bootstrappedUser);
          userModel.value = bootstrappedUser;
          Get.offAllNamed(Routes.HOME);
        } catch (_) {
          Get.offAllNamed(Routes.AUTH);
        }
      }
    } else {
      Get.offAllNamed(Routes.AUTH);
    }
  }

  UserModel _buildUserModelFromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name:
          (user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : 'User ${user.uid.substring(0, 6)}',
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
    );
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        name: name,
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoURL,
      );

      await _firestoreService.createUser(newUser);
      userModel.value = newUser;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isDesktop) {
      throw FirebaseAuthException(
        code: 'unsupported-platform',
        message:
            'Phone OTP is supported on Android, iOS, and Web. Use Android/iOS device or run on Chrome.',
      );
    }

    if (kIsWeb) {
      try {
        _webConfirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
      } catch (_) {
        rethrow;
      }
      return;
    }

    try {
      _verificationId = null;
      final completer = Completer<void>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      await completer.future;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> verifyOtp(String otp) async {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isDesktop) {
      throw FirebaseAuthException(
        code: 'unsupported-platform',
        message:
            'Phone OTP verification is supported on Android, iOS, and Web only.',
      );
    }

    if (kIsWeb) {
      try {
        if (_webConfirmationResult == null) {
          throw FirebaseAuthException(
            code: 'missing-confirmation-result',
            message: 'OTP session expired. Please request a new OTP.',
          );
        }

        final userCredential = await _webConfirmationResult!.confirm(otp);
        final user = userCredential.user!;

        try {
          final userData = await _firestoreService.getUserData(user.uid);
          userModel.value = userData;
        } catch (_) {
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: 'User ${user.uid.substring(0, 6)}',
            phoneNumber: user.phoneNumber,
          );
          await _firestoreService.createUser(newUser);
          userModel.value = newUser;
        }
      } catch (_) {
        rethrow;
      }
      return;
    }

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

      try {
        final userData = await _firestoreService.getUserData(user.uid);
        userModel.value = userData;
      } catch (_) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: 'User ${user.uid.substring(0, 6)}',
          phoneNumber: user.phoneNumber,
        );
        await _firestoreService.createUser(newUser);
        userModel.value = newUser;
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      userModel.value = null;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    var currentUser = userModel.value;
    currentUser ??=
        await (() async {
          final firebase = _auth.currentUser;
          if (firebase == null) {
            throw Exception('User not loaded');
          }

          try {
            return await _firestoreService.getUserData(firebase.uid);
          } catch (_) {
            final bootstrappedUser = _buildUserModelFromFirebaseUser(firebase);
            await _firestoreService.createUser(bootstrappedUser);
            return bootstrappedUser;
          }
        })();

    final updatedUser = UserModel(
      uid: currentUser.uid,
      email: currentUser.email,
      name: name,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      createdAt: currentUser.createdAt,
      taskStats: currentUser.taskStats,
    );

    await _firestoreService.updateUserData(updatedUser);
    userModel.value = updatedUser;
  }

  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  String? getUserId() {
    return _auth.currentUser?.uid;
  }
}
