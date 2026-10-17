import 'package:flutter/material.dart';

class EditRoomScreen extends StatefulWidget {
  final Map<String, dynamic> room;

  const EditRoomScreen({
    super.key,
    required this.room,
  });

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController roomController;
  late final TextEditingController locationController;
  late final TextEditingController priceController;
  late final TextEditingController depositController;
  late final TextEditingController areaController;

  late String selectedRoomType;
  late String selectedStatus;

  final roomTypes = [
    'Phòng đơn',
    'Phòng đôi',
    'Phòng gia đình',
  ];

  final statuses = [
    'Đang thuê',
    'Trống',
    'Đang sửa',
  ];

  @override
  void initState() {
    super.initState();

    roomController = TextEditingController(
      text: (widget.room['name'] ?? 'P.101').toString(),
    );

    locationController = TextEditingController(
      text: (widget.room['location'] ?? 'Khu A · Tầng 1').toString(),
    );

    priceController = TextEditingController(
      text: _getPriceValue(widget.room),
    );

    depositController = TextEditingController(
      text: _onlyNumber(
        (widget.room['deposit'] ?? '0').toString(),
      ),
    );

    areaController = TextEditingController(
      text: _onlyNumber(
        (widget.room['area'] ?? '0').toString(),
      ),
    );

    final roomType =
        (widget.room['roomType'] ?? 'Phòng đơn').toString();

    selectedRoomType = roomTypes.contains(roomType)
        ? roomType
        : 'Phòng đơn';

    selectedStatus = _statusForEdit(
      (widget.room['status'] ?? 'Trống').toString(),
    );
  }

  String _getPriceValue(Map<String, dynamic> room) {
    final priceValue = room['priceValue'];

    if (priceValue != null &&
        priceValue.toString().trim().isNotEmpty) {
      return _onlyNumber(priceValue.toString());
    }

    return _onlyNumber(
      (room['price'] ?? '0').toString(),
    );
  }

  String _onlyNumber(String value) {
    final result = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return result.isEmpty ? '0' : result;
  }

  String _statusForEdit(String status) {
    if (status == 'Đang cho thuê' ||
        status == 'Đang có người' ||
        status == 'Có người' ||
        status == 'Đang thuê') {
      return 'Đang thuê';
    }

    if (status == 'Đang sửa') {
      return 'Đang sửa';
    }

    return 'Trống';
  }

  @override
  void dispose() {
    roomController.dispose();
    locationController.dispose();
    priceController.dispose();
    depositController.dispose();
    areaController.dispose();
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
              width: double.infinity,
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
                    onTap: () {
                      Navigator.pop(context);
                    },
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
                          'Sửa phòng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Cập nhật thông tin phòng',
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
                  28,
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
                        hint: 'P.101',
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập số phòng';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // KHU / TẦNG
                      _label('Khu / Tầng *'),
                      const SizedBox(height: 7),

                      _textField(
                        controller: locationController,
                        hint: 'Khu A · Tầng 1',
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập khu / tầng';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // GIÁ PHÒNG
                      _label('Giá phòng *'),
                      const SizedBox(height: 7),

                      _textField(
                        controller: priceController,
                        hint: '2500000',
                        suffixText: 'đ / tháng',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập giá phòng';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // TIỀN ĐẶT CỌC
                      _label('Tiền đặt cọc *'),
                      const SizedBox(height: 7),

                      _textField(
                        controller: depositController,
                        hint: '2500000',
                        suffixText: 'đ',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập tiền đặt cọc';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // DIỆN TÍCH
                      _label('Diện tích *'),
                      const SizedBox(height: 7),

                      _textField(
                        controller: areaController,
                        hint: '25',
                        suffixText: 'm²',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập diện tích';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // LOẠI PHÒNG
                      _label('Loại phòng *'),
                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        initialValue: selectedRoomType,
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: secondary,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                        items: roomTypes
                            .map(
                              (type) =>
                                  DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedRoomType = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 17),

                      // TRẠNG THÁI
                      _label('Trạng thái'),
                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          fillColor:
                              const Color(0xFFE8F8EE),
                          borderColor:
                              const Color(0xFFBBE8C9),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: Color(0xFF16A34A),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                        items: statuses
                            .map(
                              (status) =>
                                  DropdownMenuItem<String>(
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

                      const SizedBox(height: 30),

                      // ================= SAVE =================
                      SizedBox(
                        width: double.infinity,
                        height: 49,
                        child: ElevatedButton(
                          onPressed: _saveRoom,
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
                            'Lưu thay đổi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 11),

                      const Center(
                        child: Text(
                          'Thông tin phòng sẽ được cập nhật ngay sau khi lưu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: secondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
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
    String? suffixText,
    TextInputType? keyboardType,
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
    Color? borderColor,
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
        borderSide: BorderSide(
          color:
              borderColor ?? const Color(0xFFE2E8F0),
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
  // SAVE
  // =========================================================

  void _saveRoom() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedRoom = <String, dynamic>{
      'name': roomController.text.trim(),
      'location': locationController.text.trim(),
      'priceValue': _onlyNumber(
        priceController.text.trim(),
      ),
      'deposit': _onlyNumber(
        depositController.text.trim(),
      ),
      'area': _onlyNumber(
        areaController.text.trim(),
      ),
      'roomType': selectedRoomType,
      'status': selectedStatus,
    };

    Navigator.pop(context, updatedRoom);
  }
}