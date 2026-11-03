# Biblioteca visual: carga, menús y personalización — 02/11/2026

## Entregado (D120–D124)

### Carga con formas y brillo

`AppShimmer`, `AppSkeleton` y `AppSkeletonBlock` viven en design_system. Banda
diagonal que recorre de izquierda a derecha la forma del contenido; semántica de
carga, sin cifras o personas inventadas. Respeta movimiento reducido y TickerMode;
cancela el ticker al desmontarse. Duración y geometría compartidas en tokens.

Grupos/lista de grupos, resumen, personas/miembros e historial usan composiciones
de contenido específicas de esa biblioteca. Portadas y avatares muestran brillo
en su propia forma cuando aún no hay imagen. Una imagen ya disponible permanece
visible durante su revalidación. Los demás LoadingIndicator heredan un esqueleto
genérico de contenido; dentro de botones tienen formato compacto. La restauración
de sesión también usa esta base. No quedan CircularProgressIndicator en lib.
Las barras determinadas de gráficos no se cambian: representan datos, no espera.

No hay nueva dependencia. Se consultó la receta oficial de
[shimmer de Flutter](https://docs.flutter.dev/cookbook/effects/shimmer-loading).
Los estados de error/vacío y los permisos siguen dependiendo de sus providers;
un esqueleto no acredita conexión, saldo ni confirmación de una operación.

### Acciones de Inicio

Usuario elige botón flotante **Añadir** con **Crear un nuevo grupo** y **Entrar
con código**; **Copias guardadas** pasa al menú de cuenta superior. No quedan
esos enlaces al final de la lista ni un botón Crear unido al título desplazable.
AppScaffold recibe floatingAction y reserva espacio inferior en el contenido
para evitar que tape el último grupo. AppFloatingActions presenta las acciones
sin lógica de navegación propia: Home sigue aportando sus callbacks al router.
En el visor de copias no se habilitan acciones de escritura.

### Menús compartidos

AppAvatarMenu presenta una tarjeta de identidad con avatar/nombre/correo,
acciones con iconos, separadores y salida diferenciada. Se conserva el cierre
si cambia la identidad con el menú abierto. AppMenuRow sirve también a menús
contextuales y selectores; estos muestran marca de selección, icono y superficies
del tema. La selección compacta del campo no duplica el contenido visual del menú.
PopupMenuTheme centraliza superficie, borde, forma y tipografía; se mantienen los
controles nativos de foco, teclado, cancelación y animación, con presentación propia.
No se reparten estilos de menú por features.

### Letras

**Ajustes de apariencia → Tipo de letra**: Manrope, Newsreader y Sistema.
Ambas fuentes nombradas estaban ya empaquetadas; no se descarga ninguna. La
fuente se propaga por AppTheme y AppTypography a textos, titulares, dinero,
controles y menús. No cambia el valor ni formato financiero. SnapshotBrowser
continúa recibiendo el ThemeData desde fuera de su contenedor aislado.

### Paletas propias y vista previa

Usuario elige tres colores y contraste automático, y pide un widget de ejemplo
antes de crear/guardar. **Ajustes de apariencia → Crear mi propia paleta** permite
nombre, principal, complementario y tercer acento. AppColorField abre selector
de tono/intensidad/luminosidad o código hexadecimal. AppThemePreview compone
panel, texto, etiquetas y botones reales App*, sin operaciones; claro/oscuro se
pueden alternar antes de guardar. No se crea otra colección de estilos para la demo.

Guardar aplica y conserva la paleta. Permite tener varias, elegirlas, editar y
eliminar con confirmación. Editar conserva ID; eliminar la activa vuelve a la
predefinida anterior y conserva modo/fuente. Los colores RGB elegidos se conservan;
el tema deriva tonos legibles para superficies, contenedores, botones y etiquetas.
El ajuste comprueba contraste de texto normal y acentos, incluyendo fondo alpha
de etiquetas. Semánticas de error/aviso/éxito permanecen independientes.

AppearanceSettings/CustomPalette son Dart puro. UI → AppearanceController →
AppearanceRepository → FileAppearanceService; archivo application support
`appearance.json`, versión 2. Lee preferencias anteriores sin fuente/paletas
propias; fuentes desconocidas usan Manrope y paletas locales inválidas se ignoran.
Elección por instalación, independiente de UID, sin sincronización entre teléfonos.
Archivo temporal/rename y serialización ya existentes; guardado fallido permite
reintentar. No se guardan borradores de color al cerrar sin confirmar. La paleta
se aplica optimistamente al guardar, con error visible si falla la persistencia.

## Evidencia

Once pruebas dirigidas distintas superadas, sin ejecutar la suite completa:

- Cinco en visual_library_test: brillo y movimiento reducido; contraste extremo
  y fuentes; menús/cambio de cuenta; paleta con selector/preview/guardar/editar/
  borrar; Inicio con catorce grupos y botón que no se desplaza.
- Cuatro en appearance_test: paletas predefinidas, archivo local real con paleta
  propia/fuente, carga tardía/reintento, pantalla con texto ampliado.
- Solo «Remount» de photos_test: imagen disponible conservada al revalidar.
- Solo «Botón en carga» de design_system_test: deshabilitado mientras se envía.

Se corrigió el tamaño del fixture de carga para probar un móvil, y se endureció
el contraste de etiquetas tras detectarlo en revisión/prueba. Las repeticiones
se limitaron a los casos afectados. El filtro inicial --plain-name no admite
alternativas; se corrigió a --name, sin atribuir pruebas a una ejecución vacía.

`flutter analyze --no-pub`: sin incidencias.
`flutter build apk --debug --no-pub`: compilación correcta.

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
SHA-256: `76ebe3d29612d72804b3e3b6c52f6cf4134d0492156d9e88225bbc5d0f8692a0`.

Registros de comprobación en `.dart_tool/visual-library-*.log`, sin incorporación
a Git. Rules locales siguen con SHA-256
`35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1`;
no se ha consultado ni publicado una versión remota durante esta tarea.

Cuatro capturas simuladas revisadas en `.dart_tool/visual_library_preview/`:
loading-shimmer, account-menu, custom-preview-light, custom-preview-dark. Sombras
de Material y cinta debug dependen del entorno de test; no acreditan dispositivo.
La comprobación de Inicio usa catorce grupos ficticios en memoria, sin Firestore.

## Límites y pruebas del usuario

No se ha instalado ni ejecutado el APK en móviles. Carga real, fluidez, navegación,
teclado/lector de pantalla y estética elegida requieren revisión física; iOS/Mac
sigue pendiente. Pasos **VIS-01–VIS-05**, sección 18 de GUIA_PRUEBAS_MOVILES.md.
No se modificaron datos remotos, Rules, índices, funciones, cron, IAM, permisos
del producto ni facturación. La copia semanal del portátil sigue aplazada.
