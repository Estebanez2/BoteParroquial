BoteParroquial — Instrucciones para agentes

D167 (2026-11-04): usuario pide orientación siempre vertical. Arranque Flutter
portraitUp antes de Firebase; MainActivity portrait; iOS/iPad solo Portrait y
UIRequiresFullScreen true (sin multitarea iPad). No rotaciones por feature.
No prometer bloqueo en pantallas Android 16+ >=600 dp ni en apps externas.
Estado/APK: docs/PORTRAIT_ONLY_2026-11-04.md. Usuario instala/ejecuta; iOS sin compilar.
Release vigente 1.0.6+7 compilado, portrait en manifiesto APK comprobado, análisis
limpio y firma D156 verificada. 75.860.541 bytes. Rotación física aún pendiente.

D166 (2026-11-04): usuario elige Retro 6/7/8 (C086/C087/C088) para press y pide
retirar laboratorio de clics. press_1–3 son copias exactas de las muestras elegidas,
110 ms/pico 0,85; tres variantes aleatorias sin repetir anterior. Menú mantiene
click_1–4, restantes sonidos/preferencias intactos. Retirados ruta/acceso/pantalla/
provider/catálogo/audición y 96 WAV lab_c*, generador de catálogo y test exclusivo.
prepare_ui_sounds reproduce la selección. NO reintroducir laboratorio sin petición.
Gate de animación D165 permanece. Una regresión por hashes/aleatoriedad y análisis
limpio; estado/APK en docs/SELECTED_RETRO_CLICKS_2026-11-04.md. Usuario ejecuta.
Sin cambios remotos ni nueva firma. Esta decisión sustituye conservación de D164.
Release vigente 1.0.5+6 compilado, firma D156 y versión verificadas; 75.860.545
bytes, app-release.apk. Usuario instala/ejecuta; sin aprobación acústica nueva.

D164–D165 (2026-11-04): usuario pide laboratorio temporal de clics y elige SOLO
debug/profile. Inicio → Laboratorio de clics, /testing/clicks; 104 muestras C001–104,
familias/favoritas/nivel efímeros, audición sin aplicar sonidos ni doble clic.
Una instancia de preview, no 104 pools; silencio/off/cero/segundo plano intactos.
AppInteractionHost/gate compartido cubre feedback, onda de grupo y transiciones;
handoff por frame, liberar al terminar/cancelar/desmontar, no esperar red/audio ni
congelar permisos. No encolar toques. FormGuard mantiene protección y evita otra
confirmación durante gate. Profile usa firma D156 existente para actualizar release
sin desinstalar; debug intacto, no recrear claves. Cuatro casos y análisis limpio.
Profile 1.0.4+5 compilado; release anterior no recompilada. Detalles/pending físicos:
docs/CLICK_LAB_AND_INTERACTION_LOCK_2026-11-04.md. Usuario instala/ejecuta.
No retirar laboratorio ni elegir/aplicar sonidos hasta indicación del usuario.

D161–D163 (2026-11-04): AppSystemBackSound observa back del sistema y didPop de
raíz/shell, más userGestureInProgress; deduplicar por solicitud, no por tiempo.
Gesto cancelado/bloqueado no suena; botón mantiene back sin duplicar. Router de
copias también integrado, sin SDKs nuevos. Menú usa click_1–4 anteriores y normal
press_1–4 mecánicos filtrados de 65 ms. Apariencia usa AppSoundSettingsPanel compacto,
sin textos retirados. Crear grupo sin GroupOpening, foto opcional local 16:9;
GroupDraftPhotoController por formulario/UID, PhotoRepository.editDraft sin acceso
remoto. Usuario elige conservar grupo si falla foto: mismo ID, alta confirmada
no se repite; reintentar foto o quitar borrador/abrir grupo. No atomicidad entre
Firebase y Supabase, ni borrador persistente tras cerrar. Guard protege foto/datos.
Estado, siete casos y APK: docs/BACK_SOUND_COMPACT_SETTINGS_GROUP_PHOTO_2026-11-04.md.
Usuario instala/ejecuta; sin despliegues, datos remotos o firma nuevos.
Release vigente 1.0.3+4 compilado, análisis limpio, firma D156 y versión verificadas;
75.831.857 bytes. Pruebas físicas de gesto, audio y cámara/subida aún pendientes.

