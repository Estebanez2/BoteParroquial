BoteParroquial — Instrucciones para agentes

Entrega 2026-10-23, D110–D112: copias diarias locales de consulta implementadas.
Siete últimas capturas diarias completas por UID/móvil, con Wi-Fi o datos móviles;
datos de su ámbito Firestore y fotos según caché. No sustituir por un volcado global
con privilegios, ni almacenar tokens o claves de servidor. readTime coherente y
día de servidor Europe/Madrid; calendario de informes congelado en la copia.
AES-GCM, clave segura por cuenta, JSON/cifrado en isolate, publicación verificada
y archivo anterior conservado ante fallos. No consumir la primera copia con cero
grupos: iniciar al incorporarse a uno. Primera copia válida del día, siete capturas
satisfactorias, no generación con la app cerrada. Fuente normal y visor separados;
visor usa ProviderContainer sin SDKs, rutas/operaciones de escritura bloqueadas y
aviso fijo de fecha/solo lectura. Revalidar permisos online, retirar ámbitos al
confirmar cambio y limpiar al salir/cambiar cuenta. Offline no detecta revocación.
Sin Rules/índices/despliegue/reset nuevos. Copia semanal del portátil sigue aplazada.
Evidencia, APK y pruebas físicas pendientes: docs/DAILY_OFFLINE_COPIES_VALIDATION.md;
guía COP-01–10 en docs/GUIA_PRUEBAS_MOVILES.md. El usuario ejecuta la app.

Entrega vigente 2026-10-20 (D105–D109): PDF/Excel/CSV, auditoría ampliada,
papelera/purga explícita, eliminación de grupo y baja propia implementadas y
publicadas. Caja con sumas REST int64 coherentes y escucha acotada, sin double;
cuotas comparten ingresos/devoluciones, periodos y asignaciones y aún crecen con
la historia. Reinicio autorizado ejecutado con copias externas: 63 documentos
y 3 fotos anteriores retirados; 1.254 documentos DEMO creados y releídos, después
dos estados técnicos del worker. Dos grupos, 20 personas visibles, 280 movimientos;
owner ale.manu.cristi@gmail.com. Auth/configuración conservados. No repetir el
reinicio sin nueva autorización. Copia semanal/visor aplazados expresamente.
Rules finales SHA256 35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1;
photo-access v4/lifecycle-cleanup v1 solo fotos; worker v5 solo avisos y cron activo
cada quince minutos. No IAM/clave nuevos. APK compilado, usuario ejecuta la app.
Estado/evidencia/límites: docs/FULL_PRODUCT_COMPLETION_2026-10-20.md; inventario:
docs/DEMO_DATOS_2026-10-20.md; recuperación: docs/RECUPERACION_DATOS_2026-10-20.md;
guía: docs/GUIA_PRUEBAS_MOVILES.md. Los párrafos históricos inferiores no revierten
este estado. No dar por validadas pruebas físicas, iOS/APNs ni restauración remota.

Continuación Phase 11, 2026-10-20: historial administrativo paginado, cincuenta
por página y botón «Cargar más» elegido en D104. Búsqueda/filtros sobre cargados,
detalle antes/después con permisos reactivos; cursor ligado al grupo conserva
segundos/nanosegundos e ID. Al paginar se congela la cabecera y se anuncian cambios
nuevos para actualizar; no mezclar páginas de otra cuenta/consulta. Sin cambios
de escrituras, Rules, índices o despliegues. Es consulta de eventos existentes,
no auditoría completa ni papelera. Estado y evidencia:
docs/PHASE11_AUDIT_HISTORY_VALIDATION.md. Usuario ejecuta la app.

