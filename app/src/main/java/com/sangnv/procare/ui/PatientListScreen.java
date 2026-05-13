package com.sangnv.procare.ui;

import android.content.Context;
import android.graphics.Typeface;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.cardview.widget.CardView;

import com.sangnv.procare.Model.ClinicalAssessment;
import com.sangnv.procare.R;
import com.sangnv.procare.news2.News2Scoring;

import java.text.DateFormat;
import java.util.Date;
import java.util.List;

public final class PatientListScreen {
    public interface Listener {
        void onAddNewAssessment();

        void onOpenAssessment(ClinicalAssessment assessment);

        void onViewModeChanged(boolean gridMode);
    }

    private final Context context;
    private final Listener listener;
    private final int colorPrimary;
    private final int colorPrimaryDark;
    private final int colorTextPrimary;
    private final int colorTextSecondary;

    public PatientListScreen(Context context, Listener listener, int colorPrimary, int colorPrimaryDark,
                             int colorTextPrimary, int colorTextSecondary) {
        this.context = context;
        this.listener = listener;
        this.colorPrimary = colorPrimary;
        this.colorPrimaryDark = colorPrimaryDark;
        this.colorTextPrimary = colorTextPrimary;
        this.colorTextSecondary = colorTextSecondary;
    }

    public void render(LinearLayout container, List<ClinicalAssessment> history, boolean gridMode) {
        addHeader(container);
        addModeSwitch(container, gridMode);
        addContent(container, history, gridMode);
    }