Continuación D159–D160 (2026-11-04): menú usa UiSound.menu con tap_1–4 anteriores;
normal usa click_1–4 nuevos cálidos. Override semántico en botones de apertura;
mantener silencio y no emitir doble. Inicio sustituye Gestionar por tiles Editar
grupo/Historial administrativo junto a Cuotas y etapas. Historial fallaba porque
decoder rechazaba occurredAt Timestamp antes/después: convertir en service a
DateTime UTC, conservar cursor exacto y tipos/rutas protegidos. No ocultar errores
con contador cero. Lectura remota acotada vio 21 eventos Catequesis y páginas de
51 por DEMO; no total de DEMO ni autorización de escritura. Ocho casos dirigidos
y análisis limpio. Evidencia/APK/pendientes: docs/MENUS_ACTIONS_AUDIT_2026-11-04.md.
Sin cambios remotos; usuario instala/ejecuta.
Release vigente 1.0.2+3 compilado, firma oficial D156 verificada y versión
confirmada; 75.742.297 bytes. No equivale a aprobación física de audio/historial.

Continuación D157–D158 (2026-11-04): sustituye sonido global de D152. Solo controles
activos emiten; zonas libres/scroll/deshabilitados callan (feedback visual intacto).
Volumen predeterminado 75 %, conservar elección guardada/off/silencio. Cuatro WAV
de clic de 85 ms, aleatorios sin repetición inmediata; back descendente para botones
Volver. Fuentes normalizadas a pico 0,92, no esperar audio para operar. Identidad
extendida solo en Dashboard; GroupAccessBody por defecto sin cabecera. Secciones
usan GroupSectionTopBar/AppCompactIdentity con nombre/miniatura derecha, permisos
reactivos y fotos privadas. Participantes muestra Invitar al grupo; oculto en copia.
Seis comprobaciones y análisis limpio; usuario valida audio/UI en móvil. Evidencia,
APK y límites: docs/SOUND_AND_GROUP_SECTIONS_2026-11-04.md. Sin cambios remotos.
Release vigente 1.0.1+2 compilado y firma D156 verificada; 75.704.221 bytes.
Se actualiza sobre release anterior sin desinstalar; audio/UI físicos pendientes.

Continuación D155–D156 (2026-11-04): invitación usa adjunto privado + nombre/frase/
enlace; fallback logo solo si no hay foto. No publicar imágenes ni enviar WhatsApp
automáticamente. InvitationShareRepository valida acceso remoto y sesión/código
antes de compartir; limpiar temporales por cuenta. Firma Android independiente
creada en Documents/keystores, configuración android/key.properties ignorada y
respaldo privado externo. Nunca imprimir/incluir contraseñas o clave en Git/chat.
Huellas registradas en Firebase y Hosting; no recrear clave ni usar debug en release.
Ver docs/INVITATIONS_AND_ANDROID_RELEASE_2026-11-04.md para evidencia y pendientes.
Usuario instala/ejecuta; firma nueva no actualiza APK debug/profile previo.
Release compilado, firma v2 verificada con certificado propio, 75.656.635 bytes;
APK build/app/outputs/flutter-apk/app-release.apk. Google/WhatsApp/enlaces físicos
pendientes. No confundir certificado registrado con login probado en este release.

