import '../core/errors/app_failure.dart';
import '../models/group.dart';
import '../models/group_input.dart';
import '../services/group_management_service.dart';

class GroupManagementRepository {
  const GroupManagementRepository(this._service);
  final GroupManagementService _service;
  static const currencies = {
    'EUR': 'EUR · Euro',
    'USD': 'USD · Dólar estadounidense',
    'GBP': 'GBP · Libra esterlina',
  };
  static const timeZones = {
    'Europe/Madrid': 'España peninsular',
    'Atlantic/Canary': 'Islas Canarias',
    'Europe/London': 'Reino Unido',
    'America/New_York': 'Nueva York',
    'America/Bogota': 'Bogotá',
    'America/Mexico_City': 'Ciudad de México',
  };
  static String? nameError(String? name) => name == null || name.trim().isEmpty
      ? 'Escribe el nombre del grupo.'
      : name.trim().length > 256
      ? 'El nombre admite hasta 256 caracteres.'
      : null;
  static String? descriptionError(String? text) =>
      (text?.trim().length ?? 0) > 2000
      ? 'La descripción admite hasta 2000 caracteres.'
      : null;
  String newId() => _service.newId();
  Future<void> create(
    String id,
    String uid,
    String ownerName,
    GroupInput input,
  ) {
    final error =
        nameError(input.name) ??
        descriptionError(input.description) ??
        nameError(ownerName);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    if (!currencies.containsKey(input.currency) ||
        !timeZones.containsKey(input.timeZone)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Selecciona una moneda y una zona horaria disponibles.',
      );
    }
    return _service.create(
      id,
      uid,
      ownerName.trim(),
      GroupInput(
        name: input.name.trim(),
        description: input.description.trim(),
        currency: input.currency,
        timeZone: input.timeZone,
        createOwnerPerson: input.createOwnerPerson,
      ),
    );
  }

  Future<void> update(
    Group group,
    String uid,
    String name,
    String description,
  ) {
    final error = nameError(name) ?? descriptionError(description);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    return _service.update(group, uid, name.trim(), description.trim());
  }
}
