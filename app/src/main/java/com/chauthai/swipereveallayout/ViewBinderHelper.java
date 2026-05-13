package com.chauthai.swipereveallayout;

import java.util.HashMap;
import java.util.Map;

/**
 * Minimal state binder compatible with the API used by SettingAdapter.
 */
public class ViewBinderHelper {
    private final Map<String, Boolean> openStates = new HashMap<>();
    private boolean openOnlyOne = true;
    private String openKey;

    public void setOpenOnlyOne(boolean openOnlyOne) {
        this.openOnlyOne = openOnlyOne;
    }

    public void bind(final SwipeRevealLayout swipeLayout, final String key) {
        if (swipeLayout == null || key == null) {
            return;
        }

        swipeLayout.clearSwipeListeners();

        boolean shouldOpen = Boolean.TRUE.equals(openStates.get(key));
        swipeLayout.close(false);
        if (shouldOpen) {
            swipeLayout.open(false);
            openKey = key;
        }

        swipeLayout.addSwipeListener(new SwipeRevealLayout.SwipeListener() {
            @Override
            public void onClosed(SwipeRevealLayout view) {
                openStates.put(key, false);
                if (key.equals(openKey)) {
                    openKey = null;
                }
            }

            @Override
            public void onOpened(SwipeRevealLayout view) {
                if (openOnlyOne && openKey != null && !openKey.equals(key)) {
                    openStates.put(openKey, false);
                }
                openStates.put(key, true);
                openKey = key;
            }
        });
    }
}
