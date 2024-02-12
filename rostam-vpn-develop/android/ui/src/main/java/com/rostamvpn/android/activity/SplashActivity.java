package com.rostamvpn.android.activity;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import androidx.core.splashscreen.SplashScreen;

import com.rostamvpn.android.Application;
import com.rostamvpn.util.NonNullForAll;

@NonNullForAll
public class SplashActivity extends Activity {
    private static final String TAG = "RostamVPN/" + SplashActivity.class.getSimpleName();

    @Override
    protected void onCreate(Bundle savedInstance) {
        super.onCreate(savedInstance);
        SplashScreen splashScreen = SplashScreen.installSplashScreen(this);
        splashScreen.setKeepOnScreenCondition(() -> true);

        final Boolean isOnboardingCompleted = Application.getSharedPreferences().getBoolean(OnboardingActivity.ONBOARDING_COMPLETED, false);
        if(isOnboardingCompleted) {
            // Invoke the main activity
            Intent intent = new Intent(getApplicationContext(), MainActivity.class);
            startActivity(intent);
        }
        else {
            // Invoke the onboarding activity
            Intent onboardingIntent = new Intent(getApplicationContext(), OnboardingActivity.class);
            startActivity(onboardingIntent);
        }

        // Finish the splash activity...
        finish();
    }
}