import 'package:flutter/material.dart';

class LineItemData {
  String description;
  String quantity;
  String unitPrice;

  LineItemData({
    this.description = '',
    this.quantity = '1',
    this.unitPrice = '0.00',
  });

  double get total {
    final qty = double.tryParse(quantity) ?? 0;
    final price = double.tryParse(unitPrice) ?? 0;
    return (qty * price * 100).roundToDouble() / 100;
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

class LineItemRow extends StatelessWidget {
  const LineItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDismissed,
  });

  final int index;
  final LineItemData item;
  final VoidCallback onChanged;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Item ${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${item.total.toStringAsFixed(2)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: item.description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  isDense: true,
                ),
                onChanged: (v) {
                  item.description = v;
                  onChanged();
                },
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.quantity,
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        isDense: true,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        item.quantity = v;
                        onChanged();
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.unitPrice,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price',
                        isDense: true,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        item.unitPrice = v;
                        onChanged();
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
