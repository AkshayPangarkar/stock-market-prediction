import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend/data/helper/app_exception.dart';
import 'package:frontend/domain/constants/app_urls.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiHelper {
  static const _timeout = Duration(seconds: 15);
   static const _slowTimeout = Duration(seconds: 60); 

  Future<dynamic> getApi({required String url, String? token, required Duration timeout}) async {
    return _send(() => http
        .get(Uri.parse(url), headers: _headers(token))
        .timeout(_timeout));
  }
  

  Future<dynamic> postApi({
    required String url,
    Map<String, dynamic>? mBodyParams,
    String? token,
  }) async {
    return _send(() => http
        .post(Uri.parse(url),
            headers: _headers(token), body: jsonEncode(mBodyParams))
        .timeout(_timeout));
  }
   /// GET for protected endpoints: attaches the saved access token,
  /// and if it has expired, refreshes it and retries once.
  Future<dynamic> getAuthApi({required String url}) async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString("access");
    if (access == null) {
      throw UnauthorisedException(msg: "Not logged in");
    }
    try {
      return await getApi(url: url, token: access, timeout: _slowTimeout);
    } on UnauthorisedException {
      final newAccess = await _refreshAccessToken(prefs);
      return await getApi(url: url, token: newAccess, timeout: _slowTimeout);
    }
  }

  Future<String> _refreshAccessToken(SharedPreferences prefs) async {
    final refresh = prefs.getString("refresh");
    if (refresh == null) {
      throw UnauthorisedException(msg: "Session expired");
    }
    try {
      final data = await postApi(
        url: AppUrls.refreshUrl,
        mBodyParams: {"refresh": refresh},
      );
      final access = data["access"] as String;
      await prefs.setString("access", access);
      // only present if ROTATE_REFRESH_TOKENS is on
      if (data["refresh"] != null) {
        await prefs.setString("refresh", data["refresh"]);
      }
      return access;
    } on UnauthorisedException {
      await prefs.remove("access");
      await prefs.remove("refresh");
      throw UnauthorisedException(msg: "Session expired. Please log in again.");
    }
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      return handleResponse(res: response);
    } on AppException {
      rethrow; // keep our typed exceptions intact
    } on SocketException catch (e) {
      throw NoInternetException(msg: e.toString());
    } on http.ClientException catch (e) {
      // what Flutter web throws when the server is unreachable / CORS blocks
      throw NoInternetException(msg: e.toString());
    } on TimeoutException {
      throw FetchDataException(msg: "Request timed out");
    } catch (e) {
      throw FetchDataException(msg: e.toString());
    }
  }

  dynamic handleResponse({required http.Response res}) {
    switch (res.statusCode) {
      case 200:
      case 201:
        return res.body.isEmpty ? null : jsonDecode(res.body);
      case 400:
        throw BadRequestException(msg: res.body);
      case 401:
        throw UnauthorisedException(msg: res.body);
      case 422:
        throw InvalidInputException(msg: res.body);
      default:
        throw ServerException(msg: res.body);
    }
  }
}
// import 'dart:convert';
// import 'dart:io';

// import 'package:frontend/data/helper/app_exception.dart';
// import 'package:http/http.dart' as http;

// class ApiHelper {

//    static const _timeout = Duration(seconds: 15);

//   Future<dynamic> postApi({required String url, Map<String, dynamic>? mBodyParams,String token}) async {
//   try {
//     final response = await http.post(
//       Uri.parse(url),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(mBodyParams),
//     );
//     return handleResponse(res: response);
//   } on SocketException catch (e) {
//     throw NoInternetException(msg: e.toString());
//   } on AppException {
//     rethrow;
//   } catch (e) {
//     throw FetchDataException(msg: e.toString());
//   }
// }

//   // Future<dynamic> postApi({required String url,Map<String,dynamic>?mBodyParams})async{
//   //   try{
//   //     http.Response response =await http.post(Uri.parse(url),body:jsonEncode(mBodyParams));
//   //     return handleResponse(res: response); 
//   //   }on SocketException catch(e){
//   //     throw NoInternetException(msg: e.toString());
//   //   }catch (e){
//   //     throw FetchDataException(msg: e.toString());
//   //   }
//   // }

//   dynamic handleResponse({required http.Response res}){

//     switch(res.statusCode){
//        case 200:{
//         // Success 
//         return jsonDecode(res.body);
//        }
//        case 400:{
//         // Bad Request
//         throw  BadRequestException(msg:res.body);

//        }

//        case 401:{
//         // Unauthorised 
//         throw UnauthorisedException(msg: res.body);
//        }

//        case 422:{
//         // Invalide Input
//         throw InvalidInputException(msg: res.body);
//        }

//        case 500:
//        default:{
//         // Server  error
//         throw ServerException(msg: res.body);
//        }
//     }
//   }
// }