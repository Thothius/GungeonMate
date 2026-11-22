/// What the user is reporting on — carried into the bug-report sheet so
/// the category/location/entity fields are pre-filled from wherever the
/// button was tapped. The reporter only asks for free-text notes.
enum BugReportKind {
  bug('Bug'),
  contentError('Content error'),
  suggestion('Suggestion'),
  other('Other');

  const BugReportKind(this.label);
  final String label;
}

/// Immutable description of a report's origin. [entity] is the specific
/// thing being viewed (item/gun/synergy/character name) when there is
/// one; [screen] is the human-readable surface name shown in the sheet
/// and the email subject line.
class BugReportContext {
  final BugReportKind kind;
  final String screen;
  final String? entity;

  const BugReportContext({
    required this.kind,
    required this.screen,
    this.entity,
  });

  /// Convenience for detail views — content errors on a named thing.
  const BugReportContext.content({
    required String screen,
    required String entity,
  }) : this(kind: BugReportKind.contentError, screen: screen, entity: entity);
}
