BoteParroquial

Aplicación Flutter para gestionar botes de dinero compartidos.

El proyecto comienza con un MVP pequeño para pocos administradores, pero su arquitectura está diseñada desde el principio para evolucionar hacia una aplicación con múltiples grupos, miembros, cuotas mensuales, estadísticas, notificaciones e historial completo.

Stack

Flutter

Dart

Firebase Core

Firebase Authentication

Google Sign-In

Cloud Firestore

Riverpod

go_router

Android es la primera plataforma de desarrollo.

La arquitectura debe mantenerse compatible con iOS.

Documentación

[Guía de pruebas en dos o tres móviles](docs/GUIA_PRUEBAS_MOVILES.md).
Recorridos manuales con resultados económicos concretos, permisos y pendientes;
preparada el 2026-10-20, sin ejecutar ni dar por superadas las pruebas físicas.

AGENTS.md
    Reglas principales para Codex/agentes.

PRODUCT_SPEC.md
    Alcance del MVP actual.

ARCHITECTURE.md
    Arquitectura y dependencias.

FIREBASE_SCHEMA.md
    Contrato de persistencia Firestore.

CODING_RULES.md
    Convenciones de implementación.

DESIGN_SYSTEM.md
    Identidad propuesta, tokens, componentes, galería y evaluación de librerías.

docs/DECISIONS.md
    Decisiones técnicas y funcionales ya tomadas.

docs/ROADMAP.md
    Registro general de avance: fases completadas, pendientes y pruebas aplazadas.

docs/PHASE1_VALIDATION.md
    Evidencia y lista de comprobaciones de autenticación, incluidas las pendientes.

docs/FULL_PRODUCT_SPEC.md
    Especificación funcional de la aplicación completa.

docs/firebase-setup.md
    Estado y configuración real de Firebase.

Estado actual

Corrección de tirones de navegación, D131 (03/11/2026): contenido de nuevas
secciones aplazado hasta acabar su entrada, esqueleto ligero durante el movimiento,
pantalla saliente temporalmente congelada y curvas acompasadas. Se conservan las
animaciones elegidas, la barra y los controles de acceso. Cinco casos dirigidos
superados y análisis limpio; medición física del APK actualizado pendiente.
[Estado, APK y comprobación de fluidez](docs/GROUP_NAVIGATION_PERFORMANCE_2026-11-03.md).

Animaciones elegidas e integradas el 2026-11-03: B07/B08 en controles compartidos,
B04/B05 al rechazar intentos, N01 en la barra, P03/P05 en pantallas. La entrada a
un grupo hace una onda de un segundo y crece desde su tarjeta; las secciones
entran por el lado correspondiente a la pestaña. El usuario conserva el
laboratorio para seguir comparando. Nueve casos dirigidos superados, análisis
limpio y APK debug/profile compilados; validación física pendiente.
[Cambios, APK y evidencia](docs/SELECTED_MOTION_2026-11-03.md).

Laboratorio temporal del 2026-11-03: acceso visible en Inicio de debug/profile
para comparar 24 transiciones, 12 efectos de botón y 4 barras, con velocidad
ajustable. La selección posterior se aplica según el informe anterior, sin
guardar ajustes de prueba. El laboratorio se conserva por petición del usuario. Entrar con código vuelve
a mostrar llave. Cuatro casos dirigidos, análisis limpio y APK debug/profile
compilados; pendiente de prueba física.
[Estado, APK y retirada](docs/MOTION_LAB_2026-11-03.md).

Continuación de movimiento cerrada el 2026-11-03: efectos más marcados elegidos por el
usuario, distintos por contexto, entradas simplificadas y pulso más breve. Barra
inferior persistente con indicador que se desplaza entre secciones del grupo,
también en copias. Mantiene movimiento reducido y permisos. La fluidez real se
comprueba en móvil con APK profile; el usuario ejecuta. Siete casos dirigidos
superados, análisis limpio y APK debug/profile compilados.
[Cambios, comprobaciones y APK](docs/MOTION_PERFORMANCE_2026-11-02.md).

