# Copias diarias de consulta en el móvil — preparación 23/10/2026

Petición: al abrir la app con conexión, guardar una copia diaria completa de los
datos consultables; sin conexión mantener la caché normal y ofrecer abrir una copia
anterior usando las pantallas de la app. **Implementado posteriormente en esta
misma entrega.** Evidencia y estado vigente:
[DAILY_OFFLINE_COPIES_VALIDATION.md](DAILY_OFFLINE_COPIES_VALIDATION.md).
No sustituye ni reactiva la tarea semanal del portátil aplazada en D105.

## Decisiones resueltas

El usuario ha respondido conjuntamente (D110–D112):

1. Últimas siete copias diarias.
2. Datos Firestore completos del ámbito propio, fotos según caché.
3. Wi-Fi y datos móviles.

El resto de este archivo conserva la preparación inicial. No lo interpretar como
un pendiente de respuesta ni como evidencia de pruebas físicas.

## Contrato solicitado y límites

- Cada copia pertenece a una cuenta y a este móvil. Solo información que esa
  cuenta puede consultar de sus grupos; nunca acceso privilegiado ni descarga
  global de Firebase con datos de otras cuentas, secretos o tokens de dispositivos.
- Capturar aunque no se hayan abierto Personas/Movimientos/Informes. Una caché
  parcialmente poblada no acredita una copia completa.
- Guardar fecha/hora de confirmación, grupo, identidad, permisos capturados,
  versión de formato y cobertura. No llamar «ayer» a una copia de otra fecha:
  ofrecer la última disponible, identificando su fecha real.
- No reemplazar la última copia válida por una descarga incompleta, fallida o de
  otra sesión. Escribir/cerrar/verificar antes de publicarla en el catálogo local.
- Consulta histórica separada de la caché normal y de los listeners del servidor.
  No importar documentos en la caché Firestore ni mezclar fuentes de diferentes
  instantes para calcular saldos y cuotas. Céntimos enteros exactos.
- Las pantallas de consulta deben reutilizar providers/repositorios y cálculos
  existentes. La selección de origen no introduce cálculos de dominio en widgets.
- Modo de copia visible y de solo lectura, sin envíos, cambios, invitaciones,
  borrados, marcado de avisos o recuperación automática de movimientos pendientes.
  No basta ocultar botones: los adaptadores de este modo deben rechazar escrituras.
- Conservar navegación y consulta aunque las lecturas de servidor no estén
  disponibles. Requiere sesión local de la misma cuenta; no iniciar Google offline.
- Una copia antigua no es necesariamente más reciente que la caché. Mostrar ambas
  fechas cuando se conozcan, y permitir volver expresamente al modo normal.
- Una revocación remota no puede detectarse sin conexión. Al recuperar conexión,
  comprobar permisos actuales antes de continuar y retirar copias de grupos/roles
  que ya no correspondan. No presentar los permisos históricos como permiso actual.
- Las copias completas consumen lecturas y almacenamiento. No afirmar que tienen
  coste cero, que se ejecutan con la app cerrada o que se generan en días sin abrirla
  con una conexión permitida. No programar un worker ni activar facturación.

## Puntos de integración inspeccionados

- `BoteParroquialApp`, restauración de Auth y reanudación de la app: disparador
  en primer plano con exclusión de descargas simultáneas y aislamiento por UID.
- `GroupSyncNotice` y Home: acceso a catálogo/copia disponible sin depender de
  que cargue un grupo remoto; aviso persistente al consultar una copia.
- Lecturas de grupos/personas/movimientos/cuotas/informes/auditoría/notificaciones:
  adaptadores de solo lectura sobre el conjunto guardado, conservando el cálculo
  puro y el groupId explícito. Ruta de edición siempre bloqueada en ese ámbito.
- Cuotas y calendario: el instante de copia debe gobernar los resúmenes históricos;
  no recalcular deudas con la fecha actual y presentarlas como estado de aquel día.
- Fotos: comprobar la respuesta antes de elegir almacenamiento y resolver imágenes
  en modo copia sin enviar peticiones de edición o copiar fotos entre ámbitos.

## Validación prevista, acotada

Cinco pruebas dirigidas de publicación atómica/retención/aislamiento, permisos,
lector coherente y recorrido de providers/pantallas con datos conocidos para
comparar caja/cuotas. Análisis y APK pertinentes.
Pruebas físicas las ejecuta el usuario; añadir pasos concretos a su guía al terminar.
