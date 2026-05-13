package com.sangnv.procare.ui.setting;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.chauthai.swipereveallayout.SwipeRevealLayout;
import com.chauthai.swipereveallayout.ViewBinderHelper;
import com.sangnv.procare.R;
import com.sangnv.procare.utils.AppState;

import java.util.ArrayList;
import java.util.List;

public class SettingAdapter extends RecyclerView.Adapter<SettingAdapter.SettingViewHolder> {
    private List<String> mValues;
    private final SettingFragment.OnSettingFragmentListener mListener;
    private final ViewBinderHelper binderHelper = new ViewBinderHelper();

    public SettingAdapter(List<String> mValues, SettingFragment.OnSettingFragmentListener listener) {
        this.mValues = mValues == null ? new ArrayList<String>() : mValues;
        this.mListener = listener;
    }

    @NonNull
    @Override
    public SettingViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.setting_row, parent, false);
        return new SettingViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull SettingViewHolder holder, int position) {
        String data = mValues.get(position);
        binderHelper.bind(holder.swipeLayout, data);
        holder.bind(data);
    }

    @Override
    public int getItemCount() {
        return mValues.size();
    }

    public void setmValues(List<String> mValues) {
        this.mValues = mValues == null ? new ArrayList<String>() : mValues;
        notifyDataSetChanged();
    }

    public void removeItem(int position) {
        if (position < 0 || position >= mValues.size()) {
            return;
        }

        AppState.getInstance().removeBang(position);
        notifyItemRemoved(position);
        notifyItemRangeChanged(position, mValues.size() - position);
    }

    public class SettingViewHolder extends RecyclerView.ViewHolder {
        public final TextView mTitle;
        private final SwipeRevealLayout swipeLayout;
        private final ImageButton buttonDelete;
        private final ImageButton buttonEdit;

        public SettingViewHolder(View view) {
            super(view);
            mTitle = view.findViewById(R.id.setting_text);
            swipeLayout = itemView.findViewById(R.id.swipe_layout);
            buttonDelete = itemView.findViewById(R.id.btn_delete_item);
            buttonEdit = itemView.findViewById(R.id.btn_edit_item);
        }

        public void bind(final String data) {
            mTitle.setText(data);

            buttonDelete.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    int position = getAdapterPosition();
                    if (position == RecyclerView.NO_POSITION) {
                        return;
                    }

                    removeItem(position);
                    if (mListener != null) {
                        mListener.onRefreshSwipe();
                    }
                }
            });

            buttonEdit.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (mListener != null) {
                        mListener.onItemEdit(data);
                    }
                }
            });
        }
    }
}
