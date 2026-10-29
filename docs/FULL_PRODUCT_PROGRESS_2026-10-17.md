# Avance del producto completo — 2026-10-17

Continuación solicitada después de la entrega de búsquedas/filtros. Este informe
registra una ampliación funcional; no declara terminada la especificación completa
ni supera comprobaciones físicas del MVP que siguen pendientes.

Actualización posterior del mismo día: el usuario autoriza publicar después del
respaldo. Rules desplegadas y verificadas; el bloqueo inicial queda resuelto.
Códigos, solicitudes y salida/expulsión se añaden en otro bloque, con DEMO aislada:
[PHASE7_INVITATIONS_VALIDATION.md](PHASE7_INVITATIONS_VALIDATION.md). Este archivo
conserva la evidencia y el alcance de la primera entrega; no describe toda la
versión actual ni declara superadas nuevas comprobaciones físicas.

## Implementado

| Bloque | Comportamiento disponible |
| --- | --- |
| Crear grupo | Desde inicio: nombre, descripción, EUR/USD/GBP y una zona disponible. La app conserva el ID al reintentar el mismo formulario. Transacción online crea grupo, owner, evento administrativo y persona opcional |
| Persona del propietario | Se crea por defecto, con opción de omitirla; membresía vinculada a persons/owner dentro del grupo nuevo. No altera personas de otros grupos |
| Editar grupo | Owner o admin vinculado a persona activa puede cambiar nombre/descripción. Comprueba versión; moneda y zona no se editan |
| Historial administrativo | Creación y cambios de identidad con antes/después, actor y hora de servidor, inmutables y atómicos. Solo gestión autorizada; últimos 100 eventos en pantalla |
| Informes | Mes, trimestre y año por fecha efectiva. Saldo inicial, ingresos, retiradas y saldo final; gráficas mensuales y desglose por persona |
| Ficha individual | Persona activa/inactiva, notas, ingresos/retiradas/neto históricos e historial de todos sus movimientos con acceso a originales/sustitutos |
| Nombre de cuenta | Menú de cuenta → Mi perfil. Edición propia con validación y control de versión; futuros accesos conservan el nombre de aplicación |
| CSV | Desde Informes, gestión autorizada genera el CSV del periodo y abre el menú nativo de compartir. Todos los estados, céntimos enteros, autores, fechas, motivos y enlaces de corrección |

Las operaciones de dinero existentes y su diario de recuperación conservan su
contrato. No se borran datos ni se crean ejemplos en producción durante esta entrega.
No se instalan APK ni se ejecuta la app en el móvil desconectado.

## Reglas y datos

- Escrituras de bootstrap limitadas a un grupo nuevo, owner propio y persona
  inicial acordada. No se permite autopromoción ni cambios de roles en uno existente.
- Auditoría de identidad obligatoria en el mismo commit, sin actualización/borrado
  de eventos ni posibilidad de inventar un antes/después. No es auditoría general.
- Los grupos previos siguen leyendo su contrato. La primera edición añade
  updatedBy/lastAuditEventId. No hay migración masiva ni cambio de moneda.
- El nombre propio no se replica a nombres de miembros o personas existentes.
- CSV consulta movimientos en servidor y verifica UID/permisos antes de prepararlo.
  Se escapa texto y se neutralizan fórmulas; importes y efecto de saldo van en
  céntimos. Anulados/corregidos tienen efecto cero, aunque conservan importe original.
- La restricción de exportar desde la app no impide que un miembro autorizado a
  leer copie datos. Compartir genera una copia fuera de la app en el destino que
  elija el usuario; no se puede revocar esa copia desde Firestore.
- Temporales propios por cuenta: hasta diez envíos recientes y limpieza por edad
  al compartir; purga propia al cambiar de cuenta. La caché interna del SDK de
  compartición tiene su propio ciclo. No se borran fotos ni diarios financieros.

Contrato persistido: [FIREBASE_SCHEMA.md](../FIREBASE_SCHEMA.md).

## Qué significan los informes

Los periodos se interpretan como días civiles efectivos. Solo active contribuye
a cifras y saldo. Se usan los estados actuales del historial: una corrección o
anulación posterior puede cambiar un informe antiguo. No hay cierres contables
congelados. La ficha conserva originales corregidos y anulados para inspección.
El calendario inicial del informe usa la zona IANA del grupo.

Se mantienen los flujos completos del MVP. No se han añadido paginación ni
agregados; esa optimización sigue pendiente para historiales grandes. El CSV
incluye todos los estados del periodo, no solo los que suman al saldo.

## Validación realizada

- Formato Dart correcto; análisis estático final sin incidencias y diff sin errores
  de espacios. No hay pruebas físicas nuevas.
