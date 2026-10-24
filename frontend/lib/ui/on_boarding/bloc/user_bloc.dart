import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/data/helper/api_helper.dart';
import 'package:frontend/data/helper/app_exception.dart';
import 'package:frontend/domain/constants/app_urls.dart';
import 'package:frontend/ui/on_boarding/bloc/user_event.dart';
import 'package:frontend/ui/on_boarding/bloc/user_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final ApiHelper apiHelper;

  UserBloc({required this.apiHelper}) : super(UserInitialState()) {
    on<RegisterUserEvent>((event, emit) async {
      emit(UserLoadingState());
      try {
        await apiHelper.postApi(
          url: AppUrls.registeurl,
          mBodyParams: {
            "username": event.name,
            "email": event.email,
            "password": event.pass,
            "confirm_password": event.pass,
          },
        );
        emit(RegisterSuccessState());
      } catch (e) {
        emit(RegisterFailureState(errorMsg: _readableError(e)));
      }
    });

    on<LoginUserEvent>((event, emit) async {
      emit(UserLoadingState());
      try {
        final data = await apiHelper.postApi(
          url: AppUrls.loginUrl,
          mBodyParams: {"username": event.name, "password": event.pass},
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("access", data["access"]);
        await prefs.setString("refresh", data["refresh"]);

        emit(LoginSuccessState());
      } catch (e) {
        emit(LoginFailureState(errorMsg: _readableError(e)));
      }
    });
  }

  String _readableError(Object e) {
    if (e is NoInternetException) return "Can't reach the server. Check your connection.";

    if (e is AppException) {
      try {
        final decoded = jsonDecode(e.msg);
        if (decoded is Map && decoded.isNotEmpty) {
          final first = decoded.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      } catch (_) {}
      return e.title;
    }
    return e.toString();
  }
}
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:frontend/data/helper/api_helper.dart';
// import 'package:frontend/domain/constants/app_urls.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_event.dart';
// import 'package:frontend/ui/on_boarding/bloc/user_state.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class UserBloc extends Bloc<UserEvent,UserState>{
//   ApiHelper apiHelper;
//   UserBloc({required this.apiHelper}):super(UserInitialState()){

//     on<RegisterUserEvent>((event,emit)async{
//       emit(UserLoadingState());
//       try{
//         dynamic data=await apiHelper.postApi(url:AppUrls.registeurl,mBodyParams: {
//           "username": event.name,
// "email": event.email,
// "password": event.pass,
// "confirm_password": event.pass
//         });

//         if(data['status']){
//           emit(UserSuccessState());
//           // if you want to navigate directly after registering  successfully then store token in prefs 
//         }else{
//           emit(UserFailureState(errorMsg: data["message"]));
//         }
//       }catch(e){
//         emit(UserFailureState(errorMsg: e.toString()));
//       }
//     });

//      on<LoginUserEvent>((event,emit)async{
//       emit(UserLoadingState());
//       try{
//        dynamic data=await apiHelper.postApi(url: AppUrls.loginUrl,mBodyParams: {
        
//     "username": event.name,
//     "password": event.pass

//        });
//        if(data['status']){
//         emit(UserSuccessState());
//         // storing token in prefs
//         // and navigating to home page
//         SharedPreferences prefs= await SharedPreferences.getInstance();
//         prefs.setString("token",data["token"]);
//        }else{
//          emit(UserFailureState(errorMsg: data["message"]));
//        }
//       }catch(e){
//         emit(UserFailureState(errorMsg: e.toString()));
//       }
//     });

//   }
// }