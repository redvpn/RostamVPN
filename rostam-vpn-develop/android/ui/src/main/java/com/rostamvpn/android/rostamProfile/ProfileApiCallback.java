package com.rostamvpn.android.rostamProfile;

import com.rostamvpn.util.NonNullForAll;

@NonNullForAll
public interface ProfileApiCallback {
    void onSuccess(final String address, final String[] endpoints, final String serverPublicKey);
    void onFail(final String errorMessage);
}
