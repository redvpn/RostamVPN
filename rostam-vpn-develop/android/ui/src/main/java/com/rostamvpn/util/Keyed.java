/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.rostamvpn.util;

/**
 * Interface for objects that have a identifying key of the given type.
 */

@NonNullForAll
public interface Keyed<K> {
    K getKey();
}
