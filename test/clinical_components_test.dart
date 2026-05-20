import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/domain/assessment_display.dart';
import 'package:news2_l/src/ui/clinical_components.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('ClinicalSummaryCard renders missing and complete states',
      (tester) async {
    await tester.pumpWidget(wrap(const ClinicalSummaryCard(
      display: ScoreDisplay(
        title: 'NEWS2',
        scoreText: '-',
        status: ClinicalStatus.missing,
        statusLabel: 'Chưa đủ dữ liệu',
        helperText: 'Thiếu 5/7 tiêu chí',
        completedCount: 2,
        totalCount: 7,
      ),
    )));

    expect(find.text('NEWS2'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('Chưa đủ dữ liệu'), findsOneWidget);
    expect(find.text('Thiếu 5/7 tiêu chí'), findsOneWidget);
  });

  testWidgets('StatusBadge renders label', (tester) async {
    await tester.pumpWidget(wrap(const StatusBadge(
      status: ClinicalStatus.warning,
      label: 'Nguy cơ cao',
    )));

    expect(find.text('Nguy cơ cao'), findsOneWidget);
  });

  testWidgets('MissingDataPanel invokes callback for item', (tester) async {
    MissingDataItem? tapped;
    const item = MissingDataItem(
      id: 'rr',
      label: 'Nhịp thở',
      sectionId: 'news2',
      fieldId: 'news2Respiration',
      groupLabel: 'NEWS2/qSOFA',
    );

    await tester.pumpWidget(wrap(MissingDataPanel(
      items: const [item],
      onItemTap: (value) => tapped = value,
    )));
    await tester.tap(find.text('Nhịp thở'));

    expect(tapped?.id, 'rr');
  });

  testWidgets('FormSectionAccordion shows progress text', (tester) async {
    await tester.pumpWidget(wrap(const FormSectionAccordion(
      title: 'Sinh hiệu NEWS2',
      progress: SectionProgress(
        sectionId: 'news2',
        completedCount: 3,
        totalCount: 7,
        missingLabels: ['SpO2'],
      ),
      children: [Text('body')],
    )));

    expect(find.text('Sinh hiệu NEWS2'), findsOneWidget);
    expect(find.text('3/7'), findsOneWidget);
    expect(find.textContaining('SpO2'), findsOneWidget);
  });

  testWidgets('MedicalInputField renders warning text', (tester) async {
    await tester.pumpWidget(wrap(MedicalInputField(
      label: 'Nhịp tim',
      value: '230',
      onChanged: (_) {},
      unit: 'lần/phút',
      warningText: 'Nhịp tim ngoài khoảng thường gặp',
    )));

    expect(find.text('Nhịp tim'), findsOneWidget);
    expect(find.text('Nhịp tim ngoài khoảng thường gặp'), findsOneWidget);
  });

  testWidgets('MedicalInputField cycles between multiple unit options',
      (tester) async {
    var selectedUnit = 'mg/dL';

    await tester.pumpWidget(wrap(StatefulBuilder(
      builder: (context, setState) {
        return MedicalInputField(
          label: 'Bilirubin',
          value: '',
          onChanged: (_) {},
          unitOptions: const ['mg/dL', 'µmol/L'],
          selectedUnit: selectedUnit,
          onUnitChanged: (value) => setState(() => selectedUnit = value),
        );
      },
    )));

    expect(find.widgetWithText(TextButton, 'mg/dL'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'mg/dL'));
    await tester.pump();

    expect(find.widgetWithText(TextButton, 'µmol/L'), findsOneWidget);
  });

  testWidgets('MedicalInputField shows disabled button for single unit',
      (tester) async {
    await tester.pumpWidget(wrap(MedicalInputField(
      label: 'Huyết áp',
      value: '120',
      onChanged: (_) {},
      unitOptions: const ['mmHg'],
    )));

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'mmHg'),
    );

    expect(button.onPressed, isNull);
  });
}
