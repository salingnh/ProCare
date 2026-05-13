package com.sangnv.procare.ui.setting;

import android.content.Context;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.DividerItemDecoration;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.sangnv.procare.R;
import com.sangnv.procare.utils.AppState;

import static androidx.recyclerview.widget.LinearLayoutManager.VERTICAL;

public class SettingFragment extends Fragment {
    private EditText editText;
    private SettingAdapter settingAdapter;
    private OnSettingFragmentListener mListener;

    public static SettingFragment newInstance() {
        return new SettingFragment();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.setting_fragment, container, false);
        Context context = view.getContext();
        RecyclerView recyclerView = view.findViewById(R.id.list_setting);
        editText = view.findViewById(R.id.editText);
        Button button = view.findViewById(R.id.button_them);

        settingAdapter = new SettingAdapter(AppState.getInstance().getDanhSachBang(), mListener);
        recyclerView.setLayoutManager(new LinearLayoutManager(context));
        recyclerView.addItemDecoration(new DividerItemDecoration(context, VERTICAL));
        recyclerView.setAdapter(settingAdapter);

        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                addItem(editText.getText().toString());
                editText.setText("");
            }
        });
        return view;
    }

    public void addItem(String item) {
        AppState.getInstance().addBang(item);
        refreshItem();
    }

    public void removeItem(int position) {
        AppState.getInstance().removeBang(position);
        refreshItem();
    }

    public void refreshItem() {
        if (settingAdapter != null) {
            settingAdapter.notifyDataSetChanged();
        }
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof OnSettingFragmentListener) {
            mListener = (OnSettingFragmentListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement OnSettingFragmentListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    public interface OnSettingFragmentListener {
        void onItemEdit(String item);

        void onRefreshSwipe();

        void onAddItem(String item);

        void onRemoveItem(int position);
    }
}
