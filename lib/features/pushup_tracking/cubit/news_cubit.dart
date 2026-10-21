import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_state.dart';
import 'package:pushup_bro/features/pushup_tracking/model/news.dart';

class NewsCubit extends Cubit<NewsState> {
  NewsCubit() : super(NewsInitial());

  Future<void> getNews() async {
    emit(NewsFetching());

    emit(
      NewsLoaded([
        News(
          title: 'Lucas gave you a boost!',
          description: 'description',
          type: NewsType.friendBoost,
          date: DateTime.now(),
        ),
        News(
          title: 'Double Bro Points Day!',
          description: 'Today you get double bro points for each pushup',
          type: NewsType.doublePoinstEvent,
          date: DateTime.now(),
        ),
        News(
          title: 'New Update',
          description: 'Enjoy the new features',
          type: NewsType.update,
          date: DateTime.now().subtract(
            const Duration(days: 1),
          ),
        ),
      ]),
    );
  }
}
