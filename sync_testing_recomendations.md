
### B. Pruebas de Integración (`sync_integration_test.dart`)

**Objetivo:** Probar la interacción completa del `SyncService` con una instancia real de la base de datos local y el servidor remoto de pruebas.

#### Configuración (Setup):
-   Inicializar una base de datos de prueba en memoria o en un archivo temporal (`sqflite_common_ffi`).
-   Crear instancias reales de `SongRepository`, `CategoryRepository`, y `SetlistRepository` que apunten a esta BD de prueba.
-   Crear una instancia de `SyncService` con estos repositorios.
-   **Importante:** Apuntar el `_baseUrl` del `SyncService` al servidor de desarrollo real (`cincomasuno.ar`). No se usará un mock de red para estas pruebas.
-   Asegurarse de que la base de datos remota esté en un estado conocido (ej. vacía) antes de cada suite de pruebas.

#### Escenarios:

    -   **Setup:** Insertar una nueva canción en la BD de prueba local. La BD remota debe estar vacía.
    -   **Acción:** Llamar a `sincronizarAhora()`.
    -   **Verificación:**
        1.  La llamada a `sincronizarAhora()` debe devolver un resultado exitoso.
        2.  Consultar la BD remota directamente y verificar que la nueva canción y sus categorías asociadas fueron creadas.

2.  **Descarga y aplicación de una canción actualizada:**
    -   **Setup:**
        1.  Realizar una sincronización inicial para poblar la BD remota y local.
        2.  Modificar manualmente una canción en la BD **remota** (ej. cambiar el título y actualizar `fecha_modificacion`).
    -   **Acción:** Llamar a `sincronizarAhora()`.
    -   **Verificación:** Consultar la BD de prueba **local** y verificar que la canción ahora tiene los datos actualizados del servidor.

3.  **Descarga y aplicación de una canción eliminada:**
    -   **Setup:**
        1.  Realizar una sincronización inicial.
        2.  Marcar una canción como eliminada en la BD **remota** (según la lógica de tu API, puede ser un flag `is_deleted` o moverla a otra tabla).
    -   **Acción:** Llamar a `sincronizarAhora()`.
    -   **Verificación:** Consultar la BD de prueba **local** y verificar que la canción ya no existe.

4.  **Creación de categorías durante la descarga:**
    -   **Setup:**
        1.  Realizar una sincronización inicial.
        2.  En la BD **remota**, crear una nueva canción y asociarla a un nombre de categoría que no exista localmente.
    -   **Acción:** Llamar a `sincronizarAhora()`.
    -   **Verificación:** Consultar la BD **local** y verificar que tanto la canción como la nueva categoría fueron creadas correctamente.

### C. Pruebas de Extremo a Extremo (E2E) (`app_test.dart`)












# Recomendaciones para Pruebas de Sincronización

Este documento describe una estrategia para probar la funcionalidad de sincronización (`SyncService` y `SyncProvider`) de la aplicación Cancionero Litúrgico.

## 1. Tipos de Pruebas

La sincronización es una característica compleja que interactúa con la UI, la lógica de negocio, la base de datos local y un servidor remoto. Por lo tanto, se recomienda un enfoque de pruebas en múltiples capas:

1.  **Pruebas Unitarias (Unit Tests):** Para verificar pequeñas piezas de lógica de forma aislada. Son rápidas y fáciles de mantener.
2.  **Pruebas de Integración (Integration Tests):** Para verificar la interacción entre el `SyncService` y la base de datos local, simulando la capa de red.
3.  **Pruebas de Extremo a Extremo (End-to-End - E2E):** Para simular el flujo completo desde la interacción del usuario en la UI hasta la finalización del proceso, utilizando un servidor simulado (mock server).

## 2. Herramientas Recomendadas

- **Mocking/Simulación:**
  - `mocktail` o `mockito`: Para simular dependencias como los repositorios en pruebas unitarias.
  - `http`: Para realizar llamadas de red en pruebas de integración/E2E.
  - `http_mock_adapter` o `mock_web_server`: Para crear un servidor HTTP simulado que responda a las peticiones de la API de sincronización.
- **Base de Datos para Pruebas:**
  - `sqflite_common_ffi`: Para ejecutar pruebas de base de datos en un entorno de escritorio (más rápido que en un emulador).

---

## 3. Escenarios de Prueba

### A. Pruebas Unitarias (`sync_service_test.dart`)

**Objetivo:** Probar funciones individuales del `SyncService` en aislamiento, simulando todas sus dependencias (`SongRepository`, `CategoryRepository`, `http`).

#### Escenarios:

1.  **`_recolectarCambiosLocales`:**
    -   **Prueba 1:** Si el repositorio de canciones devuelve una canción nueva (creada después de la última sincronización), verificar que `_recolectarCambiosLocales` genera un `CambioLocal` de tipo `'crear'`.
    -   **Prueba 2:** Si el repositorio devuelve una canción modificada (antes de la última sincronización), verificar que el `CambioLocal` es de tipo `'actualizar'`.
    -   **Prueba 3:** Si el repositorio no devuelve canciones modificadas, verificar que la lista de cambios esté vacía.

2.  **`_convertirCancionAJson`:**
    -   **Prueba 1:** Dada una `Song` con todos sus campos, verificar que el mapa JSON resultante contenga todas las claves (`titulo`, `letra_con_acordes`, etc.) y valores correctos.
    -   **Prueba 2:** Verificar que `isFavorite` (booleano `true`) se convierte a `1` (entero).
    -   **Prueba 3:** Verificar que la lista de `categoryIds` se convierte correctamente en una lista de nombres de categorías (`categorias`) llamando al `categoryRepository`.

