# BoteParroquial — Design System v0.4

## D166: selección final de clics

Laboratorio de clics retirado. Press usa Retro 6/7/8 elegidos por el usuario;
menús y otros eventos conservados. Variación en modelo/service, sin archivos
elegidos desde features. AppInteractionHost y handoff D165 siguen vigentes.

## D164–D165: bloqueo compartido y audición aislada

AppInteractionHost/gate de leases en la raíz; AppControlFeedback, AppGroupEntry y
AppPageTransitions mantienen el bloqueo solo por sus animaciones. Handoff sin
hueco por frame, liberación por cancelación/dispose. No bloquear providers/red ni
almacenar permisos en el gate. AppButton.soundEnabled permite escuchar muestras
sin superponer su clic normal; no silenciar acciones del producto por defecto.

## D161–D163: sonido del sistema y controles compactos

AppSystemBackSound observa éxito de navegación y emite back por AppSoundScope;
no alterar guards, callbacks ni transiciones. AppSoundSettingsPanel compone
interruptor/prueba y AppVolumeSlider.compact; mínima altura sin perder accesibilidad.
Familias de menús/normal separadas. Alta compone controles y portada solo si hay
borrador, sin un bloque promocional. No subir fotos desde componentes visuales.

## D159–D160: sonido de menú y gestión visible

UiSound.menu en componentes de desplegable; AppButton/AppIconButton admiten sonido
semántico explícito para apertura. No duplicarlo con tap. Familia normal nueva,
menú anterior. Dashboard compone AppNavigationTile para Cuotas y etapas/Editar
grupo/Historial administrativo, sin un ExpansionTile exterior de gestión.

## D157–D158: audio semántico e identidad compacta

AppSoundSurface ya no escucha pointer-down: solo controles activos emiten eventos.
AppControlFeedback conserva rechazo visual silencioso si está deshabilitado;
validación fallida de acción disponible conserva warning. Botones Volver usan back,
no tap. SDK/variantes/volumen siguen fuera de componentes. AppCompactIdentity es
presentación no interactiva de nombre elidido + miniatura, para cabecera derecha.
GroupSectionTopBar compone con providers; identidad completa solo en Dashboard.

## Distribución vigente de tarjetas de grupo (D154)

Debajo de portada, AppAdaptiveRow con descripción izquierda y saldo derecha,
alineados arriba. FittedBox.scaleDown evita recortar importes largos, manteniendo
el tamaño hero si cabe. Sustituye la columna saldo/descripción de D153. Con texto
ampliado o anchura insuficiente se permite apilar para accesibilidad. Conservar
radios, ausencia de badges y acción completa.

## Toques y volumen vigentes (D152–D153)

AppSoundSurface contiene el scope y un Listener pasivo alrededor de toda la app:
un tap físico por pointer-down, incluso zona libre/inicio de desplazamiento, sin
activar acciones. Evita el segundo tap de componentes durante ese toque/frame;
no suprimir success/warning/photo. AppTextField emite typing por cada edición,
incluida contraseña sin transmitir contenido, no por restauración. Sustituye el
comportamiento de ráfagas/exclusión anterior. AppVolumeSlider devuelve porcentajes
enteros; el provider aplica el nivel al ajustar y persiste al terminar.

AppGroupPreview: portada, saldo hero inmediato y descripción debajo, sin badges
de rol/moneda. Conservar recortes y área interactiva completa. Perfil compone fila
de avatar y acción flexible a su derecha, usando los tokens existentes.

## Marca suministrada (D151)

AppLogo usa assets/branding/bote_parroquial.png sin tintarlo y sustituye el dibujo
provisional de AppBrand. AppLogoBackdrop presenta esa imagen al 12 %, con máscara
radial de transparencia, IgnorePointer y exclusión semántica. Usarlo como fondo,
sin lógica de datos ni animación continua. AppScaffold.background es opcional y
no cambia otros layouts. Login y AppWelcomePanel componen la misma marca.
No confundir el logo de app con fotos de grupos/personas ni reemplazar esas fotos.

## Cobertura de audio (D150)

AppToggleTile encapsula switch/casilla con feedback de selección y deshabilitado
nativo. Usarlo frente a controles directos nuevos. AppTextField emite tap cuando
tiene onTap explícito (p. ej. fecha); AppColorField/Plane y AppLineChart responden
al toque/inicio del arrastre, sin sonar en cada actualización. Mantener callback
sonoro externo; sin SDK de reproducción en componentes. Un borrador seleccionado
no emite success de persistencia: no añadirlo a AppFormGuard.saved globalmente.

## Recorte de portada en tarjeta (D148)

AppGroupPreview aplica a la portada ClipRRect solo superior, con radio interior
AppRadius.large - AppSpacing.actionBorder. Se alinea al contenido dentro del
borde de AppCard y evita que la imagen cuadrada lo cubra en las esquinas.
Conserva el recorte exterior de la tarjeta, acción completa y onda de entrada.

## Portadas sin imagen (D147)

AppCover usa imagen no disponible y leyenda Sin foto con colores del tema cuando
no hay imagen o esta no se puede renderizar. Ya no calcula iniciales de grupo.
Conservar AppShimmer durante carga y foto de caché si está disponible. Avatares de
personas/cuentas siguen con iniciales: no cambiar su identidad por una avería remota.

