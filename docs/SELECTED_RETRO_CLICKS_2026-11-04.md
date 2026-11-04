# Retro 6/7/8 aplicados y laboratorio retirado — D166

El usuario elige los tres sonidos para clics normales y pide retirar el laboratorio.

| Elección | Código anterior | Archivo actual | SHA-256 |
| --- | --- | --- | --- |
| Retro 6 | C086 | press_1.wav | 77bc83f7f647ddd18ca2e39484573f5489534db53c163593488155a270735857 |
| Retro 7 | C087 | press_2.wav | 31d1c90833d85ec881e3fe498726bc713dab6e8759cb71138dca2bc656117ca2 |
| Retro 8 | C088 | press_3.wav | efcb0d6f5b22314e72a58f942da9764c35e18d108708caab396cb2b56c4ea98d |

Copias exactas verificadas antes de eliminar los originales de audición. Sonidos
de 110 ms, pico 0,85. El generador existente prepare_ui_sounds.cjs se adapta a los
tres elegidos y produce esos mismos hashes. No hay síntesis en tiempo de ejecución.

UiClickVariants admite tres variantes press y cuatro de menú. Elección aleatoria
uniforme entre las distintas de la anterior. No se utilizan los antiguos press
mecánicos para el clic normal. Menús, back, escritura, foto, éxito y aviso se
conservan. Respeta volumen elegido, cero, apagado, silencio y segundo plano.

Retirados acceso/ruta /testing/clicks, pantalla, provider, modelo de catálogo,
capacidad/reproductor de audición, test exclusivo del laboratorio, generador de
catálogo y sus 96 WAV. No quedan controles de laboratorio de clics en debug,
profile o release. El laboratorio de animaciones sigue oculto, como estaba.

Conservado AppInteractionHost/gate y el bloqueo de animaciones D165: retirar el
laboratorio no revierte esa corrección. No cambios de negocio, datos remotos,
Rules, índices, secretos, dependencias o nueva firma.

## Validación

Una comprobación dirigida: tres sonidos exactos por hash y selector aleatorio
sin repetición inmediata; menú mantiene sus cuatro variantes. flutter analyze
sin incidencias. Búsqueda en código confirma retirada de API/ruta de laboratorio;
no quedan WAV lab_c*. No se repiten suites de dominio por esta selección visual.

Release 1.0.5+6 compilado (143,5 s), misma firma D156 verificada con apksigner;
aapt confirma versionName 1.0.5/versionCode 6. 75.860.545 bytes; SHA-256:
`e6dca9db8e36125d07ff503b1b4d5ae57d151ed64c2daf75da5f7548e6443e96`.
Ruta: `build/app/outputs/flutter-apk/app-release.apk`. Usuario instala/ejecuta.
No se acredita por estas pruebas audio nativo ni fluidez física general.

## Probar

Actualizar la APK release sobre la profile 1.0.4 o release previa: misma firma y
versionCode superior. Pulsar varios controles normales para escuchar los tres
Retro alternados. Comparar menú/Volver, volumen y silencio. Inicio ya no muestra
Laboratorio de clics. La onda/transición de grupo conserva el bloqueo de pulsaciones.