Continuación vigente Phase 10, 2026-10-20: comparaciones de mes/trimestre/año en
Informes. D103: usuario elige mismo tramo transcurrido para periodos en curso;
los terminados completos, ajustando al último día si el mes anterior es más corto.
Caja por fecha efectiva; cuotas mensuales completas y estado actualizado D088–D090,
sin reconstrucción al corte ni futuros como deuda. Diferencias de cumplimiento
en puntos porcentuales; base cero/desconocida no inventa porcentajes. Reutiliza
lecturas, sin escrituras/despliegues remotos. Evidencia y pendientes:
docs/PHASE10_PERIOD_COMPARISONS_VALIDATION.md. El usuario ejecuta la app.

Estado vigente 2026-10-20 (D097–D102): worker y cron cada quince minutos
desplegados en el segundo Supabase BoteParroquialNotificaciones,
qngrmxfjckrrfiyioyzl, aislado de fotos. IAM y transferencia de la clave dedicada
autorizados expresamente por separado; secretos solo allí, nunca en Flutter/Git.
Recordatorios 10:00, actividad nueva desde 09:39:44.515Z, bandeja y reservas
duraderas; no repetir push inciertos. Preferencias independientes de recordatorios,
económico e informativo. Enlaces HTTPS publicados en boteparroquial.web.app;
Android debug preparado, apertura física e iOS/AASA/APNs pendientes. Reglas
publicadas y nueva copia externa. Cron/HTTP y una bandeja DEMO verificados;
ninguna entrega FCM a móvil acreditada. No repetir la creación de claves ni el
aprovisionamiento: consultar docs/PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md
y el registro externo. El usuario ejecuta la app. Los párrafos siguientes
conservan la secuencia histórica; sus pendientes de worker/cron están resueltos
por esta entrega, no los de pruebas físicas.

2026-10-20: terminada docs/GUIA_PRUEBAS_MOVILES.md para dos móviles y tercero
opcional. No supone ejecución ni aprobación física. Continuación Phase 9:
dominio Deno de recordatorios y lector REST readOnly coherente por grupo, con
fixtures compartidos contra informes reales de Dart. D096: usuarios que salieron
no reciben avisos; sus personas pendientes entran en el resumen de gestores.
Recuperar el recordatorio desde las 10:00 durante el mismo día del grupo, no al
siguiente. No hay todavía worker/cron, claves o reservas persistentes; la clave
lógica estable no garantiza deduplicación de entregas. No conectar estos módulos
a photo-access ni confiar en planes de Flutter para enviar. Estado y evidencia:
docs/PHASE9_REMINDER_SERVER_CALCULATION.md. El usuario ejecuta la app.

Continuación 2026-10-19 de Phase 9 (D091): el usuario elige Supabase + Firebase
Cloud Messaging dentro de cuotas gratuitas, sin activar Blaze ni planes de pago.
Recordatorios a las 10:00 de cada grupo. D092: push discreto sin importes y resumen
por grupo para gestores por personas sin usuario. D093/D094: permiso mediante botón,
preferencia por grupo y retirada confirmada antes de logout. Registro/rotación de
dispositivos, bandeja privada (últimos 50), preferencias y marcado leído implementados.
Firebase Messaging 16.7.0, auto-init desactivado hasta consentimiento; journal privado
de UID/huellas conserva tanto altas inciertas como la intención de retirar. Al
reiniciar una retirada pendiente, no reactivar. No guardar tokens de entrega en
ese fichero; sí en el registro remoto privado. AuthRepository coordina la retirada
antes de cerrar sesión; exige conexión si hay registro. El APK compila y hay pruebas
dirigidas, sin ejecución física. Publicación y respaldo exactos en
docs/PHASE9_NOTIFICATION_CLIENT_VALIDATION.md; no asumir permisos activos sin leerlo.
Publicación autorizada expresamente después del rechazo automático: nueva copia
externa de reglas/proyecto/APK, hash remoto/local coincidente e índice READY.
Worker/cron, generación de avisos, credenciales de servidor y APNs siguen pendientes.
No se ha cambiado IAM ni configurado claves. No introducir secretos en Flutter/Git ni dar acceso al módulo
de fotos a credenciales privilegiadas. El plan del cliente no autoriza envíos:
recalcular y comprobar membresía/preferencias en el futuro servidor. Ver
docs/PHASE9_NOTIFICATIONS_FOUNDATION.md para evidencia y pendientes exactos.