Último cambio visual del 2026-11-02: selector de color con cuadrado/arcoíris y
hexadecimal; Atlántico conservado y nuevas Cyberpunk, Cartoon, Arcade y Pop Art.
Pulsación completa antes de actuar y transiciones de pantalla compartidas,
respetando movimiento reducido. Trece pruebas dirigidas, tres capturas simuladas,
análisis limpio y APK debug compilado. Prueba física pendiente, usuario ejecuta.
[Entrega y evidencia](docs/COLOR_PICKER_PALETTES_MOTION_2026-11-02.md).

Continuación visual del 2026-11-02: carga con formas y brillo, menús renovados,
Añadir flotante y Copias en cuenta. Ajustes de apariencia añade fuente elegible y
paletas propias locales de tres colores con vista previa clara/oscura antes de
guardar. Once pruebas dirigidas distintas y análisis limpio, cuatro capturas
simuladas revisadas y APK debug compilado. Prueba física pendiente; usuario ejecuta la app.
[Biblioteca visual y personalización](docs/VISUAL_LIBRARY_2026-11-02.md).

Ampliación del 2026-11-02: recorte panorámico para portadas, aviso al salir con
cambios sin guardar en los editores afectados, primer mes de cuota con selección
múltiple desde Personas y cinco paletas con varios acentos. Solicitud inicial de
notificaciones tras login, manteniendo preferencias y controles de desactivación.
Sin cambios de Rules o despliegues. Validación física pendiente; el usuario ejecuta.
23 pruebas dirigidas distintas superadas, análisis limpio y APK debug compilado.
[Cambios, comprobaciones y límites](docs/UX_IMPROVEMENTS_2026-11-02.md).

Entrega visual vigente, 2026-10-30: v0.4 sustituye el resultado v0.3 rechazado por
el usuario. Cinco paletas con claro/oscuro y modo Sistema, elegibles desde Ajustes
de apariencia y guardadas en este móvil. Inicio sin recuadro promocional; portada
panorámica de ancho completo en el grupo y nombre/descripción debajo. Participantes
agrupa Personas/Miembros, acciones económicas unificadas y accesos redundantes
retirados del resumen. Atrás de una sección vuelve al resumen; de este, a Tus grupos.
37 pruebas dirigidas distintas, análisis limpio, 19 capturas simuladas revisadas y
APK debug compilado. Revisión en móvil pendiente, el usuario ejecuta la app.
[Entrega y evidencia v0.4](docs/VISUAL_REDESIGN_V04_VALIDATION.md).

Entrega visual anterior v0.3 (histórica): Design System carbón y menta, según las dos
nuevas referencias y la dirección «Más expresivo» elegida por el usuario. Tipografía
sans, tarjetas renovadas, cabeceras con órbitas, feedback de pulsación y entradas
escalonadas. Inicio/resumen reorganizados y barra inferior en las cuatro vistas
principales del grupo, también en el visor de copias. Las pantallas existentes
heredan los nuevos componentes y temas. 33 pruebas dirigidas, análisis limpio,
ocho capturas simuladas revisadas y APK debug compilado. Revisión en móvil por el
usuario pendiente. [Entrega y evidencia](docs/VISUAL_REDESIGN_V03_VALIDATION.md).

Actualización 2026-10-23: copias diarias completas de los datos consultables,
cifradas por cuenta/móvil. Siete capturas, Wi-Fi y datos móviles; fotos según caché.
Inicio y aviso de sincronización ofrecen el catálogo. Visor con pantallas habituales,
fecha fija y solo lectura, independiente de la caché y del servidor. No programa
la copia semanal del portátil. [Entrega y límites](docs/DAILY_OFFLINE_COPIES_VALIDATION.md);
prueba física COP-01–10 en [guía de móviles](docs/GUIA_PRUEBAS_MOVILES.md).

Entrega del 2026-10-20: PDF/Excel/CSV, papelera de personas, eliminación de grupos,
baja propia, auditoría ampliada y caja con agregados exactos implementados y
publicados. Reinicio autorizado completado con respaldo: dos grupos DEMO,
20 personas visibles y 280 movimientos; accesos/configuración conservados.
Copia semanal aplazada por el usuario. APK compilado, sin ejecución física.
Estado, evidencia y límites exactos:
[continuación del producto completo](docs/FULL_PRODUCT_COMPLETION_2026-10-20.md).
[Datos y saldos DEMO](docs/DEMO_DATOS_2026-10-20.md),
[copias recuperables](docs/RECUPERACION_DATOS_2026-10-20.md) y
[guía actualizada para dos/tres móviles](docs/GUIA_PRUEBAS_MOVILES.md).

