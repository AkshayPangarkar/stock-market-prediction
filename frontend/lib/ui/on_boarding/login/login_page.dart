import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/domain/constants/app_routes.dart';
import 'package:frontend/ui/on_boarding/bloc/user_bloc.dart';
import 'package:frontend/ui/on_boarding/bloc/user_event.dart';
import 'package:frontend/ui/on_boarding/bloc/user_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isPassVisible = false;

  @override
  void dispose() {
    usernameController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(11),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Hi, Welcome back..",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: usernameController,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? "Please enter your username.."
                      : null,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    labelText: "Username",
                    hintText: "Enter username here..",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: passController,
                  obscureText: !isPassVisible,
                  validator: (value) => (value == null || value.isEmpty)
                      ? "Please enter your password.."
                      : null,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.password_outlined),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => isPassVisible = !isPassVisible),
                      icon: Icon(
                        isPassVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    labelText: "Password",
                    hintText: "Enter password here..",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: BlocConsumer<UserBloc, UserState>(
                    listenWhen: (prev, curr) =>
                        curr is LoginSuccessState || curr is LoginFailureState,
                    listener: (context, state) {
                      if (state is LoginSuccessState) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.dashboard);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Logged-in successfully!!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      if (state is LoginFailureState) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.errorMsg),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is UserLoadingState;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  context.read<UserBloc>().add(
                                        LoginUserEvent(
                                          name: usernameController.text.trim(),
                                          pass: passController.text,
                                        ),
                                      );
                                }
                              },
                        child: isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 11),
                                  Text('Logging in...'),
                                ],
                              )
                            : const Text('Login'),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.signUp),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:frontend/domain/constants/app_routes.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_bloc.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_event.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_state.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   var nameController = TextEditingController();

//   var passController = TextEditingController();

//   bool isPassVisible = false;

//   bool isLoading = false;

//   GlobalKey<FormState> formKey = GlobalKey<FormState>();

//   bool isLogin = true;

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(11.0),
//         child: Form(
//           key: formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Hi, Welcome back..",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 11),
//               TextFormField(
//                 validator: (value) {
//                   RegExp emailRegExp = RegExp(
//                     r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
//                   );
//                   if (value != null && value.isEmpty) {
//                     return "Please enter your email..";
//                   }
//                   /// _____@____.___
//                   else if (!emailRegExp.hasMatch(value!)) {
//                     return "Please enter a valid email address..";
//                   } else {
//                     return null;
//                   }
//                 },
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   prefixIcon: Icon(Icons.email_outlined),
//                   labelText: "Email",
//                   hintText: "Enter email here..",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(21),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 11),
//               TextFormField(
//   validator: (value) {
//     if (value == null || value.isEmpty) {
//       return "Please enter your username..";
//     }
//     return null;
//   },
//   controller: nameController,
//   decoration: InputDecoration(
//     prefixIcon: Icon(Icons.person_outline),
//     labelText: "Username",
//     hintText: "Enter username here..",
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(21),
//     ),
//   ),
// ),
//               // TextFormField(
//               //   validator: (value) {
//               //     RegExp passRegExp = RegExp(
//               //       r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
//               //     );

//               //     if (value != null && value.isEmpty) {
//               //       return "Please enter your password..";
          
//               //     } else {
//               //       return null;
//               //     }
//               //   },
//               //   obscureText: !isPassVisible,
//               //   controller: passController,
//               //   decoration: InputDecoration(
//               //     suffixIcon: IconButton(
//               //       onPressed: () {
//               //         isPassVisible = !isPassVisible;
//               //         setState(() {});
//               //       },
//               //       icon: Icon(
//               //         isPassVisible ? Icons.visibility : Icons.visibility_off,
//               //       ),
//               //     ),
//               //     prefixIcon: Icon(Icons.password_outlined),
//               //     labelText: "Password",
//               //     hintText: "Enter password here..",
//               //     border: OutlineInputBorder(
//               //       borderRadius: BorderRadius.circular(21),
//               //     ),
//               //   ),
//               // ),
//               SizedBox(height: 11),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: BlocConsumer<UserBloc, UserState>(
//                   listenWhen: (ps, cs){
//                     return isLogin;
//                   },
//                   buildWhen: (ps, cs){
//                     return isLogin;
//                   },
//                   listener: (context, state) {
//                     if (state is UserLoadingState) {
//                       isLoading = true;
//                     }

//                     if (state is UserSuccessState) {
//                       isLoading = false;
//                       Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text("Logged-in successfully!!"),
//                           backgroundColor: Colors.green,
//                         ),
//                       );
//                     }

//                     if (state is UserFailureState) {
//                       isLoading = false;
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(state.errorMsg),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     }
//                   },
//                   builder: (context, state) {
//                     return ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                       ),
//                       onPressed: () {
//                         isLogin = true;
//                         if (formKey.currentState!.validate()) {
//                           context.read<UserBloc>().add(
//                             LoginUserEvent(
//                               name: nameController.text,
//                               pass: passController.text,
//                             ),
//                           );
//                         }
//                       },
//                       child: isLoading
//                           ? Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.all(5.0),
//                                   child: CircularProgressIndicator(
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 SizedBox(width: 11),
//                                 Text(
//                                   'Creating your account...',
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               ],
//                             )
//                           : Text('Sign Up'),
//                     );
//                   },
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text("Don't have an account?"),
//                   TextButton(
//                     onPressed: () {
//                       isLogin = false;
//                       Navigator.pushNamed(context, AppRoutes.signUp);
//                     },
//                     child: Text("Sign Up", style: TextStyle(
//                       fontWeight: FontWeight.bold
//                     ),),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }