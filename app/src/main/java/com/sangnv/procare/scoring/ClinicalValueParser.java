package com.sangnv.procare.scoring;

import java.util.List;

public final class ClinicalValueParser {
    private ClinicalValueParser() {
    }

    public static Integer parseInteger(String value) {
        if (!hasText(value)) {
            return null;
        }
        String digits = value.trim().replaceAll("[^0-9-]", "");
        if (!hasText(digits)) {
            return null;
        }
        try {
            return Integer.parseInt(digits);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    public static Double parseDouble(String value) {
        if (!hasText(value)) {
            return null;
        }
        String normalized = value.trim().replace(',', '.').replaceAll("[^0-9.-]", "");
        if (!hasText(normalized)) {
            return null;
        }
        try {
            return Double.parseDouble(normalized);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    public static boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    public static String joinStrings(List<String> items, String separator) {
        StringBuilder builder = new StringBuilder();
        for (String item : items) {
            if (builder.length() > 0) {
                builder.append(separator);
            }
            builder.append(item);
        }
        return builder.toString();
    }
}
