# Sonido y cabeceras de grupo — D157–D158

## Cambios

- D157 sustituye la captura global de D152: AppSoundSurface solo aloja el scope.
  Sin sonido al tocar zonas libres, información, scroll o controles deshabilitados;
  conservan su feedback visual sin ejecutar acciones. Validación rechazada de una
  acción disponible conserva aviso; éxitos económicos solo tras confirmación.
- Predeterminado 75 % en preferencias/modelo/estado inicial. Conservar niveles
  guardados, cero y apagado; no resetear una elección explícita. No quitar modo
  silencio nativo, segundo plano ni control 0–100.
- Antes: tap.wav de aproximadamente 10 ms y, por ejemplo, pico de typing 0,1745
  y photo 0,2440. Ahora cuatro clics propios de 85 ms, variaciones pequeñas de
  timbre y selección aleatoria sin repetir inmediatamente. Pools acotados por
  variante; superposición permitida. Sonido distinto de 180 ms descendente para
  botones Volver/flechas de regreso; no duplica el clic genérico.
- WAV normalizados a pico 0,92 (-0,72 dBFS), sin clipping de muestras. El generador
  local tools/prepare_ui_sounds.cjs documenta síntesis y normalización; no descarga
  nada al ejecutar la app. Licencias/fuentes en assets/sounds/SOURCES.md.
- D158: GroupAccessBody ya no muestra identidad extendida por defecto; Dashboard
  la pide explícitamente. Solo Inicio conserva portada, descripción, rol y moneda.
- Actividad, Participantes, Personas, Miembros e Informes usan GroupSectionTopBar
  con nombre/miniatura a la derecha mediante AppCompactIdentity compartido. Nombre
  limitado con elipsis, sin datos o SDKs en el componente visual. Foto privada por
  PhotoView y providers actuales; no mostrar identidad sin membresía activa.
- Participantes muestra Invitar al grupo directamente, sin pasar por Miembros.
  Acceso oculto en copia aislada solo lectura. No se cambian permisos de invitación.

## Evidencia

Seis comprobaciones dirigidas superadas en sound_surface_and_preferences_test.dart
y ui_sounds_test.dart: acciones/espacios libres/deshabilitado/volver, preferencias
conservadas, variantes sin repetición, cabecera con nombre largo/texto ampliado,
estado de audio y emisiones semánticas de controles. flutter analyze sin incidencias.

Release 1.0.1+2 compilado (159,8 s), misma clave propia D156, verificada con
apksigner; aapt confirma versionCode 2/versionName 1.0.1. Ruta:
`C:\Users\aleja\Documents\GitHub\BoteParroquial\build\app\outputs\flutter-apk\app-release.apk`.
75.704.221 bytes; SHA-256 del APK:
`dffe499ef1c6b225e5577d59acb200b21e57c7f7fe31e9b2420b7c2299bc8631`.
Usuario instala/ejecuta;
no afirmar volumen acústico o aprobación de timbre en móvil por medir muestras.
No despliegues, Rules, IAM, datos remotos ni claves nuevas. No introducir esperas
de audio o generación de WAV en la UI ni modificar las transiciones D131.

## Comprobación en móvil pendiente

1. Instalar release como actualización con la firma D156. Si sigue instalada la
   versión profile/debug, primero resolver el cambio de firma como indica la guía.
2. Ajustes de apariencia → Sonidos: probar 75, 100 y 0. Si ya había nivel guardado
   se conserva. Comprobar silencio/vibración y apagado explícito.
3. Tocar tarjetas/botones/menús varias veces: pequeñas diferencias de clic. Tocar
   huecos/texto informativo/deshabilitado y deslizar: no deben generar un clic.
4. Botón Volver: tono descendente claramente distinto. Escribir, añadir foto y
   guardar conservan sus sonidos específicos; cancelaciones no confirman guardado.
5. Inicio del grupo conserva descripción/rol/moneda. Resto de pestañas y Personas/
   Miembros: cabecera compacta arriba derecha, sin bloque de identidad repetido.
6. Participantes → Invitar al grupo abre Invitaciones. En copia local no ofrece
   invitar; cambiar cuenta o perder acceso retira la identidad.
