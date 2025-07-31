import 'package:flutter/material.dart';
import 'custom_text_widget.dart';

class CustomDatePickerField extends StatelessWidget {
  final String label;
  final String? selectedDateText;
  final VoidCallback onTap;
  final bool isRequired;
  final Color? borderColor;
  final Color? backgroundColor;
  final IconData? icon;
  final String? hint;

  const CustomDatePickerField({
    Key? key,
    required this.label,
    required this.selectedDateText,
    required this.onTap,
    this.isRequired = false,
    this.borderColor,
    this.backgroundColor,
    this.icon,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          text: label + (isRequired ? " *" : ""),
          fontSize: 18,
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                .copyWith(right: 0),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    fontSize: 16,
                    text: selectedDateText ?? hint ?? "Datum auswählen",
                    color:
                        selectedDateText != null ? Colors.black : Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: Icon(
                    icon ?? Icons.calendar_today,
                    color: const Color(0xFF6B456A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CustomTimePickerField extends StatelessWidget {
  final String label;
  final String? selectedTimeText;
  final VoidCallback onTap;
  final bool isRequired;
  final Color? borderColor;
  final Color? backgroundColor;
  final IconData? icon;
  final String? hint;

  const CustomTimePickerField({
    Key? key,
    required this.label,
    required this.selectedTimeText,
    required this.onTap,
    this.isRequired = false,
    this.borderColor,
    this.backgroundColor,
    this.icon,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          text: label + (isRequired ? " *" : ""),
          fontSize: 18,
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                .copyWith(right: 0),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
              border: Border.all(
                color: borderColor ??
                    (isRequired &&
                            (selectedTimeText == null ||
                                selectedTimeText!.isEmpty)
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.white),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    fontSize: 16,
                    text: selectedTimeText ?? hint ?? "Zeit auswählen",
                    color:
                        selectedTimeText != null ? Colors.black : Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: Icon(
                    icon ?? Icons.timer,
                    color: const Color(0xFF6B456A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CustomDateTimePickerField extends StatelessWidget {
  final String label;
  final String? selectedDateTimeText;
  final VoidCallback onTap;
  final bool isRequired;
  final Color? borderColor;
  final Color? backgroundColor;
  final IconData? icon;
  final String? hint;

  const CustomDateTimePickerField({
    Key? key,
    required this.label,
    required this.selectedDateTimeText,
    required this.onTap,
    this.isRequired = false,
    this.borderColor,
    this.backgroundColor,
    this.icon,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          text: label + (isRequired ? " *" : ""),
          fontSize: 14,
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                .copyWith(right: 0),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
              border: Border.all(
                color: borderColor ??
                    (isRequired &&
                            (selectedDateTimeText == null ||
                                selectedDateTimeText!.isEmpty)
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.white),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    text: selectedDateTimeText ??
                        hint ??
                        "Datum und Zeit auswählen",
                    color: selectedDateTimeText != null
                        ? Colors.black
                        : Colors.grey.withValues(alpha: 0.6),
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: Icon(
                    icon ?? Icons.event,
                    color: const Color(0xFF6B456A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
