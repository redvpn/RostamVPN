package com.rostamvpn.android.activity;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;

import com.duolingo.open.rtlviewpager.RtlViewPager;

import com.rostamvpn.android.adapter.SectionsPagerAdapter;
import com.rostamvpn.android.Application;
import com.rostamvpn.android.R;
import com.rostamvpn.android.util.LocaleUtils;
import com.rostamvpn.util.NonNullForAll;

import androidx.appcompat.app.AppCompatActivity;

@NonNullForAll
public class OnboardingActivity extends AppCompatActivity {
    private ImageView zero, one, two;
    private ImageView[] indicators;
    public final static String ONBOARDING_COMPLETED = "is_onboarding_completed";
//    public final static String ONBOARDING_COMPLETED = "is_onboarding_completed_v1_3_0";

    @Override
    protected void attachBaseContext(Context newBase) {
        // Set the default persian locale...
        Context context = LocaleUtils.setLocale(newBase, "fa");

        super.attachBaseContext(context);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Force RTL...
        getWindow().getDecorView().setLayoutDirection(View.LAYOUT_DIRECTION_RTL);

        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_onboarding);
        SectionsPagerAdapter sectionsPagerAdapter = new SectionsPagerAdapter(this, getSupportFragmentManager());
        RtlViewPager viewPager = findViewById(R.id.view_pager);
        viewPager.setAdapter(sectionsPagerAdapter);

        zero = findViewById(R.id.intro_indicator_0);
        one = findViewById(R.id.intro_indicator_1);
        two = findViewById(R.id.intro_indicator_2);
//        three = findViewById(R.id.intro_indicator_3);
        indicators = new ImageView[]{zero, one, two};

        viewPager.addOnPageChangeListener(new RtlViewPager.OnPageChangeListener() {

            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

            }

            @Override
            public void onPageSelected(int position) {
                updateIndicators(position);
            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });

        Button skipButton = findViewById(R.id.skip_button);
        skipButton.setOnClickListener(v -> {
            // Save the onboarding completed shared preference...
            SharedPreferences sharedPreferences = Application.getSharedPreferences();
            Editor editor = sharedPreferences.edit();
            editor.putBoolean(ONBOARDING_COMPLETED, true);
            editor.apply();

            // Invoke the main activity and finish this one...
            Intent intent = new Intent(getApplicationContext(), MainActivity.class);
            startActivity(intent);
            finish();
        });

        if(getScreenHeight() < 1200) {
            final LinearLayout indicatorsLayout = findViewById(R.id.indicators_layout);
            LinearLayout.LayoutParams indicatorsParams = (LinearLayout.LayoutParams)indicatorsLayout.getLayoutParams();
            indicatorsParams.bottomMargin = 0;
            indicatorsLayout.setLayoutParams(indicatorsParams);
            indicatorsLayout.requestLayout();

            final LinearLayout.LayoutParams skipButtonParams = (LinearLayout.LayoutParams)skipButton.getLayoutParams();
            skipButtonParams.topMargin = (int)getResources().getDimension(R.dimen.small_skip_button_margin);
            skipButtonParams.bottomMargin = (int)getResources().getDimension(R.dimen.small_skip_button_margin);
            skipButton.setLayoutParams(skipButtonParams);
            skipButton.requestLayout();
        }
    }

    void updateIndicators(int position) {
        for (int i = 0; i < 3; i++) {
            indicators[i].setBackgroundResource(
                i == position ? R.drawable.indicator_selected : R.drawable.indicator_unselected
            );
        }
    }

    private int getScreenHeight() {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);

        return displayMetrics.heightPixels;
    }
}