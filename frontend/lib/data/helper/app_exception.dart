class AppException implements Exception{
  String title;
  String msg;
  AppException({
    required this.title,required this.msg,
  });

@override
  String toString() {
    // TODO: implement toString
    return "$title:$msg";
  }
}

class NoInternetException extends AppException{
  NoInternetException({required String msg}):super(title:"NO Internet Connection " ,msg: msg);
}

class UnauthorisedException extends AppException{
  UnauthorisedException({required String msg}):super(title: "Unauthorised",msg: msg);
}

class InvalidInputException extends AppException{
  InvalidInputException({required String msg}):super(title: "Invalid Input",msg: msg);
}

class FetchDataException extends AppException{
  FetchDataException({required String msg}):super(title: "Internal Server Error",msg: msg);
}

class ServerException extends AppException{
  ServerException({required String msg}):super(title: "Internal Server Error",msg: msg);
} 

class BadRequestException extends AppException {
  BadRequestException({required String msg})
      : super(
          title: "Bad Request",
          msg: msg,
        );
}