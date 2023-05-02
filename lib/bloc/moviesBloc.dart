import 'package:rxdart/rxdart.dart';

import '../models/movie.dart';

class MoviesBloc {
  final BehaviorSubject<List<Movie>> _movies =
  BehaviorSubject<List<Movie>>();

  void drainStream() {
    movies.value = [];
  }

  dispose() {
    movies.close();
  }

  BehaviorSubject<List<Movie>> get movies => _movies;
}

final moviesBloc = MoviesBloc();
