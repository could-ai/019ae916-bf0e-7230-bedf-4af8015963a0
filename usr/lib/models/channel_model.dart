class Channel {
  final String id;
  final String name;
  final String url;
  final bool isAceStream;
  final String? logoUrl;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.isAceStream = false,
    this.logoUrl,
  });

  // Helper para detectar si es AceStream basado en el protocolo
  static bool checkIsAceStream(String url) {
    return url.startsWith('acestream://') || 
           url.startsWith('get_content?id=') || 
           (url.length == 40 && !url.startsWith('http')); // Hash ID común
  }
}
