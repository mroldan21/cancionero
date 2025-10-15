import 'package:flutter/material.dart';

class TransposicionControls extends StatelessWidget {
  final int semitonosActual;
  final ValueChanged<int> onTransponer;
  final VoidCallback onReset;
  final int capoActual;
  final ValueChanged<int> onCapoChanged;

  const TransposicionControls({
    Key? key,
    required this.semitonosActual,
    required this.onTransponer,
    required this.onReset,
    required this.capoActual,
    required this.onCapoChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajustes de Tono',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Controles de transposición
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transposición',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: semitonosActual > -11 
                                ? () => onTransponer(semitonosActual - 1)
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              semitonosActual == 0 
                                  ? 'Original' 
                                  : '${semitonosActual > 0 ? '+' : ''}$semitonosActual',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: semitonosActual < 11 
                                ? () => onTransponer(semitonosActual + 1)
                                : null,
                          ),
                          if (semitonosActual != 0)
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: onReset,
                              tooltip: 'Resetear a tono original',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const VerticalDivider(),
                
                // Controles de capo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capotraste',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: capoActual > 0 
                                ? () => onCapoChanged(capoActual - 1)
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              capoActual == 0 ? 'Sin capo' : 'Traste $capoActual',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: capoActual < 12 
                                ? () => onCapoChanged(capoActual + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}