## Posición vigente de nombres en portada (D146)

AppCover.titleOnImage sitúa el nombre abajo a la izquierda, headingSmall,
caja imageScrim con alfa .28 y scrim inferior .45 → 0. Sustituye la posición
superior y el texto mayor anteriores; se aplica en tarjetas e interior por el
mismo componente. Mantener dos líneas, escalado de texto y colores semánticos.

## Tarjetas y respuesta sonora (D144–D145)

AppCover.titleOnImage aloja el nombre en caja semitransparente con tokens, además
del scrim. AppGroupPreview compone esa portada y descripción/saldo adaptables,
sin un botón Entrar separado. No envolver AppExpandableRow en otra AppCard solo
para dibujar borde: el desplegable ya tiene el suyo.

AppSoundScope recibe un callback de eventos UiSound; no importa reproductores ni
providers. Controles compartidos emiten tap, typing, success, photo o warning.
AppTextField solo emite typing por edición del usuario, salvo password; nunca
envía texto al reproductor. AppSnackbar emite el resultado correspondiente.
La app aplica preferencia, silencio y limitación; componentes no esperan audio
para navegar/guardar y funcionan sin scope en showcase/tests. Solo el éxito
confirmado por la UI puede emitir success. No confundir foto preparada con subida.

## Aviso compacto de fuente (D142)

AppReadOnlyBanner recibe fecha formateada y callback de salida, sin repositorios
ni SDKs. Una fila con etiqueta/fecha y AppButton compacto conserva solo lectura
visible y objetivo táctil de 48; reduce envoltorios y texto persistente. No ocultar
la fuente al navegar ni reducir áreas táctiles para ganar espacio. La descripción
de cifras/fotos queda disponible a tecnologías de asistencia.

## Inicio y fotografía (D138–D141)

AppGroupPreview compone portada y contenido inferior con pie adaptable, rol,
moneda, saldo y entrada visible; AppWelcomePanel ofrece la cabecera de login.
AppCover.titleOnImage coloca título superior izquierdo con scrim semántico,
onImage/imageScrim centralizados. AppLineChart recibe valores enteros y etiquetas
ya formateadas; solo normaliza geometría, nunca calcula finanzas ni accede a datos.
Permite selección de puntos y resumen semántico. Usar tokens y paletas existentes.
AppImageCropper: máscara circular para avatar 1:1 y rectangular para portada 16:9;
no implica guardar un original completo ni migrar fotos. El laboratorio queda
oculto por petición expresa, conservando sus fuentes y efectos de producción.
Copias usa AppShimmer y bloques de esqueleto durante el trabajo, sin progreso ficticio.
Evidencia: docs/HOME_COPIES_PHOTOS_2026-11-03.md.

## Separación y zona de acción (D135–D136)

AppButton añade margen exterior vertical sm y horizontal xs: separar controles
y texto sin repetir ajustes por feature. El margen queda fuera de su borde y
no sustituye el objetivo táctil interior. AppExpandableRow también lleva borde
y fondo de acción, tanto abierto como cerrado. AppControlFeedback conserva las
restricciones con StackFit.passthrough; AppChoiceBar llena cada segmento con su
TextButton. No aceptar superficies pintadas con solo la etiqueta pulsable.
Conservar callbacks/disabled, foco y movimiento reducido. Sin capas persistentes
ni nuevas animaciones. Evidencia: docs/ACTION_SPACING_AND_PUSH_2026-11-03.md.

## Acciones diferenciadas (D133)

AppButton/AppIconButton y AppCard interactiva con callback usan borde de acción
AppSpacing.actionBorder, fondo semántico de acción y relieve AppShadows.action.
Foco, disabled, paletas y movimiento elegidos se conservan. Tarjetas informativas
mantienen borde neutro y no reciben relieve de botón. Aplicar por biblioteca,
sin estilos de acción duplicados en features. AppMoneyField permite prominent:
false en formularios compactos, sin reducir objetivos táctiles ni quitar el
scroll de seguridad con teclado/texto ampliado.

## Renderizado durante navegación de grupo (D131)

AppDeferredSection muestra AppSkeleton estático durante la primera entrada y
monta la feature al acabar las animaciones propia/exterior. Una sección ya montada
se congela solo durante la transición con SnapshotWidget permisivo y TickerMode;
se libera al acabar, desmontar o invalidar acceso. En web no capturar. La shell
publica AppSectionRenderScope con decisión/clave opaca de permisos, sin dominio
en los componentes visuales. Reversas easeIn acompañan entradas easeOut para
evitar aceleración tardía y separación de las páginas. Mantener D130, accesibilidad
y laboratorio. Ver [evidencia y límites](docs/GROUP_NAVIGATION_PERFORMANCE_2026-11-03.md).

## Elección vigente de movimiento (D130)

