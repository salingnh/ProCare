package com.sangnv.procare;

import android.content.Context;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.DividerItemDecoration;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.google.gson.JsonSyntaxException;
import com.google.gson.reflect.TypeToken;
import com.sangnv.procare.Model.ItemRow;
import com.sangnv.procare.utils.SharedPrefs;

import java.util.ArrayList;
import java.util.List;

import static androidx.recyclerview.widget.DividerItemDecoration.VERTICAL;

/**
 * Fragment hiển thị danh sách tiêu chí trong một bảng đánh giá.
 */
public class ItemFragment extends Fragment {
    private static final String ARG_TABLE_NAME = "arg_table_name";

    private String bangDanhGia;
    private OnListFragmentInteractionListener mListener;
    private SwipeRefreshLayout mSwipeRefreshLayout;

    public ItemFragment() {
    }

    public static ItemFragment newInstance(String bangDanhGia) {
        ItemFragment fragment = new ItemFragment();
        Bundle args = new Bundle();
        args.putString(ARG_TABLE_NAME, bangDanhGia);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            bangDanhGia = getArguments().getString(ARG_TABLE_NAME);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_item_list, container, false);
        Context context = view.getContext();
        RecyclerView recyclerView = view.findViewById(R.id.list);
        TextView emptyTextView = view.findViewById(R.id.txt_dlg);

        recyclerView.setLayoutManager(new LinearLayoutManager(context));
        recyclerView.addItemDecoration(new DividerItemDecoration(context, VERTICAL));

        List<ItemRow> itemList = loadItems(bangDanhGia);
        if (itemList.isEmpty()) {
            emptyTextView.setVisibility(View.VISIBLE);
            emptyTextView.setText(R.string.empty_table_message);
        } else {
            emptyTextView.setVisibility(View.GONE);
        }
        recyclerView.setAdapter(new RecyclerViewAdapter(itemList, mListener));

        mSwipeRefreshLayout = view.findViewById(R.id.swipeRefreshLayout);
        mSwipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                if (mListener != null) {
                    mListener.onRefreshSwipe();
                }
                mSwipeRefreshLayout.setRefreshing(false);
            }
        });

        return view;
    }

    private List<ItemRow> loadItems(String tableName) {
        if (tableName == null || tableName.trim().isEmpty()) {
            return new ArrayList<>();
        }

        String savedItems = SharedPrefs.getInstance().get(tableName, String.class);
        if (savedItems == null || savedItems.trim().isEmpty()) {
            return new ArrayList<>();
        }

        try {
            List<ItemRow> itemList = App.self().getGSon().fromJson(savedItems, new TypeToken<List<ItemRow>>() {
            }.getType());
            return itemList == null ? new ArrayList<ItemRow>() : itemList;
        } catch (JsonSyntaxException exception) {
            return new ArrayList<>();
        }
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof OnListFragmentInteractionListener) {
            mListener = (OnListFragmentInteractionListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement OnListFragmentInteractionListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    public interface OnListFragmentInteractionListener {
        void onListFragmentInteraction(ItemRow item);

        void onRefreshSwipe();

        void onItemChange();
    }
}
