abstract class UserState {}

class UserInitialState extends UserState {}

class UserLoadingState extends UserState {}

class LoginSuccessState extends UserState {}

class LoginFailureState extends UserState {
  final String errorMsg;
  LoginFailureState({required this.errorMsg});
}

class RegisterSuccessState extends UserState {}

class RegisterFailureState extends UserState {
  final String errorMsg;
  RegisterFailureState({required this.errorMsg});
}
// abstract class UserState {}

// class UserInitialState extends UserState{}
// class UserLoadingState extends UserState{}
// class UserSuccessState extends UserState{}
// class UserFailureState extends UserState{
//   String errorMsg;
//   UserFailureState({required this.errorMsg});
// }