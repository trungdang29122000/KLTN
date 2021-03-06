import 'package:app_kltn_trunghoan/bloc/app_bloc.dart';
import 'package:app_kltn_trunghoan/common/widgets/dialogs/dialog_notify_auth.dart';

import 'package:app_kltn_trunghoan/common/widgets/dialogs/dialog_with_text_and_pop_button.dart';
import 'package:app_kltn_trunghoan/common/widgets/dialogs/dialog_wrapper.dart';
import 'package:app_kltn_trunghoan/configs/application.dart';
import 'package:app_kltn_trunghoan/constants/constants.dart';
import 'package:app_kltn_trunghoan/data/local_data_source/user_local_data.dart';
import 'package:app_kltn_trunghoan/data/remote_data_source/auth_responsitory.dart';
import 'package:app_kltn_trunghoan/models/account_model.dart';
import 'package:app_kltn_trunghoan/models/enums/authenication_fail.dart';
import 'package:app_kltn_trunghoan/models/slide_model.dart';
import 'package:app_kltn_trunghoan/routes/app_pages.dart';
import 'package:app_kltn_trunghoan/routes/app_routes.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:app_kltn_trunghoan/helpers/sizer_custom/sizer.dart';

part 'authenication_event.dart';
part 'authenication_state.dart';

class AuthenicationBloc extends Bloc<AuthenicationEvent, AuthenicationState> {
  AuthenicationBloc() : super(AuthenicationInitial());
  final application = Application();
  @override
  Stream<AuthenicationState> mapEventToState(AuthenicationEvent event) async* {
    if (event is OnAuthCheck) {
      bool isLogin = _onAuthCheck();
      if (isLogin) {
        yield _getAuthenticationSuccess();
      } else {
        yield AuthenticationFail();
      }
    }

    if (event is LoginEvent) {
      try {
        bool isSuccess = await _handleLogin(event);

        if (isSuccess) {
          if (event.isRemember) {
            UserLocal().saveAccountRemember(event.email, event.password);
          } else {
            UserLocal().deleteAccountRemember(event.email);
          }

          AppNavigator.popUntil(Routes.HOME);

          yield _getAuthenticationSuccess();
        } else {
          yield AuthenticationFail();
        }
      } catch (exception) {
        if (exception is AuthenticationException) {
          AuthenticationException authException = exception;
          String? description = authException.description;

          AppNavigator.pop();

          UserLocal().deleteAccountRemember(event.email);

          if (description != null) {
            if (authException == AuthenticationException.WRONG_PASSWORD) {
              UserLocal().clearAccessToken();
              dialogAnimationWrapper(
                borderRadius: 10.sp,
                slideFrom: SlideMode.bot,
                child: DialogWithTextAndPopButton(
                  title: '????ng nh???p th???t b???i',
                  bodyBefore: description,
                  bodyAlign: TextAlign.center,
                ),
              );
            }
            if (authException == AuthenticationException.DONT_VERIFY) {
              UserLocal().clearAccessToken();
              AppNavigator.popUntil(Routes.HOME);
              showGeneralDialog(
                context: AppNavigator.context!,
                barrierDismissible: false,
                barrierColor: Colors.white,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return DialogNotifyAuth(
                    email: event.email,
                    buttonTitle: '???? hi???u',
                    content:
                        'Vui l??ng x??c th???c email\ntr?????c khi ti???n h??nh ????ng nh???p!',
                    title2:
                        ' v?? l??m theo h?????ng d???n ????? x??c th???c email. (L??u ?? ki???m tra m???c Spam n???u kh??ng nh???n ???????c email x??c th???c)',
                    title1: 'Vui l??ng truy c???p ',
                    image: null,
                  );
                },
              );
            }
          }
        }
      }
    }

    if (event is RegisterEvent) {
      bool isSuccess = await _handleRegister(event);
      AppNavigator.pop();
      if (isSuccess) {
        AppNavigator.popUntil(Routes.HOME);
        await showGeneralDialog(
          context: AppNavigator.context!,
          barrierDismissible: false,
          barrierColor: Colors.white,
          pageBuilder: (context, animation, secondaryAnimation) {
            return DialogNotifyAuth(
              email: event.email,
              buttonTitle: 'Ho??n th??nh',
              content: 'Ch??c m???ng b???n ???? ????ng k?? th??nh c??ng',
              title2:
                  'v?? l??m theo h?????ng d???n ????? x??c th???c email. (L??u ?? ki???m tra m???c Spam n???u kh??ng nh???n ???????c email x??c th???c)',
              title1: 'Vui l??ng truy c???p ',
              image: Image.asset(
                imageRegisterSuccess,
                width: 80.sp,
                height: 80.sp,
              ),
            );
          },
        );
      } else {
        dialogAnimationWrapper(
          borderRadius: 10.sp,
          slideFrom: SlideMode.bot,
          child: DialogWithTextAndPopButton(
            title: '????ng k?? th???t b???i',
            bodyAfter:
                'Email n??y ???? ???????c s??? d???ng ????? ????ng k?? t??i kho???n, h??y th??? s??? d???ng email kh??c!',
          ),
        );
      }
    }

    if (event is ForgotPasswordEvent) {
      bool isSuccess = await _handleForgotPassword(event);
      AppNavigator.pop();
      if (isSuccess) {
        await dialogAnimationWrapper(
          slideFrom: SlideMode.bot,
          child: DialogWithTextAndPopButton(
            bodyAlign: TextAlign.center,
            bodyBefore:
                'Vui l??ng ki???m tra h???p th?? v?? l??m theo h?????ng d???n ????? thi???t l???p l???i m???t kh???u.',
            bodyFontSize: 13.sp,
            bodyColor: colorBlack1,
            padding: EdgeInsets.only(
              left: 24.sp,
              right: 24.sp,
              top: 22.sp,
              bottom: 18.sp,
            ),
          ),
          borderRadius: 10.sp,
        );
        AppNavigator.popUntil(Routes.LOGIN);
      } else {
        // Show dialog change password fail
      }
    }

    if (event is LogOutEvent) {
      await _handleLogOut();
      yield AuthenticationFail();
    }
  }

  //Private methods
  AuthenticationSuccess _getAuthenticationSuccess() {
    if (state is! AuthenticationSuccess) {
      AppBloc.cleanBloc();
      AppBloc.initialHomeBloc();
    }
    return AuthenticationSuccess();
  }

  bool _onAuthCheck() {
    return UserLocal().getAccessToken() != '';
  }

  Future<bool> _handleForgotPassword(ForgotPasswordEvent event) async {
    bool isSucceed = await AuthRepository().forgotPassword(
      email: event.email,
    );
    return isSucceed;
  }

  Future<bool> _handleRegister(RegisterEvent event) async {
    AccountModel? user = await AuthRepository().register(
      email: event.email,
      password: event.password,
      fullname: event.fullname,
      passwordConfirm: event.passwordConfirm,
    );

    return user != null;
  }

  Future<bool> _handleLogin(LoginEvent event) async {
    AccountModel? user = await AuthRepository().login(
      email: event.email,
      password: event.password,
    );

    AppNavigator.pop();
    if (user != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> _handleLogOut() async {
    UserLocal().clearAccessToken();
    AppBloc.cleanBloc();
    AppBloc.initialHomeBloc();
    AppNavigator.popUntil(Routes.HOME);
  }
}
