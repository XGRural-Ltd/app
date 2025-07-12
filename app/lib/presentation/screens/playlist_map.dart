import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/playlist_models.dart'; // ajuste o path conforme seu projeto
import '../../services/playlist_manager.dart'; // ajuste o path conforme seu projeto

class MapaPlaylistsPage extends StatefulWidget {
  const MapaPlaylistsPage({super.key});

  @override
  State<MapaPlaylistsPage> createState() => _MapaPlaylistsPageState();
}

class _MapaPlaylistsPageState extends State<MapaPlaylistsPage> {
  final PlaylistManager _playlistManager = PlaylistManager();
  Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(-14.2350, -51.9253);
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeUserAndLoadPlaylists();
  }

  Future<void> _initializeUserAndLoadPlaylists() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _currentUserId = user.uid;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });

    _playlistManager.streamPlaylistsForAnotherUser(user.uid).listen((
      playlists,
    ) {
      Set<Marker> newMarkers = {};
      for (var playlist in playlists) {
        if (playlist.geolocation != null) {
          newMarkers.add(
            Marker(
              markerId: MarkerId(playlist.id ?? playlist.name),
              position: LatLng(
                playlist.geolocation!.latitude,
                playlist.geolocation!.longitude,
              ),
              // infoWindow: InfoWindow(
              //   title: playlist.name,
              //   snippet: 'Músicas: ${playlist.musics.length}',
              // ),
              onTap: () => _createViewPlaylist(playlist),
            ),
          );
        }
      }

      setState(() {
        _markers = newMarkers;
      });
    });
  }

  Future<void> _clonePlaylist(Playlist playlist) async {
    if (_currentUserId == null) return;

    final newPlaylist = Playlist(
      userId: _currentUserId!,
      name: playlist.name,
      createdAt: DateTime.now(),
      musics: playlist.musics,
      geolocation: null,
    );

    String? docId = await _playlistManager.addPlaylist(newPlaylist);
    if (docId != null) {
      print("playlist clonada com sucesso: $docId");
    } else {
      print("Erro ao clonar playlist");
    }

  }

  void _createViewPlaylist(Playlist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Stack(
          children: [
            DraggableScrollableSheet(
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            playlist.name,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: playlist.musics.length,
                            itemBuilder: (context, index) {
                              final music = playlist.musics[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    music.albumImage,
                                  ),
                                ),
                                title: Text(music.title),
                                subtitle: Text(
                                  '${music.artist} - ${music.duration}',
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'clone_button_${playlist.id ?? playlist.name}',
                backgroundColor: Colors.purple,
                tooltip: 'Clonar Playlist',
                onPressed: () {
                  _clonePlaylist(playlist);
                  Navigator.pop(context); // Fecha o modal após clonar
                },
                child: const Icon(Icons.copy),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa das Playlists")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 4,
        ),
        markers: _markers,
        myLocationEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
