// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Cloud extends GetxService {
  GetStorage statusAcc = GetStorage();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFunctions functions = FirebaseFunctions.instanceFor();
  GoogleSignIn googleIn = GoogleSignIn();
  Map<String, dynamic> output = {}, dataUser = {};
  String? message, error, system, condition, role, status, platform;
  String? get currUser => auth.currentUser?.email;
  String? get uid => auth.currentUser?.uid;
  String? get photoURL => auth.currentUser?.photoURL;
  String? get displayName => auth.currentUser?.displayName;
  bool? isReal;
  RxString token = "".obs;
  RxBool isSignedIn = false.obs;
  UserCredential? userSecret;
  late Rx<User?> user;

  Future<Cloud> init() async {
    auth.userChanges().listen((User? user) async {
      if (user == null) {
        log("Firebase => User is currently signed out!");
      } else {
        if (isSignedIn.value == true) {
          log("");
        } else {
          log("Firebase => User signs in");
        }
      }
    });
    return this;
  }

  Future<Map<String, dynamic>> signUpWithGoogle() async {
    Map<String, dynamic> result = {};
    try {
      final GoogleSignInAccount? googleUser = await googleIn.signIn();
      if (googleUser == null) {
        output = {
          "system": "cancel",
          "message": "The sign in process is cancelled by user",
          "error": "cancel",
        };
      } else {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        await auth.signInWithCredential(credential).then((values) async {
          userSecret = values;
          await authGoogle(values).then((value) {
            if (value.isNotEmpty) {
              result = Map<String, dynamic>.from(value);
            } else {
              log("Output from function authGoogle is empty [Toggle Emulator]");
            }
          });
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code.toString() == "sign_in_canceled") {
        result = {
          "system": "cancel",
          "message": "The sign in process is cancelled by user",
          "error": "cancel",
        };
      } else {
        result = {
          "system": "Firebase Auth Exception",
          "message": e.message.toString(),
          "error": e.code.toString(),
        };
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> authGoogle(UserCredential credential) async {
    Map<String, dynamic> result = {};
    await getToken(credential).then((value) => token.value = value);
    await registerUser(credential).then((value) => result = Map<String, dynamic>.from(value));
    return result;
  }

  Future<String> getToken(UserCredential credential) async {
    String? data;
    try {
      await credential.user!.getIdToken(true).then((value) {
        data = value;
        token.value = data!;
      });
    } on FirebaseAuthException catch (e) {
      output = {
        "system": "Firebase Auth Exception",
        "message": e.message.toString(),
        "error": e.code.toString(),
      };
    }
    return data!;
  }

  Future<Map<String, dynamic>> registerUser(UserCredential credential) async {
    Map<String, dynamic> result = {};
    try {
      HttpsCallable userAuth = functions.httpsCallable("ServerSignUp");
      dataUser = {
        "name": displayName,
        "email": currUser,
      };
      await userAuth.call(dataUser).then((response) async {
        system = response.data['system'];
        if (system == "success") {
          message = response.data['message'];
        } else if (system == "error") {
          message = response.data['message'];
          result = {
            "system": "error",
            "message": message,
            "error": response.data['error'],
          };
        }
      });
    } on FirebaseFunctionsException catch (e) {
      result = {
        "system": "Cloud Function Exception",
        "message": "${e.message.toString()}\n${e.details.toString()}",
        "error": e.code.toString(),
      };
    }
    return result;
  }

  Future<Map<String, dynamic>> signOutWithGoogle() async {
    Map<String, dynamic> result = {};
    try {
      await googleIn.signOut();
      await auth.signOut();
    } on FirebaseFunctionsException catch (e) {
      message = "${e.message.toString()} - ${e.details.toString()}";
      result = {
        "system": "Cloud Function Exception",
        "message": message,
        "error": e.code.toString(),
      };
    }
    return result;
  }
}
