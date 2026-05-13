package com.sangnv.procare;

import android.os.Bundle;
import android.view.Menu;

import androidx.appcompat.app.AppCompatActivity;

import com.sangnv.procare.ui.setting.SettingFragment;

public class SettingActivity extends AppCompatActivity implements SettingFragment.OnSettingFragmentListener {
    private SettingFragment settingFragment;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.setting_activity);

        if (savedInstanceState == null) {
            settingFragment = SettingFragment.newInstance();
            getSupportFragmentManager().beginTransaction()
                    .replace(R.id.container, settingFragment)
                    .commitNow();
        } else {
            settingFragment = (SettingFragment) getSupportFragmentManager().findFragmentById(R.id.container);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.setting_menu, menu);
        return true;
    }

    @Override
    public void onItemEdit(String item) {
    }

    @Override
    public void onRefreshSwipe() {
        if (settingFragment != null) {
            settingFragment.refreshItem();
        }
    }

    @Override
    public void onAddItem(String item) {
        if (settingFragment != null) {
            settingFragment.addItem(item);
        }
    }

    @Override
    public void onRemoveItem(int position) {
        if (settingFragment != null) {
            settingFragment.removeItem(position);
        }
    }
}
