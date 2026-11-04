# Efectos de interfaz

D166 (04/11/2026): usuario elige Retro 6/7/8 del laboratorio, C086/C087/C088.
Copiados sin alterar sus bytes a press_1/press_2/press_3.wav, 110 ms, pico 0,85.
Alternancia aleatoria entre tres sin repetir inmediatamente; menú conserva cuatro
click_*.wav. tools/prepare_ui_sounds.cjs reproduce ahora los tres Retro elegidos.
Eliminados catálogo, audición temporal, generador y 96 WAV lab_c*. Los apartados
inferiores son históricos; la familia press mecánica de D161 ya no se reproduce.

D164 (04/11/2026): lab_c001–lab_c096.wav son síntesis original reproducible en
tools/prepare_click_lab.cjs. Doce familias x ocho variaciones, PCM16 mono 44.100 Hz,
pico 0,85 sin clipping, duraciones 60/85/110/135 ms. Solo se audicionan en el
laboratorio debug/profile, junto a ocho muestras actuales (104 códigos en total).
No sustituyen sonidos del producto al escucharlos ni requieren descargas/servicio.

D161, 04/11/2026: los menús pasan a click_1–4.wav (clic normal anterior, 105 ms).
Los botones normales usan nuevos press_1–4.wav: clic mecánico suave de ruido
filtrado, sin nota sostenida, 65 ms. Cuatro variantes por familia, aleatorias sin
repetición inmediata. Generación local en tools/prepare_ui_sounds.cjs; ningún
audio externo nuevo. tap_1–4 quedan históricos sin uso, igual que tap.wav.

Actualización D159, 04/11/2026: tap_1–4.wav se conservan para desplegables
(evento menu); click_1–4.wav son nuevos clics normales propios, más cálidos, de
105 ms, generados por el mismo script. Selección aleatoria independiente por
familia, sin repetición inmediata. Volumen/silencio/back siguen como D157.

Actualización D157, 04/11/2026: tap_1–4.wav y back.wav son síntesis PCM propia,
generada con tools/prepare_ui_sounds.cjs (sin fuentes descargadas). Cuatro clics
de 85 ms con pequeñas diferencias de timbre; vuelta descendente de 180 ms.
Pico normalizado a 0,92 (-0,72 dBFS) sin clipping. Los demás WAV de Kenney se
normalizan al mismo techo; escritura mantiene factor relativo 0,45. tap.wav
original se conserva como histórico, pero ya no se reproduce.
Predeterminado 75 %, conservando volúmenes/apagado elegidos previamente. Esta
actualización sustituye el nivel inicial 18 % y la duración de clic inferiores.
Solo acciones disponibles emiten sonido; ni zonas libres, ni scroll, ni controles
deshabilitados. Sin repetición inmediata entre variantes y sin quitar silencio.

Autor: Kenney. Paquete Interface Sounds 1.0, licencia CC0.
Página original: https://kenney.nl/assets/interface-sounds
Licencia incluida: KENNEY-LICENSE.txt.

La descarga oficial directa devolvió HTML/403; los originales se obtuvieron de
la copia pública https://github.com/GeorgeQLe/assets-sfx-ui, carpeta
assets/kenney/interface-sounds/Audio. No se ejecutó contenido del paquete.

| Archivo local | Original | Duración aproximada |
| --- | --- | --- |
| tap.wav | click_003.ogg | 10 ms |
| typing.wav | click_001.ogg | 100 ms |
| success.wav | confirmation_001.ogg | 290 ms |
| photo.wav | open_001.ogg | 148 ms |
| warning.wav | error_004.ogg | 103 ms |

Convertidos a WAV mono PCM16 para compatibilidad Android/iOS, con suavizado
simple de agudos y entrada/salida de 6/20 ms. Volumen local ajustable entre 0 y
100 %, inicialmente 18 % del sistema; escritura al 45 % del nivel elegido.
No se descargan sonidos en tiempo de ejecución. D152 retira filtros de ráfagas
y de efectos ocupados; se admite superposición de pulsaciones rápidas.
El usuario valora el resultado auditivo en móvil; no se considera aprobado.
