# Inicio, copias y edición de fotos — 03/11/2026

## Cambios entregados

- Laboratorio de animaciones oculto. Se conserva su código aislado para recuperarlo
  si se pide; los efectos seleccionados de producción siguen funcionando.
- Tus grupos: portada horizontal y datos debajo, rol, moneda, saldo y entrada
  diferenciada. Se conserva la onda y expansión desde la tarjeta.
- Nombre del grupo sobre la foto, arriba a la izquierda, con degradado para
  mantener legibilidad. Inicio deja las operaciones económicas en Actividad,
  conserva el saldo y retira el texto «Todo el historial · Solo movimientos activos».
- Resumen destacado, login renovado y retirada de la carga fugaz del perfil sobre
  Tus grupos. La carga real de grupos conserva sus esqueletos.
- Gráfica de saldo de seis meses: tocar un punto muestra el importe de ese mes.
  Acumula movimientos activos anteriores al cierre de cada mes, incluyendo el
  dinero anterior a los seis meses. El mes actual está en curso. Refleja el estado
  actual de anulaciones/correcciones, no una reconstrucción histórica al corte.
- Copias: panel visible con brillo mientras comprueba acceso, descarga y verifica.
- Edición de avatares con máscara circular; portadas mantienen editor 16:9.
  Editar foto actual reutiliza los bytes descargados y no exige buscarla de nuevo.

## Causas de los fallos

**Copias:** el lector pedía 200 documentos por página también para notificaciones.
Las reglas de esa colección exigen un máximo de 50. La denegación ocurre incluso
si no hay avisos. Reproducido por REST con identidad de cliente en el emulador;
corregido el tamaño de página y su condición de continuación. Se siguen leyendo
todas las páginas con el mismo readTime. No se han ampliado reglas ni permisos.

**Editar foto actual:** el servicio intentaba crear un temporal dentro de una
carpeta que no existía. Ahora usa createTemp sobre el directorio temporal existente,
espera al recorte/preparación y elimina solo su carpeta de trabajo. Cancelar conserva
la foto actual. Edita la imagen guardada, sin recuperar partes ya recortadas de un
original que nunca se almacenó.

## Arquitectura y límites

Componentes compartidos AppGroupPreview, AppWelcomePanel y AppLineChart; colores,
tipografía y espacios del Design System. La gráfica solo convierte a double para
coordenadas de dibujo; sus cantidades y etiquetas mantienen céntimos enteros.

UI → dashboardTrendProvider → MovementRepository → MovementTrendSource → servicio
Firestore. En vivo usa doce sumas agregadas para seis cierres, sin descargar el
historial completo. Actualiza al cambiar la caja existente y al cambiar el mes;
no añade un listener permanente. Puede consumir lecturas agregadas al actualizar.
La gráfica y la tarjeta de saldo son lecturas separadas. En el visor local usa
los movimientos completos de la copia y su calendario congelado, sin SDK remoto.
Los errores se muestran con reintento y no se convierten en saldo cero.

Se conservan siete copias cifradas por cuenta/móvil, aislamiento de consulta,
fotos según caché y copias anteriores ante fallo. No se han modificado datos
remotos, funciones Supabase, índices, cuentas ni credenciales. Rules local sin
cambios: SHA256 fee05c4c229be0c907840b47c6c5269213c2f419955620c6d7d8f81f75556055.

## Verificación realizada

Ocho casos dirigidos distintos superados, sin ejecutar la suite completa:

1. REST con token de cliente y reglas actuales: membresías, documentos presentes
   y ausentes, subcolecciones y bandeja privada. Reproducción previa del 403 y
   lectura posterior autorizada. tools/firestore-rules/snapshot_reads.test.cjs;
   log .dart_tool/copies-read-permissions.log.
2. Lector de copia: 51 avisos en dos páginas, movimientos paginados, readTime
   estable y rechazo por cuenta/permisos cambiados. daily_snapshots_test.dart;
   log .dart_tool/home-copies-reader.log.
3. Servicio real de edición con canal nativo simulado: temporal, cancelación,
   preparación JPEG, limpieza, máscara circular y portada rectangular.
   native_photo_edit_test.dart; log .dart_tool/home-native-photo-test.log.
4. Flujo de galería/foto actual: cancelar y guardar explícitamente.
   photos_test.dart; log .dart_tool/home-photo-flow-test.log.
5. Cálculo de seis cierres, saldo previo, estados, fecha efectiva, negativos,
   cantidades superiores a 2^53 y rechazo de otro grupo.
   balance_trend_test.dart; log .dart_tool/home-balance-trend-test.log.
6. Login, perfil y cierre de sesión con UI renovada. auth_flow_test.dart;
   log .dart_tool/home-login-test.log.
7. Visor local aislado, sin acceso a SDK remoto. daily_snapshots_test.dart;
   log .dart_tool/home-snapshot-viewer.log.
8. Dashboard, gráfica, portada, retirada de acciones/laboratorio, navegación,
   texto ampliado y revocación. dashboard_test.dart;
   log .dart_tool/home-dashboard-flow.log.

flutter analyze --no-pub limpio: .dart_tool/home-copies-photos-analyze-final.log.
APK profile compilado: build/app/outputs/flutter-apk/app-profile.apk.
SHA256: 6f49406801bce3b36170899b87d3c9ed3240c5604939ff0323e40f7ad2a34b08.
Registro: .dart_tool/home-copies-photos-profile.log.

APK debug compilado: build/app/outputs/flutter-apk/app-debug.apk.
SHA256: 29f87562205e5659a3a1e2d0d6cb2845e0ffbf815ba7c5d921aeb3441f343f1a.
Registro: .dart_tool/home-copies-photos-debug.log. No se ha instalado ni arrancado
automáticamente ninguno de los dos APK. No se han generado capturas de esta UI.

## Confirmación física y continuación D142

El usuario confirma el 03/11/2026: «se guarda y abre» para la copia, y «Sí,
funciona» al editar la foto actual. Esto acredita esos dos flujos en su móvil;
no acredita otros dispositivos/roles, iOS ni todos los escenarios sin conexión.

Después solicita reducir el aviso del visor y acceder a copias junto al reintento
sin red. AppReadOnlyBanner sustituye el bloque grande por fecha, solo lectura y
botón compacto «Datos actuales», manteniendo objetivo táctil accesible. Acceso
al catálogo junto a errores de red de perfil/grupos/acceso; no ante denegación
de permisos ni dentro de un visor aislado. El aviso de sincronización de grupo
conserva su acceso existente. Nunca se cambia automáticamente de fuente ni se
mezclan datos de caché con copias. Evidencia: OFFLINE_COMPACT_ACCESS_2026-11-03.md.

## Límites de la comprobación

El usuario instala y ejecuta. La confirmación anterior resuelve los dos fallos
comunicados; no implica una auditoría de cifrado/almacenamiento ni de permisos.
No se han probado iOS, otro móvil ni otros roles en esta entrega.
Recorrido actualizado: sección 26 de GUIA_PRUEBAS_MOVILES.md.