Este es el documento principal de instrucciones para Codex y otros agentes que trabajen en este repositorio.

Antes de realizar cambios:

Leer README.md para conocer el estado real del proyecto.

Leer PRODUCT_SPEC.md si el cambio afecta al producto.

Leer ARCHITECTURE.md si afecta a estructura o dependencias.

Leer FIREBASE_SCHEMA.md si afecta a datos.

Leer CODING_RULES.md antes de implementar código.

Consultar docs/DECISIONS.md para no contradecir decisiones ya tomadas.

Consultar docs/ROADMAP.md para respetar la fase actual.

Leer DESIGN_SYSTEM.md antes de crear o modificar UI.

Seguimiento del trabajo:

docs/ROADMAP.md es el registro general de fases completadas y pendientes.
Las comprobaciones detalladas de autenticación están en docs/PHASE1_VALIDATION.md.
Al terminar una tarea, actualizar el estado, la evidencia comprobada y los pendientes.
Mantener README.md y los documentos de validación coherentes con ese registro.
No confundir implementación terminada con validación completa ni dar por superadas
pruebas aplazadas. No reanudar una prueba manual aplazada sin que el usuario lo solicite.

Las instrucciones explícitas del usuario tienen prioridad.

Durante el prototipo, el usuario autoriza crear datos ficticios en Firestore para
comprobar casos funcionales (2026-10-15). Etiquetarlos como DEMO/[Prueba] y registrar
lo generado. No sobrescribir datos existentes para sembrar ejemplos. El usuario
indica que borrará los datos al empezar el uso real: no es una petición de borrar
ni reiniciar la base ahora. Revisar esta autorización cuando indique uso real.

Preferencia explícita del usuario (2026-10-15): no dar decisiones por entendidas.
Cuando algo admita varias formas de hacerse, preguntar cuál prefiere antes de
elegir o implementar la alternativa. Explicar brevemente las diferencias y
recomendar una opción. No interpretar el silencio como respuesta. Consultar las
decisiones ya acordadas para no volver a preguntar lo que el usuario ha resuelto.

Si algo no está decidido, no inventar comportamiento. Documentarlo como pendiente o preguntar cuando sea necesario.

Proyecto

Nombre: BoteParroquial

Tecnologías principales:

Flutter.

Dart.

Android como primera plataforma.

Mantener compatibilidad con iOS.

Firebase Authentication.

Google Sign-In.

Cloud Firestore.

Riverpod.

go_router.

El proyecto empieza como un MVP utilizado por pocos administradores, pero debe mantenerse preparado para evolucionar a la aplicación completa descrita en docs/FULL_PRODUCT_SPEC.md.

Arquitectura obligatoria

Dirección general:

UI → Provider → Repository → Service → Firebase

Reglas:

La UI no accede directamente a Firestore.

La UI no contiene lógica de negocio.

Los providers coordinan estado y acciones.

Los repositories representan operaciones del dominio.

Los services encapsulan Firebase y otros SDK externos.

Los modelos de dominio no dependen de Flutter ni de Firebase.

No extender patrones antiguos que contradigan esta arquitectura.

Si una zona existente todavía mezcla Repository y Service, migrar únicamente la parte afectada cuando sea necesario. No realizar refactors masivos no solicitados.

Datos y grupos

La aplicación debe soportar múltiples grupos.

Nunca crear colecciones globales:

persons

movements

admins

Estructura base:

users/{uid}

groups/{groupId}

groups/{groupId}/members/{uid}

groups/{groupId}/persons/{personId}

groups/{groupId}/movements/{movementId}

Futuras subcolecciones:

quotaRules
auditEvents
participationPeriods
allocations
notifications
joinRequests

Todas las operaciones relacionadas con personas, miembros o movimientos deben recibir groupId explícitamente.

