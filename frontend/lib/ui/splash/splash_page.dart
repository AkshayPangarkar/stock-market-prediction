import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/domain/constants/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _decideRoute);
  }

  Future<void> _decideRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getString("access") != null;
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      loggedIn ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 50),
            Text('Stock Predictor'),
          ],
        ),
      ),
    );
  }
}
// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:frontend/domain/constants/app_routes.dart';


// class SplashPage extends StatefulWidget {

//   @override
//   State<SplashPage> createState() => _SplashPageState();
// }

// class _SplashPageState extends State<SplashPage> {
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     Timer(Duration(seconds: 2),(){
//       Navigator.pushReplacementNamed(context,AppRoutes.login);
//     });
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.bar_chart,size: 50,),
//             Text('Stock Predicator')
//           ],
//         ),
//       ),
//     );
//   }
// }