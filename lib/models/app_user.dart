class AppUser {
  const AppUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  String get firstName {
    final source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : email.split('@').first;
    if (source.isEmpty) return 'usuário';
    return '${source[0].toUpperCase()}${source.substring(1).toLowerCase()}';
  }
}
