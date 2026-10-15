# Pruebas de reglas de Phase 1

Instalar aquí con `npm ci`. Desde la raíz del repositorio, con Firebase CLI y
Java 21 disponibles:

```sh
firebase emulators:exec --only firestore --project demo-boteparroquial "node --test tools/firestore-rules/profile_rules.test.cjs"
```

El emulador carga `firestore.rules`. Las pruebas se limitan al proyecto ficticio
`demo-boteparroquial`; no utilizan datos reales ni la firma de usuarios de producción.
Ver [validación de Phase 1](../../docs/PHASE1_VALIDATION.md).
