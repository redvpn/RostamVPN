package com.rostamvpn.android.util;

import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.Build;

import com.rostamvpn.util.NonNullForAll;

import java.util.Locale;

@NonNullForAll
public class LocaleUtils {
    @SuppressWarnings("deprecation")
    public static ContextWrapper setLocale(Context context, String language){
        Resources resources = context.getResources();
        Configuration config = resources.getConfiguration();

        Locale locale = new Locale(language);
        Locale.setDefault(locale);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            config.setLocale(locale);
        } else {
            config.locale = locale;
        }
        config.setLayoutDirection(locale);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            context = context.createConfigurationContext(config);
        } else {
            context.getResources().updateConfiguration(config, context.getResources().getDisplayMetrics());
        }

        return new ContextWrapper(context);
    }
}
