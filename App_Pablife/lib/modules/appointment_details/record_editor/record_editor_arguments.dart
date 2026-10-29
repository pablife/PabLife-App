import '../../../infra/models/patient_record_model.dart';

class RecordEditorArguments {
  final PatientRecordType type;
  final String patientId;
  final String appointmentId;
  final PatientRecordModel? record;

  const RecordEditorArguments({
    required this.type,
    required this.patientId,
    required this.appointmentId,
    this.record,
  });

  bool get isEditing => record != null;
}
