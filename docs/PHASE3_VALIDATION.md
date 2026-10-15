# Phase 3 — Personas

2026-10-15: implementación terminada; validación dirigida, pendiente de cierre
con datos reales y varios móviles. El usuario pide reducir pruebas a las necesarias.

Actualización al iniciar Phase 4: el usuario confirma «funciona». No concreta las
operaciones probadas ni confirma un segundo móvil; no se amplía esa evidencia.
Autoriza sembrar casos ficticios en Firestore durante el prototipo.

Implementado:

- Listado compartido en tiempo real dentro de cada grupo; estados de carga/error/vacío.
- Nombre y notas opcionales; alta y edición en panel inferior elegido por el usuario.
- Activar/inactivar con confirmación, conservando ID, datos y metadatos históricos.
- Sin API ni permiso de borrado, tampoco para owner.
- Arquitectura UI → Provider → Repository → Service → Firebase; modelo Person
  independiente de Firebase. Validación y normalización fuera de widgets.
- Todos los miembros activos pueden leer; owner puede gestionar. Admin necesita
  vinculación a persona activa del mismo grupo para gestionar, tanto en UI como Rules.
- Reglas validan campos, longitudes, autores, estado y hora de servidor.
- Edición/cambio de estado comprueba updatedAt en transacción: un cambio concurrente
  exige cerrar y reabrir el panel para no sobrescribirlo silenciosamente.
- Reutiliza App* y AppReveal; respeta temas y movimiento reducido. No añade dependencias.

Comprobado, sin repetir la suite completa:

| Comprobación | Resultado |
| --- | --- |
| Formato y `flutter analyze --no-pub` | Sin incidencias |
| `flutter test --no-pub test/persons_test.dart` | Una prueba del flujo completo superada |
| Reglas: `persons_rules.test.cjs` en emulador | Tres pruebas superadas |
| `flutter build apk --debug --no-pub` | APK generado |
| Android A059P | APK instalado y actividad iniciada mediante ADB |
| Despliegue Firestore | Reglas publicadas en proyecto boteparroquial, base (default) |

La prueba Flutter cubre nombre vacío, normalización, crear, editar, inactivar,
reactivar con el mismo ID, alcance del grupo y retirada de controles al pasar a
member. Las tres pruebas de Rules cubren CRUD permitido para owner/admin válido,
lectura sin escritura para member, cuentas ajenas/inactivas/anónimas, separación
de grupos, validación de autor/fechas/campos y prohibición de borrado y de dinero.

Ruleset publicado: `462d2c3d-0f34-41b0-8ec2-cd607e26d0c9`.
El árbol accesible de BoteParroquial en A059P confirma el botón «Añadir persona»,
el listado vacío «Todavía no hay personas en este bote» y la membresía propietaria.
Esta lectura no equivale a validar escrituras reales ni sincronización entre móviles.
No hay cambios manuales pendientes en Firebase Console ni índices nuevos.
Se actualizan los fixtures de grupos y su prueba de reglas para reflejar el acceso
a Personas; no se han vuelto a ejecutar sus suites ni las exportaciones visuales.

Pendientes y límites:

- No se han creado personas ficticias en Firestore real. Falta comprobar alta,
  edición y cambios de estado con datos elegidos por el usuario en el móvil.
- Falta comprobar sincronización desde dos móviles con cuentas autorizadas;
  no se da por cerrado el criterio de Phase 3 solo por compilar o usar fakes.
- Las pruebas aplazadas de Phase 1 no se reanudan ni se consideran superadas.
- La vinculación usuario/persona y gestión de membresías permanecen en Phase 7.
  Si se inactiva la persona vinculada de un admin, Rules retira su permiso efectivo
  de gestionar personas. La degradación persistida del campo role todavía no existe;
  no se escribe members desde el cliente en esta fase.
- No se generan periodos de participación, cuotas, dinero, notificaciones ni auditoría.
- La política de operación económica offline permanece pendiente. Edición usa
  transacciones y requiere conexión; no se ha validado recuperación de red.
- iOS requiere Mac/Xcode y sigue sin validación nativa.

Para comprobar el flujo real: entrar en Prueba1, añadir una persona con nombre y
notas opcionales, editarla, inactivarla y reactivarla. Confirmar después desde el
otro móvil que se ve el mismo documento. Usar datos decididos por el usuario,
recordando que esta fase conserva las personas y no permite borrarlas.
