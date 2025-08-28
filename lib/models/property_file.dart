import 'package:flutter/material.dart';

class PropertyFile {
  final String id;
  final String fileNumber;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double? loanAmount;
  final double? amountOwed;
  final double? arrears;
  final String? zillowUrl; // NEW FIELD
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
    required this.id,
    required this.fileNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.loanAmount,
    this.amountOwed,
    this.arrears,
    this.zillowUrl, // NEW FIELD
    this.contacts = const [],
    this.documents = const [],
    this.judgments = const [],
    this.notes = const [],
    this.trustees = const [],
    this.auctions = const [],
    this.vesting,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalOwed {
    final loan = loanAmount ?? 0.0;
    final owed = amountOwed ?? 0.0;
    final arr = arrears ?? 0.0;
    return loan - owed + arr;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileNumber': fileNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'loanAmount': loanAmount,
      'amountOwed': amountOwed,
      'arrears': arrears,
      'zillowUrl': zillowUrl, // NEW FIELD
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
  }

  factory PropertyFile.fromMap(Map<String, dynamic> map) {
    return PropertyFile(
      id: map['id'] ?? '',
      fileNumber: map['fileNumber'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      loanAmount: map['loanAmount']?.toDouble(),
      amountOwed: map['amountOwed']?.toDouble(),
      arrears: map['arrears']?.toDouble(),
      zillowUrl: map['zillowUrl'], // NEW FIELD
      contacts: List<Contact>.from(
        map['contacts']?.map((x) => Contact.fromMap(x)) ?? [],
      ),
      documents: List<Document>.from(
        map['documents']?.map((x) => Document.fromMap(x)) ?? [],
      ),
      judgments: List<Judgment>.from(
        map['judgments']?.map((x) => Judgment.fromMap(x)) ?? [],
      ),
      notes: List<Note>.from(map['notes']?.map((x) => Note.fromMap(x)) ?? []),
      trustees: List<Trustee>.from(
        map['trustees']?.map((x) => Trustee.fromMap(x)) ?? [],
      ),
      auctions: List<Auction>.from(
        map['auctions']?.map((x) => Auction.fromMap(x)) ?? [],
      ),
      vesting:
          map['vesting'] != null ? VestingInfo.fromMap(map['vesting']) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}

class Contact {
  final String name;
  final String? phone;
  final String? email;
  final String role; // borrower, attorney, etc.

  Contact({required this.name, this.phone, this.email, required this.role});

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'email': email, 'role': role};
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'] ?? '',
      phone: map['phone'],
      email: map['email'],
      role: map['role'] ?? '',
    );
  }
}

class Document {
  final String name;
  final String type; // deed, mortgage, etc.
  final String? url;
  final DateTime uploadDate;

  Document({
    required this.name,
    required this.type,
    this.url,
    required this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'url': url,
      'uploadDate': uploadDate.millisecondsSinceEpoch,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      url: map['url'],
      uploadDate: DateTime.fromMillisecondsSinceEpoch(map['uploadDate']),
    );
  }
}

class Judgment {
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
    required this.caseNumber,
    required this.status,
    this.dateOpened,
    this.judgmentDate,
    required this.county,
    this.state = 'OR',
    required this.debtor,
    required this.grantee,
    this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory Judgment.fromMap(Map<String, dynamic> map) {
    return Judgment(
      caseNumber: map['caseNumber'] ?? '',
      status: map['status'] ?? '',
      dateOpened:
          map['dateOpened'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['dateOpened'])
              : null,
      judgmentDate:
          map['judgmentDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['judgmentDate'])
              : null,
      county: map['county'] ?? '',
      state: map['state'] ?? 'OR',
      debtor: map['debtor'] ?? '',
      grantee: map['grantee'] ?? '',
      amount: map['amount']?.toDouble(),
    );
  }
}

class Note {
  final String id;
  final String subject;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.subject,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  String get preview {
    return content.length > 100 ? content.substring(0, 100) : content;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      subject: map['subject'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null
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
    required this.id,
    required this.name,
    required this.institution,
    this.phoneNumber,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'institution': institution,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Trustee.fromMap(Map<String, dynamic> map) {
    return Trustee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      institution: map['institution'] ?? '',
      phoneNumber: map['phoneNumber'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : null,
    );
  }
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
    required this.id,
    required this.auctionDate,
    required this.place,
    required this.time,
    this.openingBid,
    this.auctionCompleted = false,
    this.salesAmount,
    required this.createdAt,
    this.updatedAt,
  });

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

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory Auction.fromMap(Map<String, dynamic> map) {
    return Auction(
      id: map['id'] ?? '',
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
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : null,
    );
  }
}

class VestingInfo {
  final List<Owner> owners;
  final String vestingType; // joint tenants, tenants in common, etc.

  VestingInfo({required this.owners, required this.vestingType});

  Map<String, dynamic> toMap() {
    return {
      'owners': owners.map((x) => x.toMap()).toList(),
      'vestingType': vestingType,
    };
  }

  factory VestingInfo.fromMap(Map<String, dynamic> map) {
    return VestingInfo(
      owners: List<Owner>.from(
        map['owners']?.map((x) => Owner.fromMap(x)) ?? [],
      ),
      vestingType: map['vestingType'] ?? '',
    );
  }
}

class Owner {
  final String name;
  final double percentage;

  Owner({required this.name, required this.percentage});

  Map<String, dynamic> toMap() {
    return {'name': name, 'percentage': percentage};
  }

  factory Owner.fromMap(Map<String, dynamic> map) {
    return Owner(
      name: map['name'] ?? '',
      percentage: map['percentage']?.toDouble() ?? 0.0,
    );
  }
}
