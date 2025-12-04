import 'package:flutter/material.dart';
import 'package:couldai_user_app/models/channel_model.dart';

class AppState extends ChangeNotifier {
  List<Channel> _favorites = [];
  List<Channel> _currentPlaylist = [];

  List<Channel> get favorites => _favorites;
  List<Channel> get currentPlaylist => _currentPlaylist;

  void addToFavorites(Channel channel) {
    if (!_favorites.any((c) => c.url == channel.url)) {
      _favorites.add(channel);
      notifyListeners();
    }
  }

  void removeFromFavorites(Channel channel) {
    _favorites.removeWhere((c) => c.url == channel.url);
    notifyListeners();
  }

  bool isFavorite(Channel channel) {
    return _favorites.any((c) => c.url == channel.url);
  }

  void setPlaylist(List<Channel> channels) {
    _currentPlaylist = channels;
    notifyListeners();
  }

  void clearPlaylist() {
    _currentPlaylist = [];
    notifyListeners();
  }
}