No codificar un único grupo como supuesto permanente de la arquitectura.

Dinero

Nunca almacenar dinero como double.

Utilizar enteros en la unidad mínima de la moneda.

Ejemplo:

20,50 € = 2050

Nombres recomendados:

amountCents
balanceCents
monthlyFeeCents

Los importes de movimientos son siempre positivos.

El campo type determina su efecto:

income
withdrawal

Movimientos económicos

Los movimientos económicos no se eliminan directamente.

Estados previstos:

active
cancelled
corrected

Una corrección conserva el movimiento original y crea un movimiento sustituto.

El saldo deriva siempre de movimientos válidos.

Nunca modificar un importe histórico simplemente para corregir el saldo.

Personas

Las personas internas son distintas de los usuarios autenticados.

Una persona puede existir sin cuenta de Google.

Las personas con historial financiero no se eliminan.

Se marcan como:

active
inactive

La vinculación usuario/persona se realiza dentro de un grupo.

Roles

Los roles pertenecen a la membresía del grupo, no al usuario global.

Roles previstos:

owner
admin
member

Firebase Authentication identifica al usuario.

La membresía del grupo determina sus permisos.

Nunca permitir que el cliente se conceda un rol a sí mismo.

Seguridad

No confiar en esconder botones en Flutter.

Firestore Security Rules debe validar:

autenticación;

pertenencia al grupo;

rol;

campos permitidos;

transiciones de estado;

integridad básica de los datos.

No utilizar reglas públicas para datos reales.

Alcance

No implementar funcionalidades futuras simplemente porque estén documentadas.

Las fases están definidas en docs/ROADMAP.md.

Storage, Cloud Functions, Scheduler y notificaciones se añadirán cuando una fase realmente los necesite.

Validación

Preferencia del usuario (2026-10-15): ejecutar solo las pruebas necesarias para
el cambio, sin multiplicar casos ni repetir suites completas sin motivo. Priorizar
permisos, integridad de datos y el flujo afectado; análisis y compilación pertinentes.
Las listas siguientes son referencias generales, no una obligación de ejecutar
toda la suite en cada cambio. Registrar exactamente qué se ha comprobado.

Para cambios Dart:

dart format lib test
flutter analyze
flutter test

Para cambios relevantes de Android:

flutter build apk --debug

Un APK compilado no demuestra que:

la app arranque correctamente;

Google Sign-In funcione;

Firebase esté accesible;

las reglas permitan las operaciones.

Para afirmar que algo funciona en dispositivo debe haberse probado realmente.

iOS requiere Mac y Xcode para compilar y probar.

Design System

Las futuras pantallas deben reutilizar lib/design_system/design_system.dart.
Buscar componentes existentes antes de crear uno nuevo.
No hardcodear colores ni estilos tipográficos en features.
No inventar paddings, radios o sombras arbitrarios: usar los tokens centrales.
Los componentes reutilizables van a lib/design_system/.
Los componentes específicos de una feature permanecen en ella y componen App*.
Envolver librerías visuales externas detrás de componentes propios cuando exista
o deba existir una abstracción equivalente; no exponer su API por todas las pantallas.

Los tokens visuales viven en design_system/theme, no duplicarlos en core/theme.
Los componentes no calculan reglas financieras ni permisos y no llaman a Firebase.
Respetar modo oscuro, texto ampliado y movimiento reducido.

