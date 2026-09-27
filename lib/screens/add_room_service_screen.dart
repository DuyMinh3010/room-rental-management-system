import 'package:flutter/material.dart';

class AddRoomServiceScreen extends StatefulWidget {
  const AddRoomServiceScreen({super.key});

  @override
  State<AddRoomServiceScreen> createState() =>
      _AddRoomServiceScreenState();
}

class _AddRoomServiceScreenState extends State<AddRoomServiceScreen> {
  String selectedService = 'Internet / Wifi';

  final TextEditingController priceController =
      TextEditingController(text: '100000');

  final List<String> services = [
    'Internet / Wifi',
    'Phí vệ sinh',
    'Tiền điện',
    'Tiền nước',
    'Giữ xe',
  ];

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0D6EFD);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Thêm dịch vụ',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= CHỌN DỊCH VỤ =================
            const Text(
              'Dịch vụ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedService,
                  isExpanded: true,
                  items: services.map((service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Text(service),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedService = value;

                        // Tự điền giá mẫu
                        if (value == 'Internet / Wifi') {
                          priceController.text = '100000';
                        } else if (value == 'Phí vệ sinh') {
                          priceController.text = '50000';
                        } else if (value == 'Tiền điện') {
                          priceController.text = '3500';
                        } else if (value == 'Tiền nước') {
                          priceController.text = '15000';
                        } else if (value == 'Giữ xe') {
                          priceController.text = '100000';
                        }
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= ĐƠN GIÁ =================
            const Text(
              'Đơn giá',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập đơn giá',
                suffixText: 'đ',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ================= NÚT THÊM =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  String price = priceController.text.trim();

                  // Kiểm tra chưa nhập giá
                  if (price.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập đơn giá'),
                      ),
                    );
                    return;
                  }

                  // Trả dữ liệu về màn trước
                  Navigator.pop(
                    context,
                    {
                      'name': selectedService,
                      'price': price,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Thêm dịch vụ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}