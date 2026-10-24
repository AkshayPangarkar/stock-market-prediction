import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/data/repository/stock_repository.dart';
import 'package:frontend/ui/dashboard/bloc/stock_bloc.dart';
import 'package:frontend/ui/dashboard/dashboard.dart';
import 'package:frontend/ui/on_boarding/login/login_page.dart';
import 'package:frontend/ui/on_boarding/sign_up/signup_page.dart';
import 'package:frontend/ui/splash/splash_page.dart';

class AppRoutes {
  static const String splash = "/splash";
  static const String login = "/login";
  static const String signUp = "/sign_up";
  static const String dashboard = "/dashboard";

  static Map<String, WidgetBuilder> getRoutess() => {
        splash: (context) => const SplashPage(),
        login: (context) => const LoginPage(),
        signUp: (context) => const SignUpPage(),
        dashboard: (context) => BlocProvider(
              create: (_) => StockBloc(StockRepository()),
              child: const DashboardPage(),
            ),
      };
}
//   import 'package:flutter/material.dart';
// import 'package:frontend/ui/dashboard/dashboard.dart';
//   import 'package:frontend/ui/on_boarding/login/login_page.dart';
//   import 'package:frontend/ui/on_boarding/sign_up/signup_page.dart';
//   import 'package:frontend/ui/splash/splash_page.dart';

//   class AppRoutes {

//     static final String splash="/splash";
//     static final String login="/login";
//     static final String signUp="/sign_up";
//     static final String dashboard="/dashboard";
    

//     static Map<String,WidgetBuilder> getRoutess()=>{
//       splash:(context)=>SplashPage(),
//       login:(conrext)=>LoginPage(), 
//       signUp:(context)=>SignUpPage(),
//       dashboard: (context) => const DashboardPage(),
//     };
//   }