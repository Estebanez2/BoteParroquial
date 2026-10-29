# Phase 9 — Dispositivos, preferencias y bandeja

2026-10-19. Implementación del cliente terminada; no ejecutada en móvil.
La generación automática y entrega real permanecen pendientes.

## Entregado

- Botón explícito para activar/retirar avisos en Tu perfil y en la bandeja.
  No se solicita permiso al login. SDK auto-init desactivado por defecto.
- Registro privado por cuenta; rotación sustituye su token sin retirar otros
  móviles. El token no se muestra en UI, logs o exportaciones.
- Preferencia de recordatorios por grupo: push o solo bandeja. Su ausencia
  permite recordatorios únicamente si antes se registró expresamente el móvil.
- Bandeja privada del grupo, abierta desde la campana del dashboard. Últimos
  50 avisos por createdAt, sin UID ajenos, con marcado leído transaccional.
  El acceso a cuotas abre los informes actuales; no afirma un cierre histórico.
- Apertura de push con recipientUid/groupId: comprueba cuenta y membresía,
  ignora otro destinatario y aplica de nuevo el guard visual del grupo.
- Logout exige retirar el registro si existía. Journal privado, atómico y
  serializado: UID/huellas de token e intención de alta/retirada. No contiene
  token FCM. Una retirada fallida/reinicio reintenta retirar, no vuelve a dar alta.
  Sin registro, el logout no necesita inicializar Messaging ni escribir servidor.
- Modelos puros; UI → providers → repositories → services → Firebase/archivos.
  La app no crea avisos, destinatarios ni envíos. No se mezcla con photo-access.

Dependencia nueva: firebase_messaging **16.7.0**, fijada para conservar la familia
actual de SDK Firebase; solo se añaden sus dos dependencias de plataforma/web.
Se evita introducir la actualización mayor 17/Firebase 13 en este bloque.
Android declara POST_NOTIFICATIONS y auto-init false. iOS declara auto-init false
y configura el delegado del plugin para UIScene según su API; no se firma ni
compila iOS. APNs/capacidades se prepararán al validar la plataforma Apple.

## Comprobaciones

- Cuatro casos Flutter nuevos distintos superados: consentimiento/alta incierta/
  logout online; rotación/otras cuentas/aislamiento; journal real temporal y
  corrupción; flujo de bandeja, preferencias, leído, registro y pérdida de acceso.
- El flujo visual comprueba oscuro/claro, 360 px, texto 160 %, movimiento reducido
  y apertura para UID correcto (otro UID ignorado). Datos y SDK simulados.
- Una regresión existente de login/perfil privado/logout superada.
- Tres casos de Rules superados en emulador demo, nunca en la base real:
  dispositivos privados/campos/fechas; bandeja acotada/inmutable/aislamiento;
  preferencias propias y acceso activo. Casos de denegación generan errores
  esperados del emulador, sin fallos en la suite.
- Se repiten solo casos afectados: el test visual necesitó mantener una escucha
  durante la consulta directa a un provider autoDispose y comprobar la pantalla
  abierta por push en vez de la URL base de GoRouter. Se verifica otra vez
  consentimiento tras añadir la intención persistente de retirada.
- Dos análisis intermedios detectaron avisos de estilo, corregidos. Análisis
  final **sin incidencias**. `dart format` de archivos afectados.
- APK debug generado en 65,9 s, con advertencias de plugins Kotlin/deprecaciones
  pero sin fallo de compilación. No se instala, arranca o prueba en dispositivo.
- No se repiten suites completas, ni se retoman pruebas manuales aplazadas.

Logs ignorados en `.dart_tool/`: notification-client-tests, withdrawal, inbox-final,
notification-auth-regression, notification-rules-tests, notification-client-analyze-final,
notification-client-build, notification-index-plan y notification-final-backup.

## Respaldo y publicación

El primer intento fue rechazado por revisión automática antes de ejecutar nada.
La autorización expresa posterior del usuario exige otra copia antes de publicar
(D095); ver [revisión concreta](PHASE9_NOTIFICATION_RULES_REVIEW.md).

