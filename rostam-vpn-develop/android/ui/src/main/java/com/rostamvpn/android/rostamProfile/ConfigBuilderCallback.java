package com.rostamvpn.android.rostamProfile;

import com.rostamvpn.util.NonNullForAll;

@NonNullForAll
public interface ConfigBuilderCallback {
    void onSuccess(final String configText);
    void onFail();
}