Continuación Phase 11, 2026-10-20: Historial administrativo añade páginas de
cincuenta con «Cargar más», búsqueda/filtros sobre los cargados y detalle de cada
evento. Conserva precisión del cursor y retira contenido al perder acceso.
En aquella entrega no cambiaba escrituras o permisos remotos; no equivalía a papelera ni auditoría de
todas las operaciones. [Entrega y comprobaciones](docs/PHASE11_AUDIT_HISTORY_VALIDATION.md).

Continuación 2026-10-20: Informes añade «Comparar con el periodo anterior» para
mes/trimestre/año, con caja y cuotas separadas, diferencias y cumplimiento. Los
periodos en curso usan el mismo tramo transcurrido, elegido por el usuario.
Reutiliza lecturas, sin cambiar permisos o datos remotos. Implementación y pruebas:
[informe de comparaciones](docs/PHASE10_PERIOD_COMPARISONS_VALIDATION.md).
La revisión en móvil sigue pendiente; el usuario ejecuta la app.

Actualización vigente, 2026-10-20: servidor de recordatorios y avisos de actividad
publicado en un segundo Supabase aislado de fotos. Cron activo cada quince
minutos, preferencias independientes y reservas para evitar repetir push inciertos.
Enlaces de invitación publicados en https://boteparroquial.web.app con preparación
Android App Links. Reglas verificadas y nueva copia externa. HTTP/cron y bandeja
DEMO comprobados; entrega push y apertura en móviles aún sin comprobar, iOS/APNs
pendientes. El usuario ejecuta el APK. Detalles, copia, muestra y pruebas:
[informe de entrega](docs/PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md).
Los apartados siguientes describen entregas anteriores y sus límites en aquel momento.

Actualización de fotos (2026-10-15): el usuario elige Supabase Storage y ha creado
el proyecto y vinculado Firebase Auth. SDK, función remota y UI de fotos integrados;
el usuario confirma las fotos de personas y su foto de cuenta. Las pruebas de permisos
con otros roles reales siguen pendientes;
las menciones siguientes al aplazamiento describen el rediseño anterior.
Ver docs/SUPABASE_SETUP.md. Firebase sigue siendo el backend de acceso y datos.
La autorización se implementa mediante Edge Function de Supabase, elegida por el
usuario. Función y bucket privado desplegados, rechazo anónimo comprobado y UI
con cámara/galería, vista previa, guardar y quitar. Cinco pruebas backend y doce
casos Flutter dirigidos superados, análisis limpio y APK instalado en A059P.
Actualización posterior: foto de cuenta por defecto en Miembros, personalización
por grupo, caché privada para evitar parpadeos y recorte/zoom/rotación antes de guardar.
APK actualizado instalado y backend versión 3 desplegado; siete pruebas de fotos,
un flujo de grupos y seis de backend superados. El usuario confirma en A059P foto
en Miembros, sin parpadeo y editor funcionando. Otros roles e iOS siguen pendientes.
No se repitió la suite completa.

Fecha de referencia: 2026-10-30.

Continuación: cálculo de recordatorios de servidor y lector REST readOnly con
instantánea consistente por grupo, preparados y comprobados localmente. Comparte
13 escenarios económicos con la proyección Dart. Sin desplegar worker/cron,
configurar secretos o enviar avisos. Informe:
[docs/PHASE9_REMINDER_SERVER_CALCULATION.md](docs/PHASE9_REMINDER_SERVER_CALCULATION.md).

