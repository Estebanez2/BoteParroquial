# Notificaciones automáticas, actividad y enlaces

2026-10-20. Entrega de los puntos 1, 2 y 3 solicitados por el usuario.
Implementación y despliegue de servidor terminados; **entrega push y apertura de
enlace en móviles reales aún no comprobadas**. El usuario ejecuta la app.

## Estado entregado

### Recordatorios y servidor

- Worker `notification-worker` desplegado exclusivamente en Supabase
  **BoteParroquialNotificaciones**, ref `qngrmxfjckrrfiyioyzl`, región eu-west-1.
  Fotos continúa en `ietnizafvtovelyuxbvk`; no se despliega allí el worker ni se
  carga su credencial Firebase. Ambos proyectos permanecen en el alcance gratuito;
  no se ha activado Blaze ni solicitado cambio de plan.
- Cron `boteparroquial-notifications`, jobid 1, activo: `*/15 * * * *`.
  El usuario elige comprobar cada quince minutos; no envía repetidos sin cambios.
  Los dos recordatorios de cuota siguen a las 10:00 civiles, siete y un día antes
  de acabar el mes, con recuperación durante ese mismo día y sin arrastre al siguiente.
- Activación de actividad: `2026-10-20T09:39:44.515Z`. Se ignora historia anterior;
  cuotas mensuales consulta el estado actual. Cursor con un segundo de solape y
  margen de cinco segundos para no mezclar commits en curso.
- Bandeja con ID determinista por fuente/categoría/destinatario y creación
  condicional. Nunca sobrescribe readAt de un aviso ya guardado.
- Reserva duradera antes de cada push por aviso/token. Si hay caída o respuesta
  incierta, no se repite ese intento; puede faltar un push, pero queda bandeja.
  FCM no garantiza exactamente una entrega y no se retiran mensajes ya aceptados.
- Relee acceso, rol, obligación/evento, preferencia y registro antes de entregar.
  Solo grupos y membresías activos. Vínculos recíprocos; admin necesita persona
  activa para recibir avisos de gestión. Usuario que salió no recibe; su persona
  pendiente entra en el resumen de gestores. Personas inactivas no reciben recordatorios.
- FCM UNREGISTERED queda en cuarentena privada por grupo/cuenta/huella; los siguientes
  avisos omiten ese token. No borra el registro cliente ni requiere permisos de
  borrado. Un token nuevo tras rotación tiene otra huella y vuelve a ser elegible.
- Texto push discreto, sin cantidades. Endpoint exige secreto propio, POST y `{}`;
  no recibe grupos, importes o destinatarios calculados por Flutter.

### Actividad y preferencias

| Suceso | Destinatarios vigentes |
| --- | --- |
| Solicitud pendiente | Gestores autorizados |
| Solicitud aprobada | Cuenta aceptada; además entrada a gestores |
| Entrada automática/aprobada | Gestores; aviso de falta de vínculo si corresponde |
| Cambio de vínculo | Cuenta afectada; si queda sin vínculo, gestores |
| Ascenso/pérdida de admin, incluida degradación por persona inactiva | Cuenta afectada |
| Ingreso/retirada asociado activo | Cuenta vinculada a la persona |
| Movimiento anulado | Cuenta vinculada a la persona |
| Cambio de cuota | Miembros activos |
| Transferencia | Gestores y cuentas afectadas, sin duplicar destinatario/categoría |
| Código regenerado | Gestores |

Sin autoavisos al autor, excepto cambios de su propio acceso/vínculo/rol. Un suceso
ya resuelto no genera una solicitud pendiente; cambios de rol/vínculo obsoletos no
se presentan como el estado actual. Una corrección económica crea el aviso asociado
al sustituto; no inventa que el original corregido fue «anulado».

