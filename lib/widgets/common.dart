import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/record.dart';
import '../services/app_store.dart';
import '../utils/validators.dart';

export '../services/app_store.dart' show errorText;

const blue = Color(0xFF2563EB);
const softBlue = Color(0xFFEAF1FF);
const ink = Color(0xFF111827);
const muted = Color(0xFF64748B);
const canvas = Color(0xFFF7F8FA);
const line = Color(0xFFE5E7EB);

final store = AppStore.instance;

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<void> perform(
  BuildContext context,
  Future<dynamic> Function() action, [
  String success = 'Đã lưu lên Firebase',
]) async {
  // Dialog chặn bấm lặp và không cho rời màn hình khi thao tác đang chờ server.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    await action();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      message(context, success);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      message(context, errorText(e));
    }
  }
}

Future<bool> confirm(BuildContext context, String text) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Xác nhận',
          style: TextStyle(
            color: ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          text,
          style: const TextStyle(color: muted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    ) ??
    false;

Future<void> openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));

Widget box(
  Widget child, {
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
}) => Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: padding,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: line, width: 1),
  ),
  child: child,
);

Widget info(String title, String value, {bool boldValue = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(title, style: const TextStyle(color: muted, fontSize: 13)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value.isEmpty ? 'Chưa cập nhật' : value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: ink,
            fontSize: 13,
            fontWeight: boldValue ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
);

InputDecoration searchDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: muted, fontSize: 12.5),
  prefixIcon: const Icon(Icons.search_rounded, size: 19, color: muted),
  filled: true,
  fillColor: Colors.white,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: line, width: 0.8),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: line, width: 0.8),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: blue, width: 1.3),
  ),
);

