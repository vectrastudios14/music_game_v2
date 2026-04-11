class Song {
  final String id;
  final String title;
  final String artist;
  final String? titleAr;
  final String? artistAr;
  final String link;
  final String year;
  final List<String> styles;
  final List<String> facts; 
  final String? gender; // New field: male, female, group

  String? artworkUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.titleAr,
    this.artistAr,
    required this.link,
    required this.year,
    required this.styles,
    this.artworkUrl,
    this.facts = const [],
    this.gender,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      titleAr: json['titleAr'] as String?,
      artistAr: json['artistAr'] as String?,
      link: json['link'] as String,
      year: json['year'] as String,
      styles: (json['styles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      artworkUrl: json['artworkUrl'] as String?,
      facts: (json['facts'] as List<dynamic>?) // Parse as List
          ?.map((e) => e.toString())
          .toList() ?? [], 
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'titleAr': titleAr,
      'artistAr': artistAr,
      'link': link,
      'year': year,
      'styles': styles,
      'artworkUrl': artworkUrl,
      'facts': facts,
      'gender': gender,
    };
  }
}