La galería se ejecuta mediante lib/main_showcase.dart, solo en debug y sin Firebase.
No incorporarla a la navegación de producción. En Phase 2 el usuario solicita
avanzar usando esta base: AppTheme está conectado y home/grupos componen App*.
Actualización visual (2026-10-15): las ocho imágenes aportadas por el usuario son
la referencia de estética. Base v0.2 con verde oscuro, menta, degradados, bordes y
títulos serif. Tema oscuro predeterminado; mantener también el tema claro y la
accesibilidad. Login ya compone App*. Personas se edita en pantalla completa según
la nueva referencia, sustituyendo el panel elegido en Phase 3.
El usuario decide hacer ahora solo el rediseño de funciones existentes con iniciales;
subidas de fotos, Storage, invitaciones, notificaciones y estadísticas avanzadas
siguen pendientes. No mostrar controles de esas funciones como si estuvieran listas.
Permisos de futuras fotos acordados en docs/DECISIONS.md; no confundirlos con Rules
implementadas. Estado y evidencia: docs/VISUAL_REDESIGN_VALIDATION.md.
Actualización posterior: el usuario elige Supabase Storage y autoriza preparar la
conexión. Sustituye el aplazamiento anterior: función y bucket privado desplegados,
UI de cámara/galería integrada; usuario confirma fotos de personas y de cuenta.
Actualización: foto de cuenta por defecto con excepción por grupo, caché privada
por cuenta y editor de recorte/zoom/rotación. Ver D057/D058; no copiar fotos entre
grupos ni permitir cambiar la foto global de otra cuenta.
El usuario confirma en A059P la foto en Miembros, navegación sin parpadeo y editor
funcionando; esto no acredita otros roles, otros móviles ni iOS.
Firebase mantiene login y datos. Consultar docs/SUPABASE_SETUP.md antes de tocar
fotos. La función comprueba JWT y roles actuales; no exponer acceso directo a Storage.
Personas internas tienen foto independiente;
sincronización automática prohibida. No confundir pruebas locales con red real.
Petición del usuario: UI distintiva y animaciones siempre que encajen, con propósito
y respetando movimiento reducido; no animar por animar ni sacrificar accesibilidad.

Avance autorizado del producto completo (2026-10-17): Phase 7 parcial permite
crear grupos y owner inicial propio, persona inicial opcional (por defecto sí),
editar nombre/descripción y registrar esa operación en auditoría inmutable.
En aquella entrega no se abrió gestión general de roles. Informes y
fichas económicos reutilizan datos actuales; CSV comparte un archivo mediante
Service nativo, sin envío automático. No confundir informes con cuotas pagadas.
El usuario decide que futuras devoluciones permitan escoger allocations revertidas;
cuotas/allocations siguen sin implementar. Ver D061–D065 y
docs/FULL_PRODUCT_PROGRESS_2026-10-17.md para estado, evidencia y pendientes.
Publicación autorizada expresamente el 2026-10-17, después del respaldo externo.
Rules publicadas y verificadas contra el archivo local; el rechazo anterior está
resuelto. Ver docs/PHASE7_INVITATIONS_VALIDATION.md para la versión activa.

Phase 7 continúa parcialmente: invitaciones con código, vista previa mínima para
cuentas autenticadas que conocen el código, configuración owner/admin autorizado,
entrada automática o aprobación, salida/expulsión con auditoría atómica. Quien
entra recibe solo member sin vinculación automática. Promociones y transferencia
se incorporan posteriormente en la entrega de roles de abajo. El owner no puede salir ni ser expulsado.
Readmisión decidida por el usuario (D069): una cuenta inactiva puede solicitar
volver con código válido, siempre con aprobación de owner/admin autorizado,
incluso si las nuevas entradas son automáticas. Vuelve como member; conservar
personId y joinedAt, sin reactivar personas ni recuperar permisos antiguos.
Estado y evidencia: docs/PHASE7_READMISSION_VALIDATION.md.
DEMO aislada: grupo demo7-invitations-20261017, sin sobrescribir datos de Prueba1.
Los UID ficticios de la muestra no son cuentas Google ni validación de otro rol
real. No reanudar la prueba manual de segunda cuenta aplazada.