Nueva copia verificada de las reglas activas:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T18-49-13-767Z
```

Versión activa previa: ruleset `38c2c77a-c18c-4c51-a8a9-f43e9dfa5702`;
SHA-256 `5c776e8d4b9b965ca4fe19a9e14f3564378e5461767a69c59d628098e20c3520`.
No sobrescribe la copia anterior de las 18:33 UTC ni otras etapas.

Instantánea externa anterior a publicar, en la misma carpeta:

- `workspace-before-notification-rules.zip`: **395 archivos**, con cambios
  sin commit y archivos nuevos. SHA-256:
  `d02e2bfe43027e0377fa176559b5da30551dfb673a591c3c8405a667da48cd2b`.
- `app-debug-notifications-prepared.apk`: APK de cliente ya preparado, copia
  comprobada contra el compilado; SHA-256:
  `62cce576ac6d545ddf82d9fef017dbe091943a0bf80eebb34fec220a0de7dce1`.
- `workspace-manifest.json`, estado Git y `WORKSPACE_RESTORE.md`. ZIP abierto y
  número de entradas verificado. HEAD informativo e00938c2bf0b1abaa70733973aa0605aebecfd9b;
  no equivale a esta instantánea con cambios locales. No se crea un commit.

Reglas publicadas después de esa copia, verificadas por lectura remota:

- Ruleset `projects/boteparroquial/rulesets/df77f648-376c-4c4d-a049-91e1db95ad44`.
- Release `2026-10-19T18:52:52.358695Z`.
- SHA-256 local/remoto:
  `0348d54d0619a3f73c0f331bd57fa22f39ee2eb60201c1d06911f25f5a9dff4f`.
- Comparación contra respaldo: sin los tres bloques nuevos, las reglas anteriores
  permanecen idénticas. No se reescribe seguridad financiera.
- Índice nuevo `CICAgOi3kJAK`, collectionGroup notifications, ámbito COLLECTION,
  recipientUid ASC/createdAt DESC. Se esperó a su construcción y se confirmó
  **READY** mediante consulta remota; no se da por listo mientras figura CREATING.
- `tools/prepare_notification_index.cjs`: consulta por defecto; --apply crea
  exclusivamente ese índice si no existe, nunca borra índices ajenos.

La política de PowerShell bloqueó cargar el script local de copia sin firma;
se ejecutaron los mismos comandos revisados directamente, sin cambiar directivas.
No hubo copia parcial previa ni sobrescritura de respaldos.

El respaldo de proyecto debe distinguir el código local ya preparado de las
reglas remotas todavía anteriores. No incluye documentos Firestore, usuarios
Auth u objetos de fotos; tampoco equivale a un commit o a un APK de una fase anterior.
El informe dentro del ZIP conserva el momento anterior a publicar; el documento
actual del repositorio registra el despliegue posterior. No se probó restaurar.

## Pendiente real

- Worker Supabase: cálculo autoritativo de cuotas, destinatarios vigentes, resumen
  por grupo, preferencias, escritura idempotente de avisos y entregas FCM.
- Credenciales mínimas de servidor, deduplicación, recuperación y cron a las 10:00
  civiles, 7 y 1 días antes del final del mes. No se ha cambiado IAM, configurado
  claves, desplegado funciones/cron ni activado facturación en esta entrega.
- Definir preferencias/destinatarios de los demás sucesos de §53; solo se configura
  aquí la preferencia de recordatorios, no categorías inventadas.
- APNs, firma/capacidades y compilación/prueba de iOS con Mac/dispositivo.
- Registro/permisos/tap/retirada reales en Android y llegada de notificaciones,
  incluido cierre completo de proceso, cuando exista servidor. Lo ejecuta el usuario.
- La retirada impide futuros envíos que consulten el registro actualizado; no
  puede retirar un aviso ya aceptado/entregado por FCM antes de confirmarla.
- La bandeja está acotada a 50 avisos recientes, no es exportación/historial ilimitado.
  Un grupo sin avisos no indica que no tenga cuotas pendientes.

No se han sembrado datos ni enviado push de prueba a cuentas reales.

Comprobación final de espacios en los archivos afectados: `git diff --check`
sin errores. Las advertencias habituales LF/CRLF no son fallos de contenido.
