# Worker de avisos — despliegue revisable

2026-10-20. El usuario solicita completar recordatorios, avisos de actividad y
enlaces, y acepta un **segundo Supabase gratuito** para aislar secretos del módulo
de fotos. No usar el proyecto de fotos `ietnizafvtovelyuxbvk` para este worker.
La CLI exigió `--db-password` al crear sin interacción. El usuario creó manualmente
**BoteParroquialNotificaciones**, ref `qngrmxfjckrrfiyioyzl`, eu-west-1, y comunicó
solo su URL. Worker, secretos y cron están desplegados allí. Estado final:
[PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md](PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md).

## Identidad de Firebase autorizada y aplicada

`boteparroquial-notifications@boteparroquial.iam.gserviceaccount.com` y rol
personalizado `projects/boteparroquial/roles/BoteParroquialNotifications`:

- `cloudmessaging.messages.create`: entregar por FCM.
- `datastore.databases.get`, `datastore.entities.get/list`: transacciones de
  lectura, contexto vigente, cuotas, fuentes de actividad y dispositivos.
- `datastore.entities.create/update`: bandeja, reservas e indicadores del worker.

No Editor/Owner, IAM, claves de otras identidades, administración de Auth, Rules
o borrado de documentos. IAM de Firestore no restringe estos permisos a las
subcolecciones del worker: el adaptador añade esa restricción en código, pero una
credencial robada podría leer/modificar otros documentos. Esa es la razón de
aislar el proyecto y no exponer la credencial a photo-access.

`tools/provision_notification_identity.cjs` muestra el plan por defecto. `--apply
--backup RUTA_ABSOLUTA` guarda primero la política IAM y conserva sus bindings/etag;
crea/reutiliza solo esta identidad y este rol. Se niega a sustituir un rol existente
con permisos distintos. No crea claves ni activa facturación.

## Procedimiento aplicado al proyecto aislado

1. Comprobar que el nuevo proyecto es distinto al de fotos, pertenece a la
   organización autorizada y mantiene Free. No contratar ni cambiar planes.
2. Crear una clave solo para la identidad dedicada y cargarla exclusivamente en
   los secretos de ese nuevo proyecto como `NOTIFICATION_FIREBASE_CREDENTIALS`.
   Transferencia por memoria/archivo temporal privado, nunca Flutter, Git, chat,
   argumentos de comandos o logs. Retirar temporales; registrar solo el ID de clave
   para revocarla. Ante fallo, no dejar una clave sin destino documentado.
3. Generar un secreto aleatorio del worker (`NOTIFICATION_WORKER_SECRET`) y
   `NOTIFICATION_STARTED_AT`: actividad nueva desde activación, sin repasar historia.
4. Desplegar explícitamente **solo** `notification-worker` al ref nuevo. Bootstrap
   rechaza el URL del proyecto de fotos; endpoint exige POST, secreto propio y
   cuerpo `{}`. No acepta destinatarios, grupo, fecha o importes del cliente.
5. Guardar URL y secreto del worker en Vault del proyecto nuevo. Instalar
   `supabase/notifications_cron.sql` tras validar entrega/recuperación. El usuario
   elige **quince minutos**: sin cambios nuevos no hay avisos repetidos. La demora
   normal de un aviso de actividad puede llegar aproximadamente a ese intervalo.
6. Verificar invocación sin secreto rechazada, ejecución autenticada, métricas y
   persistencia; realizar entrega controlada cuando esté autorizado el destino.

El archivo de cron no contiene secretos y sustituye exclusivamente el job
`boteparroquial-notifications`. No despliegues todas las funciones sin indicar
nombre/ref: el proyecto de fotos tiene otra responsabilidad y otros secretos.

## Límite de entrega aceptado

El usuario prefiere no repetir push inciertos. Se crea primero una reserva duradera
por aviso/token. Si el proceso cae tras reservar y antes de conocer el resultado,
ese token no se reenvía: puede faltar un push, pero el aviso permanece en bandeja.
No se promete exactamente una entrega por parte de FCM. Las preferencias suprimen
push, no la bandeja. Bajas/roles/obligaciones se vuelven a comprobar antes de enviar;
no se retira un mensaje que FCM ya haya aceptado.

## Autorizaciones resueltas

La revisión automática rechazó el primer intento de aplicar la identidad/rol por
considerar insuficiente la autorización explícita del acceso persistente y su
alcance sobre Firestore. **Ese intento no ejecutó la herramienta**. El usuario
autorizó expresamente esa cuenta y esos permisos; después se aplicaron conservando
la política previa. Un segundo rechazo sobre la clave se resolvió con otra
autorización expresa para crearla y transferirla solo al proyecto nuevo. Se
guardó el ID externo y se eliminaron los temporales. No queda permiso pendiente.

Cron activo `*/15 * * * *`, jobid 1. Invocación sin secreto 401; autenticada 200,
cron con respuesta HTTP 200 y muestra de bandeja verificados. Entrega física FCM
pendiente. El respaldo externo incluye Rules/proyecto/APK, metadatos Hosting y
políticas IAM anteriores; no documentos ni fotos. No repetir el aprovisionamiento
de claves: revisar primero el registro externo para evitar crear credenciales de
más. Para operación normal usar verificación y despliegue de la función nombrada.
