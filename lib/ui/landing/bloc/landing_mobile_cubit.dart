import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

enum MobileLoginStatus {
  initial,
  error,
}

class MobileLoginState extends Equatable {
  const MobileLoginState({
    this.status = MobileLoginStatus.initial,
    this.errorMessage,
  });

  final MobileLoginStatus status;

  final String? errorMessage;

  @override
  List<Object?> get props => [
        status,
        errorMessage,
      ];
}

class LandingMobileCubit extends Cubit<MobileLoginState> {
  LandingMobileCubit() : super(const MobileLoginState());



}
