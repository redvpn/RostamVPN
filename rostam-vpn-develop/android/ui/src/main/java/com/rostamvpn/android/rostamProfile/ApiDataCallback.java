package com.rostamvpn.android.rostamProfile;

import com.rostamvpn.util.NonNullForAll;

@NonNullForAll
public interface ApiDataCallback {
    void onSuccess();
    void onFail(final String errorMessage);
}
