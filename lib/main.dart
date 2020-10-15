import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:jwt_decode/jwt_decode.dart';

final userPool = new CognitoUserPool('プールID', 'アプリクライアントID');

CognitoUserSession session;

// CognitoのユーザーID取得方法
final idToken = session.getIdToken().jwtToken;
final cognitoIdToken = CognitoIdToken(idToken);
final payload = Jwt.parseJwt(cognitoIdToken.getJwtToken());
final userId = payload['sub'];

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'login sample app',
        routes: <String, WidgetBuilder>{
          '/': (_) => new MyHomePage(),
          '/TopPage': (_) => new TopPage(),
          '/RegisterUser': (_) => new RegisterUserPage(),
          '/ConfirmRegistration': (_) => new ConfirmRegistration(null),
          '/ForgotPassword': (_) => new ForgotPassword(),
          '/LoginByGoogle': (_) => new LoginByGoogle(),
        });
  }
}

class MyHomePage extends StatelessWidget {
  final _mailAddressController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ログイン'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'test@example.com',
                  labelText: 'メールアドレス',
                ),
                controller: _mailAddressController,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'password',
                  labelText: 'パスワード',
                ),
                obscureText: true,
                controller: _passwordController,
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.all(8.0),
              child: RaisedButton(
                child: Text('ログイン'),
                color: Colors.indigo,
                shape: StadiumBorder(),
                textColor: Colors.white,
                onPressed: () => _signIn(context),
              ),
            ),
            Divider(
              color: Colors.black,
            ),
            RaisedButton(
              child: Text('新しいアカウントの作成'),
              color: Colors.indigo,
              textColor: Colors.white,
              shape: StadiumBorder(),
              // routing
              onPressed: () => Navigator.of(context).pushNamed('/RegisterUser'),
            ),
            Divider(color: Colors.black),
            InkWell(
              child: Text(
                'パスワードを忘れた方はこちら',
                style: TextStyle(
                    color: Colors.purple, decoration: TextDecoration.underline),
              ),
              onTap: () => Navigator.of(context).pushNamed('/ForgotPassword'),
            ),
            Divider(
              color: Colors.black,
            ),
            RaisedButton(
              child: Text('Googleでログイン'),
              color: Colors.indigo,
              textColor: Colors.white,
              shape: StadiumBorder(),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/LoginByGoogle'),
            ),
          ],
        ),
      ),
    );
  }

  void _signIn(BuildContext context) async {
    var cognitoUser = new CognitoUser(_mailAddressController.text, userPool);
    var authDetails = new AuthenticationDetails(
      username: _mailAddressController.text,
      password: _passwordController.text,
    );
    try {
      session = await cognitoUser.authenticateUser(authDetails);
      Navigator.of(context).pushReplacementNamed('/TopPage');
    } catch (e) {
      await showDialog<int>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('エラー'),
              content: Text(e.message),
              actions: [
                FlatButton(
                  onPressed: () => Navigator.of(context).pop(1),
                  child: Text('OK'),
                ),
              ],
            );
          });
    }
  }
}

class RegisterUserPage extends StatelessWidget {
  final _mailAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('アカウント作成'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'test@example.com',
                  labelText: 'メールアドレス',
                ),
                controller: _mailAddressController,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'password',
                  labelText: 'パスワード',
                ),
                obscureText: true,
                controller: _passwordController,
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.all(8.0),
              child: RaisedButton(
                child: Text('登録'),
                color: Colors.indigo,
                shape: StadiumBorder(),
                textColor: Colors.white,
                onPressed: () => _signUp(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _signUp(BuildContext context) async {
    try {
      CognitoUserPoolData userPoolData = await userPool.signUp(
          _mailAddressController.text, _passwordController.text);
      Navigator.push(
        context,
        new MaterialPageRoute<Null>(
          settings: const RouteSettings(name: '/ConfirmRegistration'),
          builder: (BuildContext context) => ConfirmRegistration(userPoolData),
        ),
      );
    } on CognitoClientException catch (e) {
      await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('エラー'),
            content: Text(e.message),
            actions: [
              FlatButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(1),
              ),
            ],
          );
        },
      );
    }
  }
}

class ConfirmRegistration extends StatelessWidget {
  final _registrationController = TextEditingController();
  final CognitoUserPoolData _userPoolData;

  ConfirmRegistration(this._userPoolData);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('レジストレーションキー確認'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_userPoolData.user.username),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'レジストレーションコード',
                  labelText: 'レジストレーションコード',
                ),
                obscureText: true,
                controller: _registrationController,
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8.0),
              child: RaisedButton(
                child: Text('確認'),
                color: Colors.indigo,
                shape: StadiumBorder(),
                textColor: Colors.white,
                onPressed: () => _confirmRegistration(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRegistration(BuildContext context) async {
    try {
      await _userPoolData.user
          .confirmRegistration(_registrationController.text);
      await showDialog<int>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('登録完了'),
              content: Text('ユーザーの登録が完了しました'),
              actions: [
                FlatButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).popUntil(
                    ModalRoute.withName('/'),
                  ),
                ),
              ],
            );
          });
    } on CognitoClientException catch (e) {
      await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('エラー'),
            content: Text(e.message),
            actions: [
              FlatButton(
                onPressed: () => Navigator.of(context).pop(1),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

class TopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('トップページ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ログイン成功'),
            Divider(
              color: Colors.black,
            ),
            Text(userId),
          ],
        ),
      ),
    );
  }
}

