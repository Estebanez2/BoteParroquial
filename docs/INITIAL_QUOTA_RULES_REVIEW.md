# Revisión: ingreso y primera cuota atómicos

2026-11-03. El usuario elige expresamente «Ingreso y cuota juntos, con respaldo
de reglas». Publicación únicamente de firestore:rules en boteparroquial, tras
copia de la versión remota activa y comprobación del candidato.

Cambio limitado a changedAllocation: leer la identidad del ingreso con getAfter
permite que se cree dentro del mismo commit; si ya existía, se sigue exigiendo
que su updatedAt no cambie en esta operación. No se altera la creación del
movimiento, ni su tipo, importe, persona, autor, auditoría o protección histórica.
Se conservan pertenencia/rol, campos permitidos, etapa computable, contador que
limita el reparto al ingreso, revisión y auditoría inseparable. No se abren nuevos
permisos, colecciones ni acceso público. El reparto posterior sigue igual.

Cuatro casos dirigidos del emulador demo-boteparroquial-allocations superados:
commit conjunto positivo y rechazos sin ingreso huérfano (exceso, etapa ajena,
miembro sin gestión); permisos/auditoría; límites/persona/tipo; concurrencia.
Los fixtures históricos se completaron con campos reales de persona y resumen
de auditoría exacto, sin relajar los controles para hacer pasar las pruebas.
Log local: .dart_tool/entry-quota-rules-test.log. No se ejecutó sobre datos reales.

La app conserva la intención explícita del reparto en journal v3 compatible con
v1/v2. La recuperación comprueba el ingreso y el evento inmutable del reparto,
con ID estable ligado a mes/importe/etapa. No reenvía dinero por suponer que una
respuesta perdida fue un fallo. Sin reescritura de repartos históricos ni migración.

Respaldo, publicación, hashes y APK se registran en
[MOVEMENT_ENTRY_AND_NOTIFICATIONS_2026-11-03.md](MOVEMENT_ENTRY_AND_NOTIFICATIONS_2026-11-03.md).
