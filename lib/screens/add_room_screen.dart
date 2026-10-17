import 'package:flutter/material.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  final roomController = TextEditingController(text: 'P.202');
  final peopleController = TextEditingController(text: '2');
  final priceController = TextEditingController(text: '2500000');
  final depositController = TextEditingController(text: '2500000');
  final areaController = TextEditingController(text: '25');

  final member1Controller =
      TextEditingController(text: 'Thành viên 1');
  final member2Controller =
      TextEditingController(text: 'Thành viên 2');

  String member1Role = 'Vai trò';
  String member2Role = 'Vai trò';
  String selectedStatus = 'Trống';

  final roles = [
    'Vai trò',
    'Trưởng phòng',
    'Thành viên',
  ];

  final statuses = [
    'Trống',
    'Đang có người',
    'Đang sửa',
  ];

  @override
  void dispose() {
    roomController.dispose();
    peopleController.dispose();
    priceController.dispose();
    depositController.dispose();
    areaController.dispose();
    member1Controller.dispose();
    member2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    const textColor = Color(0xFF111827);
    const secondary = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                14,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(30),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm phòng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tạo thông tin phòng mới',
                          style: TextStyle(
                            fontSize: 10,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= FORM =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  25,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // SỐ PHÒNG
                      _label('Số phòng *'),
                      const SizedBox(height: 7),
                      _textField(
                        controller: roomController,
                        hint: 'P.202',
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập số phòng';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // SỐ LƯỢNG NGƯỜI
                      _label('Số lượng người *'),
                      const SizedBox(height: 7),
                      _textField(
                        controller: peopleController,
                        hint: '2',
                        keyboardType: TextInputType.number,
                        suffixText: 'người',
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập số lượng người';
                          }

                          final number =
                              int.tryParse(value.trim());

                          if (number == null || number < 0) {
                            return 'Số lượng người không hợp lệ';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // GIÁ PHÒNG
                      _label('Giá phòng *'),
                      const SizedBox(height: 7),
                      _textField(
                        controller: priceController,
                        hint: '2500000',
                        keyboardType: TextInputType.number,
                        suffixText: 'đ / tháng',
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập giá phòng';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // TIỀN ĐẶT CỌC
                      _label('Tiền đặt cọc *'),
                      const SizedBox(height: 7),
                      _textField(
                        controller: depositController,
                        hint: '2500000',
                        keyboardType: TextInputType.number,
                        suffixText: 'đ',
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập tiền đặt cọc';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // DIỆN TÍCH
                      _label('Diện tích *'),
                      const SizedBox(height: 7),
                      _textField(
                        controller: areaController,
                        hint: '25',
                        keyboardType: TextInputType.number,
                        suffixText: 'm²',
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập diện tích';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ================= THÀNH VIÊN =================
                      _label('Tên thành viên *'),
                      const SizedBox(height: 8),

                      _memberRow(
                        controller: member1Controller,
                        role: member1Role,
                        onRoleChanged: (value) {
                          if (value != null) {
                            setState(() {
                              member1Role = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 9),

                      _memberRow(
                        controller: member2Controller,
                        role: member2Role,
                        onRoleChanged: (value) {
                          if (value != null) {
                            setState(() {
                              member2Role = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 18),

                      // ================= TRẠNG THÁI =================
                      _label('Trạng thái'),
                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          fillColor:
                              const Color(0xFFEAF1FF),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: blue,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: blue,
                        ),
                        items: statuses
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 28),

                      // ================= BUTTON =================
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _createRoom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'Thêm phòng',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Center(
                        child: Text(
                          'Phòng mới sẽ được thêm vào danh sách phòng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: secondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MEMBER ROW
  // =========================================================

  Widget _memberRow({
    required TextEditingController controller,
    required String role,
    required ValueChanged<String?> onRoleChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF111827),
            ),
            decoration: _inputDecoration(),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          flex: 4,
          child: DropdownButtonFormField<String>(
            initialValue: role,
            isExpanded: true,
            decoration: _inputDecoration(),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
            ),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
            items: roles
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onRoleChanged,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LABEL
  // =========================================================

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF111827),
      ),
      decoration: _inputDecoration(
        hint: hint,
        suffixText: suffixText,
      ),
    );
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration _inputDecoration({
    String? hint,
    String? suffixText,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffixText,
      hintStyle: const TextStyle(
        fontSize: 11,
        color: Color(0xFF94A3B8),
      ),
      suffixStyle: const TextStyle(
        fontSize: 10,
        color: Color(0xFF64748B),
      ),
      filled: true,
      fillColor: fillColor ?? Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.4,
        ),
      ),
    );
  }

  // =========================================================
  // CREATE ROOM
  // =========================================================

  void _createRoom() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newRoom = <String, String>{
      'name': roomController.text.trim(),
      'people': peopleController.text.trim(),
      'area': areaController.text.trim(),
      'price': priceController.text.trim(),
      'deposit': depositController.text.trim(),

      // Giữ key này để code danh sách phòng cũ vẫn tương thích.
      'paymentDay': '05',

      'status': selectedStatus,
      'description': '',
      'member1': member1Controller.text.trim(),
      'member1Role': member1Role,
      'member2': member2Controller.text.trim(),
      'member2Role': member2Role,
    };

    Navigator.pop(context, newRoom);
  }
}