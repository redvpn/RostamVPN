package com.rostamvpn.android.rostamProfile;

import com.rostamvpn.util.NonNullForAll;

import java.util.ArrayList;

@NonNullForAll
public interface RegionsApiCallback {
    void onComplete(final ArrayList<String> regions);
}