Corrección D154 (2026-11-04): usuario precisa descripción a la izquierda y saldo
grande a la derecha bajo la foto, no en columna. AppGroupPreview usa fila adaptativa,
alineación superior y escala hacia abajo solo si el saldo no cabe. Sin EUR/rol ni
botón Entrar; radios/entrada intactos. Texto ampliado permite apilar por accesibilidad.
Solo ajuste visual, sin nuevas pruebas de negocio. Evidencia y APK en
docs/EVERY_TOUCH_VOLUME_AND_CARDS_2026-11-04.md, D154; usuario instala/ejecuta.

Continuación D152–D153 (2026-11-04): usuario sustituye ráfagas por cada toque y
edición. AppSoundSurface captura pointer-down global (también zonas libres/inicio
de scroll), sin duplicar tap semántico del mismo toque. No filtrar eventos rápidos
ni descartar efectos ocupados; permitir superposición. Volumen local 0–100 y
preview, JSON versionado compatible con txt off anterior. Silencio, apagado y
segundo plano se mantienen. Texto/password solo emiten enum, nunca contenido.
Perfil: foto y botón a su derecha. Home: saldo hero primero bajo portada,
descripción después, sin badges EUR/rol; dentro se conservan. Seis casos dirigidos
superados y análisis limpio, usuario instala/ejecuta. Evidencia y pendientes:
docs/EVERY_TOUCH_VOLUME_AND_CARDS_2026-11-04.md. Sin cambios remotos.

Continuación D151 (2026-11-04): logo del usuario movido de Descargas a
assets/branding/bote_parroquial.png, original preservado y hash verificado.
AppLogo/AppLogoBackdrop centralizan marca y fondo decorativo al 12 % del login;
AppBrand y bienvenida usan la imagen real. No capturar toques ni enviar el logo
a servicios remotos. Iconos Android/adaptativos e iOS generados con
flutter_launcher_icons.yaml (herramienta dev 0.14.4). Un caso auth dirigido y
análisis limpio; usuario instala/ejecuta. iOS solo recursos, sin compilar en Windows.
Evidencia y APK: docs/APP_LOGO_2026-11-04.md. Sin cambios remotos.

Continuación D149–D150 (2026-11-04): el 429 usa el texto solicitado «El servidor
está temporalmente fuera de servicio. Inténtalo más tarde o mañana», conservando
resourceExhausted y acceso a copias; no confundir texto de producto con diagnóstico
de caída ni prometer recuperación mañana. Audio auditado: faltaban éxito de
movimientos y controles directos. Movimiento emite success solo tras resultado
confirmado; error de controller warning. AppToggleTile centraliza casillas/switch;
campos con acción, fotos, colores y gráfica conectados. No usar saved() de guard
globalmente: puede ser un borrador. Tres casos dirigidos y análisis limpio;
usuario instala/ejecuta, audio nativo pendiente. Estado:
docs/SERVER_NOTICE_AND_SOUND_COMPLETION_2026-11-04.md. Sin cambios remotos.

Continuación D148 (2026-11-03): AppGroupPreview recorta la portada en las dos
esquinas superiores con radio interior (AppRadius.large - actionBorder), para
dejar visible el borde de la tarjeta. Cambio visual, sin nuevas pruebas de negocio.
No confundir 50.000 lecturas gratuitas de documentos/día por proyecto con 50.000
consultas o acciones de usuario. Reglas, escuchas, copias y worker también cuentan;
no atribuir el agotamiento a una causa concreta sin métricas. Evidencia en
docs/QUOTA_GROUP_CARDS_SOUNDS_2026-11-03.md, D148. Usuario instala/ejecuta.

Continuación D147 (2026-11-03): resource-exhausted del SDK se conserva como
resourceExhausted en grupos/perfil/sincronización, no unknown/network; Inicio
ofrece copias también en error de una tarjeta individual. AppCover reemplaza
iniciales por icono/leyenda Sin foto cuando no hay imagen; conservar fotos de
caché y esqueletos de carga. Los avatares personales mantienen sus iniciales.
Dos regresiones dirigidas; evidencia y límites en
docs/QUOTA_GROUP_CARDS_SOUNDS_2026-11-03.md, D147. No prometer hora exacta de
recuperación del 429: 09:00 Madrid del 04/11 solo si es la cuota diaria gratuita.

