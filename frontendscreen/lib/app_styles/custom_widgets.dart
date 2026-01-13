import 'package:flutter/material.dart';
import 'color_constants.dart';
 
/// حقل نصي قابل لإعادة الاستخدام
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Function(String)? onChanged;
  final VoidCallback? toggleVisibility; // لتفعيل إظهار/إخفاء الباسورد
  final Key? fieldKey;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
 
  const CustomTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.onChanged,
    this.toggleVisibility,
    this.fieldKey,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    super.key,
  });
 
  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      readOnly: readOnly, 
      onTap: onTap, 
      keyboardType: keyboardType, 
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: ColorConstants.primaryColor),
        suffixIcon: toggleVisibility != null
            ? InkWell(
                onTap: toggleVisibility,
                child: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: ColorConstants.primaryColor,
                ),
              )
            : null,
        hintText: hintText,
        filled: true,
        fillColor: ColorConstants.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
 
/// زر قابل لإعادة الاستخدام
class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final bool isWhiteText;
  final Key? buttonKey;
 
  const CustomButton({
    required this.title,
    required this.onTap,
    required this.backgroundColor,
    this.isWhiteText = false,
    this.buttonKey,
    super.key,
  });
 
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: buttonKey,
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isWhiteText
              ? ColorConstants.white
              : ColorConstants.accentColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
 