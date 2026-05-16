import 'package:flutter/material.dart';

const Color kPrimaryBlue = Color(0xFF3B53D6);
const Color kHintGrey = Color(0xFF7B7F8C);
const Color kFieldBg = Color(0xFFF7F8FC);

InputDecoration authInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: kFieldBg,
    prefixIcon: Icon(icon, color: const Color(0xFF9BA0AD), size: 18),
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE7EAF2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE7EAF2)),
    ),
  );
}

Widget authPrimaryButton({required String text, required VoidCallback onTap}) {
  return SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text),
    ),
  );
}

Widget authSecondaryButton({required String text, required VoidCallback onTap}) {
  return SizedBox(
    width: double.infinity,
    height: 42,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFD8DCE8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black87)),
    ),
  );
}

Widget authDivider(String text) {
  return Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, style: const TextStyle(fontSize: 10, color: kHintGrey)),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

Widget authLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
  );
}
