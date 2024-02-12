/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.rostamvpn.android.util;

import android.util.Log;

import com.rostamvpn.util.NonNullForAll;

import androidx.annotation.Nullable;
import java9.util.function.BiConsumer;

/**
 * Helpers for logging exceptions from asynchronous tasks. These can be passed to
 * {@code CompletionStage.whenComplete()} at the end of an asynchronous future chain.
 */

@NonNullForAll
public enum ExceptionLoggers implements BiConsumer<Object, Throwable> {
    D(Log.DEBUG),
    E(Log.ERROR);

    private static final String TAG = "RostamVPN/" + ExceptionLoggers.class.getSimpleName();
    private final int priority;

    ExceptionLoggers(final int priority) {
        this.priority = priority;
    }

    @Override
    public void accept(final Object result, @Nullable final Throwable throwable) {
        if (throwable != null)
            Log.println(Log.ERROR, TAG, Log.getStackTraceString(throwable));
        else if (priority <= Log.DEBUG)
            Log.println(priority, TAG, "Future completed successfully");
    }
}
