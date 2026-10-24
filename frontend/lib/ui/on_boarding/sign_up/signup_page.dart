import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/ui/on_boarding/bloc/user_bloc.dart';
import 'package:frontend/ui/on_boarding/bloc/user_event.dart';
import 'package:frontend/ui/on_boarding/bloc/user_state.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isPassVisible = false;
  bool isConfirmPassVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required IconData icon,
    required String label,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(21)),
    );
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
                  "Create your account",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a username..";
                    } else if (!RegExp(r'^[\w.@+-]+$').hasMatch(value.trim())) {
                      return "Use only letters, digits and @ . + - _ (no spaces)";
                    }
                    return null;
                  },
                  decoration: _decoration(
                    icon: Icons.account_circle_outlined,
                    label: "Username",
                    hint: "Enter username here..",
                  ),
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter your email..";
                    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                      return "Please enter a valid email address..";
                    }
                    return null;
                  },
                  decoration: _decoration(
                    icon: Icons.email_outlined,
                    label: "Email",
                    hint: "Enter email here..",
                  ),
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: passController,
                  obscureText: !isPassVisible,
                  validator: (value) {
                    final passRegExp = RegExp(
                      r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
                    );
                    if (value == null || value.isEmpty) {
                      return "Please enter your password..";
                    } else if (!passRegExp.hasMatch(value)) {
                      return "Min 8 chars with uppercase, lowercase,\ndigit and special character";
                    }
                    return null;
                  },
                  decoration: _decoration(
                    icon: Icons.password_outlined,
                    label: "Password",
                    hint: "Enter password here..",
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => isPassVisible = !isPassVisible),
                      icon: Icon(
                        isPassVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: confirmPassController,
                  obscureText: !isConfirmPassVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please re-enter your password..";
                    } else if (value != passController.text) {
                      return "Password doesn't match..";
                    }
                    return null;
                  },
                  decoration: _decoration(
                    icon: Icons.password_outlined,
                    label: "Confirm password",
                    hint: "Enter confirm password here..",
                    suffix: IconButton(
                      onPressed: () => setState(
                          () => isConfirmPassVisible = !isConfirmPassVisible),
                      icon: Icon(
                        isConfirmPassVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: BlocConsumer<UserBloc, UserState>(
                    listenWhen: (prev, curr) =>
                        curr is RegisterSuccessState ||
                        curr is RegisterFailureState,
                    listener: (context, state) {
                      if (state is RegisterSuccessState) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Account created! Please log in."),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      if (state is RegisterFailureState) {
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
                                        RegisterUserEvent(
                                          name: nameController.text.trim(),
                                          email: emailController.text.trim(),
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
                                  Text('Creating your account...'),
                                ],
                              )
                            : const Text('Sign Up'),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Login",
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
// import 'package:frontend/ui/on_boarding/bloc/user_bloc.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_event.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_state.dart';

// import '../../../domain/constants/app_routes.dart';

// class SignUpPage extends StatefulWidget {
//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   var emailController = TextEditingController();

//   var passController = TextEditingController();

//   var nameController = TextEditingController();

//   var mobNoController = TextEditingController();

//   var confirmPassController = TextEditingController();

//   bool isPassVisible = false;
//   bool isConfirmPassVisible = false;

//   bool isLoading = false;

//   GlobalKey<FormState> formKey = GlobalKey<FormState>();


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
//                   if (value != null && value.isEmpty) {
//                     return "Please enter your name..";
//                   } else {
//                     return null;
//                   }
//                 },
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   prefixIcon: Icon(Icons.account_circle_outlined),
//                   labelText: "Name",
//                   hintText: "Enter name here..",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(21),
//                   ),
//                 ),
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
//                 controller: emailController,
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
//                 validator: (value) {
//                   if (value != null && value.isEmpty) {
//                     return "Please enter your mobile no..";
//                   } else if (value!.length != 10) {
//                     return "Please enter a valid mobile no..";
//                   } else {
//                     return null;
//                   }
//                 },
//                 controller: mobNoController,
//                 decoration: InputDecoration(
//                   prefixIcon: Icon(Icons.call_outlined),
//                   //prefixText: "+91",
//                   prefix: Text("+91  "),
//                   labelText: "Mobile No",
//                   hintText: "Enter mobile no here..",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(21),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 11),
//               TextFormField(
//                 validator: (value) {
//                   RegExp passRegExp = RegExp(
//                     r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
//                   );

//                   if (value != null && value.isEmpty) {
//                     return "Please enter your password..";
//                   } else if (!passRegExp.hasMatch(value!)) {
//                     return "Please enter a strong password \nwhich contains at-least one uppercase,\none lowercase, one digit,\none special character and\ntotal of 8 characters";
//                   } else {
//                     return null;
//                   }
//                 },
//                 obscureText: !isPassVisible,
//                 controller: passController,
//                 decoration: InputDecoration(
//                   suffixIcon: IconButton(
//                     onPressed: () {
//                       isPassVisible = !isPassVisible;
//                       setState(() {});
//                     },
//                     icon: Icon(
//                       isPassVisible ? Icons.visibility : Icons.visibility_off,
//                     ),
//                   ),
//                   prefixIcon: Icon(Icons.password_outlined),
//                   labelText: "Password",
//                   hintText: "Enter password here..",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(21),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 11),
//               TextFormField(
//   validator: (value) {
//     if (value == null || value.isEmpty) {
//       return "Please enter a username..";
//     } else if (!RegExp(r'^[\w.@+-]+$').hasMatch(value)) {
//       return "Use only letters, digits and @ . + - _ (no spaces)";
//     }
//     return null;
//   },
//   controller: nameController,
//   decoration: InputDecoration(
//     prefixIcon: Icon(Icons.account_circle_outlined),
//     labelText: "Username",
//     hintText: "Enter username here..",
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(21),
//     ),
//   ),
// ),
//               // TextFormField(
//               //   validator: (value) {
//               //     if (value != null && value.isEmpty) {
//               //       return "Please re-enter your password..";
//               //     } else if(passController.text!=confirmPassController.text) {
//               //       return "Password doesn't match..";
//               //     } else {
//               //       return null;
//               //     }
//               //   },
//               //   obscureText: !isConfirmPassVisible,
//               //   controller: confirmPassController,
//               //   decoration: InputDecoration(
//               //     suffixIcon: IconButton(
//               //       onPressed: () {
//               //         isConfirmPassVisible = !isConfirmPassVisible;
//               //         setState(() {});
//               //       },
//               //       icon: Icon(
//               //         isConfirmPassVisible
//               //             ? Icons.visibility
//               //             : Icons.visibility_off,
//               //       ),
//               //     ),
//               //     prefixIcon: Icon(Icons.password_outlined),
//               //     labelText: "Confirm password",
//               //     hintText: "Enter confirm password here..",
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
//                   listener: (context, state) {
//                     if (state is UserLoadingState) {
//                       isLoading = true;
//                     }

//                     if (state is UserSuccessState) {
//                       isLoading = false;
//                       Navigator.pop(context);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text("Account created successfully!!"),
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
//                         if(formKey.currentState!.validate()){
//                           context.read<UserBloc>().add(
//                             RegisterUserEvent(
//                               email: emailController.text,
//                               mobNo: mobNoController.text,
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
//                   Text("Already have an account?"),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: Text("Login", style: TextStyle(
//                         fontWeight: FontWeight.bold
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