Widget statusPill(String value, {String? customText}) {
  final text = customText ?? label(value);
  final normalized = value.toLowerCase();
  Color foreground;
  Color background;

  if (value == 'Trống') {
    foreground = blue;
    background = softBlue;
  } else if (value == 'Đang sửa') {
    foreground = const Color(0xFFEA580C);
    background = const Color(0xFFFFF7ED);
  } else if (normalized == 'active' && text == 'Còn hiệu lực') {
    foreground = const Color(0xFF16A34A);
    background = const Color(0xFFDCFCE7);
  } else if (normalized.contains('active') ||
      normalized.contains('paid') && !normalized.contains('unpaid') ||
      normalized.contains('rented') ||
      normalized == 'done' ||
      value == 'Tốt' ||
      value == 'Đang thuê' ||
      value == 'Đang cho thuê' ||
      value == 'Đang có người' ||
      value == 'Hoàn thành') {
    foreground = const Color(0xFF16A34A);
    background = const Color(0xFFECFDF3);
  } else if (normalized == 'new' ||
      value == 'Mới' ||
      value == 'Mới tiếp nhận') {
    foreground = const Color(0xFFDC2626);
    background = const Color(0xFFFDECEC);
  } else if (normalized.contains('unpaid') || value == 'Chưa thanh toán') {
    foreground = const Color(0xFFEA580C);
    background = const Color(0xFFFFF7ED);
  } else if (normalized.contains('working') ||
      normalized.contains('reported') ||
      normalized.contains('scheduled') ||
      value == 'Đang xử lý') {
    foreground = const Color(0xFFD97706);
    background = const Color(0xFFFFF4E5);
  } else if (normalized == 'ended' ||
      value == 'Đã thanh lý' ||
      value == 'Đã kết thúc') {
    foreground = ink;
    background = const Color(0xFFBDCCE9);
  } else if (normalized.contains('void') ||
      normalized.contains('cancel') ||
      normalized.contains('expired') ||
      value == 'Sắp hết hạn') {
    foreground = const Color(0xFFC7070E);
    background = const Color(0xFFFDECEC);
  } else {
    foreground = const Color(0xFF475569);
    background = const Color(0xFFF1F5F9);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: foreground,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String twoLetterInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Widget initialAvatar(
  String name, {
  double size = 34,
  bool solidBlue = true,
  bool twoLetters = false,
  double borderRadius = 999,
}) {
  final content = twoLetters
      ? twoLetterInitials(name)
      : (name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase());
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: solidBlue ? blue : softBlue,
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: Text(
      content,
      style: TextStyle(
        color: solidBlue ? Colors.white : blue,
        fontSize: size * 0.42,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

({Color color, Color softBg, String symbol, IconData icon}) serviceVisual(
  String name, [
  String mode = '',
]) {
  final lower = name.toLowerCase();
  if (lower.contains('điện') || lower.contains('dien')) {
    return (
      color: const Color(0xFF2563EB),
      softBg: const Color(0xFFEAF1FF),
      symbol: 'ϟ',
      icon: Icons.bolt_rounded,
    );
  }
  if (lower.contains('nước') || lower.contains('nuoc')) {
    return (
      color: const Color(0xFF0891B2),
      softBg: const Color(0xFFECFEFF),
      symbol: '●',
      icon: Icons.water_drop_rounded,
    );
  }
  if (lower.contains('wifi') ||
      lower.contains('internet') ||
      lower.contains('mạng')) {
    return (
      color: const Color(0xFF7C3AED),
      softBg: const Color(0xFFF3E8FF),
      symbol: 'Wi',
      icon: Icons.wifi_rounded,
    );
  }
  if (lower.contains('rác') ||
      lower.contains('rac') ||
      lower.contains('vệ sinh')) {
    return (
      color: const Color(0xFFEA580C),
      softBg: const Color(0xFFFFF7ED),
      symbol: 'R',
      icon: Icons.delete_outline_rounded,
    );
  }
  if (lower.contains('xe') || lower.contains('parking')) {
    return (
      color: const Color(0xFF16A34A),
      softBg: const Color(0xFFECFDF3),
      symbol: 'P',
      icon: Icons.local_parking_rounded,
    );
  }
  if (mode == 'meter') {
    return (
      color: const Color(0xFF2563EB),
      softBg: const Color(0xFFEAF1FF),
      symbol: 'ϟ',
      icon: Icons.speed_rounded,
    );
  }
  return (
    color: const Color(0xFF2563EB),
    softBg: const Color(0xFFEAF1FF),
    symbol: name.trim().isEmpty ? 'DV' : name.trim()[0].toUpperCase(),
    icon: Icons.miscellaneous_services_rounded,
  );
}

Widget serviceBadge(String name, {String mode = '', double size = 34}) {
  final v = serviceVisual(name, mode);
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: v.color, shape: BoxShape.circle),
    child: Icon(v.icon, color: Colors.white, size: size * 0.52),
  );
}

Widget serviceChipPill(String name) {
  final v = serviceVisual(name);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: v.softBg,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Text(
      name,
      style: TextStyle(
        color: v.color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget figmaFilterPill({
  required String label,
  required bool selected,
  required VoidCallback onTap,
  Color? activeBg,
  Color? activeFg,
  Color? inactiveBg,
  Color? inactiveFg,
}) {
  final bg = selected ? (activeBg ?? blue) : (inactiveBg ?? Colors.white);
  final fg = selected ? (activeFg ?? Colors.white) : (inactiveFg ?? muted);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: selected || inactiveBg != null
            ? null
            : Border.all(color: line, width: 0.7),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

Widget figmaPrimaryPillButton({
  required String label,
  required VoidCallback onTap,
  bool soft = false,
}) => InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(17),
  child: Container(
    padding: EdgeInsets.symmetric(
      horizontal: soft ? 14 : 13,
      vertical: soft ? 8 : 6,
    ),
    decoration: BoxDecoration(
      color: soft ? softBlue : blue,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: soft ? blue : Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);

Widget empty(String text) => Container(
  width: double.infinity,
  margin: const EdgeInsets.symmetric(vertical: 14),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: line),
  ),
  child: Column(
    children: [
      const Icon(Icons.inbox_outlined, color: muted, size: 30),
      const SizedBox(height: 10),
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 13),
      ),
    ],
  ),
);

class RrmsBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const RrmsBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Phòng'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Người thuê'),
    (Icons.bolt_outlined, Icons.bolt_rounded, 'Dịch vụ'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Hóa đơn'),
    (Icons.description_outlined, Icons.description_rounded, 'Hợp đồng'),
    (Icons.handyman_outlined, Icons.handyman_rounded, 'Bảo trì'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == selectedIndex;
              final item = _items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: active ? softBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active ? item.$2 : item.$1,
                            size: 19,
                            color: active ? blue : muted,
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.$3,
                              maxLines: 1,
                              style: TextStyle(
                                color: active ? blue : muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class RecordsView extends StatefulWidget {
  final String collection;
  final String? field;
  final Object? equals;
  final Widget Function(BuildContext, List<Record>) builder;
  const RecordsView({
    super.key,
    required this.collection,
    required this.builder,
    this.field,
    this.equals,
  });
  @override
  State<RecordsView> createState() => _RecordsViewState();
}

class _RecordsViewState extends State<RecordsView> {
  late Stream<List<Record>> stream;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    stream = store.watch(
      widget.collection,
      field: widget.field,
      equals: widget.equals,
    );
  }

  @override
  void didUpdateWidget(covariant RecordsView old) {
    super.didUpdateWidget(old);
    if (old.collection != widget.collection ||
        old.field != widget.field ||
        old.equals != widget.equals) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Record>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            empty(errorText(snapshot.error)),
            TextButton(
              onPressed: () => setState(_load),
              child: const Text('Thử lại'),
            ),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return widget.builder(context, snapshot.data!);
    },
  );
}

class DocumentView extends StatefulWidget {
  final String collection, id;
  final Widget Function(Record) builder;
  const DocumentView({
    super.key,
    required this.collection,
    required this.id,
    required this.builder,
  });
  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  late Stream<Record?> stream;
  @override
  void initState() {
    super.initState();
    stream = store.document(widget.collection, widget.id);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Record?>(
    stream: stream,
    builder: (_, s) {
      if (s.hasError) return empty(errorText(s.error));
      if (s.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (s.data == null || s.data!.archived) {
        return empty('Bản ghi không tồn tại hoặc đã lưu trữ');
      }
      return widget.builder(s.data!);
    },
  );
}

class FieldSpec {
  final String key, title;
  final String? hint;
  final bool required, number, decimal, readOnly;
  final num? min, max;
  final Map<String, String>? options;
  const FieldSpec(
    this.key,
    this.title, {
    this.hint,
    this.required = true,
    this.number = false,
    this.decimal = false,
    this.readOnly = false,
    this.min,
    this.max,
    this.options,
  });
}

class EditForm extends StatefulWidget {
  final String title, action;
  final String? subtitle;
  final String? submitLabel;
  final String? helperText;
  final bool embedded;
  final String? id;
  final Map<String, dynamic> initial;
  final List<FieldSpec> fields;
  final Map<String, dynamic> fixed;
  const EditForm({
    super.key,
    required this.title,
    required this.action,
    required this.fields,
    this.subtitle,
    this.submitLabel,
    this.helperText,
    this.id,
    this.initial = const {},
    this.fixed = const {},
    this.embedded = false,
  });
  @override
  State<EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<EditForm> {
  final key = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final selected = <String, String?>{};
  bool saving = false;
  late final String recordId;
  @override
  void initState() {
    super.initState();
    recordId = widget.id ?? store.db.collection('_').doc().id;
    for (final f in widget.fields) {
      final value = widget.initial[f.key]?.toString() ?? '';
      if (f.options != null) {
        selected[f.key] = f.options!.containsKey(value) ? value : null;
      } else {
        controllers[f.key] = TextEditingController(text: value);
      }
    }
  }

  @override
  void didUpdateWidget(covariant EditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final f in widget.fields) {
      if (f.options != null && !f.options!.containsKey(selected[f.key])) {
        selected[f.key] = null;
      }
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (saving || !key.currentState!.validate()) return;
    final data = <String, dynamic>{...widget.fixed};
    for (final f in widget.fields) {
      final text = (controllers[f.key]?.text ?? selected[f.key] ?? '').trim();
      data[f.key] = f.number
          ? (text.isEmpty ? 0 : num.parse(text.replaceAll(',', '.')))
          : text;
    }
    setState(() => saving = true);
    try {
      await store.command(widget.action, id: widget.id, data: data);
      if (mounted) {
        Navigator.pop(context);
        message(context, 'Đã thêm phòng mới thành công');
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration _boxDecoration({String? hint, Color? fill}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: muted, fontSize: 13),
        filled: true,
        fillColor: fill ?? Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.3),
        ),
      );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      backgroundColor: canvas,
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: canvas,
              leading: IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 30,
                  color: ink,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              titleSpacing: 0,
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            if (widget.subtitle != null && !widget.embedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  widget.subtitle!,
                  style: const TextStyle(color: muted, fontSize: 12.5),
                ),
              ),
            for (final f in widget.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: RichText(
                        text: TextSpan(
                          text: f.title,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            if (f.required)
                              const TextSpan(
                                text: ' *',
                                style: TextStyle(color: Color(0xFFDC2626)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (f.options != null)
                      Builder(
                        builder: (context) {
                          final isCondition = f.key == 'condition';
                          final val = selected[f.key];
                          final condFill = isCondition
                              ? (val == 'Đang sửa'
                                    ? const Color(0xFFFFF7ED)
                                    : const Color(0xFFE9F8EF))
                              : Colors.white;
                          final condColor = isCondition
                              ? (val == 'Đang sửa'
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF16A34A))
                              : ink;
                          return DropdownButtonFormField<String>(
                            key: ValueKey(
                              '${f.key}:${selected[f.key] ?? ''}:${f.options!.keys.join(',')}',
                            ),
                            initialValue:
                                f.options!.containsKey(selected[f.key])
                                ? selected[f.key]
                                : null,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: muted,
                            ),
                            style: TextStyle(
                              color: condColor,
                              fontSize: 13.5,
                              fontWeight: isCondition
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            decoration: _boxDecoration(
                              hint: 'Chọn ${f.title.toLowerCase()}',
                              fill: condFill,
                            ),
                            items: f.options!.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (v) =>
                                f.required && (v == null || v.isEmpty)
                                ? 'Vui lòng chọn ${f.title}'
                                : null,
                            onChanged: saving
                                ? null
                                : (v) => setState(() => selected[f.key] = v),
                          );
                        },
                      )
                    else
                      TextFormField(
                        controller: controllers[f.key],
                        readOnly: f.readOnly,
                        enabled: !saving,
                        style: const TextStyle(color: ink, fontSize: 13.5),
                        keyboardType: f.number
                            ? TextInputType.numberWithOptions(
                                decimal: f.decimal,
                              )
                            : f.key == 'phone'
                            ? TextInputType.phone
                            : f.key == 'email'
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        maxLines: f.key == 'description' || f.key == 'note'
                            ? 3
                            : 1,
                        decoration: _boxDecoration(
                          hint: f.hint ?? 'Nhập ${f.title.toLowerCase()}',
                          fill: f.readOnly
                              ? const Color(0xFFF1F5F9)
                              : Colors.white,
                        ),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return f.required
                                ? 'Vui lòng nhập ${f.title}'
                                : null;
                          }
                          if (f.key == 'email') {
                            return validateEmail(text, required: f.required);
                          }
                          if (f.key == 'phone') {
                            return validateVietnamesePhone(
                              text,
                              required: f.required,
                            );
                          }
                          if (f.key == 'identity') {
                            return validateIdentity(text, required: f.required);
                          }
                          if (f.number) {
                            final n = num.tryParse(text.replaceAll(',', '.'));
                            if (n == null ||
                                !n.isFinite ||
                                (!f.decimal && n != n.round()) ||
                                (f.min != null && n < f.min!) ||
                                (f.max != null && n > f.max!)) {
                              return 'Giá trị ${f.title} không hợp lệ';
                            }
                          }
                          if (f.key.endsWith('Date') &&
                              DateTime.tryParse(text) == null) {
                            return 'Dùng dạng YYYY-MM-DD';
                          }
                          if (f.key == 'period' &&
                              !RegExp(
                                r'^\d{4}-(0[1-9]|1[0-2])$',
                              ).hasMatch(text)) {
                            return 'Dùng dạng YYYY-MM';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  saving
                      ? 'Đang lưu...'
                      : (widget.submitLabel ?? 'Lưu thay đổi'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (widget.helperText != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.helperText!,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget photos(Record record) => Column(
  children: [
    for (final url in record.strings('imageUrls'))
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            url,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => empty('Không tải được ảnh'),
          ),
        ),
      ),
  ],
);


class MoreMenuItem {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const MoreMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

Widget moreActionsMenu({
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  String editLabel = 'Sửa',
  String deleteLabel = 'Xóa',
  IconData editIcon = Icons.edit_outlined,
  IconData deleteIcon = Icons.delete_outline_rounded,
  List<MoreMenuItem> extras = const [],
  Color iconColor = muted,
  double iconSize = 20,
  EdgeInsetsGeometry padding = const EdgeInsets.all(4),
}) {
  if (onEdit == null && onDelete == null && extras.isEmpty) {
    return const SizedBox.shrink();
  }
  return PopupMenuButton<String>(
    tooltip: 'Tùy chọn',
    padding: padding,
    constraints: const BoxConstraints(minWidth: 148),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    icon: Icon(Icons.more_vert_rounded, color: iconColor, size: iconSize),
    onSelected: (value) {
      if (value == 'edit') {
        onEdit?.call();
        return;
      }
      if (value == 'delete') {
        onDelete?.call();
        return;
      }
      for (final item in extras) {
        if (item.value == value) {
          item.onTap();
          return;
        }
      }
    },
    itemBuilder: (context) => [
      if (onEdit != null)
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(editIcon, size: 18, color: blue),
              const SizedBox(width: 10),
              Text(
                editLabel,
                style: const TextStyle(
                  color: ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      for (final item in extras)
        PopupMenuItem<String>(
          value: item.value,
          child: Row(
            children: [
              Icon(item.icon, size: 18, color: item.color ?? ink),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  color: item.color ?? ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      if (onDelete != null)
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(deleteIcon, size: 18, color: const Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Text(
                deleteLabel,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

Widget cccdImageWidget(
  String src, {
  double height = 120,
  double width = double.infinity,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
  String emptyLabel = 'Chưa có ảnh CCCD',
}) {
  final radius = borderRadius ?? BorderRadius.circular(12);
  final trimmed = src.trim();
  if (trimmed.isEmpty) {
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: radius,
        border: Border.all(color: line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.badge_outlined, color: muted, size: 26),
          const SizedBox(height: 6),
          Text(
            emptyLabel,
            style: const TextStyle(color: muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
  Widget img;
  if (trimmed.startsWith('data:image')) {
    final commaIdx = trimmed.indexOf(',');
    final b64 = commaIdx >= 0 ? trimmed.substring(commaIdx + 1) : trimmed;
    try {
      final bytes = base64Decode(b64);
      img = Image.memory(
        bytes,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, _, _) => _brokenCccdBox(height, width, radius),
      );
    } catch (_) {
      img = _brokenCccdBox(height, width, radius);
    }
  } else {
    img = Image.network(
      trimmed,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, _, _) => _brokenCccdBox(height, width, radius),
    );
  }
  return ClipRRect(borderRadius: radius, child: img);
}

Widget _brokenCccdBox(double height, double width, BorderRadius radius) =>
    Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: radius,
        border: Border.all(color: line),
      ),
      child: const Text(
        'Không hiển thị được ảnh',
        style: TextStyle(color: muted, fontSize: 11.5),
      ),
    );

void showCccdFullDialog(BuildContext context, String title, String src) {
  if (src.trim().isEmpty) return;
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InteractiveViewer(
              child: cccdImageWidget(
                src,
                height: 260,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
