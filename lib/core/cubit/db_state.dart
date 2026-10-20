import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/user.dart';

sealed class DBState extends Equatable {
  const DBState(this.pushupSets, this.user);
  final List<PushupSet> pushupSets;
  final User user;

  DBStateLoaded copyWith({
    List<PushupSet>? pushupSets,
    User? user,
  }) =>
      DBStateLoaded(
        pushupSets ?? this.pushupSets,
        user ?? this.user,
      );

  @override
  List<Object?> get props => [pushupSets, user];
}

class DBStateInitial extends DBState {
  DBStateInitial() : super([], User.empty());
}

class DBStateLoaded extends DBState {
  const DBStateLoaded(super.pushupSets, super.user);
}
