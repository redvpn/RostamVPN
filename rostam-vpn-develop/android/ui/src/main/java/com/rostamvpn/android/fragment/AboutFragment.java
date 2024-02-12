package com.rostamvpn.android.fragment;

import android.os.Bundle;
import android.text.Spanned;
import android.text.method.LinkMovementMethod;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.rostamvpn.android.R;
import com.rostamvpn.util.NonNullForAll;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.text.HtmlCompat;
import androidx.fragment.app.Fragment;

/**
 * A simple {@link Fragment} subclass.
 */
@NonNullForAll
public class AboutFragment extends Fragment {

    public AboutFragment() {
        // Required empty public constructor
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_about, container, false);
        AppCompatActivity activity = (AppCompatActivity)getActivity();

        activity.getSupportActionBar().hide();
        Toolbar toolbar = rootView.findViewById(R.id.subpage_toolbar);
        toolbar.setNavigationIcon(null);
        toolbar.setTitle(getString(R.string.about_rostam_title));
        activity.setSupportActionBar(toolbar);
        activity.getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        Spanned mailTo = HtmlCompat.fromHtml(getString(R.string.feedback_email), HtmlCompat.FROM_HTML_MODE_LEGACY);
        TextView mailToLink = rootView.findViewById(R.id.feedback_mailto);
        mailToLink.setText(mailTo);
        mailToLink.setMovementMethod(LinkMovementMethod.getInstance());

        return rootView;
    }
}