Actualización 2026-10-18: vinculación manual general implementada (D070–D072).
members.personId y persons.linkedUid forman un vínculo único y recíproco. Gestión
autorizada puede asignar/cambiar/quitar; admin no modifica al owner. Se permiten
personas inactivas con advertencia. Al salir se reserva el vínculo hasta quitarlo
expresamente; para cuenta inactiva solo se habilita desvincular, no asignar.
Desvincular admin, asignarle persona inactiva o inactivar su persona degrada a
member con auditoría atómica. Reactivar no devuelve admin; owner protegido.
No habilitar promociones ni transferencia como efecto secundario. No sincronizar
fotos, nombres ni trasladar movimientos al cambiar una vinculación.
Contrato y preparación de datos anteriores en FIREBASE_SCHEMA.md; estado y
evidencia de publicación/comprobaciones en docs/PHASE7_LINKS_VALIDATION.md.

Actualización posterior 2026-10-18: gestión de roles y transferencia implementadas
por petición de continuar el producto (D073–D075). Owner/admin autorizado puede
ascender a un miembro activo con persona activa y vínculo recíproco, o degradar
un admin a member, incluido él mismo. Nunca modificar owner por esa operación.
Solo owner transfiere a otro miembro activo vinculado a persona activa. El usuario
elige que el owner anterior pase a member y que confirme escribiendo el nombre
exacto del grupo y verificando de nuevo su misma cuenta Google. Firebase reautentica
al usuario existente; no iniciar otra sesión ni almacenar credenciales. Rules
exige proveedor Google y auth_time de los últimos cinco minutos, ambas membresías,
metadatos del grupo y auditoría en el mismo commit. createdBy conserva al creador
histórico; el owner actual deriva de la membresía, no de ese campo. Sin mover
personas, dinero ni fotos. No ejecutar transferencias con UID ficticios en la
base remota para validar; las comprobaciones destructivas de permisos se aíslan
en emulador. Estado, Rules activas y pendientes físicos:
docs/PHASE7_ROLES_TRANSFER_VALIDATION.md. El usuario ejecuta la app.

Primer bloque 2026-10-19: Phase 8 empieza con modelos puros YearMonth, QuotaRule,
ParticipationPeriod y QuotaExpectationRepository. Solo proyecta importe esperado
por mes; no determina pagos/deuda ni interpreta movimientos existentes. Periodos
no configurados y meses sin regla son estados incompletos, nunca deuda cero.
Ese primer bloque no incluyó UI/persistencia ni despliegue. Sus preguntas sobre
retroactividad, primer mes de personas actuales y último mes al inactivar se
resuelven posteriormente en D077 abajo. Ver D076 y
docs/PHASE8_FOUNDATION_VALIDATION.md como informe histórico. El usuario mantiene
la ejecución manual de la app; no reanudar pruebas físicas aplazadas.

Actualización posterior del mismo día: las tres preguntas anteriores están
resueltas (D077): cambios desde el mes siguiente, primer mes de persona explícito
y último mes explícito al inactivar. El usuario también acepta cuota 0 y sustituir
una cuota futura conservando versiones. UI/servicios/repositorios y Rules
de cuotas y periodos integrados y comprobados; sin allocations ni pagos/deuda
deducidos de movimientos. No migrar personas/grupos en segundo plano.
El usuario resuelve la frontera de baja y reactivación dentro del mismo mes (D078):
pueden compartirlo y se cuenta una sola vez. Rules publicadas y hash verificado;
sin migrar ni sembrar datos remotos. La proyección admite igualdad en la frontera,
no solapamientos interiores; ordena etapas cerradas antes de abiertas con igual inicio.
Estado preciso: docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md. Mantener los cinco acuerdos,
sin volver a preguntar decisiones resueltas. Validación móvil pendiente; usuario ejecuta.

