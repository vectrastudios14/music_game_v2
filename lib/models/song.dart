class Song {
  final String id;
  final String title;
  final String artist;
  final String link;
  final String year;
  final List<String> styles;

  String? artworkUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.link,
    required this.year,
    required this.styles,
    this.artworkUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      link: json['link'] as String,
      year: json['year'] as String,
      styles: (json['styles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      artworkUrl: json['artworkUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'link': link,
      'year': year,
      'styles': styles,
      'artworkUrl': artworkUrl,
    };
  }
}
