import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final Color? fillColor;
  final bool? filled;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final String? helperText;
  final Key? fieldKey;

  const AuthTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.readOnly = false,
    this.fillColor,
    this.filled,
    this.onChanged,
    this.suffixIcon,
    this.helperText,
    this.fieldKey,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        border: const OutlineInputBorder(),
        filled: widget.filled,
        fillColor: widget.fillColor,
        helperText: widget.helperText,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
      ),
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      readOnly: widget.readOnly,
      onChanged: widget.onChanged,
    );
  }
}
