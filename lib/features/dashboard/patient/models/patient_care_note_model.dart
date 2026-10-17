/// Clinova Clinical Care Note Model
///
/// Represents an authenticated care note or clinical observation recorded for a patient.
class PatientCareNote {
  final String id;
  final String text;
  final DateTime? date;
  final String? author;
  final String? category;

  const PatientCareNote({
    required this.id,
    required this.text,
    this.date,
    this.author,
    this.category,
  });

  /// Formats the date cleanly (e.g. "12 Oct 2026") only when a real date is available
  String get formattedDate {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date!.day.toString().padLeft(2, '0')} ${months[date!.month - 1]} ${date!.year}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'date': date?.toIso8601String(),
        'author': author,
        'category': category,
      };

  factory PatientCareNote.fromJson(Map<String, dynamic> json) => PatientCareNote(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
        author: json['author'] as String?,
        category: json['category'] as String?,
      );
}
