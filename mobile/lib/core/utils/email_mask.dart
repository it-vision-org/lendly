/// Masks an email's local part for display, e.g. "ahmed@example.com" ->
/// "ah***@example.com".
String maskEmail(String email) {
  final atIndex = email.indexOf('@');
  if (atIndex <= 0) return email;
  final local = email.substring(0, atIndex);
  final domain = email.substring(atIndex);
  final visibleCount = local.length > 2 ? 2 : 1;
  return '${local.substring(0, visibleCount)}***$domain';
}
