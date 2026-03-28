import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'repositories/invoice_repository.dart';
import 'remote/remote_invoice_repository.dart';

export 'repositories/invoice_repository.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return RemoteInvoiceRepository(dio: ref.watch(dioProvider));
});
