class Movie {
  final String title;
  final String year;
  final String imdbId;
  final String posterUrl;
  final String rating;

  Movie({
    required this.title,
    required this.year,
    required this.imdbId,
    required this.posterUrl,
    required this.rating,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['Title'],
      year: json['Year'],
      imdbId: json['imdbID'],
      rating: json['imdbRating'],
      posterUrl: json['Poster'],
    );
  }
}