Phase 9 continúa: botón para registrar/retirar este móvil en Tu perfil o en la
bandeja; preferencia de recordatorios por grupo, avisos privados y marcado leído.
La campana del dashboard abre la bandeja del grupo. Cerrar sesión confirma antes
la retirada del registro; si estaba activo necesita conexión. La intención de
retirar se conserva tras fallos/reinicios y no reactiva avisos por accidente.
Sin ejecución física; pruebas dirigidas, análisis limpio y APK generado.
Publicación/respaldo y pendientes exactos:
[docs/PHASE9_NOTIFICATION_CLIENT_VALIDATION.md](docs/PHASE9_NOTIFICATION_CLIENT_VALIDATION.md).
Rules publicadas/verificadas tras el nuevo respaldo de reglas, proyecto y APK;
índice de bandeja READY. Sin documentos DEMO o push reales en esta entrega.
En aquella entrega no había worker/cron ni se crearon claves o permisos IAM;
incorporados posteriormente con autorización específica. Sin activar facturación.
Supabase + FCM, 10:00, push sin importes y resumen
por grupo acordados; la [preparación anterior](docs/PHASE9_NOTIFICATIONS_FOUNDATION.md)
conserva su evidencia histórica.

Entrega anterior: el dashboard muestra cuotas acumuladas pendientes y estado
de personas, además de cuotas y dinero del mes. Informes por mes/trimestre/año
añaden cumplimiento, previsión futura y detalle por persona, con pagos y
devoluciones actualizados. Falta de configuración mantiene el pendiente desconocido;
los sobrepagos no cubren otros meses. Solo lecturas: no cambia Firestore Rules ni
datos remotos. Evidencia y pendientes:
[docs/PHASE10_QUOTA_REPORTS_VALIDATION.md](docs/PHASE10_QUOTA_REPORTS_VALIDATION.md).
En aquella entrega el usuario prioriza informes y deja notificaciones para después. Los bloques
de Phase 8 siguientes describen la base ya entregada.

Phase 8 (2026-10-19): cuotas versionadas y periodos explícitos, más asignación de
ingresos a meses. La ficha distingue pagos parciales, pendientes, sobrepagos,
crédito futuro y sin asignar. Propone los meses pendientes más antiguos y hasta
doce futuros; cada mes se revisa y confirma por separado. No se reparten ingresos
históricos automáticamente. Anular/corregir conserva las asignaciones anteriores
sin contarlas como pagos; el sustituto requiere un reparto nuevo.
Rules publicadas y verificadas, análisis limpio y APK debug generado, sin ejecución
en móvil ni cambios de documentos remotos. Estado exacto y pruebas dirigidas:
[docs/PHASE8_ALLOCATIONS_VALIDATION.md](docs/PHASE8_ALLOCATIONS_VALIDATION.md).
Continuación: devoluciones parciales por ingreso, hasta cuatro meses y crédito
sin asignar; corregir revisa el sustituto y anular restaura los pagos. Primer mes
opcional durante el alta de personas, sin inventarlo cuando se omite. Detalle,
respaldo y validación más recientes:
[docs/PHASE8_REFUNDS_VALIDATION.md](docs/PHASE8_REFUNDS_VALIDATION.md).
La validación física sigue pendiente; el usuario ejecuta la app.
La configuración previa está documentada en
[docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md](docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md);
la [base inicial](docs/PHASE8_FOUNDATION_VALIDATION.md) es histórica.

Para revisar la entrega: grupo → Cuotas y etapas; ficha de persona → elegir su
primer mes si falta. En un ingreso, abrir «Repartir por meses»; también se accede
desde «Aportaciones para repartir» en la ficha. Las reglas/etapas no se configuran
solas y la configuración incompleta no se presenta como deuda cero.

Entrega anterior publicada (2026-10-18): gestión de administradores desde Miembros y transferencia de
propiedad con nombre exacto del grupo y nueva verificación Google. El propietario
anterior pasa a miembro. Operaciones atómicas, control de versión y auditoría;
Rules publicadas y verificadas contra la fuente local. Informe y comprobaciones:
[docs/PHASE7_ROLES_TRANSFER_VALIDATION.md](docs/PHASE7_ROLES_TRANSFER_VALIDATION.md).
Análisis limpio, dos casos Flutter dirigidos, permisos comprobados en emulador
y APK debug compilado. No se ha instalado ni ejecutado; lo hará el usuario.
Los enlaces con dominio real y el servidor de notificaciones se añaden después,
según el informe vigente. Sigue pendiente su validación física. Las cuotas
se amplían con asignaciones y devoluciones en Phase 8 arriba.
Las entregas descritas a continuación son históricas y no sustituyen este estado.

