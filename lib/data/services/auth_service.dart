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

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  void _setInitialScreen(User? user) async {
    if (user != null) {
      // User is logged in
      try {
        final userData = await _firestoreService.getUserData(user.uid);
        userModel.value = userData;
        Get.offAllNamed(Routes.HOME);
      } catch (e) {
        Get.offAllNamed(Routes.AUTH);
      }
    } else {
      // User is not logged in
      Get.offAllNamed(Routes.AUTH);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw e;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      
      final newUser = UserModel(
        uid: user.uid,
        email: user.email!,
        name: name,
      );
      
      await _firestoreService.createUser(newUser);
      userModel.value = newUser;
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      userModel.value = null;
    } catch (e) {
      throw e;
    }
  }

  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  String? getUserId() {
    return _auth.currentUser?.uid;
  }
}

