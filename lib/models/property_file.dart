import 'package:flutter/material.dart';

/// Utility for generating prefixed IDs
String generateId(String prefix) {
  return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
}

class PropertyFile {
  final String id;
  final String fileNumber;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String? county; // NEW FIELD
  final String? taxAccountNumber;
  final double? loanAmount;
  final double? amountOwed;
  final double? arrears;
  final String? zillowUrl;
  final List<Contact> contacts;
  final List<Document> documents;
  final List<Judgment> judgments;
  final List<Note> notes;
  final List<Trustee> trustees;
  final List<Auction> auctions;
  final VestingInfo? vesting;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyFile({
    String? id,
    required this.fileNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.county,
    this.loanAmount,
    this.taxAccountNumber,
    this.amountOwed,
    this.arrears,
    this.zillowUrl,
    this.contacts = const [],
    this.documents = const [],
    this.judgments = const [],
    this.notes = const [],
    this.trustees = const [],
    this.auctions = const [],
    this.vesting,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? generateId('property'),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalOwed {
    final loan = loanAmount ?? 0.0;
    final owed = amountOwed ?? 0.0;
    final arr = arrears ?? 0.0;
    return loan - owed + arr;
  }

  PropertyFile copyWith({
    String? id,
    String? fileNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? county,
    String? taxAccountNumber,
    double? loanAmount,
    double? amountOwed,
    double? arrears,
    String? zillowUrl,
    List<Contact>? contacts,
    List<Document>? documents,
    List<Judgment>? judgments,
    List<Note>? notes,
    List<Trustee>? trustees,
    List<Auction>? auctions,
    VestingInfo? vesting,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyFile(
      id: id ?? this.id,
      fileNumber: fileNumber ?? this.fileNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      county: county ?? this.county,
      taxAccountNumber: taxAccountNumber ?? this.taxAccountNumber,
      loanAmount: loanAmount ?? this.loanAmount,
      amountOwed: amountOwed ?? this.amountOwed,
      arrears: arrears ?? this.arrears,
      zillowUrl: zillowUrl ?? this.zillowUrl,
      contacts: contacts ?? this.contacts,
      documents: documents ?? this.documents,
      judgments: judgments ?? this.judgments,
      notes: notes ?? this.notes,
      trustees: trustees ?? this.trustees,
      auctions: auctions ?? this.auctions,
      vesting: vesting ?? this.vesting,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() =>
      'PropertyFile(id: $id, fileNumber: $fileNumber, address: $address, city: $city)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyFile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileNumber': fileNumber,
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'county': county,
        'taxAccountNumber': taxAccountNumber,
        'loanAmount': loanAmount,
        'amountOwed': amountOwed,
        'arrears': arrears,
        'zillowUrl': zillowUrl,
        'contacts': contacts.map((x) => x.toMap()).toList(),
        'documents': documents.map((x) => x.toMap()).toList(),
        'judgments': judgments.map((x) => x.toMap()).toList(),
        'notes': notes.map((x) => x.toMap()).toList(),
        'trustees': trustees.map((x) => x.toMap()).toList(),
        'auctions': auctions.map((x) => x.toMap()).toList(),
        'vesting': vesting?.toMap(),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory PropertyFile.fromMap(Map<String, dynamic> map) => PropertyFile(
        id: map['id'],
        fileNumber: map['fileNumber'] ?? '',
        address: map['address'] ?? '',
        city: map['city'] ?? '',
        taxAccountNumber: map['taxAccountNumber'],
        state: map['state'] ?? '',
        zipCode: map['zipCode'] ?? '',
        county: map['county'] ?? '',
        loanAmount: map['loanAmount']?.toDouble(),
        amountOwed: map['amountOwed']?.toDouble(),
        arrears: map['arrears']?.toDouble(),
        zillowUrl: map['zillowUrl'],
        contacts: List<Contact>.from(
            map['contacts']?.map((x) => Contact.fromMap(x)) ?? []),
        documents: List<Document>.from(
            map['documents']?.map((x) => Document.fromMap(x)) ?? []),
        judgments: List<Judgment>.from(
            map['judgments']?.map((x) => Judgment.fromMap(x)) ?? []),
        notes: List<Note>.from(map['notes']?.map((x) => Note.fromMap(x)) ?? []),
        trustees: List<Trustee>.from(
            map['trustees']?.map((x) => Trustee.fromMap(x)) ?? []),
        auctions: List<Auction>.from(
            map['auctions']?.map((x) => Auction.fromMap(x)) ?? []),
        vesting:
            map['vesting'] != null ? VestingInfo.fromMap(map['vesting']) : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      );
}

class Contact {
  final String name;
  final String? phone;
  final String? email;
  final String role;

  Contact({
    required this.name,
    this.phone,
    this.email,
    required this.role,
  });

  Contact copyWith({String? name, String? phone, String? email, String? role}) {
    return Contact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  @override
  String toString() => 'Contact(name: $name, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact && name == other.name && role == other.role);

  @override
  int get hashCode => name.hashCode ^ role.hashCode;

  Map<String, dynamic> toMap() =>
      {'name': name, 'phone': phone, 'email': email, 'role': role};

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        name: map['name'] ?? '',
        phone: map['phone'],
        email: map['email'],
        role: map['role'] ?? '',
      );
}

class Document {
  final String id;
  final String name;
  final String type;
  final String? url;
  final DateTime uploadDate;

  Document({
    String? id,
    required this.name,
    required this.type,
    this.url,
    required this.uploadDate,
  }) : id = id ?? generateId('doc');

  Document copyWith({
    String? id,
    String? name,
    String? type,
    String? url,
    DateTime? uploadDate,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      uploadDate: uploadDate ?? this.uploadDate,
    );
  }

  @override
  String toString() => 'Document(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Document && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'url': url,
        'uploadDate': uploadDate.millisecondsSinceEpoch,
      };

  factory Document.fromMap(Map<String, dynamic> map) => Document(
        id: map['id'],
        name: map['name'] ?? '',
        type: map['type'] ?? '',
        url: map['url'],
        uploadDate: DateTime.fromMillisecondsSinceEpoch(map['uploadDate']),
      );
}

class Judgment {
  final String id;
  final String caseNumber;
  final String status;
  final DateTime? dateOpened;
  final DateTime? judgmentDate;
  final String county;
  final String state;
  final String debtor;
  final String grantee;
  final double? amount;

  Judgment({
    String? id,
    required this.caseNumber,
    required this.status,
    this.dateOpened,
    this.judgmentDate,
    required this.county,
    this.state = 'OR',
    required this.debtor,
    required this.grantee,
    this.amount,
  }) : id = id ?? generateId('judg');

  Judgment copyWith({
    String? id,
    String? caseNumber,
    String? status,
    DateTime? dateOpened,
    DateTime? judgmentDate,
    String? county,
    String? state,
    String? debtor,
    String? grantee,
    double? amount,
  }) {
    return Judgment(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      status: status ?? this.status,
      dateOpened: dateOpened ?? this.dateOpened,
      judgmentDate: judgmentDate ?? this.judgmentDate,
      county: county ?? this.county,
      state: state ?? this.state,
      debtor: debtor ?? this.debtor,
      grantee: grantee ?? this.grantee,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() => 'Judgment(id: $id, case: $caseNumber, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Judgment && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
        'id': id,
        'caseNumber': caseNumber,
        'status': status,
        'dateOpened': dateOpened?.millisecondsSinceEpoch,
        'judgmentDate': judgmentDate?.millisecondsSinceEpoch,
        'county': county,
        'state': state,
        'debtor': debtor,
        'grantee': grantee,
        'amount': amount,
      };

  factory Judgment.fromMap(Map<String, dynamic> map) => Judgment(
        id: map['id'],
        caseNumber: map['caseNumber'] ?? '',
        status: map['status'] ?? '',
        dateOpened: map['dateOpened'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['dateOpened'])
            : null,
        judgmentDate: map['judgmentDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['judgmentDate'])
            : null,
        county: map['county'] ?? '',
        state: map['state'] ?? 'OR',
        debtor: map['debtor'] ?? '',
        grantee: map['grantee'] ?? '',
        amount: map['amount']?.toDouble(),
      );
}

class Note {
  final String id;
  final String subject;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    String? id,
    required this.subject,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  }) : id = id ?? generateId('note');

  /// Short preview of note content (first 100 characters)
  String get preview =>
      content.length > 100 ? '${content.substring(0, 100)}...' : content;

  Note copyWith({
    String? id,
    String? subject,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Note(id: $id, subject: $subject)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Note && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'content': content,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? generateId('note'),
      subject: map['subject'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }
}


class Trustee {
  final String id;
  final String name;
  final String institution;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Trustee({
    String? id,
    required this.name,
    required this.institution,
    this.phoneNumber,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? generateId('trustee'),
        createdAt = createdAt ?? DateTime.now();

  Trustee copyWith({
    String? id,
    String? name,
    String? institution,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trustee(
      id: id ?? this.id,
      name: name ?? this.name,
      institution: institution ?? this.institution,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Trustee(id: $id, name: $name, institution: $institution)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Trustee && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'institution': institution,
        'phoneNumber': phoneNumber,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
      };

  factory Trustee.fromMap(Map<String, dynamic> map) => Trustee(
        id: map['id'],
        name: map['name'] ?? '',
        institution: map['institution'] ?? '',
        phoneNumber: map['phoneNumber'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
        updatedAt: map['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
            : null,
      );
}

class Auction {
  final String id;
  final DateTime auctionDate;
  final String place;
  final TimeOfDay time;
  final double? openingBid;
  final bool auctionCompleted;
  final double? salesAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Auction({
    String? id,
    required this.auctionDate,
    required this.place,
    required this.time,
    this.openingBid,
    this.auctionCompleted = false,
    this.salesAmount,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? generateId('auction'),
        createdAt = createdAt ?? DateTime.now();

  Auction copyWith({
    String? id,
    DateTime? auctionDate,
    String? place,
    TimeOfDay? time,
    double? openingBid,
    bool? auctionCompleted,
    double? salesAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Auction(
      id: id ?? this.id,
      auctionDate: auctionDate ?? this.auctionDate,
      place: place ?? this.place,
      time: time ?? this.time,
      openingBid: openingBid ?? this.openingBid,
      auctionCompleted: auctionCompleted ?? this.auctionCompleted,
      salesAmount: salesAmount ?? this.salesAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Auction(id: $id, date: $auctionDate, place: $place)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Auction && id == other.id);

  @override
  int get hashCode => id.hashCode;

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[auctionDate.month - 1]} ${auctionDate.day}, ${auctionDate.year}';
  }

  String get formattedTime {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'auctionDate': auctionDate.millisecondsSinceEpoch,
        'place': place,
        'timeHour': time.hour,
        'timeMinute': time.minute,
        'openingBid': openingBid,
        'auctionCompleted': auctionCompleted,
        'salesAmount': salesAmount,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
      };

  factory Auction.fromMap(Map<String, dynamic> map) => Auction(
        id: map['id'],
        auctionDate: DateTime.fromMillisecondsSinceEpoch(map['auctionDate']),
        place: map['place'] ?? '',
        time: TimeOfDay(
          hour: map['timeHour'] ?? 0,
          minute: map['timeMinute'] ?? 0,
        ),
        openingBid: map['openingBid']?.toDouble(),
        auctionCompleted: map['auctionCompleted'] ?? false,
        salesAmount: map['salesAmount']?.toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
        updatedAt: map['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
            : null,
      );
}

class VestingInfo {
  final List<Owner> owners;
  final String vestingType;

  VestingInfo({required this.owners, required this.vestingType});

  VestingInfo copyWith({List<Owner>? owners, String? vestingType}) {
    return VestingInfo(
      owners: owners ?? this.owners,
      vestingType: vestingType ?? this.vestingType,
    );
  }

  @override
  String toString() => 'VestingInfo(type: $vestingType, owners: $owners)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VestingInfo && vestingType == other.vestingType);

  @override
  int get hashCode => vestingType.hashCode;

  Map<String, dynamic> toMap() => {
        'owners': owners.map((x) => x.toMap()).toList(),
        'vestingType': vestingType,
      };

  factory VestingInfo.fromMap(Map<String, dynamic> map) => VestingInfo(
        owners:
            List<Owner>.from(map['owners']?.map((x) => Owner.fromMap(x)) ?? []),
        vestingType: map['vestingType'] ?? '',
      );
}

class Owner {
  final String id;
  final String name;
  final double percentage;

  Owner({String? id, required this.name, required this.percentage})
      : id = id ?? generateId('owner');

  Owner copyWith({String? id, String? name, double? percentage}) {
    return Owner(
      id: id ?? this.id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
    );
  }

  @override
  String toString() => 'Owner(id: $id, name: $name, pct: $percentage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Owner && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'percentage': percentage};

  factory Owner.fromMap(Map<String, dynamic> map) => Owner(
        id: map['id'],
        name: map['name'] ?? '',
        percentage: map['percentage']?.toDouble() ?? 0.0,
      );
}
