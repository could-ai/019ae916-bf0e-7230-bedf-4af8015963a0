import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:couldai_user_app/models/channel_model.dart';
import 'package:couldai_user_app/providers/app_state.dart';
import 'package:couldai_user_app/services/m3u_service.dart';
import 'package:couldai_user_app/screens/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _linkController = TextEditingController();

  // Método para manejar la apertura de canales
  Future<void> _openChannel(BuildContext context, Channel channel) async {
    if (channel.isAceStream) {
      // Manejo específico para AceStream (Intent externo)
      final Uri url = Uri.parse(channel.url);
      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo abrir la aplicación externa (AceStream/VLC)')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al intentar abrir: $e')),
          );
        }
      }
    } else {
      // Reproductor interno para HLS/HTTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(channel: channel),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final List<Widget> pages = [
      _buildDirectLinkTab(context),
      _buildPlaylistTab(context, appState),
      _buildFavoritesTab(context, appState),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AceStream & M3U Player'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Enlace'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lista M3U'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
      ),
    );
  }

  // --- TABS ---

  Widget _buildDirectLinkTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 20),
          const Text(
            'Reproducir Enlace Directo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Soporta: acestream://, http://, .m3u8',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Ingresa URL o ID AceStream',
              hintText: 'acestream://... o http://...',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (_linkController.text.isNotEmpty) {
                String url = _linkController.text.trim();
                // Si es solo un hash (40 caracteres), agregar prefijo
                if (!url.contains('://') && url.length == 40) {
                  url = 'acestream://$url';
                }
                
                final channel = Channel(
                  id: 'direct',
                  name: 'Enlace Directo',
                  url: url,
                  isAceStream: Channel.checkIsAceStream(url),
                );
                _openChannel(context, channel);
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Reproducir'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTab(BuildContext context, AppState appState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.any, // Usamos any para mayor compatibilidad con extensiones .m3u
              );

              if (result != null) {
                try {
                  List<Channel> channels = await M3uService.parseFile(result.files.single);
                  appState.setPlaylist(channels);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Se cargaron ${channels.length} canales')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al leer el archivo')),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Subir Lista M3U'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        if (appState.currentPlaylist.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No hay lista cargada.\nSube un archivo .m3u para comenzar.', textAlign: TextAlign.center),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: appState.currentPlaylist.length,
              itemBuilder: (context, index) {
                final channel = appState.currentPlaylist[index];
                return _buildChannelTile(context, channel, appState);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFavoritesTab(BuildContext context, AppState appState) {
    if (appState.favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text('No tienes favoritos aún'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: appState.favorites.length,
      itemBuilder: (context, index) {
        final channel = appState.favorites[index];
        return _buildChannelTile(context, channel, appState);
      },
    );
  }

  Widget _buildChannelTile(BuildContext context, Channel channel, AppState appState) {
    final isFav = appState.isFavorite(channel);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: channel.isAceStream 
            ? const Icon(Icons.p2p, color: Colors.orange) // Icono distintivo para AceStream
            : const Icon(Icons.tv, color: Colors.blue),
        title: Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          channel.isAceStream ? 'AceStream (Requiere App Externa)' : 'Stream Directo',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
          onPressed: () {
            if (isFav) {
              appState.removeFromFavorites(channel);
            } else {
              appState.addToFavorites(channel);
            }
          },
        ),
        onTap: () => _openChannel(context, channel),
      ),
    );
  }
}
