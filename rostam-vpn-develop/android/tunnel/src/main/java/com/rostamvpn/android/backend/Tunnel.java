/*
 * Copyright © 2020 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.rostamvpn.android.backend;

import com.rostamvpn.util.NonNullForAll;

import java.util.regex.Pattern;

/**
 * Represents a WireGuard tunnel.
 */

@NonNullForAll
public interface Tunnel {
    enum State {
        DOWN,
        TOGGLE,
        UP;

        public static State of(final boolean running) {
            return running ? UP : DOWN;
        }
    }

    enum RostamState {
        OFF,
        CONNECTING,
        ON
    }

    int NAME_MAX_LENGTH = 15;
    Pattern NAME_PATTERN = Pattern.compile("[a-zA-Z0-9_=+.-]{1,15}");

    static boolean isNameInvalid(final CharSequence name) {
        return !NAME_PATTERN.matcher(name).matches();
    }

    /**
     * Get the name of the tunnel, which should always pass the !isNameInvalid test.
     *
     * @return The name of the tunnel.
     */
    String getName();

    /**
     * React to a change in state of the tunnel. Should only be directly called by Backend.
     *
     * @param newState The new state of the tunnel.
     * @return The new state of the tunnel.
     */
    void onStateChange(State newState);
}
