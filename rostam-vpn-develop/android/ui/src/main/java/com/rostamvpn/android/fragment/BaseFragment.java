/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.rostamvpn.android.fragment;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.view.View;

import com.danimahardhika.cafebar.CafeBar;

import com.rostamvpn.android.Application;
import com.rostamvpn.android.R;
import com.rostamvpn.android.activity.BaseActivity;
import com.rostamvpn.android.activity.BaseActivity.OnSelectedTunnelChangedListener;
import com.rostamvpn.android.backend.GoBackend;
import com.rostamvpn.android.backend.Tunnel.RostamState;
import com.rostamvpn.android.backend.Tunnel.State;
import com.rostamvpn.android.databinding.TunnelListItemBinding;
import com.rostamvpn.android.model.ObservableTunnel;
import com.rostamvpn.android.rostamProfile.ConfigBuilder;
import com.rostamvpn.android.rostamProfile.ConfigBuilderCallback;
import com.rostamvpn.android.rostamProfile.EndpointManager;
import com.rostamvpn.android.util.CafeBarUtils;
import com.rostamvpn.android.util.DigitalSafetyTips;
import com.rostamvpn.android.util.ErrorMessages;
import com.rostamvpn.android.util.NetworkUtils;
import com.rostamvpn.config.BadConfigException;
import com.rostamvpn.config.Config;
import com.rostamvpn.crypto.KeyPair;
import com.rostamvpn.util.NonNullForAll;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import androidx.annotation.Nullable;
import androidx.databinding.DataBindingUtil;
import androidx.databinding.ViewDataBinding;
import androidx.fragment.app.Fragment;

/**
 * Base class for fragments that need to know the currently-selected tunnel. Only does anything when
 * attached to a {@code BaseActivity}.
 */

@NonNullForAll
public abstract class BaseFragment extends Fragment implements OnSelectedTunnelChangedListener {
    private static final int REQUEST_CODE_VPN_PERMISSION = 23491;
    private static final String TAG = "RostamVPN/" + BaseFragment.class.getSimpleName();

    @Nullable private BaseActivity activity;
    @Nullable private ObservableTunnel pendingTunnel;
    @Nullable private Boolean pendingTunnelUp;
    protected DigitalSafetyTips digitalSafetyTips;
    protected EndpointManager endpointManager;
    @Nullable protected static CafeBar configRequestCafeBar = null;