Continuación del producto (2026-10-18): vincular/cambiar/desvincular cuentas y
personas del mismo grupo, vista «Sin vínculo», reserva de vínculos históricos,
personas inactivas con advertencia y pérdida automática de admin al perder la
persona activa. Cambios atómicos y auditados, sin mover dinero ni fotos. Estado,
publicación y comprobaciones: [docs/PHASE7_LINKS_VALIDATION.md](docs/PHASE7_LINKS_VALIDATION.md).

Copia verificada de las Rules anteriores de Phase 6, guardada fuera de Git para
que sobreviva a descartar cambios: [docs/FIRESTORE_RULES_BACKUP.md](docs/FIRESTORE_RULES_BACKUP.md).
Incluye configuración e instrucciones de restauración. Después del respaldo,
el usuario ha autorizado publicar las reglas nuevas; restaurar permisos no
restauraría los datos creados posteriormente.

Continuación de Phase 7 (2026-10-17): códigos de invitación, entrada automática o
con aprobación, solicitudes, salida y retirada de acceso con auditoría. Reglas
publicadas y verificadas; creado el grupo aislado «[Prueba] Invitaciones DEMO».
Análisis limpio, tres casos Flutter, once casos distintos de Rules y APK debug
compilado. Sin instalación ni ejecución en móvil. Roles y transferencia estaban
pendientes entonces; se añaden con vínculos el 2026-10-18. Enlaces siguen pendientes.
Informe: [docs/PHASE7_INVITATIONS_VALIDATION.md](docs/PHASE7_INVITATIONS_VALIDATION.md).

Readmisión acordada después: solicitar vuelta con aprobación obligatoria incluso
en grupos de entrada automática, conservando vínculo/historial y volviendo como
member. Actualización, publicación y comprobaciones propias:
[docs/PHASE7_READMISSION_VALIDATION.md](docs/PHASE7_READMISSION_VALIDATION.md).

Ampliación posterior de producto completo (2026-10-17): creación de grupos desde
la app, propietario y persona inicial opcional, edición de nombre/descripción con
auditoría atómica, informes económicos mensuales/trimestrales/anuales con gráficas,
ficha de persona y edición de nombre de cuenta. CSV del periodo con todos los
estados y menú nativo de compartir para gestión autorizada. No implica cuotas,
gestión general de roles ni producto completo terminado. Las invitaciones se
añaden después, en el bloque documentado arriba.
Estado, validación y límites: [docs/FULL_PRODUCT_PROGRESS_2026-10-17.md](docs/FULL_PRODUCT_PROGRESS_2026-10-17.md).
El rechazo inicial de publicación se resolvió con autorización explícita posterior
del usuario. Crear/editar grupos y editar nombre de cuenta ya tienen sus Rules
publicadas; informes, fichas y CSV mantienen sus lecturas autorizadas.
Análisis limpio, cuatro casos Flutter dirigidos y doce de Rules superados; APK
Android debug compilado. Sin instalación ni ejecución en dispositivo.

Revisión del MVP (2026-10-17): las funciones básicas están implementadas; Phase 6
sigue abierta por validación física de recuperación/offline, segunda cuenta y uso
compartido entre móviles, además de la revisión final de UX y paso de DEMO a uso real.
El móvil está desconectado; no se dan esas comprobaciones por superadas.
Se avanza una parte acotada de la especificación completa: búsqueda y filtros del
historial por fecha efectiva, persona, tipo, estado y creador. Aplican a los datos
actuales, conservan todos los estados y no alteran el saldo del Dashboard.
Informe de esta entrega y comprobaciones: [docs/WORK_REPORT_2026-10-17.md](docs/WORK_REPORT_2026-10-17.md).
Análisis estático sin incidencias y cinco pruebas dirigidas del historial/Dashboard superadas; sin suite completa,
instalación ni arranque. No se modifica configuración remota ni datos.

Mejoras del 2026-10-16: «Editar foto actual» reutiliza la imagen guardada y permite
ajustarla sin buscarla de nuevo; cancelar conserva la anterior y guardar es explícito.
El aviso de actualización se oculta durante la carga inicial y solo aparece tras
dos segundos sin confirmación; desaparece al confirmar el servidor. No interpreta
la caché inicial como falta de Internet. Dos pruebas dirigidas superadas;
validación física pendiente, el usuario ejecutará la app.

Actualmente:

