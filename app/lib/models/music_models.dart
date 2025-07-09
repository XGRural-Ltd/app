class Music {
  final String title;
  final String artist;
  final String albumImage;
  final String duration;

  Music({
    required this.title,
    required this.artist,
    required this.albumImage,
    required this.duration,
  });

  // Converte um mapa do Firestore para um objeto Music.
  factory Music.fromMap(Map<String, dynamic> data) {
    return Music(
      title: data['title'] ?? 'Unknown Title',
      artist: data['artist'] ?? 'Unknown Artist',
      albumImage: data['albumImage'] ?? 'https://placehold.co/64x64/7e57c2/white?text=Album',
      duration: data['duration'] ?? '00:00',
    );
  }

  // Converte um objeto Music em um mapa para o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'albumImage': albumImage,
      'duration': duration,
    };
  }

}