part of 'home_screen.dart';

enum _HomeMode {
  list,
  form,
}

class _PatientScrollBubbleState {
  final bool visible;
  final String label;
  final double fraction;

  const _PatientScrollBubbleState({
    required this.visible,
    required this.label,
    required this.fraction,
  });

  const _PatientScrollBubbleState.hidden()
      : visible = false,
        label = '',
        fraction = 0;
}

class _FullWidth extends StatelessWidget {
  final Widget child;

  const _FullWidth({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _ScoreItem {
  final String label;
  final int score;
  final bool completed;

  const _ScoreItem(
    this.label,
    this.score, {
    required this.completed,
  });
}

class _QuickScoreOption {
  final String label;
  final int score;

  const _QuickScoreOption(this.label, this.score);
}

class _QuickChoiceOption {
  final String label;
  final String value;
  final String helper;

  const _QuickChoiceOption(this.label, this.value, this.helper);
}

// Top-level constants lifted from _HomeScreenState.
const _androidFileChannel = MethodChannel('news2_l/android_files');
final _integerInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
];
final _decimalInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
];
final _dateInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9/-]')),
];
final _timeInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
];

// Top-level helpers lifted from _HomeScreenState.
String _lactateLevel(String value) {
  final lactate = ClinicalValueParser.parseDouble(value);
  if (lactate == null) {
    return '';
  }
  if (lactate < 2) {
    return '< 2 mmol/L';
  }
  if (lactate < 4) {
    return '2 - 3.9 mmol/L';
  }
  return '≥ 4 mmol/L';
}

String _two(int value) => value.toString().padLeft(2, '0');
