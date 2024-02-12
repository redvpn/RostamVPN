/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.rostamvpn.android.model;

import com.rostamvpn.android.BR;
import com.rostamvpn.android.backend.Statistics;
import com.rostamvpn.android.backend.Tunnel;
import com.rostamvpn.android.util.ExceptionLoggers;
import com.rostamvpn.config.Config;
import com.rostamvpn.util.Keyed;
import com.rostamvpn.util.NonNullForAll;

import androidx.annotation.Nullable;
import androidx.databinding.BaseObservable;
import androidx.databinding.Bindable;
import java9.util.concurrent.CompletableFuture;
import java9.util.concurrent.CompletionStage;

/**
 * Encapsulates the volatile and nonvolatile state of a WireGuard tunnel.
 */

@NonNullForAll
public class ObservableTunnel extends BaseObservable implements Keyed<String>, Tunnel {
    private final TunnelManager manager;
    @Nullable private Config config;
    private State state;
    private String name;
    private boolean stateChanging;
    private RostamState rostamState;
    @Nullable private Statistics statistics;

    ObservableTunnel(final TunnelManager manager, final String name,
           @Nullable final Config config, final State state) {
        this.name = name;
        this.manager = manager;
        this.config = config;
        this.state = state;
        this.stateChanging = false;
        this.setRostamState(RostamState.OFF);
    }

    public CompletionStage<Void> delete() {
        return manager.delete(this);
    }

    @Bindable
    @Nullable
    public Config getConfig() {
        if (config == null)
            manager.getTunnelConfig(this).whenComplete(ExceptionLoggers.E);
        return config;
    }

    public CompletionStage<Config> getConfigAsync() {
        if (config == null)
            return manager.getTunnelConfig(this);
        return CompletableFuture.completedFuture(config);
    }

    @Override
    public String getKey() {
        return name;
    }

    @Override
    @Bindable
    public String getName() {
        return name;
    }

    @Bindable
    public State getState() {
        return state;
    }

    @Bindable
    public boolean isStateChanging() {
        return stateChanging;
    }

    @Bindable
    public RostamState getRostamState() {
        return rostamState;
    }

    public CompletionStage<State> getStateAsync() {
        return TunnelManager.getTunnelState(this);
    }

    @Bindable
    @Nullable
    public Statistics getStatistics() {
        if (statistics == null || statistics.isStale())
            TunnelManager.getTunnelStatistics(this).whenComplete(ExceptionLoggers.E);
        return statistics;
    }

    public CompletionStage<Statistics> getStatisticsAsync() {
        if (statistics == null || statistics.isStale())
            return TunnelManager.getTunnelStatistics(this);
        return CompletableFuture.completedFuture(statistics);
    }

    Config onConfigChanged(final Config config) {
        this.config = config;
        notifyPropertyChanged(BR.config);
        return config;
    }

    String onNameChanged(final String name) {
        this.name = name;
        notifyPropertyChanged(BR.name);
        return name;
    }

    State onStateChanged(final State state) {
        if (state != State.UP)
            onStatisticsChanged(null);
        this.state = state;
        notifyPropertyChanged(BR.state);

        if(state == State.DOWN)
            this.setStateChanging(false);

        return state;
    }

    @Override
    public void onStateChange(final State newState) {
        onStateChanged(newState);
    }

    @Nullable
    Statistics onStatisticsChanged(@Nullable final Statistics statistics) {
        this.statistics = statistics;
        notifyPropertyChanged(BR.statistics);
        return statistics;
    }

    public CompletionStage<Config> setConfig(final Config config) {
        if (!config.equals(this.config))
            return manager.setTunnelConfig(this, config);
        return CompletableFuture.completedFuture(this.config);
    }

    public CompletionStage<String> setName(final String name) {
        if (!name.equals(this.name))
            return manager.setTunnelName(this, name);
        return CompletableFuture.completedFuture(this.name);
    }

    public CompletionStage<State> setState(final State state) {
        if(state == State.UP)
            this.setRostamState(RostamState.CONNECTING);
        this.setStateChanging(true);

        if (state != this.state)
            return manager.setTunnelState(this, state);
        return CompletableFuture.completedFuture(this.state);
    }

    public void setStateChanging(final boolean stateChanging) {
        this.stateChanging = stateChanging;
        notifyPropertyChanged(BR.stateChanging);
    }

    public void setRostamState(final RostamState rostamState) {
        this.rostamState = rostamState;
        notifyPropertyChanged(BR.rostamState);
    }
}
