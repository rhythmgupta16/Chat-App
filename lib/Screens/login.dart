import 'dart:async';
import 'package:ChatApp/Screens/register.dart';
import 'package:ChatApp/Widgets/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgotPassword.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  //Intialize variables
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  TextEditingController emailInputController;
  TextEditingController pwdInputController;

  bool isLoading = false;
  bool isLoggedIn = false;
  User currentUser;

  //Call isSignedIn() on opening app
  @override
  void initState() {
    emailInputController = new TextEditingController();
    pwdInputController = new TextEditingController();
    super.initState();
    isSignedIn();
  }

  //Validate Email input
  String emailValidator(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Email format is invalid';
    } else {
      return null;
    }
  }

  //Validate Password input
  String pwdValidator(String value) {
    if (value.length < 8) {
      return 'Password must be longer than 8 characters';
    } else {
      return null;
    }
  }

  //Check if the user has signed in before
  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HomeScreen(currentUserId: prefs.getString('id'))),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }

  //Google Sign In
  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    User firebaseUser =
        (await firebaseAuth.signInWithCredential(credential)).user;

    if (firebaseUser != null) {
      // Check is already sign up
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .get();
      final List<DocumentSnapshot> documents = result.docs;
      if (documents.length == 0) {
        // Update data to server if new user
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'nickname': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoURL,
          'id': firebaseUser.uid,
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'chattingWith': null
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoURL);
      } else {
        // Write data to local
        await prefs.setString('id', documents[0].data()['id']);
        await prefs.setString('nickname', documents[0].data()['nickname']);
        await prefs.setString('photoUrl', documents[0].data()['photoUrl']);
        await prefs.setString('aboutMe', documents[0].data()['aboutMe']);
      }
      Fluttertoast.showToast(msg: "Sign in success");
      this.setState(() {
        isLoading = false;
      });

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(currentUserId: firebaseUser.uid)));
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        isLoading = false;
      });
    }
  }

  //Sign In via Email
  Future<Null> handleEmailSignIn() async {
    prefs = await SharedPreferences.getInstance();

    if (emailInputController.text.isEmpty || pwdInputController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please fill in all details first!", textColor: Colors.yellow);
    } else {
      this.setState(() {
        isLoading = true;
      });
      User firebaseUser = (await firebaseAuth.signInWithEmailAndPassword(
        email: emailInputController.text,
        password: pwdInputController.text,
      ))
          .user;

      if (firebaseUser != null) {
        // Check is already sign up
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: firebaseUser.uid)
            .get();

        final List<DocumentSnapshot> documents = result.docs;
        if (documents.length == 0) {
          Fluttertoast.showToast(msg: "Register First");
        } else {
          // Write data to local
          await prefs.setString('id', documents[0].data()['id']);
          await prefs.setString('nickname', documents[0].data()['nickname']);
          await prefs.setString('photoUrl', documents[0].data()['photoUrl']);
          await prefs.setString('aboutMe', documents[0].data()['aboutMe']);
        }
        Fluttertoast.showToast(msg: "Sign in success");
        this.setState(() {
          isLoading = false;
        });

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HomeScreen(currentUserId: firebaseUser.uid)));
      } else {
        Fluttertoast.showToast(msg: "Sign in fail");
        this.setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff9C27B0), Color(0xff03A9F4)],
            ),
          ),
          child: Column(
            children: <Widget>[
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  "LOGIN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xffE1BEE7),
                  ),
                ),
                centerTitle: true,
                // Actions are identified as buttons which are added at the right of App Bar
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('images/logo.png'),
                  )
                ],
              ),
              ClipPath(
                // ClipPath is used to clip the child in a custom shape
                clipper: BottomClipper(),
                // here is the custom clipper for bottom cut shape
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(top: 40, bottom: 30),
                  margin: EdgeInsets.only(top: 30, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          offset: Offset(1, 2),
                          spreadRadius: 1.0,
                          blurRadius: 5.0)
                    ],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: <Widget>[
                      // Email input
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email),
                              labelText: 'Email'),
                          controller: emailInputController,
                          keyboardType: TextInputType.emailAddress,
                          validator: emailValidator,
                        ),
                      ),
                      // Password input
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            labelText: 'Password',
                            suffixIcon: Icon(Icons.remove_red_eye),
                          ),
                          controller: pwdInputController,
                          obscureText: true,
                          validator: pwdValidator,
                        ),
                      ),
                      // Forgot password
                      Container(
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 18.0),
                          child: InkWell(
                            // InkWell widget makes the widget clickable and provide call back for touch events
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordPage()));
                            },
                            child: Text(
                              'Forgot Password?',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: Color(0xff536DFE),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Login using mobile number
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: InkWell(
                          onTap: () {
                            Fluttertoast.showToast(msg: "Sign in with Phone");
                          },
                          child: RichText(
                            // RichText is used to styling a particular text span in a text by grouping them in one widget
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              text: 'Login using ',
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Mobile Number and OTP',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Submit button for login details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              //if (_loginFormKey.currentState.validate()) {
                              handleEmailSignIn();
                              //}
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 20, top: 10),
                              decoration: BoxDecoration(
                                  color: Color(0xffE1BEE7),
                                  borderRadius: BorderRadius.circular(30)),
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.navigate_next,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              ClipPath(
                clipper:
                    TopClipper(), // Custom Clipper for top clipping the social login menu box
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(top: 50, bottom: 50),
                  margin: EdgeInsets.only(left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          offset: Offset(1, 2),
                          spreadRadius: 1.0,
                          blurRadius: 5.0),
                    ],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Or",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xff898989),
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Google login
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Material(
                              child: FlatButton(
                                onPressed: handleSignIn,
                                child: Text(
                                  'SIGN IN WITH GOOGLE',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                color: Color(0xffdd4b39),
                                highlightColor: Color(0xffff7f7f),
                                splashColor: Colors.transparent,
                                textColor: Colors.white,
                                padding:
                                    EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              // Register
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Click here to signup",
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // Loading
              Center(
                child: isLoading ? const Loading() : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Clipper Class
class BottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Add Path lines to form slight cut
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height - 50);
    return path;
  }

  // we don't need to render it again and again as UI renders
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(size.width, 50);
    path.lineTo(size.width, size.height + 10);
    path.lineTo(0, size.height + 10);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
