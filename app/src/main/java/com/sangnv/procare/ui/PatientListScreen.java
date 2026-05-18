package com.sangnv.procare.ui;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.KeyEvent;
import android.view.Gravity;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.cardview.widget.CardView;

import com.sangnv.procare.Model.ClinicalAssessment;
import com.sangnv.procare.R;
import com.sangnv.procare.news2.News2Scoring;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public final class PatientListScreen {
    public static final int SORT_CREATED_RECENT = 0;
    public static final int SORT_MODIFIED_RECENT = 1;

    public interface Listener {
        void onAddNewAssessment();

        void onOpenAssessment(ClinicalAssessment assessment);

        void onSearchChanged(String query);

        void onViewModeChanged(boolean gridMode);

        void onSortModeChanged(int sortMode);

        void onExportPdf(ClinicalAssessment assessment);

        void onExportDocx(ClinicalAssessment assessment);
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

    public void render(LinearLayout container, List<ClinicalAssessment> history, boolean gridMode,
                       String searchQuery, int sortMode) {
        addKeepToolbar(container, gridMode, searchQuery, sortMode);
        addContent(container, visibleAssessments(history, searchQuery, sortMode), gridMode);
    }

    private void addKeepToolbar(LinearLayout container, boolean gridMode, String searchQuery, int sortMode) {
        LinearLayout toolbar = new LinearLayout(context);
        toolbar.setOrientation(LinearLayout.HORIZONTAL);
        toolbar.setGravity(Gravity.CENTER_VERTICAL);
        toolbar.setPadding(dp(10), dp(8), dp(10), dp(8));
        toolbar.setBackground(ProCareUi.roundedDrawable(Color.WHITE, dp(32), 0, Color.TRANSPARENT));

        TextView menu = toolbarIcon("☰", 26);
        toolbar.addView(menu, new LinearLayout.LayoutParams(dp(42), dp(48)));

        EditText search = new EditText(context);
        search.setSingleLine(true);
        search.setImeOptions(EditorInfo.IME_ACTION_SEARCH);
        search.setText(searchQuery == null ? "" : searchQuery);
        search.setHint(R.string.patient_list_search_hint);
        search.setTextColor(colorTextPrimary);
        search.setHintTextColor(Color.rgb(107, 114, 128));
        search.setTextSize(17);
        search.setPadding(dp(8), 0, dp(8), 0);
        search.setBackgroundColor(Color.TRANSPARENT);
        search.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                if (actionId == EditorInfo.IME_ACTION_SEARCH
                        || (event != null && event.getKeyCode() == KeyEvent.KEYCODE_ENTER)) {
                    listener.onSearchChanged(v.getText().toString());
                    return true;
                }
                return false;
            }
        });
        toolbar.addView(search, new LinearLayout.LayoutParams(0, dp(48), 1));

        TextView viewMode = toolbarIcon(gridMode ? "▤" : "▦", 27);
        viewMode.setContentDescription(context.getString(gridMode
                ? R.string.patient_list_list_mode
                : R.string.patient_list_grid_mode));
        viewMode.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listener.onViewModeChanged(!gridMode);
            }
        });
        toolbar.addView(viewMode, new LinearLayout.LayoutParams(dp(46), dp(48)));

        TextView sort = toolbarIcon(sortMode == SORT_CREATED_RECENT ? "↕" : "⇅", 28);
        sort.setContentDescription(context.getString(R.string.patient_list_sort_button));
        sort.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listener.onSortModeChanged(sortMode == SORT_CREATED_RECENT ? SORT_MODIFIED_RECENT : SORT_CREATED_RECENT);
            }
        });
        toolbar.addView(sort, new LinearLayout.LayoutParams(dp(46), dp(48)));

        LinearLayout.LayoutParams toolbarParams = matchWrapParams();
        toolbarParams.setMargins(0, 0, 0, dp(18));
        container.addView(toolbar, toolbarParams);

        TextView sortLabel = new TextView(context);
        sortLabel.setText(sortMode == SORT_CREATED_RECENT
                ? R.string.patient_list_sort_created_recent
                : R.string.patient_list_sort_modified_recent);
        sortLabel.setTextColor(colorTextSecondary);
        sortLabel.setTextSize(13);
        sortLabel.setPadding(dp(6), 0, 0, dp(12));
        container.addView(sortLabel, matchWrapParams());
    }

    private TextView toolbarIcon(String text, int textSize) {
        TextView icon = new TextView(context);
        icon.setText(text);
        icon.setTextColor(Color.rgb(55, 65, 81));
        icon.setTextSize(textSize);
        icon.setGravity(Gravity.CENTER);
        icon.setTypeface(Typeface.DEFAULT_BOLD);
        icon.setClickable(true);
        icon.setFocusable(true);
        return icon;
    }

    private TextView exportButton(String text) {
        TextView button = new TextView(context);
        button.setText(text);
        button.setTextColor(colorPrimaryDark);
        button.setTextSize(12);
        button.setTypeface(Typeface.DEFAULT_BOLD);
        button.setGravity(Gravity.CENTER);
        button.setPadding(dp(8), dp(7), dp(8), dp(7));
        button.setBackground(ProCareUi.roundedDrawable(Color.rgb(239, 246, 255), dp(12), dp(1), Color.rgb(191, 219, 254)));
        button.setClickable(true);
        button.setFocusable(true);
        return button;
    }

    private List<ClinicalAssessment> visibleAssessments(List<ClinicalAssessment> history, String searchQuery, int sortMode) {
        List<ClinicalAssessment> visible = new ArrayList<>();
        String normalizedQuery = searchQuery == null ? "" : searchQuery.trim().toLowerCase(Locale.getDefault());
        for (ClinicalAssessment item : history) {
            if (normalizedQuery.isEmpty() || searchableText(item).contains(normalizedQuery)) {
                visible.add(item);
            }
        }
        Collections.sort(visible, new Comparator<ClinicalAssessment>() {
            @Override
            public int compare(ClinicalAssessment left, ClinicalAssessment right) {
                long rightTime = sortMode == SORT_CREATED_RECENT ? createdTime(right) : modifiedTime(right);
                long leftTime = sortMode == SORT_CREATED_RECENT ? createdTime(left) : modifiedTime(left);
                return Long.compare(rightTime, leftTime);
            }
        });
        return visible;
    }

    private String searchableText(ClinicalAssessment item) {
        return (safe(item.fullName) + " " + safe(item.patientId) + " " + safe(item.admissionDateTime) + " "
                + safe(item.admissionReason) + " " + safe(item.infectionOrgan) + " " + safe(item.suspectedInfection))
                .toLowerCase(Locale.getDefault());
    }

    private void addContent(LinearLayout container, List<ClinicalAssessment> history, boolean gridMode) {
        if (history.isEmpty()) {
            TextView empty = new TextView(context);
            empty.setText(R.string.patient_list_empty);
            empty.setTextColor(Color.rgb(75, 85, 99));
            empty.setTextSize(15);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(dp(18), dp(28), dp(18), dp(28));
            empty.setBackground(ProCareUi.roundedDrawable(Color.WHITE, dp(22), dp(1), Color.rgb(229, 231, 235)));
            container.addView(empty, matchWrapParams());
            return;
        }
        if (gridMode) {
            addGrid(container, history);
        } else {
            for (int i = 0; i < history.size(); i++) {
                View card = createCard(history.get(i), i + 1, false);
                card.setTag(dateBubbleText(history.get(i)));
                container.addView(card, matchWrapParamsWithMargins(0, 0, 0, dp(10)));
            }
        }
    }

    private void addGrid(LinearLayout container, List<ClinicalAssessment> history) {
        LinearLayout row = null;
        for (int i = 0; i < history.size(); i++) {
            if (i % 2 == 0) {
                row = new LinearLayout(context);
                row.setOrientation(LinearLayout.HORIZONTAL);
                row.setTag(dateBubbleText(history.get(i)));
                container.addView(row, matchWrapParamsWithMargins(0, 0, 0, dp(10)));
            }
            LinearLayout.LayoutParams cellParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
            cellParams.setMargins(i % 2 == 0 ? 0 : dp(6), 0, i % 2 == 0 ? dp(6) : 0, 0);
            row.addView(createCard(history.get(i), i + 1, true), cellParams);
        }
        if (history.size() % 2 == 1 && row != null) {
            TextView spacer = new TextView(context);
            LinearLayout.LayoutParams spacerParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
            spacerParams.setMargins(dp(6), 0, 0, 0);
            row.addView(spacer, spacerParams);
        }
    }

    private View createCard(ClinicalAssessment item, int number, boolean compact) {
        CardView cardView = new CardView(context);
        cardView.setCardBackgroundColor(Color.WHITE);
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

        TextView details = new TextView(context);
        details.setText(summaryText(item, compact));
        details.setTextColor(colorTextSecondary);
        details.setTextSize(compact ? 13 : 14);
        details.setLineSpacing(dp(2), 1.0f);
        details.setPadding(0, dp(16), 0, dp(14));
        card.addView(details, matchWrapParams());

        TextView score = new TextView(context);
        score.setText(context.getString(R.string.patient_list_score_format, item.news2Total, riskText(item)));
        score.setTextColor(News2Scoring.riskColor(item));
        score.setTextSize(13);
        score.setTypeface(Typeface.DEFAULT_BOLD);
        score.setPadding(dp(10), dp(6), dp(10), dp(6));
        score.setBackground(ProCareUi.roundedDrawable(Color.rgb(243, 244, 246), dp(12), 0, Color.TRANSPARENT));
        card.addView(score, wrapParams());

        LinearLayout exportActions = new LinearLayout(context);
        exportActions.setOrientation(LinearLayout.HORIZONTAL);
        exportActions.setPadding(0, dp(10), 0, 0);
        TextView pdfButton = exportButton("PDF");
        pdfButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listener.onExportPdf(item);
            }
        });
        TextView docxButton = exportButton("DOCX");
        docxButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listener.onExportDocx(item);
            }
        });
        LinearLayout.LayoutParams pdfParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        pdfParams.setMargins(0, 0, dp(5), 0);
        LinearLayout.LayoutParams docxParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        docxParams.setMargins(dp(5), 0, 0, 0);
        exportActions.addView(pdfButton, pdfParams);
        exportActions.addView(docxButton, docxParams);
        card.addView(exportActions, matchWrapParams());

        cardView.addView(card, matchWrapParams());
        return cardView;
    }

    private String summaryText(ClinicalAssessment item, boolean compact) {
        StringBuilder builder = new StringBuilder();
        if (hasText(item.admissionDateTime)) {
            builder.append(item.admissionDateTime.trim()).append('\n');
        }
        String admissionReason = hasText(item.admissionReason) ? item.admissionReason : "";
        String infectionOrgan = hasText(item.infectionOrgan) ? item.infectionOrgan : item.suspectedInfection;
        if (hasText(admissionReason)) {
            builder.append(admissionReason.trim()).append('\n');
        }
        if (hasText(infectionOrgan)) {
            builder.append(infectionOrgan.trim()).append('\n');
        }
        builder.append(context.getString(R.string.patient_summary_saved_format,
                DateFormat.getDateTimeInstance(DateFormat.SHORT, DateFormat.SHORT).format(new Date(modifiedTime(item)))));
        if (!compact) {
            builder.append('\n').append(context.getString(R.string.patient_list_created_format,
                    DateFormat.getDateTimeInstance(DateFormat.SHORT, DateFormat.SHORT).format(new Date(createdTime(item)))));
        }
        return builder.toString();
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

    private String dateBubbleText(ClinicalAssessment item) {
        return new SimpleDateFormat("dd/MM", Locale.getDefault()).format(new Date(modifiedTime(item)));
    }

    private long createdTime(ClinicalAssessment item) {
        if (item.createdAtMillis > 0) {
            return item.createdAtMillis;
        }
        return item.savedAtMillis > 0 ? item.savedAtMillis : modifiedTime(item);
    }

    private long modifiedTime(ClinicalAssessment item) {
        if (item.modifiedAtMillis > 0) {
            return item.modifiedAtMillis;
        }
        return item.savedAtMillis > 0 ? item.savedAtMillis : System.currentTimeMillis();
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

    private String safe(String value) {
        return value == null ? "" : value;
    }

    private int dp(int value) {
        return ProCareUi.dp(context, value);
    }

    private LinearLayout.LayoutParams matchWrapParams() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private LinearLayout.LayoutParams wrapParams() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private LinearLayout.LayoutParams matchWrapParamsWithMargins(int left, int top, int right, int bottom) {
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(left, top, right, bottom);
        return params;
    }
}
