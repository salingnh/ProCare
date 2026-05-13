package com.sangnv.procare;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.graphics.Color;
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;
import android.view.Menu;
import android.view.MenuItem;
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
import com.sangnv.procare.ui.PatientListScreen;
import com.sangnv.procare.ui.ProCareUi;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.DateFormat;
import java.util.ArrayList;
import java.util.Date;
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


    private ClinicalAssessment assessment;
    private boolean isBinding;
    private boolean isFormReady;
    private boolean isDownloadingUpdate;
    private boolean showingAssessment;
    private boolean gridPatientView = true;
    private int currentWorkflowStep;
    private GitHubReleaseChecker gitHubReleaseChecker;
    private GitHubReleaseChecker.UpdateInfo availableUpdate;
    private final ExecutorService updateDownloadExecutor = Executors.newSingleThreadExecutor();
    private final AssessmentRepository assessmentRepository = new AssessmentRepository();
    private LinearLayout formContainer;
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
    private TextView patientSummaryListView;
    private TextView workflowProgressView;
    private TextView quickSummaryView;
    private TextView news2CompletionView;
    private ProgressBar news2CompletionProgressView;
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
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
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

    private void showPatientListScreen() {
        showingAssessment = false;
        isFormReady = false;
        formContainer.removeAllViews();
        formContainer.setPadding(dp(16), dp(18) + systemBarDimension("status_bar_height"), dp(16), dp(28) + systemBarDimension("navigation_bar_height"));
        new PatientListScreen(this, new PatientListScreen.Listener() {
            @Override
            public void onAddNewAssessment() {
                assessment = new ClinicalAssessment();
                initializeAssessmentForm(formContainer);
                recalculateAndSave(false);
            }

            @Override
            public void onViewModeChanged(boolean gridMode) {
                gridPatientView = gridMode;
                showPatientListScreen();
            }
        }, COLOR_PRIMARY, COLOR_PRIMARY_DARK, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY)
                .render(formContainer, loadAssessmentHistory(), gridPatientView);
        if (availableUpdate != null) {
            updateBannerView = null;
            showUpdateBanner(availableUpdate);
        }
    }

    private void initializeAssessmentForm(LinearLayout container) {
        showingAssessment = true;
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
        container.setPadding(dp(16), dp(14) + systemBarDimension("status_bar_height"), dp(16), dp(26) + systemBarDimension("navigation_bar_height"));

        addNews2TopBar(container);
        quickSummaryView = addAlertText(container, getString(R.string.quick_summary_empty), "#6B7280");

        addSpo2ScaleCard(container);
        news2RespirationGroup = addNews2CriterionCard(container, getString(R.string.news2_respiration), null,
                new String[]{"≤ 8", "9 - 11", "12 - 20", "21 - 24", "≥ 25"}, new int[]{3, 1, 0, 2, 3});
        if (assessment.news2Spo2Scale2) {
            news2Spo2Group = addNews2CriterionCard(container, getString(R.string.news2_spo2_scale2_title), getString(R.string.news2_spo2_scale2_subtitle),
                    new String[]{"≤ 83%", "84 - 85%", "86 - 87%", "88 - 92% (hoặc ≥ 93% khí phòng)", "93 - 94% (thở Oxy)", "95 - 96% (thở Oxy)", "≥ 97% (thở Oxy)"}, new int[]{3, 2, 1, 0, 1, 2, 3});
        } else {
            news2Spo2Group = addNews2CriterionCard(container, getString(R.string.news2_spo2_scale1_title), getString(R.string.news2_spo2_scale1_subtitle),
                    new String[]{"≤ 91%", "92 - 93%", "94 - 95%", "≥ 96%"}, new int[]{3, 2, 1, 0});
        }
        news2OxygenGroup = addNews2CriterionCard(container, getString(R.string.news2_oxygen), null,
                new String[]{"Thở khí phòng", "Thở Oxy"}, new int[]{0, 2});
        news2SystolicBpGroup = addNews2CriterionCard(container, getString(R.string.news2_systolic_bp), null,
                new String[]{"≤ 90", "91 - 100", "101 - 110", "111 - 219", "≥ 220"}, new int[]{3, 2, 1, 0, 3});
        news2HeartRateGroup = addNews2CriterionCard(container, getString(R.string.news2_heart_rate), null,
                new String[]{"≤ 40", "41 - 50", "51 - 90", "91 - 110", "111 - 130", "≥ 131"}, new int[]{3, 1, 0, 1, 2, 3});
        news2ConsciousnessGroup = addNews2CriterionCard(container, getString(R.string.news2_consciousness), null,
                new String[]{"A - Tỉnh táo (Alert)", "C/V/P/U - Lú lẫn, đáp ứng lời nói/đau hoặc không phản ứng"}, new int[]{0, 3});
        news2TemperatureGroup = addNews2CriterionCard(container, getString(R.string.news2_temperature), null,
                new String[]{"≤ 35.0", "35.1 - 36.0", "36.1 - 38.0", "38.1 - 39.0", "≥ 39.1"}, new int[]{3, 1, 0, 1, 2});

        addNews2ResultCard(container);
        addNews2Footer(container);
    }

    private void bindAssessmentToViews() {
        isBinding = true;
        if (news2Spo2Scale2View != null) {
            news2Spo2Scale2View.setChecked(assessment.news2Spo2Scale2);
        }
        checkRadioByOption(news2RespirationGroup, assessment.news2RespirationOption, assessment.news2Respiration);
        checkRadioByOption(news2Spo2Group, assessment.news2Spo2Option, assessment.news2Spo2);
        checkRadioByOption(news2OxygenGroup, assessment.news2OxygenOption, assessment.news2Oxygen);
        checkRadioByOption(news2SystolicBpGroup, assessment.news2SystolicBpOption, assessment.news2SystolicBp);
        checkRadioByOption(news2HeartRateGroup, assessment.news2HeartRateOption, assessment.news2HeartRate);
        checkRadioByOption(news2ConsciousnessGroup, assessment.news2ConsciousnessOption, assessment.news2Consciousness);
        checkRadioByOption(news2TemperatureGroup, assessment.news2TemperatureOption, assessment.news2Temperature);
        isBinding = false;
    }

    private void recalculateAndSave(boolean appendHistory) {
        if (isBinding || !isFormReady) {
            return;
        }

        updateAssessmentFromViews();
        assessment.news2Total = News2Scoring.total(assessment);
        assessment.savedAtMillis = System.currentTimeMillis();

        updateQuickSummaryViews();
        saveCurrentAssessment();
    }

    private void updateAssessmentFromViews() {
        assessment.news2Spo2Scale2 = news2Spo2Scale2View != null && news2Spo2Scale2View.isChecked();
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
    }

    private void applyNews2AutoScores() {
        assessment.news2Respiration = News2Scoring.scoreRespiration(parseInteger(assessment.news2RespirationMeasured), selectedScore(news2RespirationGroup));
        assessment.news2RespirationOption = optionByScore(news2RespirationGroup, assessment.news2Respiration);
        safelyCheckRadioByScore(news2RespirationGroup, assessment.news2Respiration);

        assessment.news2Spo2 = assessment.news2Spo2Scale2
                ? News2Scoring.scoreSpo2Scale2(parseInteger(assessment.news2Spo2Measured), assessment.news2Oxygen > 0, selectedScore(news2Spo2Group))
                : News2Scoring.scoreSpo2Scale1(parseInteger(assessment.news2Spo2Measured), selectedScore(news2Spo2Group));
        assessment.news2Spo2Option = assessment.news2Spo2Scale2
                ? getString(R.string.news2_spo2_scale2_option)
                : optionByScore(news2Spo2Group, assessment.news2Spo2);
        safelyCheckRadioByScore(news2Spo2Group, assessment.news2Spo2);

        assessment.news2Temperature = News2Scoring.scoreTemperature(parseDouble(assessment.news2TemperatureMeasured), selectedScore(news2TemperatureGroup));
        assessment.news2TemperatureOption = optionByScore(news2TemperatureGroup, assessment.news2Temperature);
        safelyCheckRadioByScore(news2TemperatureGroup, assessment.news2Temperature);

        assessment.news2SystolicBp = News2Scoring.scoreSystolicBp(parseInteger(assessment.news2SystolicBpMeasured), selectedScore(news2SystolicBpGroup));
        assessment.news2SystolicBpOption = optionByScore(news2SystolicBpGroup, assessment.news2SystolicBp);
        safelyCheckRadioByScore(news2SystolicBpGroup, assessment.news2SystolicBp);

        assessment.news2HeartRate = News2Scoring.scoreHeartRate(parseInteger(assessment.news2HeartRateMeasured), selectedScore(news2HeartRateGroup));
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
        Integer respiration = parseInteger(assessment.news2RespirationMeasured);
        Integer systolicBp = parseInteger(assessment.news2SystolicBpMeasured);
        if (respiration != null) {
            qsofaRespirationView.setChecked(respiration >= 22);
            assessment.qsofaRespiration = respiration >= 22;
        }
        if (systolicBp != null) {
            qsofaSystolicBpView.setChecked(systolicBp <= 100);
            assessment.qsofaSystolicBp = systolicBp <= 100;
        }
        boolean alteredConsciousness = assessment.news2Consciousness == 3;
        if (hasText(assessment.news2ConsciousnessMeasured) || findCheckedRadioButton(news2ConsciousnessGroup) != null) {
            qsofaConsciousnessView.setChecked(alteredConsciousness);
            assessment.qsofaConsciousness = alteredConsciousness;
        }
        isBinding = oldBinding;
    }

    private Integer parseInteger(String value) {
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

    private Double parseDouble(String value) {
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

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private void updateQuickSummaryViews() {
        int completedCount = completedNews2Count();
        boolean complete = completedCount == 7;
        if (news2CompletionView != null) {
            news2CompletionView.setText(getString(R.string.news2_completed_format, completedCount, 7));
        }
        if (news2CompletionProgressView != null) {
            news2CompletionProgressView.setProgress(completedCount);
        }

        if (!complete) {
            quickSummaryView.setText(getString(R.string.quick_summary_empty));
            quickSummaryView.setTextColor(Color.WHITE);
            quickSummaryView.setBackground(roundedDrawable(Color.rgb(107, 114, 128), dp(18), 0, 0));
            news2RiskView.setText(getString(R.string.news2_risk_empty));
            news2RiskView.setTextColor(Color.WHITE);
            news2RiskView.setBackground(roundedDrawable(Color.rgb(107, 114, 128), dp(18), 0, 0));
            news2TotalView.setText(getString(R.string.news2_total_pending));
            news2TotalView.setTextColor(Color.rgb(209, 213, 219));
            news2ActionView.setText("• " + getString(R.string.news2_action_empty));
            news2MonitoringView.setText("• " + getString(R.string.news2_monitoring_empty));
            news2HighestCriterionView.setText("• " + getString(R.string.news2_highest_empty));
            news2FooterScoreView.setText("-- điểm");
            news2FooterScoreView.setTextColor(Color.rgb(209, 213, 219));
            news2FooterRiskView.setText(R.string.news2_evaluating);
            news2FooterRiskView.setTextColor(Color.rgb(107, 114, 128));
            news2FooterRiskView.setBackground(roundedDrawable(Color.rgb(243, 244, 246), dp(16), 0, 0));
            return;
        }

        int color = Color.parseColor(news2AlertColor());
        String risk = news2RiskText();
        String action = news2ActionText();
        String monitoring = news2MonitoringText();
        String highestCriterion = highestNews2CriterionText();
        quickSummaryView.setText(getString(R.string.quick_summary_format, assessment.news2Total, risk, action));
        quickSummaryView.setTextColor(Color.WHITE);
        quickSummaryView.setBackground(roundedDrawable(color, dp(18), 0, 0));
        news2RiskView.setText(risk);
        news2RiskView.setTextColor(Color.WHITE);
        news2RiskView.setBackground(roundedDrawable(color, dp(18), 0, 0));
        news2TotalView.setText(getString(R.string.news2_total_format, assessment.news2Total));
        news2TotalView.setTextColor(color);
        news2ActionView.setText("• " + action);
        news2MonitoringView.setText("• " + monitoring);
        news2HighestCriterionView.setText("• " + highestCriterion);
        news2FooterScoreView.setText(getString(R.string.news2_footer_score_format, assessment.news2Total));
        news2FooterScoreView.setTextColor(COLOR_TEXT_PRIMARY);
        news2FooterRiskView.setText(risk);
        news2FooterRiskView.setTextColor(Color.WHITE);
        news2FooterRiskView.setBackground(roundedDrawable(color, dp(16), 0, 0));
    }

    private int completedNews2Count() {
        int count = 0;
        count += findCheckedRadioButton(news2RespirationGroup) == null ? 0 : 1;
        count += findCheckedRadioButton(news2Spo2Group) == null ? 0 : 1;
        count += findCheckedRadioButton(news2OxygenGroup) == null ? 0 : 1;
        count += findCheckedRadioButton(news2SystolicBpGroup) == null ? 0 : 1;
        count += findCheckedRadioButton(news2HeartRateGroup) == null ? 0 : 1;
        count += findCheckedRadioButton(news2ConsciousnessGroup) == null ? 0 : 1;
        count += findCheckedRadioButton(news2TemperatureGroup) == null ? 0 : 1;
        return count;
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
        appendCriterion(builder, getString(R.string.news2_respiration), assessment.news2Respiration);
        appendCriterion(builder, getString(R.string.news2_spo2), assessment.news2Spo2);
        appendCriterion(builder, getString(R.string.news2_oxygen), assessment.news2Oxygen);
        appendCriterion(builder, getString(R.string.news2_temperature), assessment.news2Temperature);
        appendCriterion(builder, getString(R.string.news2_systolic_bp), assessment.news2SystolicBp);
        appendCriterion(builder, getString(R.string.news2_heart_rate), assessment.news2HeartRate);
        appendCriterion(builder, getString(R.string.news2_consciousness), assessment.news2Consciousness);
        if (builder.length() == getString(R.string.news2_highest_prefix).length()) {
            return getString(R.string.news2_highest_empty);
        }
        return builder.toString();
    }

    private void appendCriterion(StringBuilder builder, String label, int score) {
        if (score < 3) {
            return;
        }
        if (builder.length() > getString(R.string.news2_highest_prefix).length()) {
            builder.append(", ");
        }
        builder.append(label);
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
        boolean hasSepsis = assessment.sofaTotal >= 2;
        boolean shock = assessment.vasopressor && lactateAtLeastTwo();
        if (shock) {
            return getString(R.string.diagnosis_shock);
        }
        if (hasSepsis) {
            return getString(R.string.diagnosis_sepsis);
        }
        return getString(R.string.diagnosis_no_sepsis);
    }

    private boolean lactateAtLeastTwo() {
        if (assessment.lactateLevel != null && !assessment.lactateLevel.isEmpty()) {
            return !assessment.lactateLevel.startsWith("<");
        }
        try {
            return Double.parseDouble(assessment.lactate.trim().replace(',', '.')) >= 2.0;
        } catch (NumberFormatException exception) {
            return false;
        }
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

    private void updatePatientSummaryList() {
        if (patientSummaryListView == null) {
            return;
        }
        List<ClinicalAssessment> history = loadAssessmentHistory();
        if (history.isEmpty()) {
            patientSummaryListView.setText(getString(R.string.patient_summary_empty));
            return;
        }
        StringBuilder builder = new StringBuilder(getString(R.string.patient_summary_title));
        int start = Math.max(0, history.size() - 10);
        for (int i = history.size() - 1; i >= start; i--) {
            ClinicalAssessment item = history.get(i);
            builder.append("\n\n• ").append(patientDisplayName(item));
            builder.append("\n  ").append(getString(R.string.patient_summary_scores_format,
                    item.news2Total,
                    riskTextForNews2(item),
                    item.qsofaTotal,
                    item.sofaTotal));
            if (hasText(item.sepsisDiagnosis)) {
                builder.append("\n  ").append(item.sepsisDiagnosis);
            }
            if (item.savedAtMillis > 0) {
                builder.append("\n  ").append(getString(R.string.patient_summary_saved_format,
                        DateFormat.getDateTimeInstance().format(new Date(item.savedAtMillis))));
            }
        }
        patientSummaryListView.setText(builder.toString());
    }

    private List<ClinicalAssessment> loadAssessmentHistory() {
        return assessmentRepository.loadAssessmentHistory();
    }

    private String patientDisplayName(ClinicalAssessment item) {
        if (hasText(item.fullName) && hasText(item.patientId)) {
            return getString(R.string.patient_summary_name_with_id, item.fullName.trim(), item.patientId.trim());
        }
        if (hasText(item.fullName)) {
            return item.fullName.trim();
        }
        if (hasText(item.patientId)) {
            return getString(R.string.patient_summary_id_only, item.patientId.trim());
        }
        return getString(R.string.patient_summary_unknown);
    }

    private String riskTextForNews2(ClinicalAssessment item) {
        if (item.news2Total >= 7) {
            return getString(R.string.news2_risk_emergency);
        }
        if (item.news2Total >= 5) {
            return getString(R.string.news2_risk_urgent);
        }
        if (hasSingleThreeScore(item)) {
            return getString(R.string.news2_risk_single_three);
        }
        if (item.news2Total == 0) {
            return getString(R.string.news2_risk_low_zero);
        }
        return getString(R.string.news2_risk_low);
    }

    private boolean hasSingleThreeScore(ClinicalAssessment item) {
        return News2Scoring.hasSingleThreeScore(item);
    }



    private void addNews2TopBar(LinearLayout container) {
        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.VERTICAL);
        header.setPadding(dp(16), dp(14), dp(16), dp(14));
        header.setBackground(roundedDrawable(Color.argb(238, 255, 255, 255), dp(22), dp(1), Color.rgb(229, 231, 235)));

        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(android.view.Gravity.CENTER_VERTICAL);

        TextView icon = new TextView(this);
        icon.setText("♥");
        icon.setTextSize(22);
        icon.setTypeface(Typeface.DEFAULT_BOLD);
        icon.setGravity(android.view.Gravity.CENTER);
        icon.setTextColor(COLOR_PRIMARY);
        icon.setBackground(roundedDrawable(Color.rgb(219, 234, 254), dp(12), 0, 0));
        LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(dp(42), dp(42));
        titleRow.addView(icon, iconParams);

        LinearLayout titleStack = new LinearLayout(this);
        titleStack.setOrientation(LinearLayout.VERTICAL);
        titleStack.setPadding(dp(10), 0, 0, 0);
        TextView title = new TextView(this);
        title.setText(R.string.news2_screen_title);
        title.setTextColor(COLOR_TEXT_PRIMARY);
        title.setTextSize(18);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        titleStack.addView(title, matchWrapParams());
        news2CompletionView = new TextView(this);
        news2CompletionView.setTextColor(Color.rgb(107, 114, 128));
        news2CompletionView.setTextSize(12);
        titleStack.addView(news2CompletionView, matchWrapParams());
        titleRow.addView(titleStack, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

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

        news2CompletionProgressView = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        news2CompletionProgressView.setMax(7);
        news2CompletionProgressView.setProgress(0);
        news2CompletionProgressView.setProgressTintList(ColorStateList.valueOf(COLOR_PRIMARY));
        news2CompletionProgressView.setProgressBackgroundTintList(ColorStateList.valueOf(Color.rgb(243, 244, 246)));
        LinearLayout.LayoutParams progressParams = matchWrapParams();
        progressParams.setMargins(0, dp(12), 0, 0);
        header.addView(news2CompletionProgressView, progressParams);

        LinearLayout.LayoutParams params = matchWrapParams();
        params.setMargins(0, 0, 0, dp(14));
        container.addView(header, params);
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
        footer.setOrientation(LinearLayout.HORIZONTAL);
        footer.setGravity(android.view.Gravity.CENTER_VERTICAL);
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
        footer.addView(scoreStack, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

        news2FooterRiskView = new TextView(this);
        news2FooterRiskView.setText(R.string.news2_evaluating);
        news2FooterRiskView.setTextColor(Color.rgb(107, 114, 128));
        news2FooterRiskView.setTextSize(14);
        news2FooterRiskView.setTypeface(Typeface.DEFAULT_BOLD);
        news2FooterRiskView.setPadding(dp(14), dp(12), dp(14), dp(12));
        news2FooterRiskView.setBackground(roundedDrawable(Color.rgb(243, 244, 246), dp(16), 0, 0));
        footer.addView(news2FooterRiskView, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT));

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
                if (completedNews2Count() < 7) {
                    Toast.makeText(MainActivity.this, R.string.patient_list_complete_before_save, Toast.LENGTH_SHORT).show();
                    return;
                }
                updateAssessmentFromViews();
                assessment.news2Total = assessment.news2Respiration + assessment.news2Spo2 + assessment.news2Oxygen
                        + assessment.news2Temperature + assessment.news2SystolicBp + assessment.news2HeartRate
                        + assessment.news2Consciousness;
                assessment.savedAtMillis = System.currentTimeMillis();
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
        if (text == null || text.isEmpty()) {
            group.clearCheck();
            return;
        }
        checkRadioByTag(group, text);
    }

    private void checkRadioByTag(RadioGroup group, Object tag) {
        for (int i = 0; i < group.getChildCount(); i++) {
            View child = group.getChildAt(i);
            if (tag.equals(child.getTag())) {
                group.check(child.getId());
                return;
            }
        }
        group.clearCheck();
    }

    private int booleanScore(boolean value) {
        return value ? 1 : 0;
    }
}
