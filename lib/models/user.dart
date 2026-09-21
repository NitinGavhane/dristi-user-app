class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final double walletBalance;
  final String referralCode;
  final bool isVerified;
  final String role;

  /// active | deactivated | deleted. A signed-in session only ever sees
  /// "active" — the backend rejects the other two — but it is carried so the
  /// UI can react if a stale cached profile is restored on cold start.
  final String accountStatus;
  final bool promotionalEmails;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.walletBalance = 0,
    this.referralCode = '',
    this.isVerified = true,
    this.role = 'customer',
    this.accountStatus = 'active',
    this.promotionalEmails = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
      referralCode: json['referral_code'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      role: json['role'] as String? ?? 'customer',
      accountStatus: json['account_status'] as String? ?? 'active',
      promotionalEmails: json['promotional_emails'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'wallet_balance': walletBalance,
      'referral_code': referralCode,
      'is_verified': isVerified,
      'role': role,
      'account_status': accountStatus,
      'promotional_emails': promotionalEmails,
    };
  }
}
