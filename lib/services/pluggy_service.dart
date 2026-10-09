import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/financial_transaction.dart';
import '../models/transaction_category.dart';
import 'statement_import.dart';

class PluggyIntegrationException implements Exception {
  const PluggyIntegrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PluggyBackendClient {
  PluggyBackendClient({
    FirebaseAuth? firebaseAuth,
    http.Client? httpClient,
    String? baseUrl,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _http = httpClient ?? http.Client(),
       baseUrl = baseUrl ?? const String.fromEnvironment('AXIOS_BACKEND_URL');

  final FirebaseAuth _firebaseAuth;
  final http.Client _http;
  final String baseUrl;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  void dispose() => _http.close();

  Future<String> createConnectToken() async {
    final payload = await _request('POST', '/api/pluggy/connect-token');
    final token = payload['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const PluggyIntegrationException(
        'O backend não retornou um Connect Token válido.',
      );
    }
    return token;
  }

  Future<void> linkItem(String itemId) async {
    await _request('POST', '/api/pluggy/items/link', body: {'itemId': itemId});
  }

  Future<PreparedStatementImport> loadTransactions(String itemId) async {
    final payload = await _request(
      'GET',
      '/api/pluggy/transactions?itemId=${Uri.encodeQueryComponent(itemId)}',
    );
    final rawResults = payload['results'];
    if (rawResults is! List) {
      throw const PluggyIntegrationException(
        'O backend retornou transações em formato inesperado.',
      );
    }
    final transactions = <FinancialTransaction>[];
    for (final raw in rawResults.whereType<Map<String, dynamic>>()) {
      final externalId = raw['externalId'] as String?;
      final dateText = raw['date'] as String?;
      final amountInCents = raw['amountInCents'] as int?;
      if (externalId == null || dateText == null || amountInCents == null) {
        continue;
      }
      final date = DateTime.tryParse(dateText);
      if (date == null || amountInCents <= 0) continue;
      transactions.add(
        FinancialTransaction(
          id: '',
          description: raw['description'] as String? ?? 'Transação Pluggy',
          category: TransactionCategory.fromId(raw['category'] as String?),
          date: date.toLocal(),
          amountInCents: amountInCents,
          type: raw['type'] == 'income'
              ? TransactionType.income
              : TransactionType.expense,
          origin: TransactionOrigin.pluggy,
          externalId: externalId,
          importBatchId: 'pluggy:$itemId',
          fingerprint: 'pluggy:$externalId',
          pending: raw['pending'] as bool? ?? false,
          excludedFromBudget: raw['excludedFromBudget'] as bool? ?? false,
        ),
      );
    }
    if (transactions.isEmpty) {
      throw const PluggyIntegrationException(
        'A conexão não retornou transações disponíveis para revisão.',
      );
    }
    transactions.sort((a, b) => a.date.compareTo(b.date));
    final first = transactions.first.date;
    final last = transactions.last.date;
    return PreparedStatementImport(
      fileName: 'Pluggy Sandbox',
      batchId: 'pluggy:$itemId',
      origin: TransactionOrigin.pluggy,
      result: StatementParseResult(
        transactions: List.unmodifiable(transactions),
        unrecognizedLines: const [],
        periodStart: DateTime(first.year, first.month),
        periodEndExclusive: DateTime(last.year, last.month + 1),
      ),
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    if (!isConfigured) {
      throw const PluggyIntegrationException(
        'Configure AXIOS_BACKEND_URL para utilizar o Pluggy Sandbox.',
      );
    }
    final user = _firebaseAuth.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const PluggyIntegrationException(
        'Entre novamente para autorizar a conexão bancária.',
      );
    }
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path');
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
    final response = method == 'POST'
        ? await _http.post(uri, headers: headers, body: jsonEncode(body ?? {}))
        : await _http.get(uri, headers: headers);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PluggyIntegrationException(
        decoded['error'] as String? ??
            'O Pluggy Sandbox está indisponível no momento.',
      );
    }
    return decoded;
  }
}