Tres preferencias independientes por cuenta/grupo: recordatorios, económico e
informativo. Desactivar push conserva bandeja. Se exige haber activado previamente
ese móvil. Pantalla reutiliza App*; avisos abren cuotas, movimientos, miembros o
invitaciones según su clase, dentro del guard del grupo.

### Enlaces

- Dominio real comprobado y publicado: `https://boteparroquial.web.app`.
  Compartir/copiar enlace produce `/join/{groupId}.{secret}`; copiar código sigue
  disponible. También admite pegar el enlace completo en la app.
- Android App Links con huella SHA-256 real del certificado debug actual. No
  sustituye una configuración futura de firma release/Play App Signing.
- Router conserva únicamente el código válido durante login/restauración; no
  acepta return URLs arbitrarias, otros hosts, HTTP o credenciales dentro del URL.
- Página de ayuda sin SDK, consultas a Firestore, rastreadores o recursos externos.
  Copiar código y abrir Android mediante gesto explícito; sin enlace ficticio a
  una tienda. Cabeceras CSP/no-referrer. Abrir el enlace no concede membresía.
- iOS: entitlements de Associated Domains preparados. Faltan Team ID real, AASA,
  firma/capacidades y verificación con Mac/iPhone. No se publica un Team ID inventado.

Hosting versión `b0b9f141f1b27e66`, release `2026-10-20T09:23:25.100Z`.
No existía una publicación anterior del sitio según la consulta de releases.

## Permisos, secretos y copias

Dos rechazos de revisión automática quedaron resueltos mediante autorizaciones
expresas independientes: identidad/rol IAM, y después creación/transferencia de
su clave privada al segundo Supabase concreto. No se eludieron los rechazos.

Identidad: `boteparroquial-notifications@boteparroquial.iam.gserviceaccount.com`.
Rol propio con seis permisos revisados: envío FCM, lectura/listado de documentos,
consulta de base y creación/actualización. Sin borrado, administración Auth, Rules
o IAM. IAM no limita escrituras por documento; el adaptador las restringe a las
tres colecciones privadas de avisos/entregas/cuarentena y al estado del worker.
La clave robada tendría mayor alcance que el código: motivo para aislar secretos.

Credencial solo en el segundo proyecto, bajo `NOTIFICATION_FIREBASE_CREDENTIALS`.
Secreto del endpoint en Edge secrets y Vault de ese mismo proyecto. Nada en
Flutter, Git o chat. Transferencia por temporales propios eliminados al terminar.
Registro externo conserva solo metadatos, etapas e ID de clave para revocarla.

Respaldo anterior al cambio:

`C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-20T08-59-14-200Z`

Incluye Rules activas, ZIP de 403 archivos con cambios sin commit, APK anterior,
referencia previa de Hosting y políticas IAM anteriores a la asignación. No es
respaldo de documentos, Auth o fotos. No se ha ensayado una restauración.
Para detener avisos, desactivar solo el job con ese nombre en el proyecto nuevo;
para revocar, usar el ID de clave/identidad del registro externo. No restaurar una
política IAM antigua completa sin revisar cambios posteriores ajenos al worker.

Rules de preferencias nuevas publicadas y verificadas:
`projects/boteparroquial/rulesets/b74cba9c-8221-4c48-9226-5ab95ea716c3`;
release `2026-10-20T09:23:23.193385Z`; SHA remoto/local
`c9e4cb547e11c5053f8814eea7ca3622a39eef6e45e7af1b02608532516d3c55`.
Solo cambia el bloque de preferencias. Ver [revisión](PHASE9_ACTIVITY_RULES_REVIEW.md).

## Evidencia ejecutada

- Cinco casos Deno de worker: concurrencia/reserva y push incierto; preferencias,
  baja e historia anterior; matriz de destinatarios; autenticación/cuerpo cerrado;
  cuarentena UNREGISTERED. Un caso adicional de OAuth/alcance/caché y escritura
  condicional. HTTP/FCM simulados, sin Google OAuth real en esas pruebas.
