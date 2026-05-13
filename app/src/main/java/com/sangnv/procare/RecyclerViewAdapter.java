package com.sangnv.procare;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.SeekBar;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import com.sangnv.procare.Model.ItemRow;

import java.util.ArrayList;
import java.util.List;

/**
 * Adapter hiển thị các tiêu chí đánh giá và cập nhật điểm người dùng chọn.
 */
public class RecyclerViewAdapter extends RecyclerView.Adapter<RecyclerViewAdapter.ViewHolder> {
    private final List<ItemRow> mValues;
    private final ItemFragment.OnListFragmentInteractionListener mListener;

    public RecyclerViewAdapter(List<ItemRow> items, ItemFragment.OnListFragmentInteractionListener listener) {
        mValues = items == null ? new ArrayList<ItemRow>() : items;
        mListener = listener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.fragment_item_row, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final ViewHolder holder, int position) {
        final ItemRow item = mValues.get(position);
        holder.mItem = item;
        holder.mTitle.setText(item.getTitle());

        final int min = item.getSeek_min();
        final int max = Math.max(min, item.getSeek_max());
        final int safeValue = clamp(item.getValue(), min, max);

        holder.seekBar.setOnSeekBarChangeListener(null);
        holder.seekBar.setMax(max - min);
        holder.seekBar.setProgress(safeValue - min);
        holder.seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (!fromUser) {
                    return;
                }

                item.setValue(progress + min);
                if (mListener != null) {
                    mListener.onItemChange();
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });

        holder.mView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mListener != null) {
                    mListener.onListFragmentInteraction(holder.mItem);
                }
            }
        });
    }

    private int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    @Override
    public int getItemCount() {
        return mValues.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        public final View mView;
        public final TextView mTitle;
        public final SeekBar seekBar;
        public ItemRow mItem;

        public ViewHolder(View view) {
            super(view);
            mView = view;
            mTitle = view.findViewById(R.id.txt_title);
            seekBar = view.findViewById(R.id.seekBar);
        }

        @Override
        public String toString() {
            return super.toString() + " '" + mTitle.getText() + "'";
        }
    }
}