El proyecto Flutter existe.

Android e iOS están configurados como plataformas.

Firebase Core está integrado.

Firebase Authentication está añadido.

Google Sign-In está añadido.

Cloud Firestore está añadido.

Riverpod está añadido.

go_router está añadido.

FlutterFire generó firebase_options.dart.

Firebase está configurado para Android e iOS.

Google Authentication está habilitado.

Firestore ha sido creado.

Base `(default)`, edición Standard, región `europe-southwest1` (Madrid).
Metadatos comprobados con Firebase CLI el 2026-10-15.

Reglas de Phase 6 (histórico; sustituidas por las entregas de Phase 7):
cada cuenta mantiene privado su perfil users/{uid}.
Puede descubrir sus membresías por uid y leer grupos activos y miembros si tiene
membresía activa. Las reglas publicadas de Phase 6 no permiten escribir grupos
ni membresías. Las reglas de Phase 7, ya publicadas, permiten crear un grupo
nuevo junto con owner inicial/auditoría y editar nombre/descripción con permisos,
conservando la moneda fija; no permiten autopromociones en grupos existentes.
Personas admite lectura de miembros activos y gestión de owner/admin autorizado.
Movimientos permite lectura de miembros y escritura controlada de owner/admin válido:
registro, anulación y corrección atómica, sin borrar ni editar importes históricos.
Ver docs/PHASE4_VALIDATION.md.

Login con Google y perfil guardado comprobados con una primera cuenta real en
A059P (Android 16, API 36). El cierre de sesión también está confirmado en registros.
La prueba con segunda cuenta está aplazada por petición del usuario: no dispone
de otra cuenta ahora. La restauración tras reinicio con sesión abierta sigue
pendiente de comprobar. No hay pruebas manuales en curso.

Phase 1 implementa login, logout, restauración de sesión, rutas protegidas,
creación/lectura del perfil, estados de carga, errores y reintento explícito.
El último acceso del perfil registra el inicio de una sesión autenticada de la app,
incluida su restauración; createdAt se conserva mediante transacción.

La feature auth ya sigue UI → Provider → Repository → Service → Firebase.
Su modelo está en lib/models/, los repositories en lib/repositories/, los services
en lib/services/ y los providers en lib/features/auth/providers/.
No se ha realizado una reorganización global de las demás features.

Detalle de verificaciones y comprobaciones pendientes:
docs/PHASE1_VALIDATION.md.

Phase 2 implementa lista de grupos propios, contexto por ruta, roles y lectura
de miembros en tiempo real. Prueba1 está aprovisionado con la cuenta de la app
confirmada por el usuario como propietaria. La creación desde UI está implementada
en el avance parcial de Phase 7; entradas/bajas/vínculos se amplían después,
mientras gestión general de roles y transferencia se incorporan después en la
entrega del 2026-10-18 enlazada al inicio.

Phase 3 implementa listado de personas en tiempo real, creación y edición de
nombre/notas en panel inferior, activar e inactivar con confirmación, sin borrado.
Datos separados por grupo, validación de autor/fechas y protección ante edición
concurrente. Comprobaciones dirigidas: una prueba Flutter de flujo, tres pruebas
de reglas, análisis sin incidencias y APK compilado e instalado en A059P.
El rediseño v0.2 posterior sustituye el panel de edición por pantalla completa.
El usuario confirma que Personas funciona el 2026-10-15. La sincronización entre dos
móviles sigue sin comprobarse; esa confirmación no se extiende a pruebas no realizadas.

Phase 4 incorpora ingresos, retiradas generales o por persona, historial en tiempo
real, anulación y corrección conservando originales. Formularios en pantalla completa,
advertencia por persona inactiva y confirmación de saldo negativo. Solo fechas de hoy
o anteriores. Reintentos del mismo envío sin crear otro documento.
Comprobaciones dirigidas: cuatro pruebas de reglas, una del flujo visual y una
comprobación nativa con la sesión real en A059P. No se repitió la suite completa.
Hay datos DEMO autorizados en Prueba1, «Prueba · Saldo negativo» y
«Prueba · Historial vacío». Ver docs/PHASE4_VALIDATION.md para cifras y límites.