Continuación D146 (2026-11-03): nombres sobre portadas abajo a la izquierda,
headingSmall, caja más transparente, por AppCover compartido (tarjetas e interior).
Nueva consulta remota sigue dando 429 RESOURCE_EXHAUSTED/Quota exceeded incluso
al leer grupos. No atribuirlo a Internet, borrado de datos o caída total. Ofrecer
consulta de copias sin cambiar plan/facturación. Análisis limpio, usuario ejecuta;
evidencia en docs/QUOTA_GROUP_CARDS_SOUNDS_2026-11-03.md, continuación D146.

Continuación 2026-11-03 D143–D145: diagnóstico real Firestore 429
RESOURCE_EXHAUSTED/Quota exceeded, antes de sumas; Android con red validada.
No confundir límite remoto con falta de Internet ni activar facturación.
Actualizar gráfica reintenta su caja dependiente; cuota conserva archivos y
ofrece copias, sin presentarlas como datos actuales. Tarjetas con nombre en caja
sobre foto y descripción/saldo debajo, sin Entrar; edición sin cabecera repetida
y Gestionar sin tarjeta exterior. Sonidos locales Kenney CC0 vía AppSoundScope →
provider → repository → service; activados por defecto, suaves, silencio nativo,
interruptor local y escritura por ráfagas. No sonar por contraseña/restauración,
no esperar audio para operar ni confirmar guardado al mero toque. El usuario
instala/ejecuta; no dar por acreditado sonido nativo ni gráfica real tras cuota.
Evidencia: docs/QUOTA_GROUP_CARDS_SOUNDS_2026-11-03.md. Sin cambios remotos.

Continuación D142, 2026-11-03: usuario confirma copia guardada/abierta y edición de
foto actual en su móvil. No extender a iOS/otros roles/dispositivos. Visor recibe
AppReadOnlyBanner compacto con fecha, solo lectura y salida; errores de red de
Inicio/acceso ofrecen catálogo junto al reintento. No saltar automáticamente a
otra fuente ni mostrar escape desde el visor aislado. Sin permisos/datos remotos.
Estado y evidencia: docs/OFFLINE_COMPACT_ACCESS_2026-11-03.md.

Entrega vigente 2026-11-03, D138–D141: laboratorio oculto (código conservado),
tarjetas de grupo con portada/datos debajo y login renovado. Nombre sobre foto,
Inicio sin acciones económicas duplicadas ni leyenda histórica; resumen destacado.
Gráfica de seis cierres acumulados por fecha efectiva con movimientos active,
incluye saldo anterior; mes actual en curso. Agregados REST en vivo y cálculo
puro en copia aislada; dinero entero, double solo para geometría. Copias fallaban
por pedir 200 avisos donde Rules exige <=50: paginar a 50, sin relajar permisos.
Editar foto actual usa temporal creado correctamente; avatar con máscara circular,
portada 16:9. Ocho casos dirigidos, análisis limpio y profile compilado; usuario
instala/ejecuta. Posteriormente confirma descarga/apertura y editor nativo;
no extender la confirmación a otros móviles, roles ni iOS.
Sin Rules/índices/despliegues/datos nuevos. Estado y evidencia:
docs/HOME_COPIES_PHOTOS_2026-11-03.md. Guía móvil sección 26.

