import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:couldai_user_app/models/channel_model.dart';

class M3uService {
  
  static Future<List<Channel>> parseFile(PlatformFile file) async {
    String content = '';

    // Manejo diferente para Web y Móvil
    if (kIsWeb) {
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      }
    } else {
      if (file.path != null) {
        final f = File(file.path!);
        content = await f.readAsString();
      }
    }

    return _parseM3uContent(content);
  }

  static List<Channel> _parseM3uContent(String content) {
    List<Channel> channels = [];
    List<String> lines = LineSplitter.split(content).toList();

    String? currentName;
    String? currentLogo;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        // Intentar extraer el nombre (lo que está después de la última coma)
        List<String> parts = line.split(',');
        if (parts.length > 1) {
          currentName = parts.sublist(1).join(',').trim();
        } else {
          currentName = "Canal Desconocido";
        }
        
        // Intentar extraer logo tvg-logo="..."
        RegExp logoRegex = RegExp(r'tvg-logo="([^"]*)"');
        var match = logoRegex.firstMatch(line);
        if (match != null) {
          currentLogo = match.group(1);
        }

      } else if (line.isNotEmpty && !line.startsWith('#')) {
        // Es una URL
        if (currentName != null) {
          channels.add(Channel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: currentName,
            url: line,
            isAceStream: Channel.checkIsAceStream(line),
            logoUrl: currentLogo,
          ));
          currentName = null; // Reset para el siguiente
          currentLogo = null;
        }
      }
    }
    return channels;
  }
}