03/11/2026: AppControlFeedback aplica B07 a principales/destructivos, B08 a
secundarios/iconos/menús y barras de elección, B04 a validación fallida y B05 a
deshabilitados visibles. No ejecutar acciones rechazadas; loading evita nuevos
ciclos. AppButton.validate es explícito y revalida al acabar. Tokens: controles
320 ms, ruta 240 ms, indicador N01 180 ms. Sin antiguo pulso de escala acumulado.
AppGroupEntry: onda de 1 s y AppGroupOrigin para crecer desde la tarjeta real;
sin origen usa P03. AppMotionPage/AppSectionMotionScope definen dirección por
índice dentro del grupo; formularios P05 con formRoute compartida. Movimiento
reducido inmediato. AppBottomSheet se aloja con modalContextOf del host sin
salir del ámbito de cuenta/copia. Laboratorio se conserva por decisión expresa.
[Estado y evidencia](docs/SELECTED_MOTION_2026-11-03.md). Lo inferior registra
las etapas anteriores, no reemplaza esta elección.

## Laboratorio temporal de movimiento

D129, 03/11/2026: las animaciones vigentes no tienen aprobación visual. El usuario
pide comparar antes de decidir. design_system/lab contiene un catálogo efímero
de rutas P01–P24, botones B01–B12 y barras N01–N04, con velocidad ajustable y
contenido ficticio. Acceso por Inicio, solo debug/profile; no aplicar elecciones
al tema ni incorporarlo a release. La galería general continúa separada/debug.
Respetar accesibilidad y aspecto actual. La retirada exige selección expresa y
se documenta en [MOTION_LAB_2026-11-03.md](docs/MOTION_LAB_2026-11-03.md).
AppFloatingActions acepta iconos por opción; Entrar con código muestra llave.

## Movimiento vigente: expresivo y por contexto

D128, 02/11/2026: sustituye el deslizamiento uniforme inferior. AppMotionPage
declara intención: grupo (zoom), sección (fundido/escala), formulario (vertical),
resto (avance corto). AppContextPageTransitionsBuilder/AppPageTransitions y
AppMotion centralizan estilo y tiempos: ruta 240 ms, indicador 180 ms, pulso
80 ms por tramo. No añadir blur ni animar también la página anterior.
AppReveal usa FadeTransition con hijo estable, sin otra entrada si la ruta anima.
GroupNavigationShell compone AppNavigationHost: barra fuera del Navigator, con
una sola selección que viaja entre pestañas y pequeño énfasis del icono/texto.
AppScaffold no duplica su slot inferior cuando existe host. Mantener uso standalone,
texto ampliado, movimiento reducido y navegación nativa Apple.
[Evidencia y pendientes](docs/MOTION_PERFORMANCE_2026-11-02.md).

## Última dirección: color visual y movimiento completo

D125–D127, 02/11/2026: AppColorPlane/AppHueSlider sustituyen deslizadores por
cuadrado y espectro, con hexadecimal sincronizado en AppColorField. Atlántico
conserva colores; nuevas Cyberpunk/Cartoon/Arcade/Pop Art en AppPaletteCatalog y
AppColors. IDs antiguos persisten, paletas propias y letras no se alteran.

AppPressFeedback.builder completa el pulso antes de actuar en AppButton,
AppIconButton y AppCard interactiva, impide repetir y cancela al deshabilitar o
desmontar. Movimiento reducido es inmediato. AppPageTransitions define la
transición Material; Apple mantiene la nativa. AppDialog/AppBottomSheet y editores
usan tokens centrales. Rutas appRoute crean MaterialPage explícitas para que el
tema se aplique con go_router 18 en este SDK. No repetir estilos en features.
Trece pruebas dirigidas y tres capturas simuladas; revisión móvil pendiente:
[COLOR_PICKER_PALETTES_MOTION_2026-11-02.md](docs/COLOR_PICKER_PALETTES_MOTION_2026-11-02.md).

## Biblioteca ampliada: carga y apariencia personal

D120–D124, 02/11/2026: AppShimmer/AppSkeleton/AppSkeletonBlock centralizan banda
diagonal, formas de contenido y semántica. LoadingIndicator usa skeleton genérico
o compacto para botones; AppAvatar/AppCover heredan brillo sin reemplazar imágenes
disponibles. Sin animación al reducir movimiento y sin círculos de espera.
Las features eligen composición de carga desde esta biblioteca, sin copiar estilos.

AppMenuRow y PopupMenuTheme renuevan cuenta/contextos; AppDropdown muestra filas
con selección y conserva foco/cancelación nativos. AppFloatingActions y el slot de
AppScaffold soportan acciones visibles al desplazar. Inicio decide callbacks:
Añadir para grupo/código, Copias en cuenta. No crear controles de dominio en DS.

AppTheme/AppTypography reciben Manrope/Newsreader/Sistema. Colores personales se
derivan de tres semillas RGB y tonos ajustados para contraste claro/oscuro y de
etiquetas sobre alpha. AppColorField ofrece HSV/hex y AppThemePreview compone App*
sin acciones reales; no estilos paralelos. Identificadores predefinidos siguen
vigentes. Apariencia local conserva fuente/modo/paletas propias sin dependencias
nuevas. Once pruebas dirigidas y cuatro capturas simuladas; móvil pendiente:
[VISUAL_LIBRARY_2026-11-02.md](docs/VISUAL_LIBRARY_2026-11-02.md).

## Ampliación 02/11/2026

