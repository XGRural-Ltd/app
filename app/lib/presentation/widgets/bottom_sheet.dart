import 'package:flutter/material.dart';

class Playlist {
  final String name;
  Playlist({required this.name});
}

class PlaylistBottomSheet extends StatelessWidget {
  final Playlist playlist;

  const PlaylistBottomSheet({super.key, required this.playlist});

  void _createViewPlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          height: MediaQuery.of(bc).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Container(
                  height: 5.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text('Playlist: ${playlist.name}'),
                      onTap: () => Navigator.pop(bc),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _createViewPlaylist(context),
      child: const SizedBox(
        width: double.infinity,
        height: 60,
        child: Center(
          child: Text('Show Playlist'),
        ),
      ),
    );
  }
}