Continuación 2026-10-19: allocations y resumen de pagos integrados (D079–D081).
Solo asignaciones de ingresos active cuentan como pagos; anular/corregir conserva
historia y el sustituto empieza sin reparto. Propuesta por antigüedad hasta doce
meses futuros, revisada y confirmada un mes cada vez; sobrante sin asignar.
Sobrepago manual advertido, sin compensación automática entre meses. Dinero no
asignado cuenta en el bote, no en cuotas pagadas. Configuración incompleta mantiene
deuda/diferencia desconocidas. UI → providers → repositories puros/operaciones →
AllocationService/Firestore; ninguna cuenta puede editar repartos sin gestión.
groups/{groupId}/allocations guarda un registro por ingreso/mes y auditoría; el
contador allocationBalances es solo un límite transaccional por ingreso, nunca
saldo del bote. Sin borrados ni reparto automático de historia. Rules publicadas
y hash verificado; sin documentos remotos modificados ni ejecución móvil.
Devoluciones con reversión seleccionada de D064 y primer mes en alta siguen
pendientes. No presentar retiradas ordinarias como devoluciones de cuotas.
Estado/evidencia: docs/PHASE8_ALLOCATIONS_VALIDATION.md. El usuario ejecuta la app.

Entrega posterior 2026-10-19: devoluciones y primer mes opcional implementados
(D082–D086), sustituyendo los pendientes anteriores de D064/alta. Devolución por
un ingreso active, hasta cuatro meses distintos y crédito sin asignar; parcial.
Anular restaura conjuntamente; corregir revisa el sustituto (reparto vacío), mismo
origen y unión de meses <=4. Para otro origen/más meses, anular y registrar otra.
Las asignaciones conservan bruto; pagos descuentan devoluciones active. Nunca
reutilizar el dinero retornado ni modificar cuotas por una retirada ordinaria.
No anular/corregir un ingreso con devoluciones activas. Counter técnico por
ingreso, movimiento y auditoría inmutable son testigos del mismo commit; Rules
reparte entre ellos las cuatro validaciones de mes, sin dejar ninguna opcional.
Mantener expresas las comprobaciones de identidad, actor, capacidades y deltas.
Journal v2 conserva plan del original/sustituto; recuperar compara plan completo.
Primer mes al crear persona es opcional y explícito; si se omite, no crea periodo.
Persona/periodo/auditoría atómicos con ID estable, sin migración histórica.
El usuario autoriza expresamente nuevo respaldo externo y publicación después de
que la revisión automática rechazase la sustitución de reglas. Respaldo de
asignaciones, ZIP local y APK anterior creados sin sobrescribir copias previas;
no incluye documentos/fotos. Reglas publicadas/verificadas y comprobaciones
dirigidas en docs/PHASE8_REFUNDS_VALIDATION.md. El usuario ejecuta la app;
no afirmar validación física ni reanudar segunda cuenta o iOS aplazados.

Continuación 2026-10-19, D087–D090: el usuario prioriza dashboard e informes de
cuotas antes de notificaciones. Implementado estado actualizado de pagos y
devoluciones hasta hoy, sin reconstrucción al cierre. Pendiente del periodo solo
hasta mes actual del grupo; futuro separado como previsión. Dashboard diferencia
acumulado, cuotas del mes y caja del mes. Caja por fecha efectiva y cuotas por mes
asignado; no confundirlas ni computar crédito libre como pago. Sobrepago no cubre
otras personas/meses ni eleva cobertura por encima de 100 %. Esperado cero no
equivale a 100 %; configuración ausente mantiene pendiente/porcentaje desconocidos.
Personas inactivas conservan obligaciones según sus periodos históricos.
QuotaReportRepository compone la proyección existente y agrupa datos por persona;
GroupQuotaService consulta periodos/asignaciones una vez por grupo y los comparte
entre dashboard/informes. Sin nuevas colecciones, campos, índices, dependencias,
reglas o despliegues. Roles actuales permiten lectura a miembros activos. No
inferir que se eligieron o configuraron Supabase/FCM por priorizar informes;
la elección posterior se registra en D091, sin despliegue. Comparaciones y agregados siguen pendientes.
Evidencia exacta: docs/PHASE10_QUOTA_REPORTS_VALIDATION.md. APK compilado,
sin instalación/arranque: lo ejecuta el usuario. Pruebas físicas previas pendientes.