D116–D119: tokens secundarios/terciarios con contenedores, copyWith/lerp y
ColorScheme completos. Atlántico azul/ámbar/lavanda; Iris violeta/lima/rosa;
Coral coral/turquesa/violeta; Bosque verde/frambuesa/ocre; Grafito tinta/cobre/
petróleo. Las vistas previas muestran los tres acentos. Botones secundarios,
paneles con degradados suaves y tonos de Participantes/estadísticas los utilizan
sin alterar éxito/aviso/error. Conserva claro/oscuro/Sistema y preferencias locales.

AppImageCropper admite portada horizontal 16:9, manteniendo cuadrado para avatares.
AppFormGuard muestra AppDialog al abandonar cambios pendientes y bloquea salida
durante envíos; no guarda datos. Primeros meses se presentan con AppCard/AppBadge,
casillas y AppMonthField, con confirmación explícita de conjunto. No se declaran
cubiertos todos los formularios históricos ni probado el editor nativo en móvil.
Evidencia: [UX_IMPROVEMENTS_2026-11-02.md](docs/UX_IMPROVEMENTS_2026-11-02.md).

## Dirección vigente — apariencia elegible, 2026-10-30

El usuario rechaza el resultado v0.3 y pide rehacer la estética y la navegación.
v0.4 introduce superficies planas, paneles tonales, radios más amplios, controles
rellenos y protagonismo de las portadas. Se retira el panel promocional de Inicio
y la ornamentación orbital de los paneles. La tipografía sigue siendo Manrope,
con titulares y cifras de mayor peso.

Cinco paletas: **Atlántico, Iris, Coral, Bosque y Grafito**, cada una con variante
clara y oscura. Ajustes de apariencia está disponible desde el icono de paleta de
Inicio y desde Tu perfil. Ofrece Sistema/Claro/Oscuro y vista previa de ambas
variantes de cada paleta. Se aplica al momento y se recuerda en este móvil,
independientemente de la cuenta. La base inicial es Atlántico y modo Sistema.

En el resumen, portada panorámica 16:9 de ancho completo y nombre/descripción
debajo. En las secciones se usa identidad compacta para dejar espacio al contenido.
Barra inferior de ancho completo: Inicio, Actividad, Participantes e Informes.
Participantes permite abrir Personas o Miembros. Ingreso/retirada comparten
`MovementActions` en resumen e historial. Los accesos generales duplicados a
movimientos, personas, miembros e informes se retiran del resumen.

Las rutas tienen padres reales: Atrás desde una sección principal vuelve al
resumen del grupo; desde el resumen, a Tus grupos. El visor de copias mantiene
ese recorrido y recibe el tema elegido desde fuera de su contenedor aislado.

37 pruebas dirigidas distintas superadas, análisis limpio, APK debug compilado
y 19 capturas simuladas revisadas. Aprobación en móvil pendiente.
Estado y evidencia: [VISUAL_REDESIGN_V04_VALIDATION.md](docs/VISUAL_REDESIGN_V04_VALIDATION.md).

## Dirección anterior — carbón y menta, histórico v0.3

El usuario aporta dos nuevas referencias móviles y elige **«Más expresivo»**
(D113): fondos carbón, acento menta, tipografía sans, tarjetas contorneadas,
cabeceras con profundidad y animaciones perceptibles con propósito. Sustituye
la dirección tipográfica serif de v0.2. Manrope se usa ahora también en titulares
y saldos; Newsreader sigue en los assets históricos, sin uso en los tokens actuales.

La base compartida actualiza las pantallas existentes, incluidos formularios,
cuotas, informes, avisos, perfil, auditoría y copias. Inicio y dashboard cambian
además su composición. El grupo ofrece barra inferior flotante de Inicio,
Actividad, Personas e Informes. La gestión del grupo se despliega desde
«Gestionar este espacio»; Miembros y Cuotas siguen accesibles desde el resumen.
La navegación también funciona en el visor aislado de copias.

