package com.rostamvpn.android.util;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;
import android.webkit.URLUtil;

import com.opencsv.CSVReader;

import com.rostamvpn.android.Application;
import com.rostamvpn.util.NonNullForAll;

import com.tonyodev.fetch2.AbstractFetchListener;
import com.tonyodev.fetch2.Download;
import com.tonyodev.fetch2.Error;
import com.tonyodev.fetch2.Fetch;
import com.tonyodev.fetch2.FetchConfiguration;
import com.tonyodev.fetch2.FetchListener;
import com.tonyodev.fetch2.NetworkType;
import com.tonyodev.fetch2.Request;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.concurrent.TimeUnit;

import org.jetbrains.annotations.NotNull;

import androidx.annotation.Nullable;

@NonNullForAll
public class DigitalSafetyTips {
    private static final String TAG = "RostamVPN/" + DigitalSafetyTips.class.getSimpleName();
    private static final String DIGITAL_SAFETY_TIP_INDEX = "digital_safety_tip_index";
    private static final String DIGITAL_SAFETY_TIPS_LAST_UPDATE = "digital_safety_tips_last_update";
    private static final String CSV_URL = "https://api.rostam.app/tips/Rostam-tips.csv";
    private String csvPath;
    private Context context;
    private Fetch fetch;
    private ArrayList<DigitalSafetyTip> digitalSafetyTips;
    private int count = 0;
    private int nextTipIndex;
    private FetchListener fetchListener = new AbstractFetchListener() {
        @Override
        public void onCompleted(@NotNull Download download) {
            super.onCompleted(download);
            Log.d(TAG,"CSV download completed.");

            setLastUpdateDate(System.currentTimeMillis());
            load();
            fetch.removeListener(this);
        }

        @Override
        public void onError(@NotNull Download download, @NotNull Error error, @org.jetbrains.annotations.Nullable Throwable throwable) {
            super.onError(download, error, throwable);
            Log.e(TAG, download.getError().toString(), throwable);
            fetch.removeListener(this);
        }
    };


    public DigitalSafetyTips(Context context) {
        this.context = context;
        csvPath = context.getFilesDir() + "/digital_safety_tips.csv";
        nextTipIndex = getNextTipIndex();

        FetchConfiguration fetchConfiguration = new FetchConfiguration.Builder(context).build();
        this.fetch = Fetch.Impl.getInstance(fetchConfiguration);

        load();
    }

    public void DownloadData() {
        // Only download a new CSV file if it hasn't been downloaded within the last 24 hours
        final long lastUpdateDate = getLastUpdateDate();
        final long now = System.currentTimeMillis();
        final long diff = TimeUnit.HOURS.convert(now - lastUpdateDate, TimeUnit.MILLISECONDS);

        if(diff >= 24) {
            deleteExistingData();

            final Request request = new Request(CSV_URL, csvPath);
            request.setNetworkType(NetworkType.ALL);

            fetch.addListener(fetchListener);
            fetch.enqueue(request, updatedRequest ->
                Log.d(TAG, "Start downloading the CSV file.")
            , error -> {
                Log.e(TAG, error.toString(), error.getThrowable());
                fetch.removeListener(fetchListener);
            });
        }
    }

    public DigitalSafetyTip getNextTip() {
        DigitalSafetyTip nextTip = null;
        if(count > 0) {
            nextTip = digitalSafetyTips.get(nextTipIndex % count);

            nextTipIndex++;
            setNextTipIndex(nextTipIndex);
        }

        return nextTip;
    }

    private void deleteExistingData() {
        File csvFile = new File(csvPath);

        if(csvFile.exists()){
            csvFile.delete();
        }
    }

    private void load() {
        this.digitalSafetyTips = new ArrayList<>();

        try {
            final File csvFile = new File(csvPath);
            if(!csvFile.exists())
                return;

            final FileInputStream fileInputStream = new FileInputStream(csvFile);
            final InputStreamReader inputStreamReader = new InputStreamReader(fileInputStream);
            final CSVReader csvReader = new CSVReader(inputStreamReader);
            String[] row;

            try {
                // Skip the header row...
                csvReader.skip(1);

                while ((row = csvReader.readNext()) != null) {
                    if(!isEmptyString(row[0]) && !isEmptyString(row[1]) && !isEmptyString(row[2]) && URLUtil.isValidUrl(row[2])) {
                        DigitalSafetyTip digitalSafetyTip = new DigitalSafetyTip(row[0], row[1], row[2]);

                        Log.d(TAG, digitalSafetyTip.url);
                        digitalSafetyTips.add(digitalSafetyTip);
                    }
                }
                this.count = this.digitalSafetyTips.size();
            } catch (Exception ex) {
                Log.e(TAG, ex.getMessage());
            } finally {
                csvReader.close();
                inputStreamReader.close();
                fileInputStream.close();
            }
        } catch (Exception ex) {
            Log.e(TAG, ex.getMessage());
        }
    }

    private int getNextTipIndex() {
        return Application.getSharedPreferences().getInt(DIGITAL_SAFETY_TIP_INDEX, 0);
    }

    private void setNextTipIndex(int nextTipIndex) {
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putInt(DIGITAL_SAFETY_TIP_INDEX, nextTipIndex);
        editor.apply();
    }

    private long getLastUpdateDate() {
        return Application.getSharedPreferences().getLong(DIGITAL_SAFETY_TIPS_LAST_UPDATE, 0);
    }

    private void setLastUpdateDate(long updateDate) {
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putLong(DIGITAL_SAFETY_TIPS_LAST_UPDATE, updateDate);
        editor.apply();
    }

    private boolean isEmptyString(String str) {
        return str == null || str.trim().length() == 0;
    }

    @NonNullForAll
    public class DigitalSafetyTip {
        @Nullable private String title;
        @Nullable private String shortDescription;
        @Nullable private String url;

        @Nullable
        public String getTitle() {
            return title;
        }

        @Nullable
        public String getShortDescription() {
            return shortDescription;
        }

        @Nullable
        public String getUrl() {
            return url;
        }

        DigitalSafetyTip(final String title, final String shortDescription, final String url) {
            this.title = title.trim();
            this.shortDescription = shortDescription.trim();
            this.url = url;
        }
    }
}
