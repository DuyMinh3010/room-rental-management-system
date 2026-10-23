import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/form_widgets.dart';

class ContractEditPage extends StatefulWidget {
  final Map<String, String>? contract;

  const ContractEditPage({super.key, this.contract});

  @override
  State<ContractEditPage> createState() => _ContractEditPageState();
}

class _ContractEditPageState extends State<ContractEditPage> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  final List<TextEditingController> memberNameFields = [];
  String _generateContractNumber() {
    final documentId = FirebaseFirestore.instance
        .collection('contracts')
        .doc()
        .id;

    return 'HD${documentId.substring(0, 8).toUpperCase()}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _pickDate(String key) async {
    final currentDate = _date(fields[key]!.text.trim());
    final startDate = _date(fields['start']!.text.trim());

    final firstDate = key == 'end' && startDate != null
        ? startDate.add(const Duration(days: 1))
        : DateTime(2000);

    final initialDate = currentDate != null && !currentDate.isBefore(firstDate)
        ? currentDate
        : (DateTime.now().isBefore(firstDate) ? firstDate : DateTime.now());

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      helpText: key == 'start' ? 'Chọn ngày bắt đầu' : 'Chọn ngày kết thúc',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      fields[key]!.text = _formatDate(selectedDate);
    });
  }

  bool isSaving = false;

  // ID tài liệu phòng trên Firestore, không phải tên phòng.
  String? selectedRoomId;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> roomDocs = [];
  List<Map<String, String>> roomServices = [];
  final Set<String> selectedServiceIds = {};
  final Map<String, TextEditingController> servicePriceFields = {};
  bool loadingRoomServices = false;
  String? roomServiceError;
  String? requestedRoomServicesRoomId;

  final labels = const {
    'id': 'Số hợp đồng',
    'name': 'Trưởng phòng',
    'room': 'Phòng',
    'phone': 'Số điện thoại',
    'email': 'Email',
    'identity': 'CCCD/Passport',
    'start': 'Ngày bắt đầu (dd/mm/yyyy)',
    'end': 'Ngày kết thúc (dd/mm/yyyy)',
    'rent': 'Tiền phòng (đ/tháng)',
    'deposit': 'Tiền đặt cọc (đ)',
    'note': 'Ghi chú',
  };

  @override
  void initState() {
    super.initState();

    selectedRoomId = widget.contract?['roomId'];

    for (final key in labels.keys) {
      fields[key] = TextEditingController(
        text: key == 'id'
            ? (widget.contract?['id'] ?? _generateContractNumber())
            : (widget.contract?[key] ?? ''),
      );
    }

    final savedMembers = _decodeMembers(widget.contract?['members']);
    for (final member in savedMembers.skip(1)) {
      memberNameFields.add(
        TextEditingController(text: (member['name'] ?? '').toString()),
      );
    }

    if (selectedRoomId != null) {
      _loadRoomServices(
        selectedRoomId!,
        contractServices: widget.contract?['services'],
      );
    }
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    for (final controller in servicePriceFields.values) {
      controller.dispose();
    }
    for (final controller in memberNameFields) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _decodeMembers(Object? value) {
    if (value is String) {
      if (value.trim().isEmpty) return [];
      value = jsonDecode(value);
    }
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((member) => Map<String, dynamic>.from(member))
        .toList();
  }

  List<Map<String, dynamic>> _decodeServices(Object? value) {
    if (value is String) {
      if (value.trim().isEmpty) return [];
      value = jsonDecode(value);
    }

    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _loadRoomServices(
    String roomId, {
    String? contractServices,
  }) async {
    requestedRoomServicesRoomId = roomId;
    setState(() {
      loadingRoomServices = true;
      roomServiceError = null;
    });

    try {
      final db = FirebaseFirestore.instance;
      final roomSnapshot = await db.collection('rooms').doc(roomId).get();
      final serviceSnapshot = await db.collection('services').get();

      if (!mounted || selectedRoomId != roomId) return;

      final roomData = roomSnapshot.data();
      final hasContractServices =
          contractServices != null && contractServices.trim().isNotEmpty;
      final savedServices = hasContractServices
          ? _decodeServices(contractServices)
          : _decodeServices(roomData?['services']);
      final hasSavedConfiguration =
          hasContractServices || roomData?.containsKey('services') == true;
      final savedById = {
        for (final service in savedServices)
          (service['id'] ?? service['serviceId'] ?? '').toString(): service,
      };

      final loadedServices = serviceSnapshot.docs
          .where((doc) => doc.data()['isActive'] != false)
          .map((doc) {
            final data = doc.data();
            return <String, String>{
              'id': doc.id,
              'name': (data['name'] ?? '').toString(),
              'mode': (data['mode'] ?? 'Theo phòng').toString(),
              'price': (data['price'] ?? 0).toString(),
              'unit': (data['unit'] ?? 'tháng').toString(),
            };
          })
          .toList();

      final newSelectedIds = <String>{};
      final newPriceFields = <String, TextEditingController>{};

      for (final service in loadedServices) {
        final id = service['id']!;
        final saved = savedById[id];

        if (!hasSavedConfiguration || saved != null) {
          newSelectedIds.add(id);
        }

        newPriceFields[id] = TextEditingController(
          text: (saved?['price'] ?? service['price'] ?? '0').toString(),
        );
      }

      for (final controller in servicePriceFields.values) {
        controller.dispose();
      }

      setState(() {
        roomServices = loadedServices;
        selectedServiceIds
          ..clear()
          ..addAll(newSelectedIds);
        servicePriceFields
          ..clear()
          ..addAll(newPriceFields);
        loadingRoomServices = false;
      });
    } catch (e) {
      if (!mounted || selectedRoomId != roomId) return;

      setState(() {
        loadingRoomServices = false;
        roomServiceError = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _selectedServicesForSave() {
    return roomServices
        .where((service) => selectedServiceIds.contains(service['id']))
        .map((service) {
          final id = service['id']!;
          final priceText = servicePriceFields[id]!.text.trim();
          final price = num.tryParse(priceText.replaceAll(',', '.'));

          if (price == null || price < 0) {
            throw FormatException(
              'Đơn giá dịch vụ "${service['name']}" không hợp lệ.',
            );
          }

          return <String, dynamic>{
            'id': id,
            'name': service['name'],
            'mode': service['mode'],
            'price': price,
            'unit': service['unit'],
          };
        })
        .toList();
  }

  List<Map<String, String>> _membersForSave() {
    return [
      {'name': fields['name']!.text.trim(), 'role': 'Trưởng phòng'},
      for (final controller in memberNameFields)
        {'name': controller.text.trim(), 'role': 'Thành viên'},
    ];
  }

  Widget _buildMembers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormInput('Tên Trưởng phòng', fields['name']!, requiredField: true),
        for (var index = 0; index < memberNameFields.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: memberNameFields[index],
              decoration: InputDecoration(
                labelText: 'Tên Thành viên ${index + 1}',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Xóa thành viên',
                  onPressed: isSaving
                      ? null
                      : () {
                          setState(() {
                            memberNameFields.removeAt(index).dispose();
                          });
                        },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Vui lòng nhập tên thành viên.';
                }
                return null;
              },
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: isSaving
                ? null
                : () {
                    setState(() {
                      memberNameFields.add(TextEditingController());
                    });
                  },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Thêm thành viên'),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dịch vụ áp dụng cho phòng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (loadingRoomServices)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (roomServiceError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Không tải được dịch vụ: $roomServiceError'),
          )
        else if (roomServices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Phòng chưa có dịch vụ khả dụng.'),
          )
        else
          for (final service in roomServices)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedServiceIds.contains(service['id']),
                      title: Text(service['name'] ?? ''),
                      subtitle: Text(
                        '${service['mode']} · /${service['unit']}',
                      ),
                      onChanged: isSaving || loadingRoomServices
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected == true) {
                                  selectedServiceIds.add(service['id']!);
                                } else {
                                  selectedServiceIds.remove(service['id']);
                                }
                              });
                            },
                    ),
                    TextFormField(
                      controller: servicePriceFields[service['id']],
                      enabled:
                          selectedServiceIds.contains(service['id']) &&
                          !isSaving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá áp dụng (đ)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _roomName(Map<String, dynamic> data) {
    return (data['name'] ?? data['room'] ?? data['roomName'] ?? '').toString();
  }

  String _roomValue(Map<String, dynamic> data, String key) {
    return (data[key] ?? '').toString();
  }

  num _roomAmount(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value;

    final digits = value?.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits ?? '');
    if (amount == null) {
      throw Exception('Giá trị ${labels[key] ?? key} của phòng không hợp lệ.');
    }
    return amount;
  }

  String? _findRoomIdByName() {
    final currentRoom = fields['room']!.text.trim();

    if (currentRoom.isEmpty) return null;

    for (final doc in roomDocs) {
      if (_roomName(doc.data()) == currentRoom) {
        return doc.id;
      }
    }

    return null;
  }

  String? _resolveRoomId() {
    if (selectedRoomId != null &&
        roomDocs.any((doc) => doc.id == selectedRoomId)) {
      return selectedRoomId;
    }

    // Hỗ trợ hợp đồng cũ chưa có roomId.
    return _findRoomIdByName();
  }

  Future<void> _selectRoom(String? roomId) async {
    if (roomId == null || isSaving) return;

    final index = roomDocs.indexWhere((doc) => doc.id == roomId);

    if (index == -1) return;

    final roomData = roomDocs[index].data();
    final roomName = _roomName(roomData);

    setState(() {
      selectedRoomId = roomId;

      fields['room']!.text = roomName;
      fields['rent']!.text = _roomValue(roomData, 'price');
      fields['deposit']!.text = _roomValue(roomData, 'deposit');
    });
    await _loadRoomServices(roomId);

    try {
      await _loadTenantForRoom(roomId, roomName);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được thông tin người thuê: $e')),
      );
    }

    setState(() {
      selectedRoomId = roomId;

      // Tự điền vào các trường cũ, giữ nguyên giao diện.
      fields['room']!.text = _roomName(roomData);
      fields['rent']!.text = _roomValue(roomData, 'price');
      fields['deposit']!.text = _roomValue(roomData, 'deposit');
    });
  }

  Future<void> _loadTenantForRoom(String roomId, String roomName) async {
    if (widget.contract == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;

    // Bước 1: Tìm hợp đồng còn hiệu lực của phòng.
    final contractSnapshot = await db
        .collection('contracts')
        .where('ownerId', isEqualTo: user.uid)
        .get();

    final activeContracts = contractSnapshot.docs.where((doc) {
      final data = doc.data();

      return data['roomId']?.toString() == roomId &&
          data['status'] == 'Còn hiệu lực';
    }).toList();

    Map<String, dynamic>? tenantData;

    if (activeContracts.length == 1) {
      // Ưu tiên dữ liệu của hợp đồng đang thuê phòng.
      tenantData = activeContracts.first.data();
    } else {
      // Bước 2: Nếu không tìm được đúng một hợp đồng,
      // tìm hồ sơ người thuê theo roomId.
      final tenantSnapshot = await db
          .collection('tenants')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      var matches = tenantSnapshot.docs.where((doc) {
        return doc.data()['roomId']?.toString() == roomId;
      }).toList();

      // Hỗ trợ dữ liệu cũ chưa lưu roomId.
      if (matches.isEmpty) {
        matches = tenantSnapshot.docs.where((doc) {
          return doc.data()['room']?.toString() == roomName;
        }).toList();
      }

      if (matches.length == 1) {
        tenantData = matches.first.data();
      }
    }

    if (!mounted) return;

    if (tenantData != null) {
      setState(() {
        fields['name']!.text = (tenantData!['name'] ?? '').toString();
        fields['phone']!.text = (tenantData['phone'] ?? '').toString();
        fields['email']!.text = (tenantData['email'] ?? '').toString();
        fields['identity']!.text = (tenantData['identity'] ?? '').toString();
      });
    } else {
      // Chỉ xóa thông tin khi tạo hợp đồng mới.
      // Khi chỉnh sửa hợp đồng cũ, giữ nguyên dữ liệu đang có.
      if (widget.contract == null) {
        setState(() {
          fields['name']!.clear();
          fields['phone']!.clear();
          fields['email']!.clear();
          fields['identity']!.clear();
        });
      }
    }
  }

  DateTime? _date(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    final date = DateTime(year, month, day);

    return date.day == day && date.month == month && date.year == year
        ? date
        : null;
  }

  Future<void> _save() async {
    if (isSaving) return;

    if (!formKey.currentState!.validate()) return;

    final roomId = _resolveRoomId();

    if (roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng cần tạo hợp đồng.')),
      );
      return;
    }

    final start = _date(fields['start']!.text.trim());
    final end = _date(fields['end']!.text.trim());

    if (start == null || end == null || !end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nhập ngày hợp lệ; ngày kết thúc phải sau ngày bắt đầu.',
          ),
        ),
      );
      return;
    }

    final contractId = fields['id']!.text.trim();

    if (contractId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số hợp đồng.')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // 1. Kiểm tra tài khoản Firebase Authentication.
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Bạn chưa đăng nhập bằng Firebase Authentication.');
      }

      final ownerId = user.uid;
      final db = FirebaseFirestore.instance;

      final contracts = db.collection('contracts');
      final tenants = db.collection('tenants');

      // 2. Đọc lại phòng đã chọn từ Firebase.
      // Không dùng giá phòng lấy từ ô nhập làm dữ liệu gốc.
      final roomRef = db.collection('rooms').doc(roomId);
      final roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception('Phòng đã chọn không còn tồn tại trên Firebase.');
      }

      final roomData = roomSnapshot.data()!;
      final roomName = _roomName(roomData);

      if (roomName.isEmpty) {
        throw Exception('Phòng được chọn chưa có mã hoặc tên phòng.');
      }

      // 3. Xác định tài liệu hợp đồng.
      DocumentReference<Map<String, dynamic>> contractRef;

      final existingDocumentId = (widget.contract?['documentId'] ?? '').trim();

      if (existingDocumentId.isNotEmpty) {
        contractRef = contracts.doc(existingDocumentId);

        final existingDoc = await contractRef.get();

        if (!existingDoc.exists) {
          throw Exception(
            'Không tìm thấy hợp đồng cần chỉnh sửa trên Firebase.',
          );
        }

        final existingOwner = existingDoc.data()?['ownerId'];

        if (existingOwner != null && existingOwner != ownerId) {
          throw Exception('Bạn không có quyền chỉnh sửa hợp đồng này.');
        }
      } else {
        final existing = await contracts
            .where('id', isEqualTo: contractId)
            .get();

        final duplicate = existing.docs.any((doc) {
          return doc.data()['ownerId'] == ownerId ||
              doc.data()['ownerId'] == null;
        });

        if (widget.contract == null && duplicate) {
          throw Exception('Số hợp đồng đã tồn tại trên Firebase.');
        }

        if (widget.contract != null && existing.docs.isNotEmpty) {
          contractRef = existing.docs.first.reference;
        } else {
          contractRef = contracts.doc();
        }
      }

      // 4. Chuẩn bị dữ liệu hợp đồng.
      final result = Map<String, String>.from(
        widget.contract ?? <String, String>{},
      );
      final selectedServices = _selectedServicesForSave();
      final members = _membersForSave();

      for (final key in fields.keys) {
        result[key] = fields[key]!.text.trim();
      }
      result['services'] = jsonEncode(selectedServices);
      result['members'] = jsonEncode(members);

      // Luôn lấy thông tin phòng trực tiếp từ Firestore.
      result['room'] = roomName;
      result['roomId'] = roomId;
      result['rent'] = _roomValue(roomData, 'price');
      result['deposit'] = _roomValue(roomData, 'deposit');
      final rentAmount = _roomAmount(roomData, 'price');
      final depositAmount = _roomAmount(roomData, 'deposit');

      if (rentAmount <= 0 || depositAmount < 0) {
        throw Exception('Giá thuê hoặc tiền đặt cọc của phòng không hợp lệ.');
      }

      result['status'] = widget.contract?['status'] ?? 'Còn hiệu lực';
      result['memberRole'] = 'Trưởng phòng';

      // 5. Tìm hồ sơ người thuê.
      QuerySnapshot<Map<String, dynamic>> tenantQuery;

      tenantQuery = await tenants
          .where('ownerId', isEqualTo: ownerId)
          .where('contractId', isEqualTo: contractRef.id)
          .limit(1)
          .get();

      DocumentReference<Map<String, dynamic>> tenantRef;

      if (tenantQuery.docs.isNotEmpty) {
        tenantRef = tenantQuery.docs.first.reference;
      } else {
        final identity = result['identity']?.trim() ?? '';

        if (identity.isNotEmpty) {
          tenantQuery = await tenants
              .where('ownerId', isEqualTo: ownerId)
              .where('identity', isEqualTo: identity)
              .limit(1)
              .get();
        } else {
          // Không ghép người thuê theo một hồ sơ bất kỳ.
          tenantQuery = await tenants
              .where('ownerId', isEqualTo: ownerId)
              .where('contractId', isEqualTo: '__no_match__')
              .limit(1)
              .get();
        }

        if (tenantQuery.docs.isNotEmpty) {
          tenantRef = tenantQuery.docs.first.reference;
        } else {
          tenantRef = tenants.doc();
        }
      }

      // 6. Lưu hợp đồng và hồ sơ người thuê trong cùng một batch.
      final batch = db.batch();

      batch.set(contractRef, {
        ...result,
        'rent': rentAmount,
        'deposit': depositAmount,
        'services': selectedServices,
        'members': members,
        'id': contractId,
        'roomId': roomId,
        'ownerId': ownerId,
        'updatedAt': FieldValue.serverTimestamp(),
        if (widget.contract == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(tenantRef, {
        'ownerId': ownerId,
        'name': result['name'] ?? '',
        'phone': result['phone'] ?? '',
        'email': result['email'] ?? '',
        'identity': result['identity'] ?? '',
        'room': roomName,
        'roomId': roomId,
        'start': result['start'] ?? '',
        'end': result['end'] ?? '',
        'rent': result['rent'] ?? '',
        'deposit': result['deposit'] ?? '',
        'note': result['note'] ?? '',
        'memberRole': 'Trưởng phòng',
        'contractId': contractRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
        if (widget.contract == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      if (!mounted) return;

      result['documentId'] = contractRef.id;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu hợp đồng và hồ sơ người thuê lên Firebase.'),
        ),
      );

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;

      final message = e is FirebaseException && e.code == 'permission-denied'
          ? widget.contract == null
                ? 'Firestore từ chối tạo hợp đồng (permission-denied). '
                      'Kiểm tra người dùng đã đăng nhập, Rules đã deploy và '
                      'rent > 0, deposit >= 0 là kiểu số.'
                : 'Firestore từ chối sửa hợp đồng (permission-denied). '
                      'Kiểm tra Rules đã deploy, tài khoản đã đăng nhập, '
                      'và rent > 0, deposit >= 0 là kiểu số.'
          : 'Lưu dữ liệu thất bại: $e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contract == null ? 'Tạo hợp đồng' : 'Chỉnh sửa hợp đồng',
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // CHỈ BỔ SUNG Ô CHỌN PHÒNG Ở ĐÂY.
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: user == null
                  ? null
                  : FirebaseFirestore.instance.collection('rooms').snapshots(),
              builder: (context, snapshot) {
                if (user == null) {
                  return const Text(
                    'Vui lòng đăng nhập để tải danh sách phòng.',
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Không tải được danh sách phòng: '
                    '${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                roomDocs = docs;

                final currentRoomId = _resolveRoomId();
                if (currentRoomId != null &&
                    requestedRoomServicesRoomId != currentRoomId) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted ||
                        requestedRoomServicesRoomId == currentRoomId) {
                      return;
                    }

                    selectedRoomId = currentRoomId;
                    _loadRoomServices(
                      currentRoomId,
                      contractServices: widget.contract?['services'],
                    );
                  });
                }

                return DropdownButtonFormField<String>(
                  value: currentRoomId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Chọn phòng',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Chọn phòng cần tạo hợp đồng'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn phòng.';
                    }
                    return null;
                  },
                  items: docs.map((doc) {
                    final data = doc.data();
                    final name = _roomName(data);
                    final price = _roomValue(data, 'price');
                    final status = _roomValue(data, 'status');

                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        '$name - $price đ/tháng'
                        '${status.isEmpty ? '' : ' ($status)'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: isSaving ? null : _selectRoom,
                );
              },
            ),

            const SizedBox(height: 16),

            if (_resolveRoomId() != null) _buildRoomServices(),
            _buildMembers(),

            // GIỮ NGUYÊN CÁC TRƯỜNG GIAO DIỆN CŨ.
            for (final key in labels.keys)
              if (key != 'name')
                if (key == 'start' || key == 'end')
                  GestureDetector(
                    onTap: isSaving ? null : () => _pickDate(key),
                    child: AbsorbPointer(
                      child: FormInput(
                        labels[key]!,
                        fields[key]!,
                        number: false,
                        requiredField: true,
                        lines: 1,
                      ),
                    ),
                  )
                else
                  FormInput(
                    labels[key]!,
                    fields[key]!,
                    number: key == 'rent' || key == 'deposit',
                    requiredField: ![
                      'email',
                      'identity',
                      'note',
                      'phone',
                    ].contains(key),
                    lines: key == 'note' ? 3 : 1,
                  ),

            // GIỮ NGUYÊN NÚT LƯU CŨ.
            FilledButton(
              onPressed: isSaving ? null : _save,
              child: Text(isSaving ? 'Đang lưu...' : 'Lưu hợp đồng'),
            ),
          ],
        ),
      ),
    );
  }
}