    private void addHeader(LinearLayout container) {
        LinearLayout header = new LinearLayout(context);
        header.setOrientation(LinearLayout.VERTICAL);
        header.setPadding(dp(18), dp(16), dp(18), dp(16));
        header.setBackground(ProCareUi.roundedDrawable(android.graphics.Color.WHITE, dp(24), dp(1), android.graphics.Color.rgb(229, 231, 235)));

        TextView eyebrow = new TextView(context);
        eyebrow.setText(R.string.patient_list_eyebrow);
        eyebrow.setTextColor(colorPrimary);
        eyebrow.setTextSize(12);
        eyebrow.setTypeface(Typeface.DEFAULT_BOLD);
        header.addView(eyebrow, matchWrapParams());

        TextView title = new TextView(context);
        title.setText(R.string.patient_list_title);
        title.setTextColor(colorTextPrimary);
        title.setTextSize(24);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setPadding(0, dp(4), 0, 0);
        header.addView(title, matchWrapParams());

        TextView subtitle = new TextView(context);
        subtitle.setText(R.string.patient_list_subtitle);
        subtitle.setTextColor(colorTextSecondary);
        subtitle.setTextSize(14);
        subtitle.setLineSpacing(dp(2), 1.0f);
        subtitle.setPadding(0, dp(6), 0, dp(14));
        header.addView(subtitle, matchWrapParams());

        Button addButton = new Button(context);
        addButton.setText(R.string.patient_list_add_new);
        ProCareUi.stylePrimaryButton(context, addButton, true, colorPrimary, colorPrimaryDark);
        addButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listener.onAddNewAssessment();
            }
        });
        header.addView(addButton, matchWrapParams());

        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, 0, 0, dp(12));
        container.addView(header, params);
    }

    private void addModeSwitch(LinearLayout container, boolean gridMode) {
        LinearLayout switcher = new LinearLayout(context);
        switcher.setOrientation(LinearLayout.HORIZONTAL);
        switcher.setPadding(0, dp(4), 0, dp(12));

        Button gridButton = new Button(context);
        gridButton.setText(R.string.patient_list_grid_mode);
        ProCareUi.stylePrimaryButton(context, gridButton, gridMode, colorPrimary, colorPrimaryDark);
        gridButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listener.onViewModeChanged(true);
            }
        });
        Button listButton = new Button(context);
        listButton.setText(R.string.patient_list_list_mode);
        ProCareUi.stylePrimaryButton(context, listButton, !gridMode, colorPrimary, colorPrimaryDark);
        listButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listener.onViewModeChanged(false);
            }
        });
        LinearLayout.LayoutParams leftParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        leftParams.setMargins(0, 0, dp(6), 0);
        LinearLayout.LayoutParams rightParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        rightParams.setMargins(dp(6), 0, 0, 0);
        switcher.addView(gridButton, leftParams);
        switcher.addView(listButton, rightParams);
        container.addView(switcher, matchWrapParams());
    }

    private void addContent(LinearLayout container, List<ClinicalAssessment> history, boolean gridMode) {
        if (history.isEmpty()) {
            TextView empty = new TextView(context);
            empty.setText(R.string.patient_list_empty);
            empty.setTextColor(android.graphics.Color.rgb(75, 85, 99));
            empty.setTextSize(15);
            empty.setGravity(android.view.Gravity.CENTER);
            empty.setPadding(dp(18), dp(28), dp(18), dp(28));
            empty.setBackground(ProCareUi.roundedDrawable(android.graphics.Color.WHITE, dp(22), dp(1), android.graphics.Color.rgb(229, 231, 235)));
            container.addView(empty, matchWrapParams());
            return;
        }
        if (gridMode) {
            addGrid(container, history);
        } else {
            for (int i = history.size() - 1; i >= 0; i--) {
                container.addView(createCard(history.get(i), i + 1, false), matchWrapParamsWithMargins(0, 0, 0, dp(10)));
            }
        }
    }

    private void addGrid(LinearLayout container, List<ClinicalAssessment> history) {
        LinearLayout row = null;
        int cellIndex = 0;
        for (int i = history.size() - 1; i >= 0; i--) {
            if (cellIndex % 2 == 0) {
                row = new LinearLayout(context);
                row.setOrientation(LinearLayout.HORIZONTAL);
                container.addView(row, matchWrapParamsWithMargins(0, 0, 0, dp(10)));
            }
            LinearLayout.LayoutParams cellParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
            cellParams.setMargins(cellIndex % 2 == 0 ? 0 : dp(6), 0, cellIndex % 2 == 0 ? dp(6) : 0, 0);
            row.addView(createCard(history.get(i), i + 1, true), cellParams);
            cellIndex++;
        }
        if (cellIndex % 2 == 1 && row != null) {
            TextView spacer = new TextView(context);
            LinearLayout.LayoutParams spacerParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
            spacerParams.setMargins(dp(6), 0, 0, 0);
            row.addView(spacer, spacerParams);
        }
    }

    private View createCard(ClinicalAssessment item, int number, boolean compact) {
        CardView cardView = new CardView(context);
        cardView.setCardBackgroundColor(android.graphics.Color.WHITE);
        cardView.setRadius(dp(22));
        cardView.setCardElevation(dp(1));
        cardView.setUseCompatPadding(true);
        cardView.setClickable(true);
        cardView.setFocusable(true);
        cardView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listener.onOpenAssessment(item);
            }
        });
        LinearLayout card = new LinearLayout(context);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(14), dp(14), dp(14), dp(14));

        TextView title = new TextView(context);
        title.setText(displayName(item, number));
        title.setTextColor(colorTextPrimary);
        title.setTextSize(compact ? 15 : 17);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        card.addView(title, matchWrapParams());

        TextView score = new TextView(context);
        score.setText(context.getString(R.string.patient_list_score_format, item.news2Total, riskText(item)));
        score.setTextColor(News2Scoring.riskColor(item));
        score.setTextSize(compact ? 13 : 14);
        score.setTypeface(Typeface.DEFAULT_BOLD);
        score.setPadding(0, dp(8), 0, 0);
        card.addView(score, matchWrapParams());

        TextView meta = new TextView(context);
        meta.setText(item.savedAtMillis > 0
                ? context.getString(R.string.patient_summary_saved_format, DateFormat.getDateTimeInstance().format(new Date(item.savedAtMillis)))
                : context.getString(R.string.patient_list_unsaved_time));
        meta.setTextColor(android.graphics.Color.rgb(107, 114, 128));
        meta.setTextSize(12);
        meta.setPadding(0, dp(8), 0, 0);
        card.addView(meta, matchWrapParams());

        cardView.addView(card, matchWrapParams());
        return cardView;
    }

    private String displayName(ClinicalAssessment item, int number) {
        if (hasText(item.fullName) && hasText(item.patientId)) {
            return context.getString(R.string.patient_summary_name_with_id, item.fullName.trim(), item.patientId.trim());
        }
        if (hasText(item.fullName)) {
            return item.fullName.trim();
        }
        if (hasText(item.patientId)) {
            return context.getString(R.string.patient_summary_id_only, item.patientId.trim());
        }
        return context.getString(R.string.patient_list_generated_name, number);
    }

    private String riskText(ClinicalAssessment item) {
        if (item.news2Total >= 7) {
            return context.getString(R.string.news2_risk_emergency);
        }
        if (item.news2Total >= 5) {
            return context.getString(R.string.news2_risk_urgent);
        }
        if (News2Scoring.hasSingleThreeScore(item)) {
            return context.getString(R.string.news2_risk_single_three);
        }
        if (item.news2Total == 0) {
            return context.getString(R.string.news2_risk_low_zero);
        }
        return context.getString(R.string.news2_risk_low);
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private int dp(int value) {
        return ProCareUi.dp(context, value);
    }

    private LinearLayout.LayoutParams matchWrapParams() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private LinearLayout.LayoutParams matchWrapParamsWithMargins(int left, int top, int right, int bottom) {
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(left, top, right, bottom);
        return params;
    }
}
