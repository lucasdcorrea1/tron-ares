import 'package:equatable/equatable.dart';

/// Connected bank account entity
class ConnectedAccount extends Equatable {
  final String id;
  final String userId;
  final String provider;
  final String accountType;
  final String accountName;
  final String lastFour;
  final double balance;
  final String color;
  final String icon;
  final bool isActive;
  final DateTime lastSync;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConnectedAccount({
    required this.id,
    required this.userId,
    required this.provider,
    required this.accountType,
    required this.accountName,
    required this.lastFour,
    required this.balance,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.lastSync,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        provider,
        accountType,
        accountName,
        lastFour,
        balance,
        color,
        icon,
        isActive,
        lastSync,
        createdAt,
        updatedAt,
      ];
}

/// Bank provider info
class BankProvider {
  final String id;
  final String name;
  final String icon;
  final String color;

  const BankProvider({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Predefined bank providers
class BankProviders {
  static const List<BankProvider> all = [
    BankProvider(id: 'nubank', name: 'Nubank', icon: 'nubank', color: '#8A05BE'),
    BankProvider(id: 'itau', name: 'Itau', icon: 'itau', color: '#EC7000'),
    BankProvider(id: 'bradesco', name: 'Bradesco', icon: 'bradesco', color: '#CC092F'),
    BankProvider(id: 'santander', name: 'Santander', icon: 'santander', color: '#EC0000'),
    BankProvider(id: 'bb', name: 'Banco do Brasil', icon: 'bb', color: '#FFEF00'),
    BankProvider(id: 'caixa', name: 'Caixa', icon: 'caixa', color: '#005CA9'),
    BankProvider(id: 'inter', name: 'Inter', icon: 'inter', color: '#FF7A00'),
    BankProvider(id: 'c6', name: 'C6 Bank', icon: 'c6', color: '#242424'),
    BankProvider(id: 'picpay', name: 'PicPay', icon: 'picpay', color: '#21C25E'),
    BankProvider(id: 'mercadopago', name: 'Mercado Pago', icon: 'mercadopago', color: '#00B1EA'),
    BankProvider(id: 'outros', name: 'Outros', icon: 'bank', color: '#808080'),
  ];

  static BankProvider? getById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