class ForgotPassword extends StatelessWidget {
  final _mailAddressController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('パスワードリセット'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'test@example.com',
                  labelText: 'メールアドレス',
                ),
                controller: _mailAddressController,
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.all(8.0),
              child: RaisedButton(
                child: Text('リセットコード送信'),
                color: Colors.indigo,
                shape: StadiumBorder(),
                textColor: Colors.white,
                onPressed: () => _forgotPassword(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _forgotPassword(BuildContext context) async {
    final cognitoUser = new CognitoUser(_mailAddressController.text, userPool);
    try {
      var response = await cognitoUser.forgotPassword();
      print(response);
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('パスワードリセット'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('メールで受信したリセット用のコードと新しいパスワードを入力してください'),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'リセットコード',
                          labelText: 'リセットコード',
                        ),
                        obscureText: true,
                        controller: _resetCodeController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '新しいパスワード',
                          labelText: '新しいパスワード',
                        ),
                        obscureText: true,
                        controller: _passwordController,
                      ),
                    ),
                    ButtonBar(
                      buttonPadding: const EdgeInsets.all(8.0),
                      mainAxisSize: MainAxisSize.max,
                      alignment: MainAxisAlignment.center,
                      children: [
                        RaisedButton(
                          child: Text('リセット'),
                          color: Colors.indigo,
                          shape: StadiumBorder(),
                          textColor: Colors.white,
                          onPressed: () async {
                            try {
                              response = await cognitoUser.confirmPassword(
                                  _resetCodeController.text,
                                  _passwordController.text);
                              Navigator.of(context)
                                  .popUntil(ModalRoute.withName('/'));
                            } catch (e) {
                              print(e);
                            }
                          },
                        ),
                        RaisedButton(
                          child: Text('キャンセル'),
                          color: Colors.red,
                          shape: StadiumBorder(),
                          textColor: Colors.white,
                          onPressed: () => Navigator.of(context).pop(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
    } catch (e) {
      await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('エラー'),
            content: Text(e.message),
            actions: [
              FlatButton(
                onPressed: () => Navigator.of(context).pop(1),
                child: Text('OK'),
              )
            ],
          );
        },
      );
    }
  }
}

class LoginByGoogle extends StatelessWidget {
  final Completer<WebViewController> _webViewController =
      Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    // Googleのログイン画面を毎回出してテストするためにCookieをクリア
    CookieManager().clearCookies();
    return Scaffold(
        appBar: AppBar(
          title: Text('Googleでログイン'),
        ),
        body: Center(
            child: WebView(
          initialUrl: "https://ap-northeast-1_47n5eD4Tq" +
              ".amazoncognito.com/oauth2/authorize?identity_provider=Google&redirect_uri=myapp://&response_type=CODE&client_id=7u8k43jcrtpfrhhsntqma8h4gm" +
              "&scope=email+openid+profile+aws.cognito.signin.user.admin",
          userAgent: 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) ' +
              'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Mobile Safari/537.36',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _webViewController.complete(webViewController);
          },
          navigationDelegate: (NavigationRequest request) async {
            if (request.url.startsWith("myapp://")) {
              var uri = Uri.parse(request.url);
              if (uri.queryParameters.containsKey('code')) {
                try {
                  session = await _signUserInWithAuthCode(
                      uri.queryParameters['code']);
                  Navigator.of(context).pushReplacementNamed('/TopPage');
                } catch (e) {
                  print(e);
                }
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          gestureNavigationEnabled: true,
        )));
  }

  Future _signUserInWithAuthCode(String authCode) async {
    String url = "https://ap-northeast-1_47n5eD4Tq" +
        ".amazoncognito.com/oauth2/token?grant_type=authorization_code&client_id=" +
        "7u8k43jcrtpfrhhsntqma8h4gm&code=" +
        authCode +
        "&redirect_uri=myapp://";
    final response = await http.post(url,
        body: {},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'});
    if (response.statusCode != 200) {
      throw Exception("Received bad status code from Cognito for auth code:" +
          response.statusCode.toString() +
          "; body: " +
          response.body);
    }

    final tokenData = json.decode(response.body);

    final idToken = new CognitoIdToken(tokenData['id_token']);
    final accessToken = new CognitoAccessToken(tokenData['access_token']);
    final refreshToken = new CognitoRefreshToken(tokenData['refresh_token']);
    return new CognitoUserSession(idToken, accessToken,
        refreshToken: refreshToken);
  }
}