    @Override
    public void onActivityResult(final int requestCode, final int resultCode, @Nullable final Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == REQUEST_CODE_VPN_PERMISSION) {
            if (pendingTunnel != null && pendingTunnelUp != null)
                setTunnelStateWithPermissionsResult(pendingTunnel, pendingTunnelUp);
            pendingTunnel = null;
            pendingTunnelUp = null;
        }
    }

    @Override
    public void onAttach(final Context context) {
        super.onAttach(context);
        if (context instanceof BaseActivity) {
            activity = (BaseActivity) context;
            activity.addOnSelectedTunnelChangedListener(this);

            digitalSafetyTips = new DigitalSafetyTips(activity);
        } else {
            activity = null;
        }
    }

    @Override
    public void onDetach() {
        if (activity != null)
            activity.removeOnSelectedTunnelChangedListener(this);
        activity = null;
        super.onDetach();
    }

    protected void getNewEndpoints(final ObservableTunnel tunnel, final String region, final boolean checked) {
        final Activity activity = getActivity();
        if (tunnel == null || activity == null)
            return;

        final KeyPair keyPair = Application.getKeyStore().getKeyPair();
        final String publicKeyBase64 = keyPair.getPublicKey().toBase64();

        ConfigBuilder.build(activity, keyPair, region, new ConfigBuilderCallback() {
            @Override
            public void onSuccess(String configText) {
                try {
                    final Config newConfig = Config.parse(new ByteArrayInputStream(configText.getBytes(StandardCharsets.UTF_8)));

                    tunnel.setConfig(newConfig).whenComplete((savedTunnel, throwable) -> {
                        final String message;
                        if (throwable == null) {
                            message = getString(R.string.config_save_success, Application.TUNNEL_NAME);
                            Log.d(TAG, message);

                            if(checked) {
                                // Turn VPN on
                                setTunnelState(activity, tunnel, true);
                            }
                        } else {
                            final String error = ErrorMessages.get(throwable);
                            message = getString(R.string.config_save_error, Application.TUNNEL_NAME, error);
                            Log.e(TAG, message, throwable);

                            displayConfigRequestMessage(activity, publicKeyBase64);
                        }
                    });
                } catch (final BadConfigException | IOException e) {
                    Log.e(TAG, e.getMessage());

                    displayConfigRequestMessage(activity, publicKeyBase64);
                }
            }

            @Override
            public void onFail() {
                displayConfigRequestMessage(activity, publicKeyBase64);
            }
        });
    }

    private void displayConfigRequestMessage(final Context context, final String publicKey) {
        if(configRequestCafeBar == null)
            configRequestCafeBar = CafeBarUtils.buildConfigRequestMessage(context, publicKey);
        configRequestCafeBar.show();
    }

    public void setTunnelState(View view) {
        final ViewDataBinding binding = DataBindingUtil.findBinding(view);
        final ObservableTunnel tunnel = ((TunnelListItemBinding) binding).getItem();
        if (tunnel == null)
            return;

        final int status = NetworkUtils.getConnectivityStatus(requireContext());
        final boolean checked = tunnel.getState() == State.DOWN;
        final boolean hasInternetConnection = status != NetworkUtils.NETWORK_STATUS_NOT_CONNECTED;
        if(!hasInternetConnection)
            tunnel.setRostamState(RostamState.OFF);

        // Only if there's internet connectivity...
        if(hasInternetConnection) {
            if(checked) {
                // If there are no stored endpoints get new ones, otherwise turn VPN on...
                final String selectedRegion = Application.getRegionManager().getSelectedRegion();
                this.endpointManager = new EndpointManager(tunnel, selectedRegion);
                if(this.endpointManager.getNextEndpoint() == null) {
                    getNewEndpoints(tunnel, selectedRegion, true);
                } else {
                    setTunnelState(view.getContext(), tunnel, true);
                }
            } else {
                // Turn VPN off
                setTunnelState(view.getContext(), tunnel, false);
            }
        }
    }

    protected void setTunnelState(final Context context, final ObservableTunnel tunnel, final boolean checked) {
        if(checked) {
            // Display digital safety tip...
            final DigitalSafetyTips.DigitalSafetyTip tip = digitalSafetyTips.getNextTip();
            if(tip != null) {
                CafeBarUtils.buildDigitalSafetyMessage(
                    context,
                    tip.getTitle(),
                    tip.getShortDescription(),
                    tip.getUrl()
                ).show();
            }
        }

        Application.getBackendAsync().thenAccept(backend -> {
            if (backend instanceof GoBackend) {
                final Intent intent = GoBackend.VpnService.prepare(context);
                if (intent != null) {
                    pendingTunnel = tunnel;
                    pendingTunnelUp = checked;
                    startActivityForResult(intent, REQUEST_CODE_VPN_PERMISSION);
                    return;
                }
            }

            setTunnelStateWithPermissionsResult(tunnel, checked);
        });
    }

    private void setTunnelStateWithPermissionsResult(final ObservableTunnel tunnel, final boolean checked) {
        tunnel.setState(State.of(checked)).whenComplete((state, throwable) -> {
            if (throwable == null) {
                return;
            }

            tunnel.setRostamState(RostamState.OFF);
            tunnel.setStateChanging(false);

            final String error = ErrorMessages.get(throwable);
            Log.e(TAG, error, throwable);
        });
    }
}