- Se repiten solo casos afectados al añadir diagnóstico/cuarentena; no suites
  generales. Check/lint y formato de los módulos modificados.
- Cuatro casos Flutter dirigidos: parser HTTPS, recorrido enlace→login→vista previa,
  regresión de compartir código/enlace y bandeja ampliada con texto 160 %, ambos
  temas y movimiento reducido. Cuentas y servicios simulados.
- Tres casos del módulo de Rules en emulador demo; el de preferencias ampliado
  con categorías económicas/informativas y denegaciones. No se prueba sobre la base real.
- Análisis final sin incidencias (6,9 s). APK debug compilado (126,5 s), sin
  instalación o ejecución. Advertencias de migración Kotlin del plugin sin error.
- Verificación remota: hash de Rules igual al local; página `/join/DEMO...` HTTP 200;
  assetlinks.json público coincide con el certificado local; CSP/no-referrer.
- Endpoint sin secreto: 401. Primera invocación autenticada dio 503; tras actualizar
  diagnóstico y repetir, 200 con cuatro grupos procesados y cero fallos. No se
  atribuye a una causa confirmada que no se haya demostrado.
- Cron: ejecución real a `2026-10-20T09:45:00Z` con status succeeded; además
  `net._http_response` confirma HTTP 200, cuatro grupos, cero fallos y sin timeout.
  No confundir «SQL encolado» con respuesta del worker: se comprobaron ambos.

APK: `build/app/outputs/flutter-apk/app-debug.apk`, 242.947.342 bytes.
SHA-256: `9e16f87cf6efbbbe0743e55e3e39d270d3bc47f4621bb85aee2674bc8bb529d6`.

### Muestra real creada

Grupo **`demo-notifications-20261020`**, nombre `[Prueba] Pipeline de avisos`.
Ocho documentos de semilla nuevos, en un commit con exists=false: grupo, membresía
de la cuenta de prueba ya conocida, tres preferencias todas false, auditoría de
creación, solicitud ficticia y su auditoría. Sin personas ni movimientos de dinero.
El UID `DEMO-notification-guest` no representa una cuenta Google ni prueba un
segundo rol autenticado; su solicitud no se usa para probar aprobaciones reales.

Invocación posterior: HTTP 200, cinco grupos y cero fallos. En el grupo DEMO hay
exactamente **un** aviso `joinRequested`, destinatario correcto y **cero** intentos
push. El worker crea también su estado privado en los grupos procesados. No se
modifica historia financiera ni se sobrescriben muestras anteriores. No se borra
la muestra; el usuario podrá verla etiquetada como prueba.

## Pendiente de comprobar

- Activar avisos en Android y recibir un push real: primer plano, segundo plano,
  proceso cerrado, pulsación y logout/otro móvil. No se envió un push de prueba real
  en esta entrega. OAuth/Firestore del servidor sí se ejercitan en invocaciones;
  una entrega FCM a un token real sigue sin acreditarse.
- Recordatorio en sus días/10:00 y cambios DST reales: calendario contrastado
  localmente, no simulando fechas del servidor de producción.
- Apertura física Android App Links y permisos con dos/tres cuentas reales.
- iOS/APNs/AASA y release Android. El debug actual no acredita esas variantes.
- Historial extremo: límites técnicos conservadores de 50 grupos por ejecución,
  500 fuentes de cada tipo por ventana y 10.000 documentos del snapshot de cuotas.
  Si se exceden, falla sin truncar ni inventar subtotales. Ampliar con paginación
  persistente/agregados pertenece al trabajo de volumen pendiente del roadmap.

Guía actualizada: [GUIA_PRUEBAS_MOVILES.md](GUIA_PRUEBAS_MOVILES.md).
Scripts de operación no imprimen secretos; no repetir configuración de claves a
ciegas si hay etapas parciales. El registro externo describe lo realmente cargado.