Phase 5 incorpora el Dashboard como inicio del grupo: saldo, totales históricos de
movimientos activos, personas activas/inactivas y los cinco últimos cambios financieros.
Corregidos/anulados no suman; la actividad ordena por fecha de registro/cambio y no
duplica el sustituto activo. Personas y miembros tienen pantallas independientes.
Los cálculos viven en DashboardRepository, fuera de widgets; no hay saldo persistido.
En el MVP se reutilizaron las suscripciones existentes por elección del usuario.
La entrega D109 del 20 de octubre sustituye la caja por agregados y la actividad
por una consulta acotada; la optimización completa de cuotas sigue documentada aparte.

Análisis sin incidencias, ocho pruebas dirigidas superadas y APK debug compilado.
El usuario reconecta el móvil y confirma que funciona el 2026-10-15. Esta confirmación
del Dashboard no acredita una segunda cuenta ni sincronización entre dos móviles.
Ver docs/PHASE5_VALIDATION.md y el apartado de cierre de MVP en docs/ROADMAP.md.

Phase 6 en curso: consulta de caché con aviso de actualización sin confirmar y
operaciones económicas con confirmación de servidor. Los envíos se guardan antes
de escribir, en archivos privados por cuenta/grupo, y se comprueban al volver al
grupo. Si faltan, el reintento requiere confirmación y conserva datos e ID; no se
reenvían automáticamente. Cambiar de cuenta no expone pendientes de otra cuenta.
La lista de grupos no depende de poder actualizar el perfil al abrir sin red.
El usuario permite descartar el intento local tras revisar y confirmar; nunca se
borra dinero. «Hoy» usa la zona IANA del grupo y Rules exige medianoche UTC para
la fecha efectiva. El margen de 24 h de servidor sigue sin validación IANA exacta.
Detalle y pendientes de cierre: docs/PHASE6_VALIDATION.md.
Tras instalar el APK de Phase 6, el usuario confirma que al activar la conexión
vuelven a aparecer los grupos. Comprobación online confirmada; caché sin conexión
y recuperación tras cierre siguen pendientes de validación física.

Design System v0.2 (histórico, sustituido por v0.3 arriba): rediseño basado en las ocho referencias del usuario.
Verde casi negro, acentos menta/coral, degradados, tarjetas con contorno y títulos
serif. Inicio, resumen, historial, formularios, Personas, Miembros y login usan App*.
Tema oscuro predeterminado; el tema claro se conserva y se revisa en vistas simuladas.
Personas pasa de panel a pantalla completa. Avatares e imágenes de grupo muestran
iniciales; subidas de fotos se aplazan expresamente, junto con Storage.
Los permisos de fotos futuras están acordados, pero no están implementados ni activos.
No se adelantan invitaciones, notificaciones ni estadísticas de las referencias.
Detalle: docs/VISUAL_REDESIGN_VALIDATION.md.
Tokens y componentes en lib/design_system/; galería debug sin Firebase:

flutter run --debug -t lib/main_showcase.dart

La app habitual sigue en lib/main.dart con AppTheme claro/oscuro y componentes App*,
con entrada animada respetuosa con movimiento reducido.
La galería muestra cifras y personas de ejemplo, sin implementar lógica financiera.
Las pruebas de segunda cuenta y restauración real aplazadas no se han reanudado.

Validación actual: docs/PHASE6_VALIDATION.md, docs/VISUAL_REDESIGN_VALIDATION.md
y docs/WORK_REPORT_2026-10-17.md para la entrega de búsqueda/filtros.
Aprovisionamiento inicial: docs/PHASE2_VALIDATION.md.

No asumir que una funcionalidad está implementada simplemente porque aparezca documentada.

Firebase

Proyecto:

boteparroquial

Configuración detallada:

docs/firebase-setup.md

Arquitectura

Dirección objetivo:

UI
↓
Provider
↓
Repository
↓
Service
↓
Firebase

Ver:

ARCHITECTURE.md

Comandos habituales

flutter pub get

flutter analyze

flutter test

flutter devices

flutter run

flutter build apk --debug

Regla importante

Antes de empezar una nueva fase con Codex:

Lee AGENTS.md y los documentos que referencia.
Estamos trabajando en Phase X de ROADMAP.md.

No volver a explicar toda la arquitectura en cada conversación salvo que haya cambiado.
