import 'package:flutter/material.dart';

class CapoControls extends StatelessWidget {
  final int capoPosition;
  final String originalKey;
  final String currentKey;
  final ValueChanged<int> onCapoChanged;

  const CapoControls({
    super.key,
    required this.capoPosition,
    required this.originalKey,
    required this.currentKey,
    required this.onCapoChanged,
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
              'Capotraste',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Posición: $capoPosition'),
                      const SizedBox(height: 8),
                      Slider(
                        value: capoPosition.toDouble(),
                        min: 0,
                        max: 12,
                        divisions: 12,
                        label: capoPosition == 0 ? 'Sin capo' : 'Capo $capoPosition',
                        onChanged: (value) {
                          onCapoChanged(value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Acordes a tocar:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      currentKey,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    if (capoPosition > 0)
                      Text(
                        'Sonido real: $originalKey',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (capoPosition > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onCapoChanged(0),
                  child: const Text('Quitar capo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}