# Phase 6 — Robustez del MVP

2026-10-15. Implementación de caché señalizada, recuperación de envíos y calendario
del grupo. La fase sigue abierta hasta las comprobaciones de cierre que se indican
abajo. El usuario confirma que el Dashboard anterior funciona en el móvil conectado;
esa confirmación no se extiende automáticamente a estos cambios nuevos.

## Cambios y decisiones

- Consulta offline de datos disponibles, con aviso cuando las fuentes de grupo,
  membresía, personas, miembros y movimientos no están confirmadas por servidor.
  Caché vacía puede estar incompleta; no es un detector de Wi-Fi/Internet.
- Confirmación económica online: revisión con lectura Source.server y escritura
  mediante transacciones existentes; no hay cola automática de dinero offline.
- Antes del envío se conserva la intención en archivo privado por UID/grupo,
  incluyendo ID, datos y versión del original. Escritura temporal, flush y rename;
  serialización de operaciones de archivo y limpieza condicionada al ID.
- Al volver al grupo se consulta el resultado. Si coincide, se limpia solo el
  intento local; si falta, se ofrece revisión/reintento explícito con el mismo ID.
  Registrar otra intención no sobrescribe la pendiente. Cuenta distinta no la ve.
- Descartar un intento exige revisar historial y confirmar, y una lectura online.
  Nunca borra/anula un movimiento ni cancela una solicitud anterior en curso.
- El inicio permite acceder a grupos aunque actualizar el perfil esté cargando o
  falle. Los providers de Groups seleccionan streams sin Ref diferido.
- Calendario IANA de la zona del grupo, con cambios de verano/invierno. Selector,
  validación y envío usan esa referencia. Zona desconocida bloquea, no se inventa.
- Rules exige occurredAt == occurredAt.date(), cerrando envíos con horas arbitrarias.
  Regla publicada en boteparroquial, ruleset `3a47ea62-c02e-47d8-ab82-deb95b2313ad`.
- Dependencias: path_provider 2.1.6 (archivos privados Android/iOS), timezone 0.11.2.
  Sin nuevas colecciones, campos financieros, índices, Functions ni datos DEMO.

## Evidencia

- Análisis estático sin incidencias y APK normal debug compilado.
- Pruebas Flutter dirigidas: 11 casos distintos entre recuperación (3), movimientos
  (1), grupos (4), Dashboard (2) y personas (1). Se repiten únicamente los afectados
  al ajustar descarte/calendario/indicador; no se ejecuta la suite completa.
- Recuperación usa archivos reales temporales y reconstruye repository/adaptador:
  respuesta perdida tras registro/corrección/anulación, resultado ausente y reintento,
  aislamiento de UID/grupo, bloqueo de otro envío, limpieza de ID incorrecto,
  conflicto concurrente y descarte bloqueado sin servidor. No simula un corte eléctrico.
- Flujo visual comprueba recuperación explícita con aviso por persona inactiva.
  Dashboard comprueba aviso de frescura al pasar de caché a confirmación; el caso
  de grupos permite acceder pese a error de perfil.
- Calendario comprueba Europe/Madrid en invierno/verano, otra zona y zona inválida,
  además de validar la misma fecha contra dos calendarios distintos.
- Cuatro pruebas económicas de Rules pasan en emulador: permisos, integridad,
  correcciones, estados terminales y concurrencia. Se añade rechazo de fecha con hora.
  No se repiten suites de Rules de perfiles/personas que no se han modificado.
- APK instalado con éxito en A059P, sesión/datos conservados; proceso observado.
  Esto por sí solo no demuestra recuperación, funcionamiento offline ni dos cuentas.
  En el primer arranque observado, Firestore notifica UNAVAILABLE y el inicio está
  cargando perfil/grupos. Se solicita al usuario comprobar la conexión del móvil;
  no se registra ese arranque como flujo validado. Jerarquía inicial en
  .dart_tool/phase6-ui.xml y despliegue en .dart_tool/phase6-rules-deploy.log, fuera de Git.
- Confirmación posterior del usuario (2026-10-15): «He activado la conexión y ya
  aparecen los grupos». Queda confirmada la carga online de grupos con el nuevo
  APK y resuelta la comprobación de conexión solicitada. No se atribuyen pruebas
  de caché, recuperación tras cierre ni operaciones económicas a esa confirmación.

## Límites y cierre pendiente

- Comprobar físicamente estos cambios: consulta de caché, recuperación tras cierre
  y errores/reintentos en el SDK Android real. Las pruebas de archivos son locales
  y las financieras de recuperación usan un servicio simulado.
- El reloj del dispositivo sigue aportando el instante. Rules conserva el margen
  request.time+24 h; no valida «hoy» exactamente por zona IANA. No afirmar lo contrario.
- Un aviso de saldo negativo no reserva saldo frente a otros administradores.
- Desinstalar/borrar datos elimina el diario local; descartar no detiene solicitudes
  anteriores. Revisar historial antes de iniciar otra intención en esos casos.
- Caché permite ver lo previamente disponible sin consultar permisos actuales en
  servidor; una revocación offline no puede detectarse al instante. Al reconectar,
  Rules y los guards rechazan el acceso. No se habilita ninguna escritura por caché.
- Segunda cuenta y sincronización entre dos móviles siguen aplazadas. No se han
  retomado las comprobaciones manuales de autenticación de Phase 1.
- Revisar UX/accesibilidad final y acordar transición de DEMO a uso real; no se
  borra ni reinicia la base. iOS necesita Mac/Xcode para validación nativa.

Referencias de implementación: [metadata y caché de Firestore](https://firebase.google.com/docs/firestore/manage-data/enable-offline),
[Timestamp.date en Rules](https://firebase.google.com/docs/reference/rules/rules.Timestamp_?hl=en),
[path_provider](https://pub.dev/packages/path_provider) y [timezone](https://pub.dev/packages/timezone).
Registro general: [ROADMAP.md](ROADMAP.md).