Referencias externas consultadas: [Forui](https://forui.dev),
[Flutter Animate](https://github.com/gskinner/flutter_animate) y
[animaciones de Flutter](https://docs.flutter.dev/ui/animations).
Se adaptan sus ideas de superficies mínimas, feedback de estado y entradas
escalonadas a App*, con implementación propia sobre el SDK existente.

Comprobaciones: 33 pruebas dirigidas, análisis limpio y APK debug compilado;
ocho capturas simuladas exportadas y revisadas. Aprobación estética en el móvil
pendiente del usuario. Detalles y comandos:
[VISUAL_REDESIGN_V03_VALIDATION.md](docs/VISUAL_REDESIGN_V03_VALIDATION.md).

Los apartados fechados de entregas anteriores conservan su contexto histórico.

Implementación y galería disponibles. v0.2 adapta las ocho referencias visuales
aportadas por el usuario el 2026-10-15. Inicio, grupos, resumen, personas, miembros,
formularios, historial y login usan App*. Oscuro predeterminado y variante clara
conservada para compatibilidad y revisión; no hay selector de tema implementado.
Los datos de la galería son ejemplos, no información del backend.

Fotos (ampliación posterior): AppAvatar y AppCover siguen recibiendo ImageProvider
sin SDK ni reglas. Las wrappers de photos/presentation consultan providers y usan
la caché privada por providers; editor con App*, animación de entrada y movimiento reducido. AppAvatarMenu
añade callback opcional de foto sin conocer Firebase/Supabase. Sin imagen o ante
error sin imagen, se conservan las iniciales. Durante primera carga se usa un
espacio neutro; las revalidaciones mantienen la foto sin volver a iniciales.
AppImageCropper envuelve recorte/zoom/rotación nativos con tokens claro/oscuro.
Detalles en docs/SUPABASE_SETUP.md.
AppDelayedVisibility añade un margen de presentación para avisos transitorios,
con retirada inmediata al resolverlos. El token statusNoticeDelay es de dos
segundos; no es una animación y no depende de movimiento reducido. No reserva
espacio mientras el aviso está oculto ni contiene lógica de conectividad.

## Identidad visual

Copias locales (23/10/2026): catálogo con AppTopBar/AppCard/AppReveal y AppButton;
entrada disponible desde Inicio y GroupSyncNotice. El visor conserva AppTheme y
pantallas existentes, con aviso fijo AppBadge/AppCard de fecha y solo lectura y
salida explícita. No confundirlo con aviso transitorio de conexión: su banner no
desaparece al recuperar Internet. Fotos no interactivas en copia. Sin nuevos tokens
visuales ni estilos paralelos. Validación física pendiente.

Entrega 2026-10-20: exportación mediante AppDropdown/AppButton; papelera y bajas
componen AppTopBar, AppHeroPanel/AppCard, AppDialog y AppReveal existentes.
Pendientes de borrado se presentan desde Inicio con AppButton. Caja conserva
BalanceCard y fecha de confirmación; los widgets reciben cifras/permisos preparados,
sin Firebase ni cálculos financieros. No hay nuevos colores, fuentes o biblioteca
visual. La validación en móvil de estas pantallas queda para el usuario.

Auditoría (2026-10-20): cabecera AppHeroPanel, fichas AppCard/AppReveal, búsqueda
y filtros AppTextField/AppDropdown; detalle antes/después en AppBottomSheet con
AppAdaptiveRow. Sin estilos paralelos. Caché pendiente usa AppDelayedVisibility
para evitar avisos fugaces; consulta vacía sin confirmar no anuncia un final.
Claro/oscuro, texto 160 % y movimiento reducido comprobados con datos simulados.
Ver docs/PHASE11_AUDIT_HISTORY_VALIDATION.md.

Comparaciones (2026-10-20): bloque desplegable en Informes con AppExpandableRow,
AppReveal, AppHeroPanel y AppCard. Importes/diferencias en filas adaptables;
sin colores arbitrarios para calificar subidas/bajadas. Claro/oscuro, texto al
160 % y movimiento reducido revisados en el flujo simulado. Evidencia y revisión
móvil pendiente: docs/PHASE10_PERIOD_COMPARISONS_VALIDATION.md.

Notificaciones: bandeja/perfil componen AppReveal, AppCard, AppBadge,
AppChoiceBar, AppButton y AppTopBar; sin componentes paralelos o tokens nuevos.
Oscuro/claro, texto al 160 % y movimiento reducido comprobados en flujo simulado.
No se considera validación visual en móvil; ver docs/PHASE9_NOTIFICATION_CLIENT_VALIDATION.md.

Cuotas (2026-10-19): AppMonthField compone AppDropdown/AppAdaptiveRow para mes y
año, sin modelos o permisos. intl 0.20.2 se declara directa, conservando la versión
existente, para etiquetas localizadas. Pantallas y editor de participación usan
AppHeroPanel/AppCard/AppReveal/AppBottomSheet/AppDialog y heredan temas/movimiento.
Evidencia: docs/PHASE8_QUOTAS_PERIODS_VALIDATION.md.

Asignaciones: editor por ingreso y resumen individual reutilizan AppHeroPanel,
AppMonthField, AppMoneyField, AppDialog y AppReveal. Los paneles nuevos usan
onHero en texto/cifras también en tema claro. Se conservan texto ampliado y
movimiento reducido. Los cálculos y advertencias financieras vienen de providers;
no se añade lógica a MoneyText/StatusChip. Validación:
docs/PHASE8_ALLOCATIONS_VALIDATION.md.

Superficies planas con matiz de la paleta elegida y paneles tonales, sin órbitas.
Las acciones e importes de movimientos mantienen tonos semánticos verde/rojo,
además de iconos y etiquetas, independientemente del acento. La marca
vectorial representa dos formas que comparten un centro; es una propuesta de
interfaz, no un logotipo definitivo. No incorpora símbolos religiosos explícitos.

Manrope para lectura, acciones, titulares y cifras, también en el saldo destacado.
Los nombres semánticos editorialTitle/moneyHero se conservan como API.
Las fuentes se incluyen localmente en
`assets/fonts/` con sus licencias SIL OFL, sin descargas al abrir la app.
Iconografía Material outlined/rounded coherente, sin otra dependencia de iconos.

## Arquitectura visual

```text
Flutter / Material / eventual librería externa
  → lib/design_system/
    → componentes App* y componentes semánticos como BalanceCard
      → pantallas de features
```

API pública: `package:bote_parroquial/design_system/design_system.dart`.
Los tokens viven en `lib/design_system/theme/`; no crear otra paleta en `core/theme`.
Los componentes no importan Firebase ni modelos/providers de negocio. Reciben
valores y callbacks. PersonListTile, MovementListTile o MonthlyContributionCard
seguirán en su feature y compondrán estas piezas cuando se implementen.

## Tokens

Resolver con `AppColors.of(context)` y `AppTypography.of(context)`. AppColors es
una ThemeExtension con `copyWith`, `lerp` y paletas light/dark. AppTheme configura
la implementación Material de inputs, calendario, diálogos, paneles y tipografía.
  AppTheme se conecta tanto a la galería como a la app desde Phase 2.

### Color

| Paleta | Primary claro | Primary oscuro | Fondo claro | Fondo oscuro |
| --- | --- | --- | --- | --- |
| Atlántico | #2459C4 | #AAC5FF | #F4F6FA | #11151E |
| Iris | #713BC1 | #D4B8FF | #F8F5FD | #19131F |
| Coral | #B7472A | #FFB497 | #FFF7F1 | #211715 |
| Bosque | #25694F | #ABD3B7 | #F2F7F3 | #111A16 |
| Grafito | #3D475A | #C5CEDF | #F3F4F6 | #0C0D11 |

`AppColors.forPalette` resuelve todos los tokens, también superficies, variantes,
contornos y hero. `AppTheme.forPalette` construye el tema Material completo.
hero es ahora tonal y onHero es texto primario, también en claro; no conservar
el supuesto histórico de texto siempre blanco sobre hero. La fuente exacta de
tokens es `lib/design_system/theme/app_colors.dart`.

Primary identifica acciones, secondary aporta acento cálido, hero distingue el
saldo, surface contiene cards/formularios, divider separa y outline delimita
controles. Estados siempre con etiqueta/icono además de color. Los tonos no
conceden permisos ni interpretan estados persistidos.

### Tipografía

| Estilos | Tamaños base |
| --- | --- |
| displayLarge / editorialTitle | 32 / 26, Manrope extra-bold / bold |
| headingLarge / Medium / Small | 30 / 24 / 19, Manrope |
| bodyLarge / Medium / Small | 16 / 14 / 12 |
| labelLarge / Medium / Small | 14 / 12 / 11 |
| moneyHero / Large / Medium | 46 / 30 / 18, Manrope con cifras tabulares |
| sectionTitle / statisticValue / movementAmount | Alias de headingSmall / moneyLarge / moneyMedium |

Usar estilos semánticos, no TextStyle arbitrarios por pantalla. Las cifras usan
`FontFeature.tabularFigures`. Respetar texto ampliado con layouts flexibles y scroll.

### Espaciado, radios y sombras

- AppSpacing: xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, xxxl 48. Página 20,
  separación de secciones 24, contenido máximo 1080.
- Botón normal: mínimo 52; compacto e icon button: mínimo 48 de alto.
- AppRadius: small 8, medium 16, large 24, extraLarge 32, pill 999.
  Controles 16, cards 24, hero/overlays 32. Cubiertas pequeñas 88/112; portada
  panorámica 16:9. Avatar de editor 112.
- AppShadows.soft: elevación ligera; floating: preparada para superficies
  flotantes. Las cards base usan borde, sin sombra. No inventar sombras por feature.

### Movimiento

AppMotion: fast 140 ms, normal 220 ms, slow 320 ms; easeOutCubic/easeInOutCubic.
AppReveal combina fade, desplazamiento de 18 puntos y escala .985 → 1 en 540 ms;
order permite hasta cinco escalones de 65 ms. AppPressFeedback aplica escala .975
mientras se pulsa, sin gestionar las acciones del control Material. Cancelar no
confirma acciones. Con movimiento reducido se omiten la entrada y la escala.
AppAtmosphere queda como pieza histórica de v0.3, sin uso en los paneles actuales.
Desplegables y barra inferior usan
las duraciones comunes. MoneyText conserva AnimatedSwitcher opcional, sin animar
valores financieros intermedios. LoadingIndicator usa un icono estático accesible
con movimiento reducido.

## Componentes implementados

Ampliación del 2026-10-17: AppPairedBars presenta pares de series con etiquetas y
valores ya proporcionados, color semántico, escala visual y animación reducida
según AppMotion. No calcula saldos ni periodos. AppAvatarMenu admite onProfile
sin conocer el dominio. Nuevas pantallas reutilizan formularios, cards y App*.

| Componente | Variantes y capacidad |
| --- | --- |
| AppButton | primary, secondary, outline, ghost, destructive; normal/compact; loading; disabled con onPressed null; iconos inicial/final; fullWidth |
| AppIconButton | standard (por defecto), ghost, danger; tooltip obligatorio |
| AppTextField | label, hint, icon, error, helper, password, enabled, readOnly, controller, validator y formateadores |
| AppMoneyField | currency explícita; callback int? de céntimos; dos decimales sin miles ni negativos |
| AppDropdown<T> | Opciones tipadas, valor controlado, error y deshabilitado |
| AppDateField | Fecha controlada, límites opcionales y calendario localizado |
| AppCard | standard (por defecto), elevated, outlined, interactive |
| AppPaletteTile | Nombre/descripción, muestras clara/oscura, selección y callback; sin persistencia propia |
| BalanceCard | Saldo/moneda proporcionados; ingresos/retiradas opcionales; pie y motivo decorativo |
| StatisticCard | Etiqueta, valor ya preparado, icono y pie opcional |
| AppAvatar | ImageProvider con fallback a iniciales de nombre y apellidos; small/medium/large/editor; indicador con etiqueta |
| AppBadge | neutral, primary, success, warning, danger, info; icono opcional |
| StatusChip | Pagado, Pendiente, Parcial, Adelantado, Admin, Owner, Member, Activo, Inactivo |
| MoneyText | balance, income, withdrawal; hero/large/medium; moneda y animación opcionales |
| AppDialog | information, confirmation, warning, danger; cancelación/descartar devuelve false |
| AppSnackbar | success, error, warning, info; un mensaje visible a la vez |
| LoadingIndicator | Tamaño/color, etiqueta accesible y alternativa sin movimiento |
| EmptyState | Icono, título, explicación y acción opcional |
| AppTopBar | Título, leading, acciones; sin elevación ni tintes automáticos |
| AppBottomNavigation | Destinos tipados, índice y callback, sin lógica de rutas |
| AppScaffold | SafeArea, margen, fondo con degradado, ancho máximo, scroll, app bar y navegación inferior |
| AppSection | Título, introducción opcional y separación común |
| AppBottomSheet | Título, builder, scroll y ajuste al teclado |
| AppBrand | Marca vectorial con nombre o compacta |

Cada archivo tiene implementación real. Los enums usan `standard` para la
variante por defecto porque `default` es palabra reservada de Dart.

Ampliaciones v0.2: AppHeroPanel, AppCover, AppNavigationTile, AppAdaptiveRow,
AppChoiceBar, AppExpandableRow, AppAvatarMenu y AppActionMenu. Gradientes en
theme/app_gradients.dart; las features no repiten colores ni estilos.
AppAvatarMenu cierra el menú abierto si cambia la identidad para no conservar
datos de la cuenta anterior. Estos controles no conceden permisos de Firebase.
AppCover/AppAvatar admiten imágenes proporcionadas por el llamador, pero las
subidas se aplazan por elección del usuario. Ahora muestran iniciales; no hay
selector de fotos, Storage ni imágenes de demostración asignadas a grupos reales.

### Dinero y fechas

`parseMoneyCents('20,50')` devuelve 2050, también acepta punto decimal. No usa
double. El input bloquea caracteres inválidos y más de dos decimales; vacío
devuelve null. Admite hasta 12 cifras de unidades y dos decimales. Cero se puede
escribir: su validez en una operación pertenece al validador/repository de negocio.

`formatMoneyCents` usa punto de miles y coma decimal. MoneyText añade signo y
semántica; saldo admite negativos. Withdrawal recibe importe positivo. EUR, USD
y GBP tienen símbolo; otros códigos se muestran como texto conservando **dos
decimales**. No convierte divisas ni soporta todavía otras unidades mínimas.
BalanceCard no calcula el saldo. StatisticCard no calcula métricas. StatusChip no
implementa cuotas o permisos. Ninguno de estos componentes persiste datos.

AppDateField devuelve una fecha de calendario local. Conversión a zona de grupo,
UTC y persistencia corresponde a la feature/service. Controllers externos son
propiedad del llamador y deben liberarse en su ciclo de vida.

## Uso

```dart
import 'package:bote_parroquial/design_system/design_system.dart';

AppButton(
  label: 'Guardar',
  leadingIcon: Icons.check_rounded,
  loading: state.isLoading,
  fullWidth: true,
  onPressed: save,
)
```

En features, las acciones de negocio deben venir de providers. Buscar el componente
existente antes de crear otro. No instanciar componentes complejos externos
directamente en pantallas si hay o debe haber un equivalente App*.

## Galería de desarrollo

```sh
flutter run --debug -t lib/main_showcase.dart
```

Identidad, Controles, Feedback y Tokens permiten revisar claro/oscuro, inputs,
fechas/opciones, cards, badges, diálogos, snackbars y paneles. El estado es local.
No inicializa Firebase ni se añade a rutas de producción. El entrypoint rechaza
ejecución fuera de debug. No se añadió soporte web/escritorio al proyecto; los
layouts anchos también se revisan en el entorno de pruebas.

Para volver a la app: `flutter run --debug -t lib/main.dart`. Ambos entrypoints
usan el mismo identificador Android: ejecutar uno sustituye temporalmente el
binario instalado. No hace falta desinstalar para alternarlos.

Desde v0.2 también login compone App*. Personas abre una pantalla completa según
la referencia; no modifica sus validaciones ni añade activación durante el alta.
Las funciones futuras dibujadas en las imágenes no se simulan con botones inertes.

## Librerías evaluadas

Consulta del 2026-10-15 para Flutter 3.44.8 / Dart 3.12.2. Son requisitos declarados,
no prueba de integración de paquetes no instalados. Los candidatos publican
soporte Android/iOS. Las fechas permiten evaluar actividad sin instalar paquetes.

| Candidato | Versión / publicación | Requisitos declarados | Decisión |
| --- | --- | --- | --- |
| [Forui](https://pub.dev/packages/forui) | 0.27.6 / 2026-10-14 | Flutter ≥3.47.0-0; Dart ≥3.13.0-0 | Incompatible con el SDK instalado; referencia visual |
| [shadcn_flutter](https://pub.dev/packages/shadcn_flutter) | 0.0.55 / 2026-10-01 | Flutter ≥3.47.0; Dart ≥3.13.0 | Incompatible con el SDK instalado |
| [shad](https://pub.dev/packages/shad) | 0.99.4 / 2026-08-18 | Flutter ≥3.41.0; Dart ≥3.11.0 | Requisitos compatibles; no hace falta otra capa completa de UI |
| [flutter_animate](https://pub.dev/packages/flutter_animate) | 4.5.2 / 2024-11-25 | Flutter ≥2.0.0; Dart ≥2.17.0 | Compatible por requisitos; el SDK cubre la animación actual. Reevaluar si crecen los efectos |
| [Widgetbook](https://pub.dev/packages/widgetbook) | 3.25.0 / 2026-06-25 | Flutter ≥3.44.0; Dart ≥3.10.0 | Compatible por requisitos; la galería equivalente basta ahora. Candidato de desarrollo cuando crezca el catálogo |

Elección actual: App* propios sobre Flutter/Material y `flutter_localizations` del
SDK para calendario en español. No se añadió una biblioteca visual externa.
Envolver una futura biblioteca detrás de App*. No actualizar Flutter ni fijar
paquetes antiguos solo por esta propuesta.

Referencias: [tokens shadcn/ui](https://ui.shadcn.com/docs/theming),
[Forui](https://forui.dev/docs),
[Manrope](https://github.com/google/fonts/tree/main/ofl/manrope) y
[Newsreader](https://github.com/google/fonts/tree/main/ofl/newsreader).

## Validación inicial de la etapa visual (histórico v0.1)

- Suite completa: 22 pruebas superadas; exportación visual optativa omitida por
  defecto. Las ocho pruebas de auth/base siguen pasando.
- Design System: 14 pruebas, incluyendo dinero, contraste, estados, diálogo,
  calendario y ocho combinaciones claro/oscuro a 360 px con texto al 160 %.
- Contraste ≥4.5:1 comprobado para los tres textos sobre fondo y para los pares
  primary/onPrimary y hero/onHero. No equivale a una auditoría completa de accesibilidad.
- Se exportaron seis vistas de galería; se inspeccionaron identidad clara/oscura,
  controles, feedback y paleta. No son capturas de datos reales ni pruebas nativas iOS.
- `flutter analyze`: sin incidencias. Los APK debug de la galería y de la app normal
  compilan. La galería se conserva en `build/app/outputs/flutter-apk/design-system-debug.apk`
  y la app normal en `build/app/outputs/flutter-apk/app-debug.apk`.

```sh
flutter test --dart-define=EXPORT_DESIGN_PREVIEWS=true test/design_system_preview_test.dart
```

Las vistas se escriben en `.dart_tool/design_system_preview/`, fuera de Git. La
exportación carga las fuentes reales y MaterialIcons. Las pruebas ordinarias no
escriben artefactos ni dependen de un golden de plataforma.

La validación anterior registra la etapa visual inicial. Ver docs/PHASE2_VALIDATION.md
para las pantallas que ya usan esta base. Las pruebas manuales de autenticación
aplazadas siguen pendientes. iOS requiere Mac/Xcode para validación nativa.

Validación actual de v0.2, capturas y límites: docs/VISUAL_REDESIGN_VALIDATION.md.

Continuación Phase 8: RefundEditorScreen compone AppHeroPanel, AppCard,
AppDropdown, AppMoneyField, AppDateField y AppDialog; no añade tokens ni una
segunda paleta. AppReveal respeta movimiento reducido. Parte del ingreso y
separa meses de crédito sin asignar. La corrección empieza con reparto vacío,
con explicación y confirmación expresa. Los importes disponibles derivan de
providers/repositorios. El historial muestra badge Devolución y acceso al origen.
La creación de persona incorpora AppChoiceBar/AppMonthField para primer mes
opcional. Validaciones dirigidas y pendientes: docs/PHASE8_REFUNDS_VALIDATION.md.

Informes de cuotas: QuotaReportSection es específico de reports y compone
AppHeroPanel, AppCard, StatisticCard, AppBadge, AppExpandableRow, AppPairedBars y
PhotoAvatar existente. Dashboard separa acumulado/mes; informes separan caja,
cuotas y previsión. No se añaden tokens ni APIs externas. Los badges conservan
etiquetas de estado y los gráficos incorporan textos accesibles e incompletitud.
Detalle mensual/persona se despliega para limitar la densidad inicial; AppReveal
y barras respetan movimiento reducido. Evidencia de ambos temas, texto 160 % y
360 px: docs/PHASE10_QUOTA_REPORTS_VALIDATION.md. Sin aprobación visual física.
