# Copias: aviso compacto y acceso sin red — D142

El usuario confirma que la copia se guarda y abre y que Editar foto actual funciona
en su móvil. No se extiende esa confirmación a otros móviles, roles ni iOS.

## Cambios

- AppReadOnlyBanner: una fila compacta con «COPIA GUARDADA · SOLO LECTURA», fecha
  y botón «Datos actuales». El aviso permanece al navegar. No se reducen las áreas
  táctiles; se retiran los envoltorios y la explicación larga del bloque anterior.
- DailyCopyRecovery: junto al reintento de red en perfil/lista de grupos/acceso,
  acceso al catálogo de copias del móvil. Desde allí se elige la fecha. Si aún no
  hay copias, el catálogo lo indica; no se inventa una copia ni se descarga sin red.
- El aviso de actualización pendiente dentro de grupos ya ofrecía este acceso y
  se conserva. El visor aislado no muestra atajos a la fuente viva por un error.
- Sin cambios de backend, datos, reglas, cifrado, conservación o permisos.

## Verificación

Solo dos casos dirigidos: navegación a catálogo por error de red sin reemplazar
reintento y sin ofrecerlo ante denegación/visor; regresión del visor aislado y
altura compacta y texto al doble de tamaño. Registros: .dart_tool/offline-compact-recovery.log y
.dart_tool/offline-compact-viewer.log. Ambos superados. El visor sigue bloqueando
escrituras y SDKs remotos. Análisis limpio: .dart_tool/offline-compact-analyze.log.
APK profile compilado en build/app/outputs/flutter-apk/app-profile.apk;
registro .dart_tool/offline-compact-profile.log. No instalado ni ejecutado por el agente.
SHA256: 170751263bf0e6cd3c18d7f7c68bcdbec85fc2353cd3dde9e92f961326172de6.

## Comprobar en móvil

Instalar el profile actualizado con `adb install -r` (comando en sección 26 de
GUIA_PRUEBAS_MOVILES.md). El usuario ejecuta la app.

1. Abrir una copia: comprobar franja pequeña, fecha y solo lectura; navegar a
   otra sección y comprobar que persiste. «Datos actuales» sale del visor.
2. Con copia guardada, desconectar Internet. Si aparece un reintento de red en
   Inicio o al abrir un grupo, debe ofrecer también copias. Si carga caché dentro
   del grupo, usar el acceso del aviso de actualización pendiente.
3. Abrir el catálogo, elegir una copia y consultar sin red. No debe permitir
   escribir ni confundir la fecha archivada con datos actuales. Recuperar red.
4. Con texto ampliado, comprobar que la franja sigue legible sin solapamientos.

Estos cambios nuevos de presentación/acceso quedan pendientes de prueba física.
