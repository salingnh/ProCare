package com.sangnv.procare.ui;

import android.content.Context;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;
import android.widget.Button;

import com.sangnv.procare.news2.News2Scoring;

public final class ProCareUi {
    private ProCareUi() {
    }

    public static int dp(Context context, int value) {
        return (int) (value * context.getResources().getDisplayMetrics().density + 0.5f);
    }

    public static int systemBarDimension(Context context, String name) {
        int resourceId = context.getResources().getIdentifier(name, "dimen", "android");
        return resourceId > 0 ? context.getResources().getDimensionPixelSize(resourceId) : 0;
    }

    public static GradientDrawable roundedDrawable(int color, int radius, int strokeWidth, int strokeColor) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(radius);
        if (strokeWidth > 0) {
            drawable.setStroke(strokeWidth, strokeColor);
        }
        return drawable;
    }

    public static StateListDrawable checkedBackground(int checkedColor, int uncheckedColor, int checkedStroke, int uncheckedStroke, int radius, int strokeWidth) {
        StateListDrawable drawable = new StateListDrawable();
        drawable.addState(new int[]{android.R.attr.state_checked}, roundedDrawable(checkedColor, radius, strokeWidth, checkedStroke));
        drawable.addState(new int[]{}, roundedDrawable(uncheckedColor, radius, strokeWidth, uncheckedStroke));
        return drawable;
    }

    public static ColorStateList optionTintList(int primaryColor) {
        return new ColorStateList(
                new int[][]{new int[]{android.R.attr.state_checked}, new int[]{}},
                new int[]{primaryColor, Color.rgb(148, 163, 184)});
    }

    public static void stylePrimaryButton(Context context, Button button, boolean filled, int primaryColor, int primaryDarkColor) {
        button.setAllCaps(false);
        button.setTextSize(15);
        button.setTypeface(Typeface.DEFAULT_BOLD);
        button.setTextColor(filled ? Color.WHITE : primaryDarkColor);
        button.setPadding(dp(context, 12), dp(context, 10), dp(context, 12), dp(context, 10));
        int backgroundColor = filled ? primaryColor : Color.rgb(239, 246, 255);
        int strokeColor = filled ? primaryColor : Color.rgb(191, 219, 254);
        button.setBackground(roundedDrawable(backgroundColor, dp(context, 16), dp(context, 1), strokeColor));
    }

    public static int scoreAccentColor(int score) {
        switch (score) {
            case 0:
                return News2Scoring.COLOR_SUCCESS;
            case 1:
                return News2Scoring.COLOR_WARNING;
            case 2:
                return News2Scoring.COLOR_ORANGE;
            case 3:
                return News2Scoring.COLOR_DANGER;
            default:
                return Color.rgb(209, 213, 219);
        }
    }

    public static int scoreSoftColor(int score) {
        switch (score) {
            case 0:
                return Color.rgb(236, 253, 245);
            case 1:
                return Color.rgb(254, 252, 232);
            case 2:
                return Color.rgb(255, 247, 237);
            case 3:
                return Color.rgb(254, 242, 242);
            default:
                return Color.WHITE;
        }
    }
}
