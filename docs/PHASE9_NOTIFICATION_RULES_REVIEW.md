# Revisión de permisos — dispositivos y bandeja

2026-10-19. Revisión del candidato completo en `firestore.rules`.
**Publicado tras autorización y nueva copia; índice READY**. Evidencia en
[PHASE9_NOTIFICATION_CLIENT_VALIDATION.md](PHASE9_NOTIFICATION_CLIENT_VALIDATION.md).

## Cambio concreto propuesto

Proyecto `boteparroquial`, base `(default)`:

- `users/{uid}/pushDevices/{deviceId}`: solo su cuenta autenticada lee,
  registra, actualiza o retira dispositivos. Campos cerrados: token, plataforma
  android/ios y fechas de servidor. Creación protegida, createdAt inmutable,
  identificador hexadecimal de 64 caracteres. No concede roles ni lee perfiles
  de otras cuentas. Son tokens de entrega FCM, no credenciales de autenticación.
- `groups/{groupId}/members/{uid}/notificationPreferences/reminders`: solo su
  cuenta con membresía activa en un grupo activo consulta/cambia su preferencia.
  Solo booleano `quotaPushEnabled` y `updatedAt` de servidor.
- `groups/{groupId}/notifications/{notificationId}`: solo el destinatario con
  acceso activo al grupo lee. La consulta filtra UID y limita a 50 resultados.
  Solo puede pasar readAt de null a fecha de servidor; contenido/destinatario
  inmutables. Nadie desde la app, ni owner/admin, crea o elimina avisos.
- Índice nuevo exclusivamente para `notifications`: recipientUid ascendente,
  createdAt descendente, ámbito COLLECTION. La herramienta crea solo este índice;
  no borra ni modifica índices anteriores.

No se modifica ninguna regla financiera, de vínculos, miembros, fotos o perfiles
ya existente. Comparación automática: quitando exclusivamente los tres bloques
nuevos, el archivo coincide con la copia de las reglas activas.
SHA-256 del candidato:
`0348d54d0619a3f73c0f331bd57fa22f39ee2eb60201c1d06911f25f5a9dff4f`.

## Respaldo y comprobaciones

Copia externa verificada, sin sobrescribir las anteriores:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T18-33-56-773Z
```

Ruleset respaldado `38c2c77a-c18c-4c51-a8a9-f43e9dfa5702`;
SHA-256 `5c776e8d4b9b965ca4fe19a9e14f3564378e5461767a69c59d628098e20c3520`.
Incluye manifest/fuente/configuración y RESTORE.md. No es copia de documentos,
Auth, índices o fotos. No se ha probado una restauración.

- Tres pruebas nuevas de Rules superadas en emulador demo, ajeno a la base real:
  privacidad/integridad de dispositivos; consulta/marcado y prohibición de
  falsificar/borrar avisos; preferencias y revocación/inactividad del grupo.
- Cuatro pruebas Flutter distintas del flujo nuevo superadas; una regresión de
  login/logout existente superada. Solo se repiten casos afectados por ajustes.
- `flutter analyze --no-pub`: sin incidencias.
- `flutter build apk --debug --no-pub`: APK generado, sin instalación/ejecución.
- Índice consultado en modo plan, sin crearlo. Sin documentos DEMO remotos.

## Estado de autorización

El intento conjunto de crear el índice y publicar Rules fue rechazado por la
revisión automática antes de ejecutar el proceso: considera que la aprobación
previa para devoluciones no acredita autorización exacta para esta nueva frontera
de dispositivos/bandeja. No se ha eludido el rechazo ni realizado una publicación
indirecta. El usuario autoriza después crear otra copia y publicar. Se guarda una
nueva copia externa de reglas, proyecto actual y APK; autorización ejercida y
hash publicado coincidente con el candidato. Estado final en la validación enlazada.

El rechazo inicial quedó resuelto por esa autorización. El worker y los envíos
automáticos son otro bloque; esta publicación no activa recordatorios ni facturación.