Continuación 2026-11-03 D135–D137: AppButton reserva márgenes exteriores centrales;
AppExpandableRow tiene borde/fondo de acción (incluye Gestionar este espacio).
AppControlFeedback usa StackFit.passthrough para conservar todo el hueco asignado;
AppChoiceBar llena cada segmento, sin limitar el toque a la etiqueta. No perder
disabled/foco/animaciones ni el scroll de seguridad. Comprobar registro muestra
loading y confirmación/error, sin enviar una prueba desde Flutter.
Aviso 18:00 falló: token unregistered de antigua cuenta DEMO, además destino
distinto de la cuenta que el usuario usaba. La cuenta actual fue identificada por
su propiedad de Catequesis; no reutilizar UID histórico para envíos manuales.
Prueba 19:20 programada y enviada a Catequesis: FCM sent y usuario confirma
«Sí, ha llegado». La de 20:00 se conserva con ese destino; recepción pendiente.
Cinco casos dirigidos superados, análisis limpio, sin Rules/dinero/secretos nuevos.
Estado y evidencia: docs/ACTION_SPACING_AND_PUSH_2026-11-03.md. Usuario ejecuta
el nuevo APK para cambios visuales; no fue necesario instalarlo para recibir push.

Entrega 2026-11-03 D132–D134: formulario compacto de movimientos y cuota inicial
opcional de un mes/importe explícito para ingresos nuevos. Guardar juntos ingreso,
asignación, contador, testigos y auditoría, nunca dos escrituras consecutivas.
Journal v3 compatible con v1/v2, conserva y recupera el reparto; reintento mantiene
plan/ID. Correcciones mantienen reparto posterior explícito; retiradas normales
no alteran cuotas. AppButton/AppIconButton/AppCard interactiva comparten borde
de acción y relieve; información conserva borde neutro. Reglas publicadas tras
respaldo remoto externo 2026-11-03T16-19-30-199Z, hash activo
fee05c4c229be0c907840b47c6c5269213c2f419955620c6d7d8f81f75556055.
Pruebas push autorizadas para hoy 18:00/20:00 Madrid en notification-probe del
Supabase de notificaciones; cron jobs 2/3 de una ejecución, no cambiar job 1.
Solo registro más reciente de la cuenta, sin modificar preferencias ni dinero;
ventanas fechadas caducan. No acreditar entrega hasta probar el móvil.
El usuario confirma fluidez D131 en A059P, sin medición de FPS general.
Estado, límites y comprobaciones: docs/MOVEMENT_ENTRY_AND_NOTIFICATIONS_2026-11-03.md.

Corrección de navegación D131, 2026-11-03: AppDeferredSection aplaza montar las
features durante la entrada y muestra un esqueleto estático. La página saliente
usa SnapshotWidget efímero y TickerMode pausado durante el movimiento; no es una
copia diaria ni una caché persistente. GroupNavigationShell observa permisos fuera
del subárbol pausado y entrega clave opaca/permiso en AppSectionRenderScope:
cambio de cuenta, acceso o grupo descarta inmediatamente el cuadro anterior.
Conservar aislamiento del visor y movimiento reducido. Curvas de salida/entrada
acompasadas, sin cambiar D130 ni retirar laboratorio. Cinco casos dirigidos
superados y análisis limpio; fluidez física aún no acreditada. Diagnóstico profile
optativo TRACE_GROUP_MOTION registra tiempos/índices, nunca datos personales.
Estado vigente: docs/GROUP_NAVIGATION_PERFORMANCE_2026-11-03.md.

Selección aplicada 2026-11-03, D130: B07 principales/destructivos; B08 secundarios,
iconos, menús y AppChoiceBar; B04 validación rechazada y B05 deshabilitado visible,
sin ejecutar acciones rechazadas ni activar permisos. AppControlFeedback espera
320 ms, revalida al terminar y cancela por busy/acceso/desmontaje/ruta no actual.
AppButton.validate explícito; reglas del dominio permanecen en controllers/repos.
N01 sin escala del icono; P03 derecha y P05 formularios abajo. GroupNavigationShell
con AppSectionMotionScope/sectionIndex mueve izquierda/derecha según índice,
incluido volver a Inicio. AppGroupEntry: onda de 1 s y expansión desde rectángulo
real AppGroupOrigin (geometría efímera, no persistir ni usar para permisos).
Movimiento reducido sin efectos/espera. AppBottomSheet usa contexto modal del
host fuera del Navigator de sección, dentro del ámbito actual/copia. El usuario
elige CONSERVAR el laboratorio por ahora. No retirarlo automáticamente. Estado,
evidencia, APK y pendientes físicos: docs/SELECTED_MOTION_2026-11-03.md.
Nueve casos dirigidos superados, análisis limpio y APK debug/profile compilados;
sin cambios remotos. Usuario ejecuta; no acreditar fluidez o aprobación física.

