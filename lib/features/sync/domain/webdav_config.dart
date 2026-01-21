class WebDavConfig {
  final String url;
  final String username;
  final String password;
  final String remotePath;

  const WebDavConfig({
    this.url = '',
    this.username = '',
    this.password = '',
    this.remotePath = '/aurora_backup',
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'username': username,
    'password': password,
    'remotePath': remotePath,
  };

  factory WebDavConfig.fromJson(Map<String, dynamic> json) => WebDavConfig(
    url: json['url'] as String? ?? '',
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
    remotePath: json['remotePath'] as String? ?? '/aurora_backup',
  );

  WebDavConfig copyWith({
    String? url,
    String? username,
    String? password,
    String? remotePath,
  }) {
    return WebDavConfig(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
    );
  }
}