3.  **`_procesarCancionDescargada`:**
    -   **Prueba 1 (Canción Nueva):** Dado un JSON de una canción que no existe localmente, verificar que se llama a `songRepository.songExists` (devolviendo `false`) y luego a `songRepository.insertSong`.
    -   **Prueba 2 (Canción Actualizada):** Dado un JSON de una canción que ya existe, verificar que se llama a `songRepository.songExists` (devolviendo `true`) y luego a `songRepository.updateSong`.
    -   **Prueba 3 (Con Categorías Nuevas):** Dado un JSON con nombres de categorías que no existen, verificar que se llama a `categoryRepository.getOrCreateCategoryByName` para cada una.

4.  **`_generarHashLocal`:**
    -   **Prueba 1:** Si el `songRepository` devuelve una lista de canciones, verificar que se genera un hash no vacío.
    -   **Prueba 2:** Si el `songRepository` devuelve una lista vacía, verificar que el hash es el correspondiente a una cadena vacía.

### B. Pruebas de Integración (`sync_integration_test.dart`)

**Objetivo:** Probar la interacción del `SyncService` con una instancia real (pero de prueba) de la base de datos, mientras se simula la red.

#### Configuración (Setup):
-   Inicializar una base de datos de prueba en memoria o en un archivo temporal.
-   Crear instancias reales de `SongRepository`, `CategoryRepository`, y `SetlistRepository` que apunten a esta BD de prueba.
-   Crear una instancia de `SyncService` con estos repositorios.
-   Configurar un `http_mock_adapter` para simular las respuestas de la API (`iniciar_sync`, `subir_cambios`, etc.).

#### Escenarios:

1.  **Subida de una nueva canción:**
    -   **Setup:** Insertar una nueva canción en la BD de prueba.
    -   **Acción:** Llamar a `sincronizarAhora()`. Simular respuestas exitosas del servidor.
    -   **Verificación:** Asegurarse de que el mock de `subir_cambios.php` fue llamado con los datos correctos de la nueva canción.

2.  **Descarga y aplicación de una canción actualizada:**
    -   **Setup:** Insertar una canción "v1" en la BD de prueba. Configurar el mock de `descargar_cambios.php` para que devuelva una versión "v2" de la misma canción (ej. con el título cambiado).
    -   **Acción:** Llamar a `sincronizarAhora()`.
    -   **Verificación:** Consultar la BD de prueba y verificar que la canción ahora tiene los datos de la versión "v2".

3.  **Descarga y aplicación de una canción eliminada:**
    -   **Setup:** Insertar una canción en la BD de prueba. Configurar el mock de `descargar_cambios.php` para que devuelva el ID de esa canción en la lista `cancionesEliminadas`.
    -   **Acción:** Llamar a `sincronizarAhora()`.
    -   **Verificación:** Consultar la BD de prueba y verificar que la canción ya no existe.

4.  **Creación de categorías durante la descarga:**
    -   **Setup:** Configurar el mock de `descargar_cambios.php` para que devuelva una canción con una categoría que no existe en la BD de prueba.
    -   **Acción:** Llamar a `sincronizarAhora()`.
    -   **Verificación:** Consultar la BD y verificar que tanto la canción como la nueva categoría fueron creadas correctamente.

### C. Pruebas de Extremo a Extremo (E2E) (`app_test.dart`)

**Objetivo:** Probar el flujo completo desde la perspectiva del usuario.

#### Configuración (Setup):
-   Utilizar `flutter_test` con `integration_test`.
-   Lanzar la aplicación completa.
-   Utilizar un `ProviderScope` o similar para inyectar una versión del `SyncService` que se comunique con un **servidor simulado**.

#### Escenarios:

1.  **Sincronización exitosa sin cambios:**
    -   **Acción:** El usuario pulsa el botón "Sincronizar".
    -   **Simulación:** El servidor simulado indica que no hay cambios para descargar y no recibe cambios para subir.
    -   **Verificación:** La UI muestra un mensaje de "Sincronización completada" y el estado vuelve a la normalidad. No hay cambios en la lista de canciones visible.

2.  **Sincronización con descarga de nueva canción:**
    -   **Setup:** El servidor simulado está configurado para devolver una nueva canción ("Canción de Prueba E2E").
    -   **Acción:** El usuario pulsa "Sincronizar".
    -   **Verificación:** Después de que la UI indica que la sincronización ha finalizado, verificar que "Canción de Prueba E2E" aparece en la lista de canciones de la aplicación.

3.  **Sincronización con subida de nueva canción:**
    -   **Acción 1:** El usuario crea una nueva canción ("Mi Canción Local") a través de la UI.
    -   **Acción 2:** El usuario pulsa "Sincronizar".
    -   **Verificación:** Verificar que el servidor simulado recibió una petición para crear "Mi Canción Local".

4.  **Manejo de error de red:**
    -   **Setup:** El servidor simulado está configurado para devolver un error 500 (error de servidor).
    -   **Acción:** El usuario pulsa "Sincronizar".
    -   **Verificación:** La UI muestra un mensaje de error claro (ej. "Error de conexión") y el estado de "sincronizando" se desactiva.

