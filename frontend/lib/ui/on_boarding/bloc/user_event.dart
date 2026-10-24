abstract class UserEvent {}

class LoginUserEvent extends UserEvent{
  String name,pass;
  LoginUserEvent({
    required this.name,
    required this.pass,
  });
}
class RegisterUserEvent extends UserEvent{
  String  name,email,pass;

  RegisterUserEvent({
    required this.name,
    required this.email,
  
    required this.pass,
  });
}
