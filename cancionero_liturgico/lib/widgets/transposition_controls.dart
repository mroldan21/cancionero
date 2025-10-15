import 'package:flutter/material.dart';

class TranspositionControls extends StatelessWidget {
  final int currentTransposition;
  final String originalKey;
  final String currentKey;
  final VoidCallback onTransposeUp;
  final VoidCallback onTransposeDown;
  final VoidCallback onReset;

  const TranspositionControls({
    super.key,
    required this.currentTransposition,
    required this.originalKey,
    required this.currentKey,
    required this.onTransposeUp,
    required this.onTransposeDown,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transposición',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Controles de transposición
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: currentTransposition > -11 ? onTransposeDown : null,
                      tooltip: 'Bajar semitono',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentTransposition == 0 
                            ? 'Original' 
                            : currentTransposition > 0 
                                ? '+$currentTransposition' 
                                : '$currentTransposition',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: currentTransposition < 11 ? onTransposeUp : null,
                      tooltip: 'Subir semitono',
                    ),
                  ],
                ),
                // Información de tonalidad
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tono: $currentKey',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (currentTransposition != 0)
                      Text(
                        'Original: $originalKey',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (currentTransposition != 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Resetear a original'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}