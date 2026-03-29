import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_mode_provider.dart';
import '../services/database_service.dart';
import '../services/local_pdf_service.dart';
import 'api_client.dart';
import 'repositories/invoice_repository.dart';
import 'remote/remote_invoice_repository.dart';
import 'local/local_invoice_repository.dart';

export 'repositories/invoice_repository.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final mode = ref.watch(appModeProvider).mode;
  if (mode == AppMode.offline) {
    final dbAsync = ref.watch(databaseServiceProvider);
    final pdfService = ref.watch(localPdfServiceProvider);
    return dbAsync.whenOrNull(
            data: (db) =>
                LocalInvoiceRepository(db: db, pdfService: pdfService))
        ?? _ThrowingInvoiceRepository();
  }
  return RemoteInvoiceRepository(dio: ref.watch(dioProvider));
});

/// Placeholder while database is loading.
class _ThrowingInvoiceRepository implements InvoiceRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw StateError('Database not ready');
}
