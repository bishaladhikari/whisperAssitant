class Movie {
  final String title;
  final String year;
  final String imdbId;
  final String posterUrl;

  Movie({
    required this.title,
    required this.year,
    required this.imdbId,
    required this.posterUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['Title'],
      year: json['Year'],
      imdbId: json['imdbID'],
      posterUrl: json['Poster'],
    );
  }
}
