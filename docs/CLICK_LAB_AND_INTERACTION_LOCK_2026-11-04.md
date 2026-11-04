# Laboratorio temporal de clics y bloqueo de interacción — D164–D165

## Laboratorio

El usuario elige visible solo en debug/profile. Inicio → Laboratorio de clics,
ruta autenticada /testing/clicks. Ruta/acceso ausentes en release y pantalla con
guard adicional kReleaseMode. No reactivar el laboratorio de animaciones oculto.

104 muestras con códigos C001–C104:

- C001–C096: doce familias de ocho variantes: Suave, Ratón, Tecla, Madera, Grave,
  Pop, Burbuja, Digital, Cristal, Interruptor, Retro y Papel.
- C097–C100: clic normal actual; C101–C104: menú actual, para comparar.
- Filtrar familia, ajustar nivel de prueba, favoritas y filtro Solo favoritas.
  Última muestra y códigos visibles. Favoritas efímeras mientras el laboratorio
  permanezca abierto; anotar los códigos elegidos para indicárselos al agente.
- Escuchar no aplica ninguna selección al producto. El botón de muestra no emite
  además su clic normal, para no contaminar la comparación. Audición inmediata,
  sin los 320 ms de feedback de los botones normales.
- UI → ClickLabController → UiSoundRepository → ClickSoundPreviewService en
  DeviceUiSoundService. Una instancia AudioPlayer de previsualización, sustitución
  de la muestra anterior y cancelación por generación; no crear 104 pools.
- Respeta apagado, volumen general cero, silencio nativo y segundo plano. Volumen
  de audición y favoritas no cambian preferencias guardadas. Activar sonidos es
  un botón explícito si estaban apagados. No hay SDK ni datos Firebase en el catálogo.
- Assets originales generados localmente con tools/prepare_click_lab.cjs, sin
  descargas externas ni procesamiento en ejecución. Fuentes/licencias en assets/sounds.

## Bloqueo durante animaciones

AppInteractionHost aloja un gate efímero compartido fuera de MaterialApp; bloquea
punteros y acciones semánticas mientras existan leases de animación. AppControlFeedback
consulta el estado sincronamente antes de sonar/ejecutar y adquiere un lease para
su feedback. Rechazo visual también queda cubierto. No se encolan toques rechazados.

AppGroupEntry lo mantiene durante su onda; AppPageTransitions durante avance y
retroceso de páginas, también formularios y transiciones nativas Apple. Traspaso
sin hueco de un fotograma: el callback inicia la siguiente acción mientras el
lease anterior se libera al terminar ese frame. No hay espera de duración fija.

Se libera al completar, cancelar, deshabilitar o desmontar. No espera cargas de
Firebase/audio, ni congela providers, permisos o comprobaciones de acceso.
Movimiento reducido evita animaciones/esperas temporizadas. No modifica D131 ni
añade nuevas capturas de pantallas. Dispatcher/guard de ruta rechazan otro Atrás
durante el bloqueo, sin romper un gesto que ya estaba en progreso. AppFormGuard
no abre una segunda confirmación por un pop rechazado por el gate; mantiene su
protección normal de cambios sin guardar.

## APK y firma

Profile 1.0.4+5 compilado (96,6 s). Profile usa ahora la firma privada D156 cuando
está configurada; debug conserva su configuración anterior. Este profile puede
actualizar la release oficial existente sin desinstalar ni perder datos locales.
No recrear/exportar la clave. No llamar a este APK release/definitivo.

Ruta: `build/app/outputs/flutter-apk/app-profile.apk`.
Firma verificada con apksigner: certificado D156 coincidente. aapt confirma
versionName 1.0.4/versionCode 5. 106.279.687 bytes, SHA-256 del APK:
`74e9fc29e917a16c70e5433d69ccd9a0803df0430f56fadf18dca16ac78e7df9`.
La release anterior app-release.apk no se ha recompilado en esta tarea y no
incluye el laboratorio. Una release futura conservará el bloqueo y ocultará la
entrada/ruta del laboratorio según kReleaseMode.

## Evidencia

Cuatro casos dirigidos distintos en interaction_gate_test.dart y
click_sound_lab_test.dart: grupo → onda → transición impide pulsar Apariencia;
dos controles no compiten y desmontar libera; 104 IDs/assets y límites de audición;
pantalla reproduce solo muestra/favoritas sin aplicar preferencias. Se corrigió
la base de tiempo de la primera prueba (primer tick de la animación), después
pasaron los dos casos de gate. flutter analyze final: sin incidencias.

Sin cambios Rules, índices, despliegues, datos remotos o claves. Usuario instala y
ejecuta; pruebas físicas de timbres, fluidez y pulsaciones simultáneas pendientes.

## Probar y retirar

1. Instalar app-profile.apk como actualización. Inicio muestra Laboratorio de clics.
2. Escuchar familias, marcar favoritas y usar su filtro. Indicar los códigos Cxxx
   elegidos; no se aplica nada automáticamente.
3. Tocar un grupo e intentar abrir Apariencia/cuenta, Añadir u otro grupo durante
   la onda/entrada. Solo debe completarse la entrada elegida; al terminar se
   puede interactuar de nuevo. Probar regresar y movimiento reducido.
4. Para retirar cuando el usuario lo indique: quitar ruta/acceso/modelo/feature y
   archivos lab_c*.wav/generador de catálogo; conservar el gate compartido y la
   firma de profile si sigue siendo útil. No borrar fuentes actuales elegidas.
