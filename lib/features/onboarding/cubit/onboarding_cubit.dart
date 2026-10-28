import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_interface.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.loaded = false,
    this.completed = false,
    this.answers = const OnboardingAnswers(),
  });

  /// Whether [completed] was read from storage yet.
  final bool loaded;
  final bool completed;
  final OnboardingAnswers answers;

  OnboardingState copyWith({
    bool? loaded,
    bool? completed,
    OnboardingAnswers? answers,
  }) =>
      OnboardingState(
        loaded: loaded ?? this.loaded,
        completed: completed ?? this.completed,
        answers: answers ?? this.answers,
      );

  @override
  List<Object?> get props => [loaded, completed, answers];
}

/// The first-launch onboarding: whether it's done and what was answered.
/// Every player sees it once, existing players included.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._prefs) : super(const OnboardingState());

  final SharedPreferencesInterface _prefs;

  Future<void> load() async {
    final completed = await _prefs
        .getSharedPrefBool(SharedPreferencesKey.onboardingCompleted);
    final answers = OnboardingAnswers.decode(
      await _prefs.getSharedPrefString(SharedPreferencesKey.onboardingAnswers),
    );
    emit(
      OnboardingState(
        loaded: true,
        completed: completed ?? false,
        answers: answers,
      ),
    );
  }

  /// Saves new answers right away, so they survive the app being closed
  /// halfway.
  Future<void> answer(OnboardingAnswers answers) async {
    emit(state.copyWith(answers: answers));
    await _prefs.writeStringToSharedPrefs(
      SharedPreferencesKey.onboardingAnswers,
      answers.encode(),
    );
  }

  Future<void> complete() async {
    await _prefs.writeBoolToSharedPrefs(
      SharedPreferencesKey.onboardingCompleted,
      value: true,
    );
    emit(state.copyWith(completed: true));
  }
}
