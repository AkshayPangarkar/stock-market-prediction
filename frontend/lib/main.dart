import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/data/helper/api_helper.dart';
import 'package:frontend/domain/constants/app_routes.dart';
import 'package:frontend/ui/on_boarding/bloc/user_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => UserBloc(apiHelper: ApiHelper()),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutess(),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:frontend/data/helper/api_helper.dart';
// import 'package:frontend/domain/constants/app_routes.dart';
// import 'package:frontend/ui/dashboard/bloc/stock_bloc.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_bloc.dart';

// void main() {
//   runApp(
//     MultiBlocProvider(
//       providers: [
//         BlocProvider(create: (_) => UserBloc(apiHelper: ApiHelper())),
//         BlocProvider(create: (_) => StockBloc(apiHelper: ApiHelper())),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Stock Predictor',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       initialRoute: AppRoutes.splash,
//       routes: AppRoutes.getRoutess(),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:frontend/data/helper/api_helper.dart';
// import 'package:frontend/domain/constants/app_routes.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_bloc.dart';

// void main() {
//   runApp(BlocProvider(create: ((context) => UserBloc(apiHelper: ApiHelper())),child:MyApp(),));
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: .fromSeed(seedColor: Colors.deepPurple),
//       ),
//       initialRoute: AppRoutes.splash,
//       routes: AppRoutes.getRoutess(),
//     );
//   }
// }

