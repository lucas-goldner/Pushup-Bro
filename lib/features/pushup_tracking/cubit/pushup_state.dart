import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/pushup.dart';

class PushupState extends Equatable {
  const PushupState({required this.pushups, required this.inPushup});
  final List<Pushup> pushups;
  final bool inPushup;

  PushupState copyWith({
    List<Pushup>? pushups,
    bool? inPushup,
  }) {
    return PushupState(
      pushups: pushups ?? this.pushups,
      inPushup: inPushup ?? this.inPushup,
    );
  }

  @override
  List<Object?> get props => [pushups, inPushup];
}
