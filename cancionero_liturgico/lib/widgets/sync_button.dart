import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_provider.dart';

class SyncButton extends StatelessWidget {
  final double? size;
  final Color? color;

  const SyncButton({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return IconButton(
          icon: Stack(
            children: [
              // Ícono principal
              Icon(
                Icons.sync,
                size: size ?? 24,
                color: syncProvider.sincronizando 
                  ? Colors.orange 
                  : color ?? Theme.of(context).iconTheme.color,
              ),
              // Indicador de progreso (si está sincronizando)
              if (syncProvider.sincronizando)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: syncProvider.sincronizando 
            ? null 
            : () => _onSyncPressed(context, syncProvider),
          tooltip: 'Sincronizar ahora',
        );
      },
    );
  }

  Future<void> _onSyncPressed(BuildContext context, SyncProvider syncProvider) async {
    try {
      final resultado = await syncProvider.sincronizar();
      
      // Mostrar snackbar con resultado
      if (context.mounted) {
        if (resultado.success) {
          _mostrarSnackbarExito(context, resultado);
        } else {
          _mostrarSnackbarError(context, resultado.message);
        }
      }
    } catch (e) {
      _mostrarSnackbarError(context, 'Error: $e');
    }
  }

  void _mostrarSnackbarExito(BuildContext context, ResultadoSync resultado) {
    final message = '✅ Sync exitosa: '
      '${resultado.cancionesDescargadas} descargadas, '
      '${resultado.cancionesSubidas} subidas';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _mostrarSnackbarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $mensaje'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}