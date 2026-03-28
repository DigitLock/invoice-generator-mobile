import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_mode_provider.dart';
import 'api_client.dart';
import 'repositories/invoice_repository.dart';
import 'remote/remote_invoice_repository.dart';
import 'local/stub_invoice_repository.dart';

export 'repositories/invoice_repository.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.offline) {
    return StubInvoiceRepository();
  }
  return RemoteInvoiceRepository(dio: ref.watch(dioProvider));
});