Laboratorio temporal 2026-11-03, D129: el usuario no aprueba las animaciones
actuales y pide compararlas antes de elegir. Inicio muestra Laboratorio de
animaciones, ruta autenticada /testing/motion solo debug/profile (!kReleaseMode).
No exponer la galería general ni el laboratorio en release. Catálogo aislado
lib/design_system/lab: 24 rutas P01–P24, 12 botones B01–B12 y 4 barras N01–N04;
velocidad 150–1.000 ms, estado visual efímero y contenido ficticio, sin SDKs/datos.
No aplicar ninguna opción al producto ni borrarlo hasta recibir la selección
del usuario. Las transiciones D128 siguen provisionales. Entrar con código usa
llave mediante iconos por opción en AppFloatingActions; conservar ese ajuste al
retirar el laboratorio. Evidencia, retirada y pendientes físicos:
docs/MOTION_LAB_2026-11-03.md. Cuatro casos dirigidos distintos superados, análisis
limpio y APK debug/profile compilados. Usuario ejecuta; sin cambios remotos.

Última continuación cerrada 2026-11-03, D128: el usuario comunica lag y elige efectos más
marcados. AppMotionPage/AppContextPageTransitionsBuilder distinguen grupo (zoom),
secciones (fundido/escala), formularios (vertical) y resto (avance corto). Sustituye
deslizamiento uniforme D127; pulso completo 80 ms por tramo, rutas 240 ms.
GroupNavigationShell/AppNavigationHost mantienen una sola barra con indicador
continuo, fuera del Navigator de secciones, en vivo y en visor aislado. Editores
manuales de personas/fotos en Navigator raíz: cubren la barra durante edición. Conservar
rutas/guards/Atrás y acceso reactivo; no cachear permisos. AppReveal usa hijo
estable y evita su entrada mientras la ruta se anima. Biblioteca App*, reducción
de movimiento y Apple nativo conservados. Estado/evidencia/APK y pendientes:
docs/MOTION_PERFORMANCE_2026-11-02.md. Siete casos dirigidos, análisis limpio y APK
debug/profile compilados. Usuario ejecuta; no afirmar fluidez medida.
Sin cambios remotos. Los párrafos siguientes de movimiento son históricos.

Último cambio 2026-11-02, D125–D127: selector cuadrado + arcoíris con hexadecimal
sincronizado; conservar confirmación y preview. Atlántico intacto; Cyberpunk,
Cartoon, Arcade y Pop Art sustituyen las otras cuatro, conservando IDs locales.
AppPressFeedback completa presión/retorno antes del callback de botones/iconos/
tarjetas; cancelar/deshabilitar/desmontar anula la acción pendiente, reducir
movimiento elimina espera. Rutas usan appRoute (MaterialPage SDK explícita) porque
go_router 18 detectaba material_ui y elegía NoTransitionPage. AppTheme y
AppPageTransitions comparten deslizamiento; editores, paneles y diálogos reutilizan
tokens. Visor aislado y guards intactos. Trece pruebas dirigidas y tres capturas
simuladas, análisis limpio y APK debug compilado; estado/APK/pendientes físicos:
docs/COLOR_PICKER_PALETTES_MOTION_2026-11-02.md.
Sin cambios remotos. Usuario ejecuta la app.