- Cuatro casos Flutter dirigidos: cálculos y límites de periodos/estados, grupo y
  cuenta correctos antes de escribir, CSV/escapado/céntimos/permisos y flujo visual
  integrado de crear/editar grupo, auditoría, informe anual, ficha y nombre propio.
- Flujo visual a 360 px con texto al 160 % y movimiento reducido, sin excepciones.
  Usa servicios simulados; no demuestra acceso real de otra cuenta ni compartir nativo.
- Siete casos de Rules en emulador: tres de nueva gestión de grupos/auditoría y
  cuatro regresiones financieras. Incluyen bootstrap incompleto rechazado,
  propietario ajeno, eventos falsos, moneda, inmutabilidad y grupos anteriores.
- Cinco casos de Rules de perfil: privacidad, campos/fechas y edición conservando
  el último acceso. Se adapta el caso de grupo ajeno al nuevo bootstrap legítimo.
- Se repiten únicamente los casos fallidos al corregir datos simulados, selección
  de controles y comprobación de bytes; no se ejecuta la suite completa.
- `flutter build apk --debug --no-pub -t lib/main.dart`: correcto. APK generado
  en build/app/outputs/flutter-apk/app-debug.apk, con el nuevo plugin nativo.
  Advertencia de compatibilidad futura de Kotlin en plugins Firebase; no impide
  esta compilación. No se actualizan Firebase/Gradle por esa advertencia.
- Publicación inicialmente bloqueada por revisión automática al faltar permiso
  explícito de cambio de acceso real. Resuelto después de la copia externa y la
  autorización del usuario; Rules publicadas y fuente remota verificada.

Crear/editar grupos y editar nombre ya tienen Rules publicadas. Los informes,
fichas y CSV reutilizan lecturas autorizadas. El comando utilizado es:

```powershell
firebase.cmd deploy --only firestore:rules --project boteparroquial --non-interactive
```

Solo publica reglas: no borra ni migra documentos. El diff revisable está en
firestore.rules; permite bootstrap propio de grupo nuevo y cambios auditados de
identidad, sin abrir gestión general de roles. Rulesets, horas y hashes de esta
publicación y del siguiente bloque figuran en PHASE7_INVITATIONS_VALIDATION.md.

La dependencia nueva es share_plus 13.3.1, comprobada contra Flutter 3.44.8,
Dart 3.12.2, AGP 9.0.1, Gradle 9.1 y Kotlin 2.3.20 del repositorio. SDK encapsulado
en NativeFileSharingService; no se expone a pantallas ni modelos.
Referencia de API/requisitos: [share_plus](https://pub.dev/packages/share_plus).

## Pendiente del producto completo

1. Completar Phase 7: enlaces, gestión general de roles y transferencia de
   propiedad. La vinculación única se incorpora el 2026-10-18, en
   [PHASE7_LINKS_VALIDATION.md](PHASE7_LINKS_VALIDATION.md). Los códigos, aprobación y
   salida/expulsión se incorporaron en la entrega posterior enlazada arriba.
   La readmisión con aprobación obligatoria se añade tras responder el usuario:
   [PHASE7_READMISSION_VALIDATION.md](PHASE7_READMISSION_VALIDATION.md).
   No se utiliza un dominio de invitaciones inventado ni se abre seguridad por UI.
2. Phase 8: cuota inicial y cambios temporales, periodos de participación,
   allocations, deuda, adelantos y crédito. El usuario decide que las devoluciones
   permitan escoger asignaciones revertidas; retiradas generales no las alteran.
   Esa política queda registrada, todavía sin implementación financiera.
3. Phase 9: notificaciones y preferencias, sin botones que simulen estar disponibles.
4. Informes de cumplimiento/cuotas y comparaciones entre periodos; agregados y
   consultas acotadas para escalabilidad.
5. Auditoría de todas las entidades, recuperación/papelera y operaciones definitivas.
6. PDF/Excel y exportaciones grandes. CSV es la primera entrega de Phase 12.
7. Validaciones físicas pendientes del MVP, otros roles reales, compartir un CSV
   en Android y validación iOS con Mac/Xcode. No se retoma la segunda cuenta aplazada.

## Revisión posterior en el móvil

Crear un grupo de prueba, comprobar la persona inicial elegida, editar su identidad
y abrir su historial administrativo. Abrir Informes, cambiar periodo y consultar
una ficha. Desde gestión autorizada exportar el CSV y elegir un destino en el menú
del sistema. En el menú de cuenta comprobar Mi perfil. Son pasos propuestos para
cuando el usuario ejecute la app; no se registran como pruebas físicas superadas.
