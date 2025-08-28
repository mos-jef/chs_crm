import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBsBvZn4RAOQkTJ82GzU2bTYzzYSUXODxQ",
        authDomain: "chs-crm.firebaseapp.com",
        projectId: "chs-crm",
        storageBucket: "chs-crm.firebasestorage.app",
        messagingSenderId: "507014107846",
        appId: "1:507014107846:web:ec01bc2cdb9982287a3dc7",
      ),
    );
  }
}
