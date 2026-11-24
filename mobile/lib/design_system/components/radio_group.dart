import 'package:flutter/material.dart';

import '../tokens/typography.dart';
import 'radio_card.dart';

class DSRadioOption {
  final String value;
  final Widget content;
  final bool disabled;
  const DSRadioOption(this.value, this.content, {this.disabled = false});
}

/// RadioGroup — labelled set of DSRadioCards presented as a single-choice
/// group (e.g. "I am a…" Student/Teacher). Whole tile is the hit area.
/// [columns] defaults to 2 (role-picker style); pass 1 for stacked lists.
class DSRadioGroup extends StatelessWidget {
  final String? label;
  final List<DSRadioOption> options;
  final String value;
  final ValueChanged<String> onChanged;
  final int columns;

  const DSRadioGroup({
    super.key,
    this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: DSText.label),
          const SizedBox(height: 6),
        ],
        if (columns <= 1)
          Column(
            children: [
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DSRadioCard(
                    selected: value == o.value,
                    disabled: o.disabled,
                    onSelect: () => onChanged(o.value),
                    child: o.content,
                  ),
                ),
            ],
          )
        else
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2,
            children: [
              for (final o in options)
                DSRadioCard(
                  selected: value == o.value,
                  disabled: o.disabled,
                  onSelect: () => onChanged(o.value),
                  child: o.content,
                ),
            ],
          ),
      ],
    );
  }
}
