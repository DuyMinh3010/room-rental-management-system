import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../models/record.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/form_widgets.dart';

class TenantEditPage extends StatefulWidget {
  final Record? tenant;
  final String? initialRoomId;
  const TenantEditPage({super.key, this.tenant, this.initialRoomId});

  @override
  State<TenantEditPage> createState() => _TenantEditPageState();
}

class _TenantEditPageState extends State<TenantEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _identityCtrl;
  late final TextEditingController _birthdayCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _noteCtrl;

  late String _roomId;
  late String _role;
  late String _cccdFrontUrl;
  late String _cccdBackUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    _nameCtrl = TextEditingController(text: t?.text('name') ?? '');
    _phoneCtrl = TextEditingController(text: t?.text('phone') ?? '');
    _emailCtrl = TextEditingController(text: t?.text('email') ?? '');
    _identityCtrl = TextEditingController(text: t?.text('identity') ?? '');
    _birthdayCtrl = TextEditingController(text: t?.text('birthday') ?? '');
    _addressCtrl = TextEditingController(text: t?.text('address') ?? '');
    _noteCtrl = TextEditingController(text: t?.text('note') ?? '');
    _roomId = t?.text('roomId') ?? widget.initialRoomId ?? '';
    _role = (t?.text('role') == 'leader' || t?.text('role') == 'member')
        ? t!.text('role')
        : 'leader';
    _cccdFrontUrl = t?.text('cccdFrontUrl') ?? '';
    _cccdBackUrl = t?.text('cccdBackUrl') ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _identityCtrl.dispose();
    _birthdayCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCccdImage({
    required bool front,
    required ImageSource source,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 75,
      );
      if (picked == null) return;
      final rawBytes = await picked.readAsBytes();
      final dataUrl = _compressToDataUrl(rawBytes);
      if (!mounted) return;
      setState(() {
        if (front) {
          _cccdFrontUrl = dataUrl;
        } else {
          _cccdBackUrl = dataUrl;
        }
      });
    } catch (e) {
      if (mounted) {
        message(
          context,
          'Không mở được camera/thư viện trên thiết bị này. Bạn có thể bấm "Tạo ảnh mẫu" để kiểm thử nhanh.',
        );
      }
    }
  }

  String _compressToDataUrl(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      return 'data:image/jpeg;base64,${base64Encode(rawBytes)}';
    }
    final resized = decoded.width > 640
        ? img.copyResize(decoded, width: 640)
        : decoded;
    final jpg = img.encodeJpg(resized, quality: 65);
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  }

  void _generateSampleCccd({required bool front}) {
    final canvasImg = img.Image(width: 480, height: 300);
    // Nền thẻ CCCD màu xanh nhạt / kem
    img.fill(
      canvasImg,
      color: front
          ? img.ColorRgb8(232, 244, 252)
          : img.ColorRgb8(241, 245, 249),
    );
    // Viền thẻ
    img.drawRect(
      canvasImg,
      x1: 6,
      y1: 6,
      x2: 473,
      y2: 293,
      color: img.ColorRgb8(37, 99, 235),
      thickness: 3,
    );
    // Dải tiêu đề trên
    img.fillRect(
      canvasImg,
      x1: 6,
      y1: 6,
      x2: 473,
      y2: 58,
      color: front
          ? img.ColorRgb8(37, 99, 235)
          : img.ColorRgb8(71, 85, 105),
    );
    img.drawString(
      canvasImg,
      front ? 'CAN CUOC CONG DAN (MAT TRUOC)' : 'CAN CUOC CONG DAN (MAT SAU)',
      font: img.arial24,
      x: 24,
      y: 20,
      color: img.ColorRgb8(255, 255, 255),
    );
    if (front) {
      // Khung ảnh chân dung
      img.fillRect(
        canvasImg,
        x1: 24,
        y1: 80,
        x2: 140,
        y2: 240,
        color: img.ColorRgb8(203, 213, 225),
      );
      img.drawString(
        canvasImg,
        'ANH 3x4',
        font: img.arial14,
        x: 52,
        y: 150,
        color: img.ColorRgb8(51, 65, 85),
      );
      final idNum = _identityCtrl.text.trim().isEmpty
          ? '079203001234'
          : _identityCtrl.text.trim();
      img.drawString(
        canvasImg,
        'So CCCD: $idNum',
        font: img.arial24,
        x: 160,
        y: 95,
        color: img.ColorRgb8(220, 38, 38),
      );
      img.drawString(
        canvasImg,
        'Ho ten: ${_nameCtrl.text.trim().isEmpty ? 'NGUYEN VAN A' : _nameCtrl.text.trim()}',
        font: img.arial14,
        x: 160,
        y: 145,
        color: img.ColorRgb8(17, 24, 39),
      );
      img.drawString(
        canvasImg,
        'SDT: ${_phoneCtrl.text.trim().isEmpty ? '0901234567' : _phoneCtrl.text.trim()}',
        font: img.arial14,
        x: 160,
        y: 180,
        color: img.ColorRgb8(17, 24, 39),
      );
      img.drawString(
        canvasImg,
        'Ngay sinh: ${_birthdayCtrl.text.trim().isEmpty ? '01/01/2000' : _birthdayCtrl.text.trim()}',
        font: img.arial14,
        x: 160,
        y: 215,
        color: img.ColorRgb8(17, 24, 39),
      );
    } else {
      // Chip và MRZ mặt sau
      img.fillRect(
        canvasImg,
        x1: 30,
        y1: 82,
        x2: 110,
        y2: 145,
        color: img.ColorRgb8(234, 179, 8),
      );
      img.drawString(
        canvasImg,
        'CHIP',
        font: img.arial14,
        x: 52,
        y: 106,
        color: img.ColorRgb8(17, 24, 39),
      );
      img.drawString(
        canvasImg,
        'Noi cap: CUC CANH SAT QLHC VE TTXH',
        font: img.arial14,
        x: 130,
        y: 95,
        color: img.ColorRgb8(17, 24, 39),
      );
      img.drawString(
        canvasImg,
        'Ngay cap: 15/06/2022',
        font: img.arial14,
        x: 130,
        y: 130,
        color: img.ColorRgb8(17, 24, 39),
      );
      img.fillRect(
        canvasImg,
        x1: 20,
        y1: 195,
        x2: 460,
        y2: 270,
        color: img.ColorRgb8(226, 232, 240),
      );
      img.drawString(
        canvasImg,
        'IDVNM079203001234<<<<<<<<<<<<<',
        font: img.arial14,
        x: 34,
        y: 212,
        color: img.ColorRgb8(15, 23, 42),
      );
      img.drawString(
        canvasImg,
        '0001018M3001015VNM<<<<<<<<<<<6',
        font: img.arial14,
        x: 34,
        y: 238,
        color: img.ColorRgb8(15, 23, 42),
      );
    }
    final jpg = img.encodeJpg(canvasImg, quality: 75);
    final url = 'data:image/jpeg;base64,${base64Encode(jpg)}';
    setState(() {
      if (front) {
        _cccdFrontUrl = url;
      } else {
        _cccdBackUrl = url;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await store.command(
        'saveTenant',
        id: widget.tenant?.id,
        data: {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'identity': _identityCtrl.text.trim(),
          'roomId': _roomId,
          'role': _role,
          'cccdFrontUrl': _cccdFrontUrl,
          'cccdBackUrl': _cccdBackUrl,
          'birthday': _birthdayCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'note': _noteCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        message(
          context,
          widget.tenant == null
              ? 'Đã thêm người thuê thành công'
              : 'Đã lưu thông tin người thuê',
        );
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _cccdCard({
    required String title,
    required String src,
    required bool front,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.badge_outlined, size: 17, color: blue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (src.isNotEmpty)
              InkWell(
                onTap: () => setState(() {
                  if (front) {
                    _cccdFrontUrl = '';
                  } else {
                    _cccdBackUrl = '';
                  }
                }),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: src.isEmpty
              ? null
              : () => showCccdFullDialog(context, title, src),
          child: cccdImageWidget(
            src,
            height: 115,
            emptyLabel: front ? 'Chưa có ảnh mặt trước' : 'Chưa có ảnh mặt sau',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _pickCccdImage(
                      front: front,
                      source: ImageSource.camera,
                    ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 15),
              label: const Text('Chụp ảnh', style: TextStyle(fontSize: 11.5)),
            ),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _pickCccdImage(
                      front: front,
                      source: ImageSource.gallery,
                    ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 15),
              label: const Text('Thư viện', style: TextStyle(fontSize: 11.5)),
            ),
            TextButton.icon(
              onPressed: _saving ? null : () => _generateSampleCccd(front: front),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
              label: const Text('Ảnh mẫu', style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.tenant == null;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          backgroundColor: canvas,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
            onPressed: () => Navigator.maybePop(context),
          ),
          titleSpacing: 0,
          title: Text(
            isNew ? 'Thêm người thuê' : 'Sửa người thuê',
            style: const TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: RecordsView(
          collection: 'rooms',
          builder: (_, rs) {
            final rooms = rs.where((r) => !r.archived).toList()
              ..sort((a, b) => naturalCompare(a.name, b.name));
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                children: [
                  formLabel('Họ và tên', required: true),
                  TextFormField(
                    controller: _nameCtrl,
                    enabled: !_saving,
                    style: const TextStyle(color: ink, fontSize: 13.5),
                    decoration: formDecoration(hint: 'Nhập họ và tên'),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Vui lòng nhập họ và tên'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  formLabel('Số điện thoại', required: true),
                  TextFormField(
                    controller: _phoneCtrl,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: ink, fontSize: 13.5),
                    decoration: formDecoration(hint: 'Nhập số điện thoại'),
                    validator: (v) =>
                        validateVietnamesePhone(v, required: true),
                  ),
                  const SizedBox(height: 14),
                  formLabel('CCCD / Passport'),
                  TextFormField(
                    controller: _identityCtrl,
                    enabled: !_saving,
                    style: const TextStyle(color: ink, fontSize: 13.5),
                    decoration: formDecoration(
                      hint: 'Nhập 12 số CCCD hoặc Passport',
                    ),
                    validator: (v) => validateIdentity(v, required: false),
                  ),
                  const SizedBox(height: 14),
                  formLabel('Ảnh chụp Căn cước công dân (CCCD)'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _cccdCard(
                          title: 'CCCD Mặt trước',
                          src: _cccdFrontUrl,
                          front: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _cccdCard(
                          title: 'CCCD Mặt sau',
                          src: _cccdBackUrl,
                          front: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  formLabel('Phòng đang ở'),
                  DropdownButtonFormField<String>(
                    key: ValueKey('room:$_roomId:${rooms.length}'),
                    initialValue:
                        _roomId.isEmpty || rooms.any((r) => r.id == _roomId)
                        ? _roomId
                        : '',
                    isExpanded: true,
                    decoration: formDecoration(hint: 'Chọn phòng'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Chưa gán phòng'),
                      ),
                      for (final r in rooms)
                        DropdownMenuItem(value: r.id, child: Text(r.name)),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _roomId = v ?? ''),
                  ),
                  const SizedBox(height: 14),
                  formLabel('Vai trò trong phòng'),
                  DropdownButtonFormField<String>(
                    key: ValueKey('role:$_role'),
                    initialValue: _role,
                    isExpanded: true,
                    decoration: formDecoration(),
                    items: const [
                      DropdownMenuItem(
                        value: 'leader',
                        child: Text('Trưởng phòng (Đại diện hợp đồng)'),
                      ),
                      DropdownMenuItem(
                        value: 'member',
                        child: Text('Thành viên ở ghép'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _role = v ?? 'member'),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Mỗi phòng chỉ có duy nhất 1 Trưởng phòng. Nếu chọn Trưởng phòng mới, hệ thống tự động chuyển người cũ thành Thành viên và đồng bộ với Hợp đồng & Hóa đơn.',
                      style: TextStyle(color: muted, fontSize: 11.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  formLabel('Email tài khoản đăng nhập'),
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: ink, fontSize: 13.5),
                    decoration: formDecoration(
                      hint: 'Nhập đúng email người thuê sẽ xác minh',
                    ),
                    validator: (v) => validateEmail(v, required: false),
                  ),
                  const SizedBox(height: 14),
                  formLabel('Ngày sinh'),
                  TextFormField(
                    controller: _birthdayCtrl,
                    enabled: !_saving,
                    style: const TextStyle(color: ink, fontSize: 13.5),
                    decoration: formDecoration(hint: 'VD: 24/08/2003'),
                  ),
                  const SizedBox(height: 14),
                  formLabel('Quê quán / Địa chỉ thường trú'),
                  TextFormField(
                    controller: _addressCtrl,
                    enabled: !_saving,
                    style: const TextStyle(color: ink, fontSize: 13.5),
                    decoration: formDecoration(hint: 'Nhập địa chỉ'),
                  ),
                  const SizedBox(height: 14),
                  formLabel('Ghi chú'),
                  TextFormField(
                    controller: _noteCtrl,
                    enabled: !_saving,
                    maxLines: 3,
                    style: const TextStyle(color: ink, fontSize: 13.5),
                    decoration: formDecoration(hint: 'Ghi chú thêm...'),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _saving
                            ? 'Đang lưu...'
                            : (isNew ? 'Thêm người thuê' : 'Lưu thay đổi'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
