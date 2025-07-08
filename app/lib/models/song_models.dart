class Song { 
  final String name; 
  final String artist; 
  final String albumCoverUrl;

  Song({ 
    required this.name, 
    required this.artist, 
    required this.albumCoverUrl
  });

  Map<String, dynamic> toMap() {
    return {
      'title': name,
      'artist': artist,
      'album_cover_url': albumCoverUrl,
    };
  }
    // Cria um Song a partir de um Map, útil para desserialização
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      name: map['title'],
      artist: map['artist'],
      albumCoverUrl: map['albumCoverUrl']
    );
  }

  @override
  String toString() {
    return '$name - $artist - $albumCoverUrl';
  }
} 