Continuación visual 2026-11-02, D120–D124: carga con AppShimmer/AppSkeleton y
formas de grupos/personas/movimientos/resumen, fotos y botones; sin círculos ni
datos ficticios, estática con movimiento reducido. Inicio usa Añadir flotante
(crear/código) y Copias en cuenta. Menús con AppMenuRow/PopupMenuTheme compartidos.
Manrope/Newsreader/Sistema y paletas propias de tres colores, preview claro/oscuro
con App* y contraste automático, incluyendo etiquetas. Apariencia versión 2 local,
compatible con preferencias anteriores, independiente de UID y sin SDK nuevos.
AppTheme/AppTypography propagan fuente y paleta; conservar aislamiento del visor.
Once pruebas dirigidas distintas, análisis limpio y APK debug compilado; cuatro capturas simuladas;
estado exacto/APK/pendientes en docs/VISUAL_LIBRARY_2026-11-02.md. Usuario ejecuta
la app; no acreditar validación física. Sin cambios remotos ni Rules.

Ampliación 2026-11-02, D116–D119: portadas con editor y vista previa 16:9;
avatares cuadrados, sin migrar fotos existentes. AppFormGuard protege cambios
sin guardar en personas/perfil/grupos/movimientos/fotos y primeros meses en lote.
Personas muestra pendientes activas sin etapas y permite selección múltiple con
primer mes común explícito; cada persona conserva transacción/auditoría individual,
detener e informar ante fallo parcial. Cinco paletas ampliadas con complementario
y tercer acento, conservando errores/avisos. D119 sustituye D093: solicitud nativa
de avisos en primera entrada autenticada por UID/móvil, elección local persistida;
rechazo/retirada no se reactivan automáticamente. Preferencias ausentes de grupo
ya activas; no sobrescribir false. Sin Rules/despliegues/datos remotos nuevos.
Evidencia y pendientes físicos: docs/UX_IMPROVEMENTS_2026-11-02.md.
23 pruebas dirigidas distintas superadas, análisis limpio y APK debug compilado.
El usuario ejecuta la app; no dar por comprobada entrega push ni editor nativo.

Entrega vigente v0.4, 2026-10-30, D114–D115: el usuario rechaza v0.3. Cinco paletas
(Atlántico/Iris/Coral/Bosque/Grafito), claro/oscuro/Sistema y selección guardada en
este móvil mediante UI → provider → repository → service local. Inicio sin bloque
promocional; grupo con portada 16:9 de ancho completo y nombre/descripción debajo.
Barra Inicio/Actividad/Participantes/Informes; Participantes abre Personas/Miembros.
Acciones económicas compartidas y enlaces generales duplicados retirados. Atrás
de sección vuelve al resumen, de este a Tus grupos, con rutas principales anidadas.
El visor recibe tema sin romper su aislamiento. 37 pruebas dirigidas distintas,
análisis limpio, 19 capturas simuladas revisadas y APK debug compilado e instalado
en A059P mediante actualización. Aprobación física v0.4 pendiente; el usuario ejecuta la app. Evidencia:
docs/VISUAL_REDESIGN_V04_VALIDATION.md. v0.3 inferior es histórico, no aprobado.

Entrega visual 2026-10-30, D113: Design System v0.3 carbón/menta implementado según
dos nuevas referencias; el usuario elige «Más expresivo». Manrope también en
titulares/saldos sustituye el serif de v0.2. App* renueva las pantallas existentes;
Inicio/resumen reorganizados, barra inferior en cuatro vistas de grupo, entradas
escalonadas, pulsación y órbitas decorativas, con movimiento reducido. Forui y
Flutter Animate consultados como referencias; implementación en SDK existente.
33 pruebas dirigidas, análisis limpio, ocho capturas simuladas revisadas y APK debug
compilado; aprobación visual en móvil pendiente, el usuario ejecuta la app. Ver
docs/VISUAL_REDESIGN_V03_VALIDATION.md. Los párrafos visuales antiguos son históricos.

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
