package com.sangnv.procare;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.os.Build;
import android.os.Environment;
import android.graphics.Color;
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;
import android.view.Menu;
import android.view.MenuItem;
import android.view.WindowManager;
import android.view.View;
import android.util.Log;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.ProgressBar;
import android.widget.RadioGroup;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.cardview.widget.CardView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.FileProvider;

import com.sangnv.procare.Model.ClinicalAssessment;
import com.sangnv.procare.data.AssessmentRepository;
import com.sangnv.procare.news2.News2Scoring;
import com.sangnv.procare.scoring.ClinicalValueParser;
import com.sangnv.procare.scoring.News2InputValidator;
import com.sangnv.procare.scoring.QsofaScoring;
import com.sangnv.procare.scoring.SofaScoring;
import com.sangnv.procare.ui.PatientListScreen;
import com.sangnv.procare.ui.ProCareUi;
import com.sangnv.procare.ui.assessment.News2CriterionViews;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity implements GitHubReleaseChecker.UpdateListener {
    private static final String TAG = "MainActivity";
    private static final int STEP_COUNT = 5;
    private static final int COLOR_SCREEN_BACKGROUND = Color.rgb(243, 244, 246);
    private static final int COLOR_CARD_BACKGROUND = Color.WHITE;
    private static final int COLOR_TEXT_PRIMARY = Color.rgb(17, 24, 39);
    private static final int COLOR_TEXT_SECONDARY = Color.rgb(75, 85, 99);
    private static final int COLOR_PRIMARY = Color.rgb(37, 99, 235);
    private static final int COLOR_PRIMARY_DARK = Color.rgb(30, 64, 175);
    private static final int COLOR_FIELD_STROKE = Color.rgb(209, 213, 219);
    private static final int COLOR_FIELD_BACKGROUND = Color.rgb(249, 250, 251);
    private static final int ASSESSMENT_STATUS_FALLBACK_HEIGHT_DP = 150;


    private ClinicalAssessment assessment;
    private boolean isBinding;
    private boolean isFormReady;
    private boolean isDownloadingUpdate;
    private boolean showingAssessment;
    private boolean gridPatientView = true;
    private String patientSearchQuery = "";
    private int patientSortMode = PatientListScreen.SORT_MODIFIED_RECENT;
    private int currentWorkflowStep;
    private GitHubReleaseChecker gitHubReleaseChecker;
    private GitHubReleaseChecker.UpdateInfo availableUpdate;
    private final ExecutorService updateDownloadExecutor = Executors.newSingleThreadExecutor();
    private final AssessmentRepository assessmentRepository = new AssessmentRepository();
    private LinearLayout formContainer;
    private LinearLayout assessmentStatusContainer;
    private Button floatingAddButton;
    private TextView scrollDateBubble;
    private LinearLayout updateBannerView;
    private TextView updateBannerTitleView;
    private TextView updateBannerMessageView;
    private ProgressBar updateProgressView;
    private TextView updateProgressTextView;

    private EditText patientIdView;
    private EditText admissionDateTimeView;
    private EditText fullNameView;
    private EditText ageView;
    private EditText suspectedInfectionView;
    private EditText wardView;
    private EditText otherComorbidityView;
    private EditText news2RespirationMeasuredView;
    private EditText news2Spo2MeasuredView;
    private EditText news2OxygenMeasuredView;
    private EditText news2TemperatureMeasuredView;
    private EditText news2SystolicBpMeasuredView;
    private EditText news2HeartRateMeasuredView;
    private EditText news2ConsciousnessMeasuredView;
    private EditText lactateView;
    private EditText lactateSampleTimeView;
    private EditText sofaRespirationMeasuredView;
    private EditText sofaCoagulationMeasuredView;
    private EditText sofaLiverMeasuredView;
    private EditText sofaCardiovascularMeasuredView;
    private EditText sofaNeurologicMeasuredView;
    private EditText sofaRenalMeasuredView;
    private EditText treatmentDaysView;

    private RadioGroup genderGroup;
    private RadioGroup lactateLevelGroup;
    private RadioGroup treatmentOutcomeGroup;
    private RadioGroup news2RespirationGroup;
    private RadioGroup news2Spo2Group;
    private RadioGroup news2OxygenGroup;
    private RadioGroup news2TemperatureGroup;
    private RadioGroup news2SystolicBpGroup;
    private RadioGroup news2HeartRateGroup;
    private RadioGroup news2ConsciousnessGroup;
    private RadioGroup sofaRespirationGroup;
    private RadioGroup sofaCoagulationGroup;
    private RadioGroup sofaLiverGroup;
    private RadioGroup sofaCardiovascularGroup;
    private RadioGroup sofaNeurologicGroup;
    private RadioGroup sofaRenalGroup;

    private CheckBox diabetesView;
    private CheckBox chronicKidneyDiseaseView;
    private CheckBox liverFailureView;
    private CheckBox hypertensionView;
    private CheckBox copdView;
    private CheckBox news2Spo2Scale2View;
    private CheckBox qsofaRespirationView;
    private CheckBox qsofaSystolicBpView;
    private CheckBox qsofaConsciousnessView;
    private CheckBox vasopressorView;

    private final List<View> workflowStepContainers = new ArrayList<>();
    private TextView workflowProgressView;
    private TextView assessmentStatusTitleView;
    private TextView assessmentStatusScoreView;
    private TextView assessmentStatusRiskView;
    private ProgressBar assessmentStatusProgressView;
    private TextView quickSummaryView;
    private TextView news2FooterScoreView;
    private TextView news2FooterRiskView;
    private TextView news2TotalView;
    private TextView news2RiskView;
    private TextView news2ActionView;
    private TextView news2MonitoringView;
    private TextView news2HighestCriterionView;
    private TextView qsofaTotalView;
    private TextView sofaTotalView;
    private TextView sepsisDiagnosisView;
    private TextView lastSavedView;
    private Button previousStepButton;
    private Button nextStepButton;
    private Button saveAssessmentButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        configureFullScreenWindow();
        setTitle("");
        if (getSupportActionBar() != null) {
            getSupportActionBar().hide();
        }

        assessment = loadCurrentAssessment();
        formContainer = (LinearLayout) findViewById(R.id.form_container);
        assessmentStatusContainer = (LinearLayout) findViewById(R.id.assessment_status_container);
        floatingAddButton = (Button) findViewById(R.id.fab_add_assessment);
        scrollDateBubble = (TextView) findViewById(R.id.scroll_date_bubble);
        configureFloatingAddButton();
        configureScrollDateBubble();
        showPatientListScreen();
        gitHubReleaseChecker = new GitHubReleaseChecker(this);
        gitHubReleaseChecker.checkForNewRelease();
    }

    private void configureFullScreenWindow() {
        getWindow().setStatusBarColor(Color.TRANSPARENT);
        getWindow().setNavigationBarColor(Color.TRANSPARENT);
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            WindowManager.LayoutParams attributes = getWindow().getAttributes();
            attributes.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            getWindow().setAttributes(attributes);
        }
    }

    @Override
    protected void onDestroy() {
        if (gitHubReleaseChecker != null) {
            gitHubReleaseChecker.shutdown();
        }
        updateDownloadExecutor.shutdownNow();
        super.onDestroy();
    }


    @Override
    public void onBackPressed() {
        if (showingAssessment) {
            showPatientListScreen();
            return;
        }
        super.onBackPressed();
    }

    @Override
    public void onUpdateAvailable(GitHubReleaseChecker.UpdateInfo updateInfo) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                availableUpdate = updateInfo;
                showUpdateBanner(updateInfo);
            }
        });
    }

    private void showUpdateBanner(GitHubReleaseChecker.UpdateInfo updateInfo) {
        if (formContainer == null || isFinishing() || isDestroyed()) {
            return;
        }
        if (updateBannerView == null) {
            updateBannerView = new LinearLayout(this);
            updateBannerView.setOrientation(LinearLayout.VERTICAL);
            updateBannerView.setPadding(dp(14), dp(12), dp(14), dp(12));
            GradientDrawable background = new GradientDrawable();
            background.setColor(Color.parseColor("#E3F2FD"));
            background.setCornerRadius(dp(12));
            background.setStroke(dp(1), Color.parseColor("#1976D2"));
            updateBannerView.setBackground(background);
            updateBannerView.setClickable(true);
            updateBannerView.setFocusable(true);
            updateBannerView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    startUpdateDownload();
                }
            });

            updateBannerTitleView = new TextView(this);
            updateBannerTitleView.setTextColor(Color.parseColor("#0D47A1"));
            updateBannerTitleView.setTextSize(16);
            updateBannerTitleView.setText(R.string.update_banner_title);
            updateBannerView.addView(updateBannerTitleView, matchWrapParams());

            updateBannerMessageView = new TextView(this);
            updateBannerMessageView.setTextColor(Color.parseColor("#263238"));
            updateBannerMessageView.setPadding(0, dp(4), 0, 0);
            updateBannerView.addView(updateBannerMessageView, matchWrapParams());

            updateProgressView = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
            updateProgressView.setMax(100);
            updateProgressView.setVisibility(View.GONE);
            LinearLayout.LayoutParams progressParams = matchWrapParams();
            progressParams.setMargins(0, dp(10), 0, 0);
            updateBannerView.addView(updateProgressView, progressParams);

            updateProgressTextView = new TextView(this);
            updateProgressTextView.setTextColor(Color.parseColor("#0D47A1"));
            updateProgressTextView.setPadding(0, dp(4), 0, 0);
            updateProgressTextView.setVisibility(View.GONE);
            updateBannerView.addView(updateProgressTextView, matchWrapParams());

            LinearLayout.LayoutParams bannerParams = matchWrapParams();
            bannerParams.setMargins(0, 0, 0, dp(12));
            formContainer.addView(updateBannerView, 0, bannerParams);
        }
        updateBannerMessageView.setText(getString(R.string.update_banner_message, updateInfo.version));
        if (!isDownloadingUpdate) {
            updateProgressView.setVisibility(View.GONE);
            updateProgressTextView.setVisibility(View.GONE);
        }
        updateBannerView.setVisibility(View.VISIBLE);
    }

    private void startUpdateDownload() {
        if (availableUpdate == null || isDownloadingUpdate) {
            return;
        }
        isDownloadingUpdate = true;
        updateProgressView.setVisibility(View.VISIBLE);
        updateProgressView.setIndeterminate(true);
        updateProgressTextView.setVisibility(View.VISIBLE);
        updateProgressTextView.setText(R.string.update_download_starting);
        updateBannerMessageView.setText(getString(R.string.update_downloading_message, availableUpdate.version));

        updateDownloadExecutor.execute(new Runnable() {
            @Override
            public void run() {
                File apkFile = null;
                try {
                    apkFile = downloadUpdateApk(availableUpdate);
                    File finalApkFile = apkFile;
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            isDownloadingUpdate = false;
                            updateProgressView.setIndeterminate(false);
                            updateProgressView.setProgress(100);
                            updateProgressTextView.setText(R.string.update_download_complete);
                            openApkInstaller(finalApkFile);
                        }
                    });
                } catch (IOException exception) {
                    Log.w(TAG, "Unable to download update APK.", exception);
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            isDownloadingUpdate = false;
                            updateProgressView.setIndeterminate(false);
                            updateProgressTextView.setText(R.string.update_download_failed);
                            updateBannerMessageView.setText(getString(R.string.update_banner_message, availableUpdate.version));
                        }
                    });
                }
            }
        });
    }

    private File downloadUpdateApk(GitHubReleaseChecker.UpdateInfo updateInfo) throws IOException {
        HttpURLConnection connection = null;
        InputStream inputStream = null;
        FileOutputStream outputStream = null;
        try {
            URL url = new URL(updateInfo.downloadUrl);
            connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(15000);
            connection.setReadTimeout(30000);
            connection.setRequestProperty("User-Agent", "ProCare-Android");
            connection.connect();

            int responseCode = connection.getResponseCode();
            if (responseCode < HttpURLConnection.HTTP_OK || responseCode >= HttpURLConnection.HTTP_MULT_CHOICE) {
                throw new IOException("Download failed with HTTP " + responseCode);
            }

            int contentLength = connection.getContentLength();
            File downloadsDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS);
            if (downloadsDir == null) {
                downloadsDir = getFilesDir();
            }
            File apkFile = new File(downloadsDir, "ProCare-v" + updateInfo.version + ".apk");
            inputStream = connection.getInputStream();
            outputStream = new FileOutputStream(apkFile);
            byte[] buffer = new byte[8192];
            long totalRead = 0;
            int lastProgress = -1;
            int read;
            while ((read = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, read);
                totalRead += read;
                if (contentLength > 0) {
                    int progress = (int) ((totalRead * 100) / contentLength);
                    if (progress != lastProgress) {
                        lastProgress = progress;
                        updateDownloadProgress(progress);
                    }
                }
            }
            outputStream.flush();
            return apkFile;
        } finally {
            if (outputStream != null) {
                outputStream.close();
            }
            if (inputStream != null) {
                inputStream.close();
            }
            if (connection != null) {
                connection.disconnect();
            }
        }
    }

    private void updateDownloadProgress(int progress) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                updateProgressView.setIndeterminate(false);
                updateProgressView.setProgress(progress);
                updateProgressTextView.setText(getString(R.string.update_download_progress, progress));
            }
        });
    }

    private void openApkInstaller(File apkFile) {
        Uri apkUri = FileProvider.getUriForFile(this, BuildConfig.APPLICATION_ID + ".fileprovider", apkFile);
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(apkUri, "application/vnd.android.package-archive");
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            startActivity(intent);
        } catch (ActivityNotFoundException exception) {
            openReleaseInBrowser();
        }
    }

    private void openReleaseInBrowser() {
        if (availableUpdate == null) {
            return;
        }
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(availableUpdate.releaseUrl));
        try {
            startActivity(intent);
        } catch (ActivityNotFoundException exception) {
            Toast.makeText(this, R.string.update_open_failed, Toast.LENGTH_SHORT).show();
        }
    }

    private int dp(int value) {
        return ProCareUi.dp(this, value);
    }

    private int systemBarDimension(String name) {
        return ProCareUi.systemBarDimension(this, name);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == R.id.action_clear_assessment) {
            assessment = new ClinicalAssessment();
            bindAssessmentToViews();
            recalculateAndSave(false);
            return true;
        }
        return super.onOptionsItemSelected(item);
    }


    private void configureFloatingAddButton() {
        if (floatingAddButton == null) {
            return;
        }
        floatingAddButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startNewAssessment();
            }
        });
    }

    private void configureScrollDateBubble() {
        ScrollView scrollView = (ScrollView) findViewById(R.id.assessment_scroll);
        if (scrollView == null || scrollDateBubble == null) {
            return;
        }
        scrollView.setOnScrollChangeListener(new View.OnScrollChangeListener() {
            @Override
            public void onScrollChange(View v, int scrollX, int scrollY, int oldScrollX, int oldScrollY) {
                updateScrollDateBubble(scrollY);
            }
        });
    }

    private void updateScrollDateBubble(int scrollY) {
        if (scrollDateBubble == null || showingAssessment) {
            if (scrollDateBubble != null) {
                scrollDateBubble.setVisibility(View.GONE);
            }
            return;
        }
        String date = findVisibleDateLabel(scrollY);
        if (date == null || date.trim().isEmpty()) {
            scrollDateBubble.setVisibility(View.GONE);
            return;
        }
        scrollDateBubble.setText(date);
        scrollDateBubble.setVisibility(View.VISIBLE);
        scrollDateBubble.removeCallbacks(hideScrollDateBubbleRunnable);
        scrollDateBubble.postDelayed(hideScrollDateBubbleRunnable, 900);
    }

    private final Runnable hideScrollDateBubbleRunnable = new Runnable() {
        @Override
        public void run() {
            if (scrollDateBubble != null) {
                scrollDateBubble.setVisibility(View.GONE);
            }
        }
    };

    private String findVisibleDateLabel(int scrollY) {
        String lastDate = null;
        int target = scrollY + dp(96);
        for (int i = 0; i < formContainer.getChildCount(); i++) {
            View child = formContainer.getChildAt(i);
            Object tag = child.getTag();
            if (tag instanceof String) {
                lastDate = (String) tag;
                if (child.getTop() >= target) {
                    return lastDate;
                }
            }
        }
        return lastDate;
    }

    private void startNewAssessment() {
        assessment = new ClinicalAssessment();
        long now = System.currentTimeMillis();
        assessment.createdAtMillis = now;
        assessment.modifiedAtMillis = now;
        currentWorkflowStep = 0;
        initializeAssessmentForm(formContainer);
        recalculateAndSave(false);
    }

    private void showPatientListScreen() {
        showingAssessment = false;
        isFormReady = false;
        formContainer.removeAllViews();
        if (assessmentStatusContainer != null) {
            assessmentStatusContainer.setVisibility(View.GONE);
            assessmentStatusContainer.removeAllViews();
        }
        if (floatingAddButton != null) {
            floatingAddButton.setVisibility(View.VISIBLE);
        }
        if (scrollDateBubble != null) {
            scrollDateBubble.setVisibility(View.GONE);
        }
        formContainer.setPadding(dp(16), dp(18) + systemBarDimension("status_bar_height"), dp(16), dp(28) + systemBarDimension("navigation_bar_height"));
        new PatientListScreen(this, new PatientListScreen.Listener() {
            @Override
            public void onAddNewAssessment() {
                startNewAssessment();
            }

            @Override
            public void onOpenAssessment(ClinicalAssessment selectedAssessment) {
                assessment = cloneAssessment(selectedAssessment);
                currentWorkflowStep = 0;
                initializeAssessmentForm(formContainer);
                recalculateAndSave(false);
            }

            @Override
            public void onSearchChanged(String query) {
                patientSearchQuery = query;
                showPatientListScreen();
            }

            @Override
            public void onViewModeChanged(boolean gridMode) {
                gridPatientView = gridMode;
                showPatientListScreen();
            }

            @Override
            public void onSortModeChanged(int sortMode) {
                patientSortMode = sortMode;
                showPatientListScreen();
            }
        }, COLOR_PRIMARY, COLOR_PRIMARY_DARK, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY)
                .render(formContainer, loadAssessmentHistory(), gridPatientView, patientSearchQuery, patientSortMode);
        if (availableUpdate != null) {
            updateBannerView = null;
            showUpdateBanner(availableUpdate);
        }
    }

    private void initializeAssessmentForm(LinearLayout container) {
        showingAssessment = true;
        if (floatingAddButton != null) {
            floatingAddButton.setVisibility(View.GONE);
        }
        if (scrollDateBubble != null) {
            scrollDateBubble.setVisibility(View.GONE);
        }
        configureFixedAssessmentStatusCard();
        isFormReady = false;
        isBinding = true;
        try {
            buildAssessmentForm(container);
            bindAssessmentToViews();
            isFormReady = true;
        } finally {
            isBinding = false;
        }
    }

    private void buildAssessmentForm(LinearLayout container) {
        container.removeAllViews();
        workflowStepContainers.clear();
        setAssessmentFormPadding(container, dp(ASSESSMENT_STATUS_FALLBACK_HEIGHT_DP));
        updateAssessmentFormPaddingForFixedStatus();

        addNews2TopBar(container);
        addWorkflowControls(container);

        LinearLayout patientStep = addWorkflowStep(container, R.string.workflow_step_patient, R.string.workflow_step_patient_hint);
        addPatientInfoCard(patientStep);

        LinearLayout news2Step = addWorkflowStep(container, R.string.workflow_step_news2, R.string.workflow_step_news2_hint);
        quickSummaryView = addAlertText(news2Step, getString(R.string.quick_summary_empty), "#6B7280");
        addSpo2ScaleCard(news2Step);
        News2CriterionViews respirationViews = addNews2MeasuredCriterionCard(news2Step, getString(R.string.news2_respiration), "Đơn vị chuẩn: lần/phút", getString(R.string.news2_respiration), true,
                new String[]{"≤ 8", "9 - 11", "12 - 20", "21 - 24", "≥ 25"}, new int[]{3, 1, 0, 2, 3});
        news2RespirationMeasuredView = respirationViews.measuredView;
        news2RespirationGroup = respirationViews.group;
        if (assessment.news2Spo2Scale2) {
            News2CriterionViews spo2Views = addNews2MeasuredCriterionCard(news2Step, getString(R.string.news2_spo2_scale2_title), getString(R.string.news2_spo2_scale2_subtitle), getString(R.string.news2_spo2), true,
                    new String[]{"≤ 83%", "84 - 85%", "86 - 87%", "88 - 92%", "93 - 94%", "95 - 96%", "≥ 97%"}, new int[]{3, 2, 1, 0, 1, 2, 3});
            news2Spo2MeasuredView = spo2Views.measuredView;
            news2Spo2Group = spo2Views.group;
        } else {
            News2CriterionViews spo2Views = addNews2MeasuredCriterionCard(news2Step, getString(R.string.news2_spo2_scale1_title), getString(R.string.news2_spo2_scale1_subtitle), getString(R.string.news2_spo2), true,
                    new String[]{"≤ 91%", "92 - 93%", "94 - 95%", "≥ 96%"}, new int[]{3, 2, 1, 0});
            news2Spo2MeasuredView = spo2Views.measuredView;
            news2Spo2Group = spo2Views.group;
        }
        News2CriterionViews oxygenViews = addNews2MeasuredCriterionCard(news2Step, getString(R.string.news2_oxygen), getString(R.string.news2_oxygen_note), getString(R.string.news2_oxygen), false,
                new String[]{"Thở khí phòng", "Thở Oxy"}, new int[]{0, 2});
        news2OxygenMeasuredView = oxygenViews.measuredView;
        news2OxygenGroup = oxygenViews.group;
        News2CriterionViews sbpViews = addNews2MeasuredCriterionCard(news2Step, getString(R.string.news2_systolic_bp), "Đơn vị chuẩn: mmHg", getString(R.string.news2_systolic_bp), true,
                new String[]{"≤ 90", "91 - 100", "101 - 110", "111 - 219", "≥ 220"}, new int[]{3, 2, 1, 0, 3});
        news2SystolicBpMeasuredView = sbpViews.measuredView;
        news2SystolicBpGroup = sbpViews.group;
        News2CriterionViews heartRateViews = addNews2MeasuredCriterionCard(news2Step, getString(R.string.news2_heart_rate), "Đơn vị chuẩn: lần/phút", getString(R.string.news2_heart_rate), true,
                new String[]{"≤ 40", "41 - 50", "51 - 90", "91 - 110", "111 - 130", "≥ 131"}, new int[]{3, 1, 0, 1, 2, 3});
        news2HeartRateMeasuredView = heartRateViews.measuredView;
        news2HeartRateGroup = heartRateViews.group;
        News2CriterionViews consciousnessViews = addNews2MeasuredCriterionCard(news2Step, getString(R.string.news2_consciousness), getString(R.string.news2_consciousness_hint), getString(R.string.news2_consciousness), false,
                new String[]{"A - Tỉnh táo (Alert)", "C/V/P/U - Lú lẫn, đáp ứng lời nói/đau hoặc không phản ứng"}, new int[]{0, 3});
        news2ConsciousnessMeasuredView = consciousnessViews.measuredView;
        news2ConsciousnessGroup = consciousnessViews.group;
        News2CriterionViews temperatureViews = addNews2MeasuredCriterionCard(news2Step, getString(R.string.news2_temperature), "Đơn vị chuẩn: °C", getString(R.string.news2_temperature), false,
                new String[]{"≤ 35.0", "35.1 - 36.0", "36.1 - 38.0", "38.1 - 39.0", "≥ 39.1"}, new int[]{3, 1, 0, 1, 2});
        news2TemperatureMeasuredView = temperatureViews.measuredView;
        news2TemperatureGroup = temperatureViews.group;
        addNews2ResultCard(news2Step);

        LinearLayout qsofaStep = addWorkflowStep(container, R.string.workflow_step_qsofa_lactate, R.string.workflow_step_qsofa_lactate_hint);
        addQsofaLactateCard(qsofaStep);

        LinearLayout sofaStep = addWorkflowStep(container, R.string.workflow_step_sofa, R.string.workflow_step_sofa_hint);
        addSofaCard(sofaStep);

        LinearLayout saveStep = addWorkflowStep(container, R.string.workflow_step_save, R.string.workflow_step_save_hint);
        addSaveReviewCard(saveStep);
        addNews2Footer(saveStep);
        updateWorkflowStepVisibility();
    }

    private void bindAssessmentToViews() {
        isBinding = true;
        setEditTextValue(patientIdView, assessment.patientId);
        setEditTextValue(fullNameView, assessment.fullName);
        setEditTextValue(ageView, assessment.age);
        setEditTextValue(wardView, assessment.ward);
        setEditTextValue(admissionDateTimeView, assessment.admissionDateTime);
        setEditTextValue(suspectedInfectionView, assessment.suspectedInfection);
        setEditTextValue(news2RespirationMeasuredView, assessment.news2RespirationMeasured);
        setEditTextValue(news2Spo2MeasuredView, assessment.news2Spo2Measured);
        setEditTextValue(news2OxygenMeasuredView, assessment.news2OxygenMeasured);
        setEditTextValue(news2TemperatureMeasuredView, assessment.news2TemperatureMeasured);
        setEditTextValue(news2SystolicBpMeasuredView, assessment.news2SystolicBpMeasured);
        setEditTextValue(news2HeartRateMeasuredView, assessment.news2HeartRateMeasured);
        setEditTextValue(news2ConsciousnessMeasuredView, assessment.news2ConsciousnessMeasured);
        setEditTextValue(lactateView, assessment.lactate);
        setEditTextValue(lactateSampleTimeView, assessment.lactateSampleTime);
        setEditTextValue(sofaRespirationMeasuredView, assessment.sofaRespirationMeasured);
        setEditTextValue(sofaCoagulationMeasuredView, assessment.sofaCoagulationMeasured);
        setEditTextValue(sofaLiverMeasuredView, assessment.sofaLiverMeasured);
        setEditTextValue(sofaCardiovascularMeasuredView, assessment.sofaCardiovascularMeasured);
        setEditTextValue(sofaNeurologicMeasuredView, assessment.sofaNeurologicMeasured);
        setEditTextValue(sofaRenalMeasuredView, assessment.sofaRenalMeasured);
        setEditTextValue(treatmentDaysView, assessment.treatmentDays);
        if (news2Spo2Scale2View != null) {
            news2Spo2Scale2View.setChecked(assessment.news2Spo2Scale2);
        }
        if (qsofaRespirationView != null) {
            qsofaRespirationView.setChecked(assessment.qsofaRespiration);
        }
        if (qsofaSystolicBpView != null) {
            qsofaSystolicBpView.setChecked(assessment.qsofaSystolicBp);
        }
        if (qsofaConsciousnessView != null) {
            qsofaConsciousnessView.setChecked(assessment.qsofaConsciousness);
        }
        if (vasopressorView != null) {
            vasopressorView.setChecked(assessment.vasopressor);
        }
        checkRadioByOption(news2RespirationGroup, assessment.news2RespirationOption, assessment.news2Respiration);
        checkRadioByOption(news2Spo2Group, assessment.news2Spo2Option, assessment.news2Spo2);
        checkRadioByOption(news2OxygenGroup, assessment.news2OxygenOption, assessment.news2Oxygen);
        checkRadioByOption(news2SystolicBpGroup, assessment.news2SystolicBpOption, assessment.news2SystolicBp);
        checkRadioByOption(news2HeartRateGroup, assessment.news2HeartRateOption, assessment.news2HeartRate);
        checkRadioByOption(news2ConsciousnessGroup, assessment.news2ConsciousnessOption, assessment.news2Consciousness);
        checkRadioByOption(news2TemperatureGroup, assessment.news2TemperatureOption, assessment.news2Temperature);
        checkRadioByScore(sofaRespirationGroup, assessment.sofaRespiration);
        checkRadioByScore(sofaCoagulationGroup, assessment.sofaCoagulation);
        checkRadioByScore(sofaLiverGroup, assessment.sofaLiver);
        checkRadioByScore(sofaCardiovascularGroup, assessment.sofaCardiovascular);
        checkRadioByScore(sofaNeurologicGroup, assessment.sofaNeurologic);
        checkRadioByScore(sofaRenalGroup, assessment.sofaRenal);
        checkRadioByText(lactateLevelGroup, assessment.lactateLevel);
        checkRadioByText(treatmentOutcomeGroup, assessment.treatmentOutcome);
        isBinding = false;
    }

    private void recalculateAndSave(boolean appendHistory) {
        if (isBinding || !isFormReady) {
            return;
        }

        updateAssessmentFromViews();
        markAssessmentModified();

        updateQuickSummaryViews();
        saveCurrentAssessment();
    }

    private void updateAssessmentFromViews() {
        assessment.patientId = editTextValue(patientIdView);
        assessment.fullName = editTextValue(fullNameView);
        assessment.age = editTextValue(ageView);
        assessment.ward = editTextValue(wardView);
        assessment.admissionDateTime = editTextValue(admissionDateTimeView);
        assessment.suspectedInfection = editTextValue(suspectedInfectionView);
        assessment.news2Spo2Scale2 = news2Spo2Scale2View != null && news2Spo2Scale2View.isChecked();
        assessment.news2RespirationMeasured = editTextValue(news2RespirationMeasuredView);
        assessment.news2Spo2Measured = editTextValue(news2Spo2MeasuredView);
        assessment.news2OxygenMeasured = editTextValue(news2OxygenMeasuredView);
        assessment.news2TemperatureMeasured = editTextValue(news2TemperatureMeasuredView);
        assessment.news2SystolicBpMeasured = editTextValue(news2SystolicBpMeasuredView);
        assessment.news2HeartRateMeasured = editTextValue(news2HeartRateMeasuredView);
        assessment.news2ConsciousnessMeasured = editTextValue(news2ConsciousnessMeasuredView);
        assessment.news2Respiration = selectedScore(news2RespirationGroup);
        assessment.news2RespirationOption = selectedOption(news2RespirationGroup);
        assessment.news2Spo2 = selectedScore(news2Spo2Group);
        assessment.news2Spo2Option = selectedOption(news2Spo2Group);
        assessment.news2Oxygen = selectedScore(news2OxygenGroup);
        assessment.news2OxygenOption = selectedOption(news2OxygenGroup);
        assessment.news2SystolicBp = selectedScore(news2SystolicBpGroup);
        assessment.news2SystolicBpOption = selectedOption(news2SystolicBpGroup);
        assessment.news2HeartRate = selectedScore(news2HeartRateGroup);
        assessment.news2HeartRateOption = selectedOption(news2HeartRateGroup);
        assessment.news2Consciousness = selectedScore(news2ConsciousnessGroup);
        assessment.news2ConsciousnessOption = selectedOption(news2ConsciousnessGroup);
        assessment.news2Temperature = selectedScore(news2TemperatureGroup);
        assessment.news2TemperatureOption = selectedOption(news2TemperatureGroup);
        applyNews2AutoScores();
        assessment.news2Total = News2Scoring.total(assessment);

        assessment.qsofaRespiration = qsofaRespirationView != null && qsofaRespirationView.isChecked();
        assessment.qsofaSystolicBp = qsofaSystolicBpView != null && qsofaSystolicBpView.isChecked();
        assessment.qsofaConsciousness = qsofaConsciousnessView != null && qsofaConsciousnessView.isChecked();
        assessment.qsofaTotal = QsofaScoring.total(assessment);

        assessment.lactate = editTextValue(lactateView);
        assessment.lactateSampleTime = editTextValue(lactateSampleTimeView);
        assessment.lactateLevel = selectedText(lactateLevelGroup);
        assessment.vasopressor = vasopressorView != null && vasopressorView.isChecked();
        assessment.sofaRespirationMeasured = editTextValue(sofaRespirationMeasuredView);
        assessment.sofaCoagulationMeasured = editTextValue(sofaCoagulationMeasuredView);
        assessment.sofaLiverMeasured = editTextValue(sofaLiverMeasuredView);
        assessment.sofaCardiovascularMeasured = editTextValue(sofaCardiovascularMeasuredView);
        assessment.sofaNeurologicMeasured = editTextValue(sofaNeurologicMeasuredView);
        assessment.sofaRenalMeasured = editTextValue(sofaRenalMeasuredView);
        assessment.sofaRespiration = SofaScoring.scoreRespiration(assessment.sofaRespirationMeasured, selectedScore(sofaRespirationGroup));
        assessment.sofaCoagulation = SofaScoring.scoreCoagulation(assessment.sofaCoagulationMeasured, selectedScore(sofaCoagulationGroup));
        assessment.sofaLiver = SofaScoring.scoreLiver(assessment.sofaLiverMeasured, selectedScore(sofaLiverGroup));
        assessment.sofaCardiovascular = SofaScoring.scoreCardiovascular(assessment.sofaCardiovascularMeasured, assessment.vasopressor, selectedScore(sofaCardiovascularGroup));
        assessment.sofaNeurologic = SofaScoring.scoreNeurologic(assessment.sofaNeurologicMeasured, selectedScore(sofaNeurologicGroup));
        assessment.sofaRenal = SofaScoring.scoreRenal(assessment.sofaRenalMeasured, selectedScore(sofaRenalGroup));
        assessment.sofaTotal = SofaScoring.total(assessment);
        safelyCheckRadioByScore(sofaRespirationGroup, assessment.sofaRespiration);
        safelyCheckRadioByScore(sofaCoagulationGroup, assessment.sofaCoagulation);
        safelyCheckRadioByScore(sofaLiverGroup, assessment.sofaLiver);
        safelyCheckRadioByScore(sofaCardiovascularGroup, assessment.sofaCardiovascular);
        safelyCheckRadioByScore(sofaNeurologicGroup, assessment.sofaNeurologic);
        safelyCheckRadioByScore(sofaRenalGroup, assessment.sofaRenal);
        assessment.sepsisDiagnosis = buildSepsisDiagnosis();
        assessment.treatmentOutcome = selectedText(treatmentOutcomeGroup);
        assessment.treatmentDays = editTextValue(treatmentDaysView);
    }

    private void applyNews2AutoScores() {
        assessment.news2Respiration = News2Scoring.scoreRespiration(ClinicalValueParser.parseInteger(assessment.news2RespirationMeasured), selectedScore(news2RespirationGroup));
        assessment.news2RespirationOption = optionByScore(news2RespirationGroup, assessment.news2Respiration);
        safelyCheckRadioByScore(news2RespirationGroup, assessment.news2Respiration);

        assessment.news2Oxygen = News2InputValidator.scoreOxygenText(assessment.news2OxygenMeasured, selectedScore(news2OxygenGroup));
        assessment.news2OxygenOption = hasText(assessment.news2OxygenMeasured) ? assessment.news2OxygenMeasured : optionByScore(news2OxygenGroup, assessment.news2Oxygen);
        safelyCheckRadioByScore(news2OxygenGroup, assessment.news2Oxygen);

        assessment.news2Spo2 = assessment.news2Spo2Scale2
                ? News2Scoring.scoreSpo2Scale2(ClinicalValueParser.parseInteger(assessment.news2Spo2Measured), assessment.news2Oxygen > 0, selectedScore(news2Spo2Group))
                : News2Scoring.scoreSpo2Scale1(ClinicalValueParser.parseInteger(assessment.news2Spo2Measured), selectedScore(news2Spo2Group));
        assessment.news2Spo2Option = assessment.news2Spo2Scale2
                ? getString(R.string.news2_spo2_scale2_option)
                : optionByScore(news2Spo2Group, assessment.news2Spo2);
        safelyCheckRadioByScore(news2Spo2Group, assessment.news2Spo2);

        assessment.news2Temperature = News2Scoring.scoreTemperature(ClinicalValueParser.parseDouble(assessment.news2TemperatureMeasured), selectedScore(news2TemperatureGroup));
        assessment.news2TemperatureOption = optionByScore(news2TemperatureGroup, assessment.news2Temperature);
        safelyCheckRadioByScore(news2TemperatureGroup, assessment.news2Temperature);

        assessment.news2SystolicBp = News2Scoring.scoreSystolicBp(ClinicalValueParser.parseInteger(assessment.news2SystolicBpMeasured), selectedScore(news2SystolicBpGroup));
        assessment.news2SystolicBpOption = optionByScore(news2SystolicBpGroup, assessment.news2SystolicBp);
        safelyCheckRadioByScore(news2SystolicBpGroup, assessment.news2SystolicBp);

        assessment.news2HeartRate = News2Scoring.scoreHeartRate(ClinicalValueParser.parseInteger(assessment.news2HeartRateMeasured), selectedScore(news2HeartRateGroup));
        assessment.news2HeartRateOption = optionByScore(news2HeartRateGroup, assessment.news2HeartRate);
        safelyCheckRadioByScore(news2HeartRateGroup, assessment.news2HeartRate);

        assessment.news2Consciousness = News2Scoring.scoreConsciousness(assessment.news2ConsciousnessMeasured, selectedScore(news2ConsciousnessGroup));
        assessment.news2ConsciousnessOption = consciousnessOption(assessment.news2ConsciousnessMeasured, news2ConsciousnessGroup);
        safelyCheckRadioByScore(news2ConsciousnessGroup, assessment.news2Consciousness);

        autoSyncQsofaFromVitals();
    }

    private void autoSyncQsofaFromVitals() {
        boolean oldBinding = isBinding;
        isBinding = true;
        Integer respiration = ClinicalValueParser.parseInteger(assessment.news2RespirationMeasured);
        Integer systolicBp = ClinicalValueParser.parseInteger(assessment.news2SystolicBpMeasured);
        if (respiration != null) {
            assessment.qsofaRespiration = respiration >= 22;
            if (qsofaRespirationView != null) {
                qsofaRespirationView.setChecked(assessment.qsofaRespiration);
            }
        }
        if (systolicBp != null) {
            assessment.qsofaSystolicBp = systolicBp <= 100;
            if (qsofaSystolicBpView != null) {
                qsofaSystolicBpView.setChecked(assessment.qsofaSystolicBp);
            }
        }
        boolean alteredConsciousness = assessment.news2Consciousness == 3;
        if (hasText(assessment.news2ConsciousnessMeasured) || findCheckedRadioButton(news2ConsciousnessGroup) != null) {
            assessment.qsofaConsciousness = alteredConsciousness;
            if (qsofaConsciousnessView != null) {
                qsofaConsciousnessView.setChecked(alteredConsciousness);
            }
        }
        isBinding = oldBinding;
    }

    private String editTextValue(EditText editText) {
        return editText == null || editText.getText() == null ? "" : editText.getText().toString().trim();
    }

    private void setEditTextValue(EditText editText, String value) {
        if (editText == null) {
            return;
        }
        String safeValue = value == null ? "" : value;
        if (!safeValue.contentEquals(editText.getText())) {
            editText.setText(safeValue);
        }
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private void updateQuickSummaryViews() {
        int completedCount = completedNews2Count();
        boolean complete = missingNews2Fields().isEmpty();
        updateQsofaSofaViews();
        if (!complete) {
            String missingText = getString(R.string.news2_missing_required_format, ClinicalValueParser.joinStrings(missingNews2Fields(), ", "));
            if (quickSummaryView != null) {
                quickSummaryView.setText(getString(R.string.news2_missing_required_title) + "\n" + missingText);
                quickSummaryView.setTextColor(Color.WHITE);
                quickSummaryView.setBackground(roundedDrawable(Color.rgb(107, 114, 128), dp(18), 0, 0));
            }
            if (news2RiskView != null) {
                news2RiskView.setText(getString(R.string.news2_risk_empty));
                news2RiskView.setTextColor(Color.WHITE);
                news2RiskView.setBackground(roundedDrawable(Color.rgb(107, 114, 128), dp(18), 0, 0));
            }
            if (news2TotalView != null) {
                news2TotalView.setText(getString(R.string.news2_total_pending) + "\n" + missingText);
                news2TotalView.setTextColor(Color.rgb(107, 114, 128));
            }
            if (news2ActionView != null) {
                news2ActionView.setText("• " + getString(R.string.news2_action_empty));
            }
            if (news2MonitoringView != null) {
                news2MonitoringView.setText("• " + getString(R.string.news2_monitoring_empty));
            }
            if (news2HighestCriterionView != null) {
                news2HighestCriterionView.setText("• " + getString(R.string.clinical_disclaimer));
            }
            if (news2FooterScoreView != null) {
                news2FooterScoreView.setText("-- điểm");
                news2FooterScoreView.setTextColor(Color.rgb(209, 213, 219));
            }
            if (news2FooterRiskView != null) {
                news2FooterRiskView.setText(R.string.news2_evaluating);
                news2FooterRiskView.setTextColor(Color.rgb(107, 114, 128));
                news2FooterRiskView.setBackground(roundedDrawable(Color.rgb(243, 244, 246), dp(16), 0, 0));
            }
            updateAssessmentStatusCard();
            return;
        }

        int color = Color.parseColor(news2AlertColor());
        String risk = news2RiskText();
        String action = news2ActionText();
        String monitoring = news2MonitoringText();
        String highestCriterion = highestNews2CriterionText();
        if (quickSummaryView != null) {
            quickSummaryView.setText(getString(R.string.quick_summary_format, assessment.news2Total, risk, action));
            quickSummaryView.setTextColor(Color.WHITE);
            quickSummaryView.setBackground(roundedDrawable(color, dp(18), 0, 0));
        }
        if (news2RiskView != null) {
            news2RiskView.setText(risk);
            news2RiskView.setTextColor(Color.WHITE);
            news2RiskView.setBackground(roundedDrawable(color, dp(18), 0, 0));
        }
        if (news2TotalView != null) {
            news2TotalView.setText(getString(R.string.news2_total_format, assessment.news2Total));
            news2TotalView.setTextColor(color);
        }
        if (news2ActionView != null) {
            news2ActionView.setText("• " + action);
        }
        if (news2MonitoringView != null) {
            news2MonitoringView.setText("• " + monitoring);
        }
        if (news2HighestCriterionView != null) {
            news2HighestCriterionView.setText("• " + highestCriterion + "\n• " + getString(R.string.clinical_disclaimer));
        }
        if (news2FooterScoreView != null) {
            news2FooterScoreView.setText(getString(R.string.news2_footer_score_format, assessment.news2Total));
            news2FooterScoreView.setTextColor(COLOR_TEXT_PRIMARY);
        }
        if (news2FooterRiskView != null) {
            news2FooterRiskView.setText(risk);
            news2FooterRiskView.setTextColor(Color.WHITE);
            news2FooterRiskView.setBackground(roundedDrawable(color, dp(16), 0, 0));
        }
        updateAssessmentStatusCard();
    }

    private void updateQsofaSofaViews() {
        if (qsofaTotalView != null) {
            String qsofaText = getString(R.string.qsofa_total_format, assessment.qsofaTotal) + "\n"
                    + (assessment.qsofaTotal >= 2 ? getString(R.string.qsofa_risk_high) : getString(R.string.qsofa_risk_low));
            qsofaTotalView.setText(qsofaText);
            qsofaTotalView.setTextColor(assessment.qsofaTotal >= 2 ? Color.rgb(220, 38, 38) : COLOR_PRIMARY_DARK);
        }
        if (sofaTotalView != null) {
            sofaTotalView.setText(getString(R.string.sofa_total_format, assessment.sofaTotal) + "\n" + sofaInterpretationText());
            sofaTotalView.setTextColor(assessment.sofaTotal >= 9 ? Color.rgb(220, 38, 38) : COLOR_PRIMARY_DARK);
        }
        if (sepsisDiagnosisView != null) {
            sepsisDiagnosisView.setText(assessment.sepsisDiagnosis);
            sepsisDiagnosisView.setTextColor(assessment.sofaTotal >= 2 ? Color.rgb(220, 38, 38) : COLOR_PRIMARY_DARK);
        }
    }

    private String sofaInterpretationText() {
        int riskGroup = SofaScoring.riskGroup(assessment.sofaTotal);
        if (riskGroup == SofaScoring.RISK_HIGH) {
            return getString(R.string.sofa_interpretation_high);
        }
        if (riskGroup == SofaScoring.RISK_INTERMEDIATE) {
            return getString(R.string.sofa_interpretation_intermediate);
        }
        return getString(R.string.sofa_interpretation_low);
    }

    private int completedNews2Count() {
        return News2InputValidator.completedRequiredCount(assessment);
    }

    private List<String> missingNews2Fields() {
        return News2InputValidator.missingRequiredFields(assessment);
    }

    private String news2RiskText() {
        if (assessment.news2Total >= 7) {
            return getString(R.string.news2_risk_emergency);
        }
        if (assessment.news2Total >= 5) {
            return getString(R.string.news2_risk_urgent);
        }
        if (hasSingleThreeScore()) {
            return getString(R.string.news2_risk_single_three);
        }
        if (assessment.news2Total == 0) {
            return getString(R.string.news2_risk_low_zero);
        }
        return getString(R.string.news2_risk_low);
    }

    private String news2ActionText() {
        if (assessment.news2Total >= 7) {
            return getString(R.string.news2_action_emergency);
        }
        if (assessment.news2Total >= 5) {
            return getString(R.string.news2_action_urgent);
        }
        if (hasSingleThreeScore()) {
            return getString(R.string.news2_action_single_three);
        }
        return getString(R.string.news2_action_low);
    }

    private String news2MonitoringText() {
        if (assessment.news2Total >= 7) {
            return getString(R.string.news2_monitoring_emergency);
        }
        if (assessment.news2Total >= 5 || hasSingleThreeScore()) {
            return getString(R.string.news2_monitoring_hourly);
        }
        if (assessment.news2Total == 0) {
            return getString(R.string.news2_monitoring_low_zero);
        }
        return getString(R.string.news2_monitoring_low);
    }

    private String news2AlertColor() {
        if (assessment.news2Total >= 7) {
            return "#DC2626";
        }
        if (assessment.news2Total >= 5) {
            return "#F97316";
        }
        if (hasSingleThreeScore()) {
            return "#EAB308";
        }
        return "#10B981";
    }

    private boolean hasSingleThreeScore() {
        return News2Scoring.hasSingleThreeScore(assessment);
    }

    private String highestNews2CriterionText() {
        StringBuilder builder = new StringBuilder(getString(R.string.news2_highest_prefix));
        appendCriterion(builder, getString(R.string.news2_respiration), assessment.news2RespirationOption, assessment.news2Respiration);
        appendCriterion(builder, getString(R.string.news2_spo2), assessment.news2Spo2Option, assessment.news2Spo2);
        appendCriterion(builder, getString(R.string.news2_oxygen), assessment.news2OxygenOption, assessment.news2Oxygen);
        appendCriterion(builder, getString(R.string.news2_temperature), assessment.news2TemperatureOption, assessment.news2Temperature);
        appendCriterion(builder, getString(R.string.news2_systolic_bp), assessment.news2SystolicBpOption, assessment.news2SystolicBp);
        appendCriterion(builder, getString(R.string.news2_heart_rate), assessment.news2HeartRateOption, assessment.news2HeartRate);
        appendCriterion(builder, getString(R.string.news2_consciousness), assessment.news2ConsciousnessOption, assessment.news2Consciousness);
        if (builder.length() == getString(R.string.news2_highest_prefix).length()) {
            return getString(R.string.news2_highest_empty);
        }
        return builder.toString();
    }

    private void appendCriterion(StringBuilder builder, String label, String option, int score) {
        if (score < 3) {
            return;
        }
        if (builder.length() > getString(R.string.news2_highest_prefix).length()) {
            builder.append("; ");
        }
        String displayOption = hasText(option) ? option.trim() : getString(R.string.measured_value);
        builder.append(getString(R.string.news2_highest_item_format, label, displayOption, score));
    }

    private boolean hasMinimalAssessmentData() {
        boolean hasPatient = hasText(assessment.patientId) || hasText(assessment.fullName);
        boolean hasMeasuredNews2Input = hasText(assessment.news2RespirationMeasured) || hasText(assessment.news2Spo2Measured)
                || hasText(assessment.news2OxygenMeasured) || hasText(assessment.news2TemperatureMeasured)
                || hasText(assessment.news2SystolicBpMeasured) || hasText(assessment.news2HeartRateMeasured)
                || hasText(assessment.news2ConsciousnessMeasured);
        boolean hasSelectedNews2Option = findCheckedRadioButton(news2RespirationGroup) != null
                || findCheckedRadioButton(news2Spo2Group) != null
                || findCheckedRadioButton(news2OxygenGroup) != null
                || findCheckedRadioButton(news2TemperatureGroup) != null
                || findCheckedRadioButton(news2SystolicBpGroup) != null
                || findCheckedRadioButton(news2HeartRateGroup) != null
                || findCheckedRadioButton(news2ConsciousnessGroup) != null;
        return hasPatient && (hasMeasuredNews2Input || hasSelectedNews2Option);
    }

    private String buildSepsisDiagnosis() {
        if (SofaScoring.hasSepticShock(assessment)) {
            return getString(R.string.diagnosis_shock);
        }
        if (SofaScoring.hasSepsisBySofa(assessment)) {
            return getString(R.string.diagnosis_sepsis);
        }
        return getString(R.string.diagnosis_no_sepsis);
    }

    private void markAssessmentModified() {
        long now = System.currentTimeMillis();
        if (assessment.createdAtMillis <= 0) {
            assessment.createdAtMillis = assessment.savedAtMillis > 0 ? assessment.savedAtMillis : now;
        }
        assessment.modifiedAtMillis = now;
        assessment.savedAtMillis = now;
    }

    private void saveCurrentAssessment() {
        assessmentRepository.saveCurrentAssessment(assessment);
    }

    private void appendAssessmentHistory() {
        assessmentRepository.appendAssessmentHistory(assessment);
    }

    private ClinicalAssessment loadCurrentAssessment() {
        return assessmentRepository.loadCurrentAssessment();
    }

    private List<ClinicalAssessment> loadAssessmentHistory() {
        return assessmentRepository.loadAssessmentHistory();
    }

    private ClinicalAssessment cloneAssessment(ClinicalAssessment source) {
        if (source == null) {
            return new ClinicalAssessment();
        }
        return App.self().getGSon().fromJson(App.self().getGSon().toJson(source), ClinicalAssessment.class);
    }

    private void addWorkflowControls(LinearLayout container) {
        workflowProgressView = addAlertText(container, "", "#1565C0");
        LinearLayout controls = new LinearLayout(this);
        controls.setOrientation(LinearLayout.HORIZONTAL);
        controls.setPadding(0, dp(10), 0, dp(10));
        previousStepButton = new Button(this);
        stylePrimaryButton(previousStepButton, false);
        previousStepButton.setText(R.string.workflow_previous);
        previousStepButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                goToWorkflowStep(currentWorkflowStep - 1);
            }
        });
        nextStepButton = new Button(this);
        stylePrimaryButton(nextStepButton, true);
        nextStepButton.setText(R.string.workflow_next);
        nextStepButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                goToWorkflowStep(currentWorkflowStep + 1);
            }
        });
        LinearLayout.LayoutParams previousParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        previousParams.setMargins(0, 0, dp(6), 0);
        LinearLayout.LayoutParams nextParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        nextParams.setMargins(dp(6), 0, 0, 0);
        controls.addView(previousStepButton, previousParams);
        controls.addView(nextStepButton, nextParams);
        container.addView(controls, matchWrapParams());
    }

    private LinearLayout addWorkflowStep(LinearLayout container, int titleResId, int hintResId) {
        CardView cardView = new CardView(this);
        cardView.setCardBackgroundColor(COLOR_CARD_BACKGROUND);
        cardView.setRadius(dp(22));
        cardView.setCardElevation(dp(3));
        cardView.setUseCompatPadding(true);

        LinearLayout stepContainer = new LinearLayout(this);
        stepContainer.setOrientation(LinearLayout.VERTICAL);
        stepContainer.setPadding(dp(18), dp(14), dp(18), dp(18));
        addSection(stepContainer, getString(titleResId));
        TextView hint = addLabel(stepContainer, getString(hintResId));
        hint.setTextColor(COLOR_TEXT_SECONDARY);
        hint.setBackground(roundedDrawable(Color.rgb(240, 253, 250), dp(14), dp(1), Color.rgb(153, 246, 228)));
        hint.setPadding(dp(12), dp(10), dp(12), dp(10));
        cardView.addView(stepContainer, matchWrapParams());
        workflowStepContainers.add(cardView);
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, dp(6), 0, dp(14));
        container.addView(cardView, params);
        return stepContainer;
    }

    private void goToWorkflowStep(int step) {
        if (step < 0 || step >= STEP_COUNT) {
            return;
        }
        currentWorkflowStep = step;
        updateWorkflowStepVisibility();
    }

    private void updateWorkflowStepVisibility() {
        for (int i = 0; i < workflowStepContainers.size(); i++) {
            View stepView = workflowStepContainers.get(i);
            boolean visible = i == currentWorkflowStep;
            if (visible && stepView.getVisibility() != View.VISIBLE) {
                stepView.setAlpha(0f);
                stepView.setTranslationY(dp(10));
                stepView.setVisibility(View.VISIBLE);
                stepView.animate().alpha(1f).translationY(0f).setDuration(220).start();
            } else if (!visible) {
                stepView.setVisibility(View.GONE);
            }
        }
        if (workflowProgressView != null) {
            workflowProgressView.setText(getWorkflowProgressText());
        }
        if (previousStepButton != null) {
            previousStepButton.setEnabled(currentWorkflowStep > 0);
        }
        if (nextStepButton != null) {
            nextStepButton.setEnabled(currentWorkflowStep < STEP_COUNT - 1);
            nextStepButton.setText(currentWorkflowStep == STEP_COUNT - 1 ? R.string.workflow_reviewing : R.string.workflow_next);
        }
        updateAssessmentStatusCard();
    }

    private String getWorkflowProgressText() {
        int titleResId;
        switch (currentWorkflowStep) {
            case 0:
                titleResId = R.string.workflow_step_patient;
                break;
            case 1:
                titleResId = R.string.workflow_step_news2;
                break;
            case 2:
                titleResId = R.string.workflow_step_qsofa_lactate;
                break;
            case 3:
                titleResId = R.string.workflow_step_sofa;
                break;
            default:
                titleResId = R.string.workflow_step_save;
                break;
        }
        return getString(R.string.workflow_progress_format, currentWorkflowStep + 1, STEP_COUNT, getString(titleResId));
    }

    private void configureFixedAssessmentStatusCard() {
        if (assessmentStatusContainer == null) {
            return;
        }
        assessmentStatusContainer.removeAllViews();
        assessmentStatusContainer.setVisibility(View.VISIBLE);
        assessmentStatusContainer.setPadding(dp(16), dp(14) + systemBarDimension("status_bar_height"), dp(16), 0);

        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.VERTICAL);
        header.setPadding(dp(16), dp(14), dp(16), dp(14));
        header.setBackground(roundedDrawable(Color.argb(248, 255, 255, 255), dp(22), dp(1), Color.rgb(229, 231, 235)));

        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(android.view.Gravity.CENTER_VERTICAL);

        Button backButton = new Button(this);
        backButton.setText("‹");
        backButton.setTextSize(26);
        backButton.setTextColor(COLOR_PRIMARY_DARK);
        backButton.setContentDescription(getString(R.string.patient_list_back_assessment));
        backButton.setBackground(roundedDrawable(Color.rgb(239, 246, 255), dp(18), dp(1), Color.rgb(191, 219, 254)));
        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showPatientListScreen();
            }
        });
        titleRow.addView(backButton, new LinearLayout.LayoutParams(dp(46), dp(42)));

        LinearLayout statusStack = new LinearLayout(this);
        statusStack.setOrientation(LinearLayout.VERTICAL);
        statusStack.setPadding(dp(10), 0, 0, 0);
        assessmentStatusTitleView = new TextView(this);
        assessmentStatusTitleView.setTextColor(COLOR_TEXT_PRIMARY);
        assessmentStatusTitleView.setTextSize(18);
        assessmentStatusTitleView.setTypeface(Typeface.DEFAULT_BOLD);
        statusStack.addView(assessmentStatusTitleView, matchWrapParams());

        assessmentStatusScoreView = new TextView(this);
        assessmentStatusScoreView.setTextSize(14);
        assessmentStatusScoreView.setTypeface(Typeface.DEFAULT_BOLD);
        assessmentStatusScoreView.setPadding(0, dp(3), 0, 0);
        statusStack.addView(assessmentStatusScoreView, matchWrapParams());

        assessmentStatusRiskView = new TextView(this);
        assessmentStatusRiskView.setTextSize(13);
        assessmentStatusRiskView.setPadding(0, dp(3), 0, 0);
        statusStack.addView(assessmentStatusRiskView, matchWrapParams());
        titleRow.addView(statusStack, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

        Button resetButton = new Button(this);
        resetButton.setText("↻");
        resetButton.setTextSize(18);
        resetButton.setTextColor(Color.rgb(75, 85, 99));
        resetButton.setBackground(roundedDrawable(Color.rgb(243, 244, 246), dp(18), 0, 0));
        resetButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                assessment = new ClinicalAssessment();
                bindAssessmentToViews();
                recalculateAndSave(false);
                ScrollView scrollView = (ScrollView) findViewById(R.id.assessment_scroll);
                if (scrollView != null) {
                    scrollView.smoothScrollTo(0, 0);
                }
            }
        });
        titleRow.addView(resetButton, new LinearLayout.LayoutParams(dp(46), dp(42)));
        header.addView(titleRow, matchWrapParams());

        assessmentStatusProgressView = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        assessmentStatusProgressView.setProgressBackgroundTintList(ColorStateList.valueOf(Color.rgb(243, 244, 246)));
        LinearLayout.LayoutParams progressParams = matchWrapParams();
        progressParams.setMargins(0, dp(12), 0, 0);
        header.addView(assessmentStatusProgressView, progressParams);

        assessmentStatusContainer.addView(header, matchWrapParams());
        updateAssessmentStatusCard();
        updateAssessmentFormPaddingForFixedStatus();
    }

    private void updateAssessmentFormPaddingForFixedStatus() {
        if (assessmentStatusContainer == null || formContainer == null || !showingAssessment) {
            return;
        }
        assessmentStatusContainer.post(new Runnable() {
            @Override
            public void run() {
                int measuredHeight = assessmentStatusContainer.getHeight();
                int fallbackHeight = dp(ASSESSMENT_STATUS_FALLBACK_HEIGHT_DP) + systemBarDimension("status_bar_height");
                int topPadding = (measuredHeight > 0 ? measuredHeight : fallbackHeight) + dp(12);
                setAssessmentFormPadding(formContainer, topPadding);
            }
        });
    }

    private void setAssessmentFormPadding(LinearLayout container, int topPadding) {
        container.setPadding(dp(16), topPadding, dp(16), dp(26) + systemBarDimension("navigation_bar_height"));
    }

    private void updateAssessmentStatusCard() {
        if (assessmentStatusTitleView == null || assessmentStatusScoreView == null
                || assessmentStatusRiskView == null || assessmentStatusProgressView == null || assessment == null) {
            return;
        }
        switch (currentWorkflowStep) {
            case 0:
                updatePatientStatusCard();
                break;
            case 1:
                updateNews2StatusCard();
                break;
            case 2:
                updateQsofaStatusCard();
                break;
            case 3:
                updateSofaStatusCard();
                break;
            default:
                updateReviewStatusCard();
                break;
        }
    }

    private void updatePatientStatusCard() {
        boolean ready = hasText(assessment.patientId) || hasText(assessment.fullName);
        int color = ready ? News2Scoring.COLOR_SUCCESS : COLOR_TEXT_SECONDARY;
        setAssessmentStatus(
                getString(R.string.assessment_status_patient_title),
                getString(R.string.assessment_status_score_format, ready ? "1/1" : "0/1"),
                ready ? getString(R.string.assessment_status_patient_ready) : getString(R.string.assessment_status_patient_missing),
                color,
                ready ? 1 : 0,
                1);
    }

    private void updateNews2StatusCard() {
        int completed = completedNews2Count();
        boolean complete = missingNews2Fields().isEmpty();
        int color = complete ? News2Scoring.riskColor(assessment) : COLOR_TEXT_SECONDARY;
        String risk = complete ? news2RiskText() : getString(R.string.news2_missing_required_title);
        setAssessmentStatus(
                getString(R.string.news2_screen_title) + " (" + completed + "/7)",
                getString(R.string.assessment_status_score_format, assessment.news2Total + "/21"),
                risk,
                color,
                completed,
                7);
    }

    private void updateQsofaStatusCard() {
        int completed = completedQsofaCount();
        int color = assessment.qsofaTotal >= 2 ? Color.rgb(220, 38, 38) : News2Scoring.COLOR_SUCCESS;
        String risk = assessment.qsofaTotal >= 2 ? getString(R.string.qsofa_risk_high) : getString(R.string.qsofa_risk_low);
        setAssessmentStatus(
                getString(R.string.assessment_status_qsofa_title, completed, 3),
                getString(R.string.assessment_status_score_format, assessment.qsofaTotal + "/3"),
                risk,
                color,
                completed,
                3);
    }

    private void updateSofaStatusCard() {
        int completed = completedSofaCount();
        int color = assessment.sofaTotal >= 9 ? Color.rgb(220, 38, 38) : News2Scoring.COLOR_SUCCESS;
        setAssessmentStatus(
                getString(R.string.assessment_status_sofa_title, completed, 6),
                getString(R.string.assessment_status_score_format, assessment.sofaTotal + "/24"),
                sofaInterpretationText(),
                color,
                completed,
                6);
    }

    private void updateReviewStatusCard() {
        int completed = (missingNews2Fields().isEmpty() ? 1 : 0) + (completedQsofaCount() == 3 ? 1 : 0) + (completedSofaCount() > 0 ? 1 : 0);
        int color = assessment.sofaTotal >= 2 || assessment.qsofaTotal >= 2 || assessment.news2Total >= 5
                ? Color.rgb(220, 38, 38) : News2Scoring.COLOR_SUCCESS;
        setAssessmentStatus(
                getString(R.string.assessment_status_review_title, completed, 3),
                getString(R.string.assessment_status_score_format, getString(R.string.assessment_status_review_score, assessment.news2Total, assessment.qsofaTotal, assessment.sofaTotal)),
                buildSepsisDiagnosis(),
                color,
                completed,
                3);
    }

    private void setAssessmentStatus(String title, String score, String risk, int color, int progress, int max) {
        assessmentStatusTitleView.setText(title);
        assessmentStatusScoreView.setText(score);
        assessmentStatusScoreView.setTextColor(color);
        assessmentStatusRiskView.setText(risk);
        assessmentStatusRiskView.setTextColor(color);
        assessmentStatusProgressView.setMax(Math.max(1, max));
        assessmentStatusProgressView.setProgress(Math.max(0, Math.min(progress, max)));
        assessmentStatusProgressView.setProgressTintList(ColorStateList.valueOf(color));
    }

    private int completedQsofaCount() {
        int count = 0;
        count += hasText(assessment.news2RespirationMeasured) || findCheckedRadioButton(news2RespirationGroup) != null ? 1 : 0;
        count += hasText(assessment.news2SystolicBpMeasured) || findCheckedRadioButton(news2SystolicBpGroup) != null ? 1 : 0;
        count += hasText(assessment.news2ConsciousnessMeasured) || findCheckedRadioButton(news2ConsciousnessGroup) != null ? 1 : 0;
        return count;
    }

    private int completedSofaCount() {
        int count = 0;
        count += hasText(assessment.sofaRespirationMeasured) || findCheckedRadioButton(sofaRespirationGroup) != null ? 1 : 0;
        count += hasText(assessment.sofaCoagulationMeasured) || findCheckedRadioButton(sofaCoagulationGroup) != null ? 1 : 0;
        count += hasText(assessment.sofaLiverMeasured) || findCheckedRadioButton(sofaLiverGroup) != null ? 1 : 0;
        count += hasText(assessment.sofaCardiovascularMeasured) || findCheckedRadioButton(sofaCardiovascularGroup) != null ? 1 : 0;
        count += hasText(assessment.sofaNeurologicMeasured) || findCheckedRadioButton(sofaNeurologicGroup) != null ? 1 : 0;
        count += hasText(assessment.sofaRenalMeasured) || findCheckedRadioButton(sofaRenalGroup) != null ? 1 : 0;
        return count;
    }

    private void addPatientInfoCard(LinearLayout container) {
        CardView cardView = new CardView(this);
        cardView.setCardBackgroundColor(Color.WHITE);
        cardView.setRadius(dp(22));
        cardView.setCardElevation(dp(1));
        cardView.setUseCompatPadding(true);

        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(16));

        TextView title = new TextView(this);
        title.setText(R.string.patient_info_quick_title);
        title.setTextColor(COLOR_TEXT_PRIMARY);
        title.setTextSize(17);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        card.addView(title, matchWrapParams());

        TextView hint = new TextView(this);
        hint.setText(R.string.patient_info_quick_hint);
        hint.setTextColor(COLOR_TEXT_SECONDARY);
        hint.setTextSize(13);
        hint.setLineSpacing(dp(2), 1.0f);
        hint.setPadding(0, dp(4), 0, dp(8));
        card.addView(hint, matchWrapParams());

        patientIdView = addEditText(card, getString(R.string.patient_id));
        fullNameView = addEditText(card, getString(R.string.full_name));
        ageView = addNumberEditText(card, getString(R.string.age));
        wardView = addEditText(card, getString(R.string.ward));
        admissionDateTimeView = addDateTimeEditText(card, getString(R.string.admission_datetime));
        suspectedInfectionView = addEditText(card, getString(R.string.suspected_infection));

        cardView.addView(card, matchWrapParams());
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, 0, 0, dp(12));
        container.addView(cardView, params);
    }

    private void addSpo2ScaleCard(LinearLayout container) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(android.view.Gravity.CENTER_VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(14));
        card.setBackground(roundedDrawable(Color.rgb(239, 246, 255), dp(20), dp(1), Color.rgb(219, 234, 254)));

        LinearLayout copy = new LinearLayout(this);
        copy.setOrientation(LinearLayout.VERTICAL);
        TextView title = new TextView(this);
        title.setText(R.string.news2_spo2_scale_question);
        title.setTextColor(Color.rgb(30, 58, 138));
        title.setTextSize(14);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        copy.addView(title, matchWrapParams());
        TextView subtitle = new TextView(this);
        subtitle.setText(R.string.news2_spo2_scale_hint);
        subtitle.setTextColor(Color.rgb(29, 78, 216));
        subtitle.setTextSize(12);
        subtitle.setLineSpacing(dp(2), 1.0f);
        subtitle.setPadding(0, dp(4), 0, 0);
        copy.addView(subtitle, matchWrapParams());
        card.addView(copy, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

        news2Spo2Scale2View = new CheckBox(this);
        news2Spo2Scale2View.setText("");
        news2Spo2Scale2View.setButtonTintList(optionTintList());
        news2Spo2Scale2View.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (!isBinding) {
                    updateAssessmentFromViews();
                    assessment.news2Spo2Scale2 = isChecked;
                    assessment.news2Spo2 = 0;
                    assessment.news2Spo2Option = "";
                    initializeAssessmentForm(formContainer);
                    recalculateAndSave(false);
                }
            }
        });
        card.addView(news2Spo2Scale2View, new LinearLayout.LayoutParams(dp(48), dp(48)));

        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, 0, 0, dp(14));
        container.addView(card, params);
    }

    private News2CriterionViews addNews2MeasuredCriterionCard(LinearLayout container, String title, String subtitle, String hint, boolean numberOnly, String[] options, int[] scores) {
        CardView cardView = new CardView(this);
        cardView.setCardBackgroundColor(COLOR_CARD_BACKGROUND);
        cardView.setRadius(dp(22));
        cardView.setCardElevation(dp(1));
        cardView.setUseCompatPadding(true);

        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(16));

        TextView titleView = new TextView(this);
        titleView.setText(title);
        titleView.setTextColor(COLOR_TEXT_PRIMARY);
        titleView.setTextSize(16);
        titleView.setTypeface(Typeface.DEFAULT_BOLD);
        card.addView(titleView, matchWrapParams());
        if (subtitle != null && !subtitle.isEmpty()) {
            TextView subtitleView = new TextView(this);
            subtitleView.setText(subtitle);
            subtitleView.setTextColor(Color.rgb(107, 114, 128));
            subtitleView.setTextSize(12);
            subtitleView.setPadding(0, dp(3), 0, dp(4));
            card.addView(subtitleView, matchWrapParams());
        }

        EditText measuredView = numberOnly ? addNumberEditText(card, hint + " • " + getString(R.string.measured_value)) : addEditText(card, hint + " • " + getString(R.string.measured_value));
        RadioGroup group = createScoreRadioGroup(options, scores);
        card.addView(group, matchWrapParams());
        cardView.addView(card, matchWrapParams());
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, 0, 0, dp(10));
        container.addView(cardView, params);
        return new News2CriterionViews(measuredView, group);
    }

    private void addQsofaLactateCard(LinearLayout container) {
        CardView cardView = new CardView(this);
        cardView.setCardBackgroundColor(Color.WHITE);
        cardView.setRadius(dp(22));
        cardView.setCardElevation(dp(1));
        cardView.setUseCompatPadding(true);
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(16));
        addSection(card, getString(R.string.section_qsofa));
        qsofaRespirationView = addCheckBox(card, getString(R.string.qsofa_respiration));
        qsofaSystolicBpView = addCheckBox(card, getString(R.string.qsofa_systolic_bp));
        qsofaConsciousnessView = addCheckBox(card, getString(R.string.qsofa_consciousness));
        qsofaTotalView = addTotalText(card, getString(R.string.qsofa_total_format, assessment.qsofaTotal));
        addSection(card, getString(R.string.section_lactate));
        lactateView = addDecimalEditText(card, getString(R.string.lactate_value));
        lactateSampleTimeView = addDateTimeEditText(card, getString(R.string.lactate_sample_time));
        lactateLevelGroup = addRadioGroup(card, getString(R.string.lactate_level), new String[]{"< 2 mmol/L", "≥ 2 mmol/L", "≥ 4 mmol/L"}, null);
        cardView.addView(card, matchWrapParams());
        container.addView(cardView, matchWrapParams());
    }

    private void addSofaCard(LinearLayout container) {
        CardView cardView = new CardView(this);
        cardView.setCardBackgroundColor(Color.WHITE);
        cardView.setRadius(dp(22));
        cardView.setCardElevation(dp(1));
        cardView.setUseCompatPadding(true);
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(16));
        addSection(card, getString(R.string.section_sofa));
        TextView note = addLabel(card, getString(R.string.sofa_missing_note));
        note.setTextColor(COLOR_TEXT_SECONDARY);
        sofaRespirationMeasuredView = addEditText(card, getString(R.string.sofa_respiration) + " • PaO2/FiO2");
        sofaRespirationGroup = addScoreRadioGroup(card, getString(R.string.sofa_respiration), new String[]{"≥ 400", "< 400", "< 300", "< 200 + hỗ trợ hô hấp", "< 100 + hỗ trợ hô hấp"}, new int[]{0, 1, 2, 3, 4});
        sofaCoagulationMeasuredView = addDecimalEditText(card, getString(R.string.sofa_coagulation) + " • x10³/µL");
        sofaCoagulationGroup = addScoreRadioGroup(card, getString(R.string.sofa_coagulation), new String[]{"≥ 150", "< 150", "< 100", "< 50", "< 20"}, new int[]{0, 1, 2, 3, 4});
        sofaLiverMeasuredView = addEditText(card, getString(R.string.sofa_liver) + " • mg/dL hoặc µmol/L");
        sofaLiverGroup = addScoreRadioGroup(card, getString(R.string.sofa_liver), new String[]{"< 1.2", "1.2 - 1.9", "2.0 - 5.9", "6.0 - 11.9", "≥ 12.0"}, new int[]{0, 1, 2, 3, 4});
        sofaCardiovascularMeasuredView = addEditText(card, getString(R.string.sofa_cardiovascular) + " • MAP/thuốc/liều");
        vasopressorView = addCheckBox(card, getString(R.string.vasopressor));
        sofaCardiovascularGroup = addScoreRadioGroup(card, getString(R.string.sofa_cardiovascular), new String[]{"MAP ≥ 70, không vận mạch", "MAP < 70", "Dopamine ≤ 5 hoặc Dobutamine", "Dopamine > 5 hoặc Epi/Norepi ≤ 0.1", "Dopamine > 15 hoặc Epi/Norepi > 0.1"}, new int[]{0, 1, 2, 3, 4});
        sofaNeurologicMeasuredView = addNumberEditText(card, getString(R.string.sofa_neurologic));
        sofaNeurologicGroup = addScoreRadioGroup(card, getString(R.string.sofa_neurologic), new String[]{"15", "13 - 14", "10 - 12", "6 - 9", "< 6"}, new int[]{0, 1, 2, 3, 4});
        sofaRenalMeasuredView = addEditText(card, getString(R.string.sofa_renal) + " • mg/dL/µmol/L hoặc nước tiểu mL/ngày");
        sofaRenalGroup = addScoreRadioGroup(card, getString(R.string.sofa_renal), new String[]{"Cr < 1.2", "Cr 1.2 - 1.9", "Cr 2.0 - 3.4", "Cr 3.5 - 4.9 hoặc nước tiểu < 500", "Cr ≥ 5.0 hoặc nước tiểu < 200"}, new int[]{0, 1, 2, 3, 4});
        sofaTotalView = addTotalText(card, getString(R.string.sofa_total_format, assessment.sofaTotal));
        sepsisDiagnosisView = addTotalText(card, buildSepsisDiagnosis());
        cardView.addView(card, matchWrapParams());
        container.addView(cardView, matchWrapParams());
    }

    private void addSaveReviewCard(LinearLayout container) {
        CardView cardView = new CardView(this);
        cardView.setCardBackgroundColor(Color.WHITE);
        cardView.setRadius(dp(22));
        cardView.setCardElevation(dp(1));
        cardView.setUseCompatPadding(true);
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(16));
        addSection(card, getString(R.string.save_review_title));
        addLabel(card, getString(R.string.save_review_hint));
        addLabel(card, getString(R.string.clinical_disclaimer));
        treatmentOutcomeGroup = addRadioGroup(card, getString(R.string.treatment_outcome), new String[]{getString(R.string.outcome_recovered), getString(R.string.outcome_transfer), getString(R.string.outcome_death)}, null);
        treatmentDaysView = addNumberEditText(card, getString(R.string.treatment_days));
        cardView.addView(card, matchWrapParams());
        container.addView(cardView, matchWrapParams());
    }

    private RadioGroup addNews2CriterionCard(LinearLayout container, String title, String subtitle, String[] options, int[] scores) {
        CardView cardView = new CardView(this);
        cardView.setCardBackgroundColor(COLOR_CARD_BACKGROUND);
        cardView.setRadius(dp(22));
        cardView.setCardElevation(dp(1));
        cardView.setUseCompatPadding(true);

        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(16));

        TextView titleView = new TextView(this);
        titleView.setText(title);
        titleView.setTextColor(COLOR_TEXT_PRIMARY);
        titleView.setTextSize(16);
        titleView.setTypeface(Typeface.DEFAULT_BOLD);
        card.addView(titleView, matchWrapParams());
        if (subtitle != null && !subtitle.isEmpty()) {
            TextView subtitleView = new TextView(this);
            subtitleView.setText(subtitle);
            subtitleView.setTextColor(Color.rgb(107, 114, 128));
            subtitleView.setTextSize(12);
            subtitleView.setPadding(0, dp(3), 0, dp(4));
            card.addView(subtitleView, matchWrapParams());
        }

        RadioGroup group = createScoreRadioGroup(options, scores);
        card.addView(group, matchWrapParams());
        cardView.addView(card, matchWrapParams());
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, 0, 0, dp(10));
        container.addView(cardView, params);
        return group;
    }

    private RadioGroup createScoreRadioGroup(String[] options, int[] scores) {
        RadioGroup group = new RadioGroup(this);
        group.setOrientation(RadioGroup.VERTICAL);
        group.setPadding(0, dp(6), 0, 0);
        for (int i = 0; i < options.length; i++) {
            RadioButton radioButton = new RadioButton(this);
            radioButton.setId(View.generateViewId());
            int score = scores[i];
            radioButton.setText(options[i] + "\n" + score + " điểm");
            radioButton.setContentDescription(options[i]);
            radioButton.setTag(score);
            radioButton.setTextColor(COLOR_TEXT_PRIMARY);
            radioButton.setTextSize(14);
            radioButton.setTypeface(score == 3 ? Typeface.DEFAULT_BOLD : Typeface.DEFAULT);
            radioButton.setPadding(dp(14), dp(11), dp(14), dp(11));
            radioButton.setButtonTintList(optionTintList());
            radioButton.setBackground(checkedBackground(
                    scoreSoftColor(score),
                    Color.WHITE,
                    scoreAccentColor(score),
                    Color.rgb(229, 231, 235),
                    dp(16)));
            LinearLayout.LayoutParams optionParams = matchWrapParams();
            optionParams.setMargins(0, dp(4), 0, dp(4));
            group.addView(radioButton, optionParams);
        }
        group.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {
                recalculateAndSave(false);
            }
        });
        return group;
    }

    private void addNews2ResultCard(LinearLayout container) {
        CardView cardView = new CardView(this);
        cardView.setCardBackgroundColor(Color.WHITE);
        cardView.setRadius(dp(24));
        cardView.setCardElevation(dp(2));
        cardView.setUseCompatPadding(true);
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(16), dp(16), dp(16));
        news2RiskView = addAlertText(card, getString(R.string.news2_risk_empty), "#6B7280");
        news2TotalView = addTotalText(card, getString(R.string.news2_total));
        TextView guidanceTitle = addLabel(card, getString(R.string.news2_guidance_title));
        guidanceTitle.setTextColor(COLOR_TEXT_PRIMARY);
        guidanceTitle.setTypeface(Typeface.DEFAULT_BOLD);
        guidanceTitle.setTextSize(14);
        news2ActionView = addNews2GuidanceText(card, getString(R.string.news2_action_empty));
        news2MonitoringView = addNews2GuidanceText(card, getString(R.string.news2_monitoring_empty));
        news2HighestCriterionView = addNews2GuidanceText(card, getString(R.string.news2_highest_empty));
        cardView.addView(card, matchWrapParams());
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, dp(2), 0, dp(12));
        container.addView(cardView, params);
    }

    private void addNews2Footer(LinearLayout container) {
        LinearLayout footer = new LinearLayout(this);
        footer.setOrientation(LinearLayout.VERTICAL);
        footer.setPadding(dp(16), dp(14), dp(16), dp(14));
        footer.setBackground(roundedDrawable(Color.WHITE, dp(22), dp(1), Color.rgb(229, 231, 235)));

        LinearLayout scoreStack = new LinearLayout(this);
        scoreStack.setOrientation(LinearLayout.VERTICAL);
        TextView label = new TextView(this);
        label.setText(R.string.news2_footer_total_label);
        label.setTextColor(Color.rgb(156, 163, 175));
        label.setTextSize(11);
        label.setTypeface(Typeface.DEFAULT_BOLD);
        scoreStack.addView(label, matchWrapParams());
        news2FooterScoreView = new TextView(this);
        news2FooterScoreView.setText("-- điểm");
        news2FooterScoreView.setTextColor(Color.rgb(209, 213, 219));
        news2FooterScoreView.setTextSize(30);
        news2FooterScoreView.setTypeface(Typeface.DEFAULT_BOLD);
        scoreStack.addView(news2FooterScoreView, matchWrapParams());
        footer.addView(scoreStack, matchWrapParams());

        news2FooterRiskView = new TextView(this);
        news2FooterRiskView.setText(R.string.news2_evaluating);
        news2FooterRiskView.setTextColor(Color.rgb(107, 114, 128));
        news2FooterRiskView.setTextSize(14);
        news2FooterRiskView.setTypeface(Typeface.DEFAULT_BOLD);
        news2FooterRiskView.setPadding(dp(14), dp(12), dp(14), dp(12));
        news2FooterRiskView.setBackground(roundedDrawable(Color.rgb(243, 244, 246), dp(16), 0, 0));
        LinearLayout.LayoutParams riskParams = matchWrapParams();
        riskParams.setMargins(0, dp(10), 0, 0);
        footer.addView(news2FooterRiskView, riskParams);

        container.addView(footer, matchWrapParams());

        LinearLayout actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        actions.setPadding(0, dp(10), 0, 0);
        Button backButton = new Button(this);
        backButton.setText(R.string.patient_list_back);
        stylePrimaryButton(backButton, false);
        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showPatientListScreen();
            }
        });
        Button saveButton = new Button(this);
        saveButton.setText(R.string.patient_list_save_patient);
        stylePrimaryButton(saveButton, true);
        saveButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                updateAssessmentFromViews();
                if (!missingNews2Fields().isEmpty()) {
                    Toast.makeText(MainActivity.this, getString(R.string.news2_missing_required_format, ClinicalValueParser.joinStrings(missingNews2Fields(), ", ")), Toast.LENGTH_SHORT).show();
                    return;
                }
                markAssessmentModified();
                appendAssessmentHistory();
                saveCurrentAssessment();
                Toast.makeText(MainActivity.this, R.string.patient_list_saved, Toast.LENGTH_SHORT).show();
                showPatientListScreen();
            }
        });
        LinearLayout.LayoutParams backParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        backParams.setMargins(0, 0, dp(6), 0);
        LinearLayout.LayoutParams saveParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        saveParams.setMargins(dp(6), 0, 0, 0);
        actions.addView(backButton, backParams);
        actions.addView(saveButton, saveParams);
        container.addView(actions, matchWrapParams());
    }

    private void addNews2HeaderCard(LinearLayout container) {
        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.VERTICAL);
        header.setPadding(dp(16), dp(14), dp(16), dp(14));
        header.setBackground(roundedDrawable(Color.rgb(239, 246, 255), dp(20), dp(1), Color.rgb(191, 219, 254)));

        TextView title = new TextView(this);
        title.setText(getString(R.string.section_news2));
        title.setTextColor(COLOR_PRIMARY_DARK);
        title.setTextSize(20);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        header.addView(title, matchWrapParams());

        TextView hint = new TextView(this);
        hint.setText(getString(R.string.news2_quick_hint));
        hint.setTextColor(Color.rgb(30, 64, 175));
        hint.setTextSize(13);
        hint.setLineSpacing(dp(2), 1.0f);
        hint.setPadding(0, dp(6), 0, 0);
        header.addView(hint, matchWrapParams());

        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, dp(6), 0, dp(14));
        container.addView(header, params);
    }

    private TextView addNews2GuidanceText(LinearLayout container, String text) {
        TextView textView = addLabel(container, "• " + text);
        textView.setTextColor(Color.rgb(55, 65, 81));
        textView.setTextSize(14);
        textView.setBackground(roundedDrawable(Color.rgb(255, 255, 255), dp(14), dp(1), Color.rgb(229, 231, 235)));
        textView.setPadding(dp(14), dp(10), dp(14), dp(10));
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) textView.getLayoutParams();
        params.setMargins(0, dp(4), 0, dp(6));
        textView.setLayoutParams(params);
        return textView;
    }

    private void styleScale2Toggle(CheckBox checkBox) {
        checkBox.setTextColor(Color.rgb(30, 64, 175));
        checkBox.setTypeface(Typeface.DEFAULT_BOLD);
        checkBox.setTextSize(14);
        checkBox.setBackground(checkedBackground(Color.rgb(219, 234, 254), Color.rgb(239, 246, 255), COLOR_PRIMARY, Color.rgb(191, 219, 254), dp(18)));
        checkBox.setPadding(dp(12), dp(10), dp(12), dp(10));
    }

    private android.graphics.drawable.StateListDrawable checkedBackground(int checkedColor, int uncheckedColor, int checkedStroke, int uncheckedStroke, int radius) {
        return ProCareUi.checkedBackground(checkedColor, uncheckedColor, checkedStroke, uncheckedStroke, radius, dp(1));
    }

    private int scoreAccentColor(int score) {
        return ProCareUi.scoreAccentColor(score);
    }

    private int scoreSoftColor(int score) {
        return ProCareUi.scoreSoftColor(score);
    }

    private Button addButton(LinearLayout container, String text) {
        Button button = new Button(this);
        button.setText(text);
        stylePrimaryButton(button, true);
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, dp(12), 0, dp(8));
        container.addView(button, params);
        return button;
    }

    private TextView addAlertText(LinearLayout container, String text, String color) {
        TextView textView = addLabel(container, text);
        int parsedColor = Color.parseColor(color);
        textView.setTextSize(16);
        textView.setTypeface(Typeface.DEFAULT_BOLD);
        textView.setTextColor(Color.WHITE);
        textView.setBackground(roundedDrawable(parsedColor, dp(18), 0, 0));
        textView.setPadding(dp(16), dp(14), dp(16), dp(14));
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) textView.getLayoutParams();
        params.setMargins(0, dp(6), 0, dp(10));
        textView.setLayoutParams(params);
        return textView;
    }

    private EditText addNumberEditText(LinearLayout container, String hint) {
        EditText editText = addEditText(container, hint);
        editText.setInputType(InputType.TYPE_CLASS_NUMBER);
        return editText;
    }

    private EditText addDecimalEditText(LinearLayout container, String hint) {
        EditText editText = addEditText(container, hint);
        editText.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        return editText;
    }

    private EditText addDateTimeEditText(LinearLayout container, String hint) {
        EditText editText = addEditText(container, hint);
        editText.setSingleLine(true);
        editText.setInputType(InputType.TYPE_CLASS_DATETIME | InputType.TYPE_DATETIME_VARIATION_NORMAL);
        return editText;
    }

    private EditText addEditText(LinearLayout container, String hint) {
        EditText editText = new EditText(this);
        editText.setHint(hint);
        editText.setSingleLine(false);
        editText.setMinLines(1);
        editText.setTextColor(COLOR_TEXT_PRIMARY);
        editText.setHintTextColor(Color.rgb(100, 116, 139));
        editText.setTextSize(16);
        editText.setPadding(dp(14), dp(12), dp(14), dp(12));
        editText.setBackground(roundedDrawable(COLOR_FIELD_BACKGROUND, dp(16), dp(1), COLOR_FIELD_STROKE));
        editText.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            @Override
            public void onFocusChange(View v, boolean hasFocus) {
                v.setBackground(roundedDrawable(COLOR_FIELD_BACKGROUND, dp(16), dp(1), hasFocus ? COLOR_PRIMARY : COLOR_FIELD_STROKE));
                v.animate().scaleX(hasFocus ? 1.01f : 1f).scaleY(hasFocus ? 1.01f : 1f).setDuration(150).start();
            }
        });
        editText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                recalculateAndSave(false);
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, dp(6), 0, dp(10));
        container.addView(editText, params);
        return editText;
    }

    private CheckBox addCheckBox(LinearLayout container, String text) {
        CheckBox checkBox = new CheckBox(this);
        checkBox.setText(text);
        checkBox.setTextColor(COLOR_TEXT_PRIMARY);
        checkBox.setTextSize(15);
        checkBox.setPadding(dp(10), dp(8), dp(10), dp(8));
        checkBox.setButtonTintList(optionTintList());
        checkBox.setBackground(roundedDrawable(Color.rgb(248, 250, 252), dp(14), dp(1), Color.rgb(226, 232, 240)));
        checkBox.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                recalculateAndSave(false);
            }
        });
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, dp(4), 0, dp(6));
        container.addView(checkBox, params);
        return checkBox;
    }

    private RadioGroup addScoreRadioGroup(LinearLayout container, String label, String[] options, int[] scores) {
        return addRadioGroup(container, label, options, scores);
    }

    private RadioGroup addRadioGroup(LinearLayout container, String label, String[] options, int[] scores) {
        TextView labelView = addLabel(container, label);
        labelView.setTypeface(Typeface.DEFAULT_BOLD);
        labelView.setTextColor(COLOR_TEXT_PRIMARY);
        labelView.setTextSize(16);
        RadioGroup group = new RadioGroup(this);
        group.setOrientation(RadioGroup.VERTICAL);
        group.setPadding(0, dp(2), 0, dp(10));
        for (int i = 0; i < options.length; i++) {
            RadioButton radioButton = new RadioButton(this);
            radioButton.setId(View.generateViewId());
            int score = scores == null ? -1 : scores[i];
            radioButton.setText(scores == null ? options[i] : options[i] + "\n" + scores[i] + " điểm");
            radioButton.setContentDescription(options[i]);
            radioButton.setTag(scores == null ? options[i] : scores[i]);
            radioButton.setTextColor(COLOR_TEXT_PRIMARY);
            radioButton.setTextSize(15);
            radioButton.setTypeface(score == 3 ? Typeface.DEFAULT_BOLD : Typeface.DEFAULT);
            radioButton.setPadding(dp(14), dp(12), dp(14), dp(12));
            radioButton.setButtonTintList(optionTintList());
            radioButton.setBackground(checkedBackground(
                    scoreSoftColor(score),
                    Color.WHITE,
                    scoreAccentColor(score),
                    Color.rgb(229, 231, 235),
                    dp(16)));
            LinearLayout.LayoutParams optionParams = matchWrapParams();
            optionParams.setMargins(0, dp(5), 0, dp(5));
            group.addView(radioButton, optionParams);
        }
        group.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {
                recalculateAndSave(false);
            }
        });
        container.addView(group, matchWrapParams());
        return group;
    }

    private TextView addTotalText(LinearLayout container, String text) {
        TextView textView = addLabel(container, text);
        textView.setTextSize(19);
        textView.setTypeface(Typeface.DEFAULT_BOLD);
        textView.setTextColor(COLOR_PRIMARY_DARK);
        textView.setBackground(roundedDrawable(Color.rgb(236, 253, 245), dp(18), dp(1), Color.rgb(153, 246, 228)));
        textView.setPadding(dp(16), dp(14), dp(16), dp(14));
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) textView.getLayoutParams();
        params.setMargins(0, dp(12), 0, dp(10));
        textView.setLayoutParams(params);
        return textView;
    }

    private void addTitle(LinearLayout container, String text) {
        TextView textView = addLabel(container, text);
        textView.setTextSize(25);
        textView.setTypeface(Typeface.DEFAULT_BOLD);
        textView.setTextColor(COLOR_TEXT_PRIMARY);
        textView.setPadding(0, dp(10), 0, dp(6));
    }

    private void addSection(LinearLayout container, String text) {
        TextView textView = addLabel(container, text);
        textView.setTextSize(20);
        textView.setTypeface(Typeface.DEFAULT_BOLD);
        textView.setTextColor(COLOR_PRIMARY_DARK);
        textView.setPadding(0, dp(16), 0, dp(8));
    }

    private TextView addLabel(LinearLayout container, String text) {
        TextView textView = new TextView(this);
        textView.setText(text);
        textView.setTextColor(COLOR_TEXT_SECONDARY);
        textView.setTextSize(15);
        textView.setLineSpacing(dp(2), 1.0f);
        textView.setPadding(0, dp(10), 0, dp(4));
        container.addView(textView, matchWrapParams());
        return textView;
    }

    private LinearLayout.LayoutParams matchWrapParams() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private LinearLayout.LayoutParams matchWrapParamsWithMargins(int left, int top, int right, int bottom) {
        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(left, top, right, bottom);
        return params;
    }

    private GradientDrawable roundedDrawable(int color, int radius, int strokeWidth, int strokeColor) {
        return ProCareUi.roundedDrawable(color, radius, strokeWidth, strokeColor);
    }

    private ColorStateList optionTintList() {
        return ProCareUi.optionTintList(COLOR_PRIMARY);
    }

    private void stylePrimaryButton(Button button, boolean filled) {
        ProCareUi.stylePrimaryButton(this, button, filled, COLOR_PRIMARY, COLOR_PRIMARY_DARK);
    }

    private void safelyCheckRadioByScore(RadioGroup group, int score) {
        boolean oldBinding = isBinding;
        isBinding = true;
        checkRadioByScore(group, score);
        isBinding = oldBinding;
    }

    private String optionByScore(RadioGroup group, int score) {
        if (group == null) {
            return "";
        }
        for (int i = 0; i < group.getChildCount(); i++) {
            View child = group.getChildAt(i);
            if (child.getTag() instanceof Integer && ((Integer) child.getTag()) == score && child.getContentDescription() != null) {
                return child.getContentDescription().toString();
            }
        }
        return selectedOption(group);
    }

    private String consciousnessOption(String measuredValue, RadioGroup group) {
        if (hasText(measuredValue)) {
            return measuredValue.trim();
        }
        return selectedOption(group);
    }

    private int selectedScore(RadioGroup group) {
        RadioButton checked = findCheckedRadioButton(group);
        if (checked == null || !(checked.getTag() instanceof Integer)) {
            return 0;
        }
        return (Integer) checked.getTag();
    }

    private String selectedText(RadioGroup group) {
        RadioButton checked = findCheckedRadioButton(group);
        if (checked == null) {
            return "";
        }
        Object tag = checked.getTag();
        return tag instanceof String ? (String) tag : checked.getText().toString();
    }

    private String selectedOption(RadioGroup group) {
        RadioButton checked = findCheckedRadioButton(group);
        if (checked == null || checked.getContentDescription() == null) {
            return "";
        }
        return checked.getContentDescription().toString();
    }

    private RadioButton findCheckedRadioButton(RadioGroup group) {
        if (group == null) {
            return null;
        }
        int checkedId = group.getCheckedRadioButtonId();
        return checkedId == -1 ? null : group.findViewById(checkedId);
    }

    private void checkRadioByScore(RadioGroup group, int score) {
        checkRadioByTag(group, score);
    }

    private void checkRadioByOption(RadioGroup group, String option, int fallbackScore) {
        if (group == null) {
            return;
        }
        if (option == null || option.isEmpty()) {
            group.clearCheck();
            return;
        }
        for (int i = 0; i < group.getChildCount(); i++) {
            View child = group.getChildAt(i);
            if (option.contentEquals(child.getContentDescription())) {
                group.check(child.getId());
                return;
            }
        }
        checkRadioByScore(group, fallbackScore);
    }

    private void checkRadioByText(RadioGroup group, String text) {
        if (group == null) {
            return;
        }
        if (text == null || text.isEmpty()) {
            group.clearCheck();
            return;
        }
        checkRadioByTag(group, text);
    }

    private void checkRadioByTag(RadioGroup group, Object tag) {
        if (group == null || tag == null) {
            return;
        }
        for (int i = 0; i < group.getChildCount(); i++) {
            View child = group.getChildAt(i);
            if (tag.equals(child.getTag())) {
                group.check(child.getId());
                return;
            }
        }
        group.clearCheck();
    }
}
