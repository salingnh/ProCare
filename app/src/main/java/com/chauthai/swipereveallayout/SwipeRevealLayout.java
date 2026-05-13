package com.chauthai.swipereveallayout;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.widget.FrameLayout;

import java.util.ArrayList;
import java.util.List;

/**
 * Lightweight replacement for the old swipe-reveal-layout dependency.
 *
 * <p>The layout expects the first child to contain the action buttons and the last child to be the
 * foreground content. Swiping the foreground content to the left reveals the action buttons.</p>
 */
public class SwipeRevealLayout extends FrameLayout {
    public interface SwipeListener {
        void onClosed(SwipeRevealLayout view);

        void onOpened(SwipeRevealLayout view);
    }

    private final List<SwipeListener> swipeListeners = new ArrayList<>();
    private final int touchSlop;

    private float downX;
    private float downY;
    private float startTranslationX;
    private boolean dragging;
    private boolean opened;
    private boolean lockDrag;

    public SwipeRevealLayout(Context context) {
        this(context, null);
    }

    public SwipeRevealLayout(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public SwipeRevealLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        touchSlop = ViewConfiguration.get(context).getScaledTouchSlop();
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();
        View frontView = getFrontView();
        if (frontView != null) {
            frontView.bringToFront();
        }
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        if (lockDrag || getActionWidth() == 0) {
            return super.onInterceptTouchEvent(event);
        }

        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                downX = event.getX();
                downY = event.getY();
                startTranslationX = getFrontTranslationX();
                dragging = false;
                break;
            case MotionEvent.ACTION_MOVE:
                float dx = event.getX() - downX;
                float dy = event.getY() - downY;
                if (Math.abs(dx) > touchSlop && Math.abs(dx) > Math.abs(dy)) {
                    dragging = true;
                    if (getParent() != null) {
                        getParent().requestDisallowInterceptTouchEvent(true);
                    }
                    return true;
                }
                break;
            case MotionEvent.ACTION_CANCEL:
            case MotionEvent.ACTION_UP:
                dragging = false;
                break;
            default:
                break;
        }
        return super.onInterceptTouchEvent(event);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (lockDrag || getActionWidth() == 0) {
            return super.onTouchEvent(event);
        }

        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                downX = event.getX();
                downY = event.getY();
                startTranslationX = getFrontTranslationX();
                return true;
            case MotionEvent.ACTION_MOVE:
                float dx = event.getX() - downX;
                float dy = event.getY() - downY;
                if (!dragging && Math.abs(dx) > touchSlop && Math.abs(dx) > Math.abs(dy)) {
                    dragging = true;
                    if (getParent() != null) {
                        getParent().requestDisallowInterceptTouchEvent(true);
                    }
                }
                if (dragging) {
                    setRevealAmount(-(startTranslationX + dx));
                    return true;
                }
                break;
            case MotionEvent.ACTION_UP:
                if (dragging) {
                    settle();
                    dragging = false;
                    return true;
                }
                if (opened) {
                    close(true);
                    return true;
                }
                break;
            case MotionEvent.ACTION_CANCEL:
                if (dragging) {
                    settle();
                    dragging = false;
                    return true;
                }
                break;
            default:
                break;
        }
        return super.onTouchEvent(event);
    }

    public void open(boolean animate) {
        updateOpenState(true, animate);
    }

    public void close(boolean animate) {
        updateOpenState(false, animate);
    }

    public boolean isOpened() {
        return opened;
    }

    public void setLockDrag(boolean lockDrag) {
        this.lockDrag = lockDrag;
    }

    public void addSwipeListener(SwipeListener listener) {
        if (listener != null && !swipeListeners.contains(listener)) {
            swipeListeners.add(listener);
        }
    }

    public void clearSwipeListeners() {
        swipeListeners.clear();
    }

    private void settle() {
        updateOpenState(getRevealAmount() > getActionWidth() / 2f, true);
    }

    private void updateOpenState(boolean open, boolean animate) {
        opened = open;
        float targetTranslation = open ? -getActionWidth() : 0f;
        View frontView = getFrontView();
        if (frontView == null) {
            return;
        }

        if (animate) {
            frontView.animate().translationX(targetTranslation).setDuration(180L).start();
        } else {
            frontView.setTranslationX(targetTranslation);
        }

        for (SwipeListener listener : swipeListeners) {
            if (open) {
                listener.onOpened(this);
            } else {
                listener.onClosed(this);
            }
        }
    }

    private void setRevealAmount(float amount) {
        View frontView = getFrontView();
        if (frontView == null) {
            return;
        }
        float clampedAmount = Math.max(0f, Math.min(amount, getActionWidth()));
        frontView.setTranslationX(-clampedAmount);
        opened = clampedAmount == getActionWidth();
    }

    private float getRevealAmount() {
        return -getFrontTranslationX();
    }

    private float getFrontTranslationX() {
        View frontView = getFrontView();
        return frontView == null ? 0f : frontView.getTranslationX();
    }

    private int getActionWidth() {
        View backView = getBackView();
        return backView == null ? 0 : backView.getWidth();
    }

    private View getBackView() {
        return getChildCount() > 1 ? getChildAt(0) : null;
    }

    private View getFrontView() {
        return getChildCount() > 0 ? getChildAt(getChildCount() - 1) : null;
    }
}
