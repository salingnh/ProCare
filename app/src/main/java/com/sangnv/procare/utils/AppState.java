package com.sangnv.procare.utils;

import com.google.gson.JsonSyntaxException;
import com.google.gson.reflect.TypeToken;
import com.sangnv.procare.App;
import com.sangnv.procare.R;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class AppState {
    private static final AppState ourInstance = new AppState();
    private String mType;
    private List<String> strings;

    public static AppState getInstance() {
        return ourInstance;
    }

    private AppState() {
        this.mType = App.self().getResources().getString(R.string.key_danh_gia);
        this.strings = getList(this.mType);
    }

    public String getmType() {
        return mType;
    }

    public void setmType(String mType) {
        if (this.mType != null && this.mType.equals(mType)) {
            return;
        }
        this.mType = mType;
        this.strings = getList(this.mType);
    }

    public List<String> getDanhSachBang() {
        return strings;
    }

    public List<String> getList(String key) {
        String savedValue = SharedPrefs.getInstance().get(key, String.class);
        if (savedValue == null || savedValue.trim().isEmpty()) {
            return new ArrayList<>();
        }

        try {
            List<String> stringList = App.self().getGSon().fromJson(savedValue, new TypeToken<List<String>>() {
            }.getType());
            return stringList == null ? new ArrayList<String>() : new ArrayList<>(stringList);
        } catch (JsonSyntaxException exception) {
            return new ArrayList<>();
        }
    }

    public void addBang(String bang) {
        if (bang == null) {
            return;
        }

        String normalizedBang = bang.trim();
        if (normalizedBang.isEmpty() || strings.contains(normalizedBang)) {
            return;
        }

        strings.add(normalizedBang);
        updateShare();
    }

    public void removeBang(int position) {
        if (position < 0 || position >= strings.size()) {
            return;
        }

        strings.remove(position);
        updateShare();
    }

    public void removeAll(List<String> list) {
        if (list == null || list.isEmpty()) {
            return;
        }

        strings.removeAll(list);
        updateShare();
    }

    public List<String> snapshot() {
        return Collections.unmodifiableList(new ArrayList<>(strings));
    }

    public void updateShare() {
        SharedPrefs.getInstance().put(mType, App.self().getGSon().toJson(strings));
    }
}
