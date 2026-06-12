class Address {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zip;
  final String country;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      addressLine1: json['address_line1'],
      addressLine2: json['address_line2'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
      country: json['country'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ---------- Display helpers ----------
  //
  // All display getters elide empty fields, so a Nigerian address with no
  // postal code (common) renders cleanly instead of producing artifacts
  // like "Lagos, , Nigeria" or "Plot 5, , Lekki".

  /// First display line: address line 1, with address line 2 appended after
  /// a comma when present and non-empty.
  String get streetDisplay {
    return [
      addressLine1,
      addressLine2 ?? '',
    ].where((s) => s.isNotEmpty).join(', ');
  }

  /// Second display line: `"city, state zip"`, optionally followed by the
  /// country. Set [includeCountry] = false when the surrounding UI renders
  /// the country on its own line (e.g. the address list).
  String regionDisplay({bool includeCountry = true}) {
    final stateZip = [state, zip].where((p) => p.isNotEmpty).join(' ');
    final parts = [city, stateZip, if (includeCountry) country];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  /// Compact single-line summary suitable for narrow UI slots
  /// (order details, notification snippets). Country is omitted to keep
  /// the line short; it's almost always implied by context.
  String get summaryLine {
    return [
      streetDisplay,
      regionDisplay(includeCountry: false),
    ].where((p) => p.isNotEmpty).join(', ');
  }
}
