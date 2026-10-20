import 'package:equatable/equatable.dart';
import 'package:pushup_bro/features/pushup_tracking/model/news.dart';

sealed class NewsState extends Equatable {
  const NewsState(this.news);

  final List<News> news;

  List<News> get activeNews => news.where((news) => news.isActive).toList();

  @override
  List<Object?> get props => [news];
}

class NewsInitial extends NewsState {
  NewsInitial() : super(List<News>.empty());
}

class NewsFetching extends NewsState {
  NewsFetching() : super(List<News>.empty());
}

class NewsLoaded extends NewsState {
  const NewsLoaded(super.news);
}
