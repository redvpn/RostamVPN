package com.rostamvpn.android.fragment;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.util.FitPolicy;

import com.rostamvpn.android.R;
import com.rostamvpn.util.NonNullForAll;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;

/**
 * A simple {@link Fragment} subclass.
 */
@NonNullForAll
public class PrivacyPolicyFragment extends Fragment {
    private static final String TAG = "RostamVPN/" + PrivacyPolicyFragment.class.getSimpleName();

    public PrivacyPolicyFragment() {
        // Required empty public constructor
    }


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_privacy_policy, container, false);
        AppCompatActivity activity = (AppCompatActivity)getActivity();

        PDFView pdfView = rootView.findViewById(R.id.pdfView);
        pdfView.fromAsset("privacy_policy.pdf")
                .swipeHorizontal(false)
                .defaultPage(0)
                .onError(error -> {
                    Log.e(TAG, error.getMessage());
                })
                .enableAntialiasing(true)
                .spacing(0)
                .autoSpacing(false)
                .pageFitPolicy(FitPolicy.WIDTH)
                .pageSnap(false)
                .pageFling(true)
                .load();

        activity.getSupportActionBar().hide();
        Toolbar toolbar = rootView.findViewById(R.id.subpage_toolbar);
        toolbar.setNavigationIcon(null);
        toolbar.setTitle(getString(R.string.privacy_policy_title));
        activity.setSupportActionBar(toolbar);
        activity.getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        return rootView;
    }
}
