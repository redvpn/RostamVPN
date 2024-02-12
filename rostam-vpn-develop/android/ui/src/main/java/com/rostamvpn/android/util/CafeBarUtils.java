package com.rostamvpn.android.util;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.text.Spanned;
import android.text.method.LinkMovementMethod;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import com.amplitude.api.Amplitude;

import com.danimahardhika.cafebar.CafeBar;

import com.rostamvpn.android.R;
import com.rostamvpn.util.NonNullForAll;

import org.json.JSONException;
import org.json.JSONObject;

import androidx.appcompat.widget.AppCompatButton;
import androidx.core.content.ContextCompat;
import androidx.core.text.HtmlCompat;

@NonNullForAll
public final class CafeBarUtils {
    private static final String TAG = "RostamVPN/" + CafeBarUtils.class.getSimpleName();
    public static final int TYPE_SUCCESS = 1;
    public static final int TYPE_ERROR = 2;
    public static final int TYPE_INFO = 3;

    public static final int LENGTH_INDEFINITE = -1;
    public static final int LENGTH_SHORT = 3000;
    public static final int LENGTH_MEDIUM = 5000;
    public static final int LENGTH_LONG = 8000;

    public static CafeBar build(Context context, int type, int text, int duration) {
        final CafeBar cafeBar = CafeBar.builder(context)
            .customView(R.layout.snackbar_layout)
            .autoDismiss(duration > -1)
            .duration(duration)
            .build();

        final View view = cafeBar.getView();
        view.setBackgroundColor(ContextCompat.getColor(context, getCafeBarColor(type)));

        final AppCompatButton closeButton = view.findViewById(R.id.snackbar_close);
        closeButton.setOnClickListener(v -> cafeBar.dismiss());

        final TextView textView = view.findViewById(R.id.snackbar_text);
        textView.setText(text);

        final ImageView icon = view.findViewById(R.id.snackbar_icon);
        icon.setImageResource(getCafeBarIcon(type));

        return cafeBar;
    }

    public static CafeBar buildConfigRequestMessage(Context context, final String publicKey) {
        final CafeBar cafeBar = CafeBar.builder(context)
                .customView(R.layout.config_request_snackbar_layout)
                .autoDismiss(false)
                .build();

        final View view = cafeBar.getView();

        final String mailToString = context.getString(R.string.config_request_email).replace("PUBKEY", publicKey);
        final Spanned mailTo = HtmlCompat.fromHtml(mailToString, HtmlCompat.FROM_HTML_MODE_LEGACY);
        final TextView mailToLink = view.findViewById(R.id.config_request_mailto);
        mailToLink.setText(mailTo);
        mailToLink.setMovementMethod(LinkMovementMethod.getInstance());

        return cafeBar;
    }

    public static CafeBar buildDigitalSafetyMessage(Context context, String title, String shortDescription, String url) {
        final CafeBar cafeBar = CafeBar.builder(context)
                .customView(R.layout.digital_safety_snackbar_layout)
                .autoDismiss(false)
                .build();

        final View view = cafeBar.getView();

        final AppCompatButton closeButton = view.findViewById(R.id.digital_safety_close);
        closeButton.setOnClickListener(v -> cafeBar.dismiss());

        final TextView titleText = view.findViewById(R.id.digital_safety_title);
        titleText.setText(title);

        final TextView shortDescriptionText = view.findViewById(R.id.digital_safety_short_description);
        shortDescriptionText.setText(shortDescription);

        final Spanned readMore = HtmlCompat.fromHtml(context.getString(R.string.digital_safety_tip_read_more), HtmlCompat.FROM_HTML_MODE_LEGACY);
        final TextView readMoreLink = view.findViewById(R.id.digital_safety_read_more);
        readMoreLink.setText(readMore);
        readMoreLink.setOnClickListener(v -> {
            Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            context.startActivity(browserIntent);

            try {
                JSONObject eventProperties = new JSONObject();
                eventProperties.put("url", url);
                Amplitude.getInstance().logEvent("Digital safety tip opened", eventProperties);
            }
            catch (JSONException ex) {
                Log.e(TAG, ex.getMessage());
            }

            cafeBar.dismiss();
        });

        return cafeBar;
    }


    private static int getCafeBarIcon(int type) {
        switch (type) {
            case TYPE_SUCCESS:
                return R.drawable.ic_alert_success;
            case TYPE_ERROR:
                return R.drawable.ic_alert_error;
            case TYPE_INFO:
                return R.drawable.ic_alert_info;
            default:
                break;
        }

        return  R.drawable.ic_alert_info;
    }

    private static int getCafeBarColor(int type) {
        switch (type) {
            case TYPE_SUCCESS:
                return R.color.snackbar_success;
            case TYPE_ERROR:
                return R.color.snackbar_error;
            case TYPE_INFO:
                return R.color.snackbar_info;
            default:
                break;
        }

        return R.color.snackbar_info;
    }
}
