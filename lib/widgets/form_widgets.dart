import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const InfoCard({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const InfoLine(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? 'Chưa cập nhật' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FormInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool number;
  final bool requiredField;
  final bool password;
  final int lines;
  const FormInput(
    this.label,
    this.controller, {
    super.key,
    this.number = false,
    this.requiredField = true,
    this.password = false,
    this.lines = 1,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  if (requiredField)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFB60F0F)),
                    ),
                ],
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: password,
            maxLines: lines,
            keyboardType: number ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Color(0xFF111827), fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
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
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.4,
                ),
              ),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (requiredField && text.isEmpty) return 'Vui lòng nhập $label';
              if (number &&
                  text.isNotEmpty &&
                  (int.tryParse(text) == null || int.parse(text) < 0)) {
                return 'Vui lòng nhập số không âm';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
