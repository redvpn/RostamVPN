/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.rostamvpn.android.fragment;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.net.ConnectivityManager;
import android.os.Build;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.Handler;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebResourceRequest;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.RelativeLayout;
import android.view.Gravity;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageButton;
import android.widget.PopupWindow;
import android.widget.TextView;

import com.amplitude.api.Amplitude;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.JsonObjectRequest;

import com.danimahardhika.cafebar.CafeBar;

import com.google.android.material.bottomsheet.BottomSheetBehavior;

import com.rostamvpn.android.Application;
import com.rostamvpn.android.R;
import com.rostamvpn.android.databinding.ObservableKeyedRecyclerViewAdapter;
import com.rostamvpn.android.databinding.TunnelListFragmentBinding;
import com.rostamvpn.android.databinding.TunnelListItemBinding;
import com.rostamvpn.android.rostamProfile.ConfigBuilder;
import com.rostamvpn.android.rostamProfile.EndpointManager;
import com.rostamvpn.android.model.ObservableTunnel;
import com.rostamvpn.android.backend.Tunnel.State;
import com.rostamvpn.android.backend.Tunnel.RostamState;
import com.rostamvpn.android.rostamProfile.RegionManager;
import com.rostamvpn.android.util.CafeBarUtils;
import com.rostamvpn.android.util.ErrorMessages;
import com.rostamvpn.android.util.NetworkUtils;
import com.rostamvpn.config.BadConfigException;
import com.rostamvpn.config.Config;
import com.rostamvpn.config.InetEndpoint;
import com.rostamvpn.crypto.KeyPair;
import com.rostamvpn.util.NonNullForAll;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.json.JSONException;
import org.json.JSONObject;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;
import androidx.core.widget.NestedScrollView;
import androidx.fragment.app.FragmentTransaction;
import java9.util.concurrent.CompletableFuture;

@NonNullForAll
public class TunnelListFragment extends BaseFragment {
    private static final String TAG = "RostamVPN/" + TunnelListFragment.class.getSimpleName();
    private static final String API_TAG = "RostamVPNApi";
    private static final String API_URL = "https://api.rostam.app/";
    private static final String LANDING_PAGE_URL = "https://www.rostam.app/ads/01/";
    public static final String SHOW_LANDING_PAGE_KEY = "show_landing_page";
    // Don't show the landing page the first time
    public static boolean showLandingPage = Application.getSharedPreferences().getBoolean(SHOW_LANDING_PAGE_KEY, false);
    @Nullable private static CafeBar noInternetCafeBar = null;
//    private BottomSheetBehavior bottomSheetBehavior;
    private BottomSheetBehavior.BottomSheetCallback bottomSheetCallback;

    @Nullable private TunnelListFragmentBinding binding;
    private final Handler handler = new Handler();
    private Runnable runnable;
    private final int interval = 5 * 1000;
    private int vpnConnectivityCheckAttempts = 0;
    private final int maxAttempts = 1;
    private final BroadcastReceiver networkChangeReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final ObservableTunnel tunnel =  getRostamTunnel();
            if(tunnel == null)
                return;
            final Activity activity = getActivity();
            if(activity == null)
                return;

            final int status = NetworkUtils.getConnectivityStatus(context);

            Log.d(TAG, "Network connectivity changed: " + status);
            Log.d(TAG, "Rostam state: " + tunnel.getRostamState());

            if(status == NetworkUtils.NETWORK_STATUS_NOT_CONNECTED) {
                tunnel.setRostamState(RostamState.OFF);
                showLandingPage = Application.getSharedPreferences().getBoolean(SHOW_LANDING_PAGE_KEY, false);
//                enableRegionSelection();

                if(noInternetCafeBar == null)
                    noInternetCafeBar = CafeBarUtils.build(activity, CafeBarUtils.TYPE_ERROR, R.string.no_internet_connection, CafeBarUtils.LENGTH_INDEFINITE);
                noInternetCafeBar.show();
            }
            else {
                if(noInternetCafeBar != null) {
                    noInternetCafeBar.dismiss();
                    noInternetCafeBar = null;
                }
            }

            if(status == NetworkUtils.NETWORK_STATUS_VPN &&
                    (tunnel.getState() == State.UP || tunnel.getRostamState() == RostamState.CONNECTING)) {
//                disableRegionSelection();
                handler.post(runnable = () -> checkVpnConnectivity(activity));
            }
            else {
                tunnel.setStateChanging(false);
                tunnel.setRostamState(RostamState.OFF);
                showLandingPage = Application.getSharedPreferences().getBoolean(SHOW_LANDING_PAGE_KEY, false);
//                enableRegionSelection();

                stopVpnConnectivityCheck();
            }

            Log.d(TAG, "Rostam state: " + tunnel.getRostamState());
        }
    };

    private ObservableTunnel getRostamTunnel() {
        if(binding == null || binding.getTunnels() == null)
            return null;

        return binding.getTunnels().get(Application.TUNNEL_NAME);
    }

    private void checkVpnConnectivity(Context context) {
        final ObservableTunnel tunnel = getRostamTunnel();
        if(tunnel == null)
            return;

        Log.d(TAG, "Check VPN connectivity - Config:\n" + tunnel.getConfig().toWgQuickString());

        // Get the RequestQueue.
        RequestQueue queue = Application.getRequestQueue();
        queue.getCache().clear();

        // Call the Rostam API to check VPN connectivity...
        JsonObjectRequest jsonObjectRequest = new JsonObjectRequest
                (Request.Method.GET, API_URL, null, response -> {
                    Log.d(TAG, "API Response: " + response);

                    String status = "";
                    String ipAddress = "";
                    try {
                        status = response.getString("status");
                        ipAddress = response.getString("ip");
                    }
                    catch (JSONException ex) {
                        Log.e(TAG, ex.getMessage());
                    }

                    if(status.equals("ok")) {
                        stopVpnConnectivityCheck();

                        if(showLandingPage) {
                            showLandingPage(tunnel, ipAddress);
                        } else {
                            tunnel.setStateChanging(false);
                            tunnel.setRostamState(RostamState.ON);

                            SharedPreferences sharedPreferences = Application.getSharedPreferences();
                            SharedPreferences.Editor editor = sharedPreferences.edit();
                            editor.putBoolean(SHOW_LANDING_PAGE_KEY, true);
                            editor.apply();
                        }

                        final JSONObject eventProperties = getAmplitudeEventProperties(tunnel);
                        Amplitude.getInstance().logEvent("Connected", eventProperties);

                        if(configRequestCafeBar != null) {
                            configRequestCafeBar.dismiss();
                            configRequestCafeBar = null;
                        }

                        // Download new digital safety tips CSV file...
                        digitalSafetyTips.DownloadData();
                    }
                    else {
                        onVpnConnectionFailure(context);
                    }
                }, error -> {
                    Log.e(TAG, error.getMessage(), error);

                    onVpnConnectionFailure(context);
                });

        // Add the request to the RequestQueue.
        jsonObjectRequest.setTag(API_TAG);
        jsonObjectRequest.setRetryPolicy(Application.getDefaultRetryPolicy());
        jsonObjectRequest.setShouldCache(false);
        queue.add(jsonObjectRequest);

        // Set Rostam state to Connecting...
        if(tunnel.getRostamState() == RostamState.OFF) {
            tunnel.setStateChanging(true);
            tunnel.setRostamState(RostamState.CONNECTING);
//            disableRegionSelection();
        }
    }

    private void onVpnConnectionFailure(Context context) {
        final ObservableTunnel tunnel =  getRostamTunnel();
        if(tunnel == null)
            return;

        final String selectedRegion = Application.getRegionManager().getSelectedRegion();
        if(endpointManager == null) {
            endpointManager = new EndpointManager(tunnel, selectedRegion);
        }

        if(NetworkUtils.getConnectivityStatus(context) == NetworkUtils.NETWORK_STATUS_VPN) {
            vpnConnectivityCheckAttempts += 1;
            if (runnable != null)
                handler.postDelayed(runnable, interval);

            final JSONObject eventProperties = getAmplitudeEventProperties(tunnel);
            Amplitude.getInstance().logEvent("Endpoint connection failed", eventProperties);
            if (vpnConnectivityCheckAttempts == maxAttempts) {
                final InetEndpoint nextEndpoint = endpointManager.getNextEndpoint();
                if(nextEndpoint != null) {
                    Log.d(TAG, "Trying endpoint " + nextEndpoint.toString());
                    changeTunnelEndpoint(tunnel, nextEndpoint);

                    vpnConnectivityCheckAttempts = 0;
                }
                else {
                    // Turn VPN off...
                    setTunnelState(context, tunnel, false);

                    Amplitude.getInstance().logEvent("Connection failed");

                    CafeBarUtils.build(context, CafeBarUtils.TYPE_ERROR, R.string.vpn_connection_try_again, CafeBarUtils.LENGTH_LONG).show();
                    EndpointManager.removeEndpoints(selectedRegion);

                    stopVpnConnectivityCheck();
                }
            }
        }
        else {
            stopVpnConnectivityCheck();
        }
    }

    private void stopVpnConnectivityCheck() {
        if(runnable != null)
            handler.removeCallbacks(runnable);

        vpnConnectivityCheckAttempts = 0;

        RequestQueue queue = Application.getRequestQueue();
        queue.cancelAll(API_TAG);
    }

    private JSONObject getAmplitudeEventProperties(ObservableTunnel tunnel) {
        if(tunnel == null)
            return null;

        InetEndpoint endpoint = EndpointManager.getEndpoint(tunnel.getConfig());
        final RegionManager regionManager = Application.getRegionManager();
        if(endpoint != null) {
            try {
                JSONObject eventProperties = new JSONObject();
                eventProperties.put("endpoint", endpoint.toString());
                eventProperties.put("region", regionManager.getSelectedRegion());
                return eventProperties;
            }
            catch (JSONException ex) {
                Log.e(TAG, ex.getMessage());
            }
        }

        return null;
    }

    public String rostamStateToString(RostamState rostamState) {
        int res = R.string.vpn_state_off;

        switch (rostamState)  {
            case ON:
                res = R.string.vpn_state_on;
                break;
            case CONNECTING:
                res = R.string.vpn_state_connecting;
                break;
            case OFF:
                res = R.string.vpn_state_off;
                break;
        }

        return getResources().getString(res);
    }

    public String getRostamStateText(RostamState rostamState) {
        int res = R.string.tap_to_connect;

        switch (rostamState)  {
            case ON:
                res = R.string.tap_to_disconnect;
                break;
            case CONNECTING:
                res = R.string.connecting;
                break;
            case OFF:
                res = R.string.tap_to_connect;
                break;
        }

        return getResources().getString(res);
    }

    public void updateTunnel(final ObservableTunnel tunnel, @NonNull final String configText) {
        final Activity activity = getActivity();
        if (activity == null)
            return;

        Log.d(TAG, "Attempting to save config of VPN");
        try {
            final Config newConfig = Config.parse(new ByteArrayInputStream(configText.getBytes(StandardCharsets.UTF_8)));

            tunnel.setConfig(newConfig).whenComplete((savedTunnel, throwable) -> {
                final String message;
                if (throwable == null) {
                    message = getString(R.string.config_save_success, Application.TUNNEL_NAME);
                    Log.d(TAG, message);
                } else {
                    final String error = ErrorMessages.get(throwable);
                    message = getString(R.string.config_save_error, Application.TUNNEL_NAME, error);
                    Log.e(TAG, message, throwable);
                }
            });
        }
        catch (final BadConfigException | IOException e) {
            Log.e(TAG, e.getMessage());
        }
    }

    public void updateTunnel(final ObservableTunnel tunnel, @Nullable final InputStream inputStream) {
        final Activity activity = getActivity();
        if (activity == null || inputStream == null)
            return;

        Log.d(TAG, "Attempting to save config of VPN");
        try {
            final KeyPair keyPair = Application.getKeyStore().getKeyPair();
            final Config newConfig = ConfigBuilder.parse(keyPair, inputStream);

            tunnel.setConfig(newConfig).whenComplete((savedTunnel, throwable) -> {
                final String message;
                if (throwable == null) {
                    message = getString(R.string.config_save_success, Application.TUNNEL_NAME);
                    Log.d(TAG, message);
                    CafeBarUtils.build(activity, CafeBarUtils.TYPE_SUCCESS, R.string.config_update_success, CafeBarUtils.LENGTH_LONG).show();
                } else {
                    final String error = ErrorMessages.get(throwable);
                    message = getString(R.string.config_save_error, Application.TUNNEL_NAME, error);
                    Log.e(TAG, message, throwable);
                    if (binding != null) {
                        CafeBarUtils.build(activity, CafeBarUtils.TYPE_ERROR, R.string.config_update_error, CafeBarUtils.LENGTH_LONG).show();
                    }
                }
            });
        }
        catch (final BadConfigException | JSONException | InvalidKeyException ex) {
            final String error = ErrorMessages.get(ex);
            Log.e(TAG, error);
            CafeBarUtils.build(activity, CafeBarUtils.TYPE_ERROR, R.string.bad_config_file_error, CafeBarUtils.LENGTH_LONG).show();
        }
        catch (final IOException ex) {
            Log.e(TAG, ex.getMessage());
            CafeBarUtils.build(activity, CafeBarUtils.TYPE_ERROR, R.string.config_update_error, CafeBarUtils.LENGTH_LONG).show();
        }
    }

    private void changeTunnelEndpoint(final ObservableTunnel tunnel, InetEndpoint endpoint) {
        Log.d(TAG, "Attempting to change the tunnel endpoint to " + endpoint.toString());
        final String configText = tunnel.getConfig().toWgQuickString();
        try {
            final Config newConfig = Config.parse(new ByteArrayInputStream(configText.getBytes(StandardCharsets.UTF_8)));
            if(EndpointManager.changeConfigEndpoint(newConfig, endpoint)) {
                tunnel.setConfig(newConfig).whenComplete((savedTunnel, throwable) -> {
                    final String message;
                    if (throwable == null) {
                        message = getString(R.string.config_save_success, Application.TUNNEL_NAME);
                        Log.d(TAG, message);
                    } else {
                        final String error = ErrorMessages.get(throwable);
                        message = getString(R.string.config_save_error, Application.TUNNEL_NAME, error);
                        Log.e(TAG, message, throwable);
                    }
                });
            }
        } catch (final BadConfigException | IOException e) {
            Log.e(TAG, e.getMessage());
        }
    }

    public void importTunnel(@NonNull final String configText) {
        try {
            final Config newConfig = Config.parse(new ByteArrayInputStream(configText.getBytes(StandardCharsets.UTF_8)));

            Application.getTunnelManager().create(Application.TUNNEL_NAME, newConfig).whenComplete((tunnel, throwable) -> {
                if(tunnel == null) {
                    onTunnelImportFinished(Collections.emptyList(), Collections.singletonList(throwable));
                }
            });
        }
        catch (final BadConfigException | IOException e) {
            onTunnelImportFinished(Collections.emptyList(), Collections.singletonList(e));
        }
    }

    public void importTunnel(@Nullable final InputStream inputStream) {
        final Activity activity = getActivity();
        if (activity == null || inputStream == null)
            return;

        final Collection<CompletableFuture<ObservableTunnel>> futureTunnels = new ArrayList<>();
        final List<Throwable> throwables = new ArrayList<>();
        Application.getAsyncWorker().supplyAsync(() -> {
            final Config newConfig = Config.parse(inputStream);

            futureTunnels.add(Application.getTunnelManager().create(Application.TUNNEL_NAME,
                    newConfig).toCompletableFuture());

            if (futureTunnels.isEmpty()) {
                if (throwables.size() == 1)
                    throw throwables.get(0);
                else if (throwables.isEmpty())
                    throw new IllegalArgumentException(getResources().getString(R.string.no_configs_error));
            }

            return CompletableFuture.allOf(futureTunnels.toArray(new CompletableFuture[futureTunnels.size()]));
        }).whenComplete((future, exception) -> {
            if (exception != null) {
                onTunnelImportFinished(Collections.emptyList(), Collections.singletonList(exception));
            } else {
                future.whenComplete((ignored1, ignored2) -> {
                    final List<ObservableTunnel> tunnels = new ArrayList<>(futureTunnels.size());
                    for (final CompletableFuture<ObservableTunnel> futureTunnel : futureTunnels) {
                        ObservableTunnel tunnel = null;
                        try {
                            tunnel = futureTunnel.getNow(null);
                        } catch (final Exception e) {
                            throwables.add(e);
                        }
                        if (tunnel != null)
                            tunnels.add(tunnel);
                    }
                    onTunnelImportFinished(tunnels, throwables);
                });
            }
        });
    }

    @SuppressWarnings("deprecation")
    @SuppressLint("ClickableViewAccessibility")
    @Override
    public View onCreateView(@NonNull final LayoutInflater inflater, @Nullable final ViewGroup container,
                             @Nullable final Bundle savedInstanceState) {
        super.onCreateView(inflater, container, savedInstanceState);

        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        getActivity().registerReceiver(networkChangeReceiver, intentFilter);

        binding = TunnelListFragmentBinding.inflate(inflater, container, false);
        binding.executePendingBindings();

        // TODO: Uncomment this code to enable the regions bottom sheet in the future
//        View bottomSheet = binding.getRoot().findViewById(R.id.bottom_sheet_layout);
//        bottomSheetBehavior = BottomSheetBehavior.from(bottomSheet);
//
//        setupBottomSheet(bottomSheet);

        return binding.getRoot();
    }

//    private void setupBottomSheet(View bottomSheet) {
//        LinearLayout collapsedView = bottomSheet.findViewById(R.id.bottom_sheet_collapsed_view);
//        LinearLayout expandedView = bottomSheet.findViewById(R.id.bottom_sheet_expanded_view);
//
//        bottomSheetCallback = new BottomSheetBehavior.BottomSheetCallback() {
//            @Override
//            public void onStateChanged(View bottomSheet, int newState) {
//                if (newState == BottomSheetBehavior.STATE_COLLAPSED) {
//                    expandedView.setVisibility(View.GONE);
//                    collapsedView.setVisibility(View.VISIBLE);
//                } else if (newState == BottomSheetBehavior.STATE_EXPANDED) {
//                    collapsedView.setVisibility(View.GONE);
//                    expandedView.setVisibility(View.VISIBLE);
//
//                    NestedScrollView scrollView = bottomSheet.findViewById(R.id.bottom_sheet_scroll_view);
//                    scrollView.scrollTo(0, 0);
//                }
//            }
//
//            @Override
//            public void onSlide(@NonNull View view, float v) {
//                if (v == 0) {
//                    expandedView.setVisibility(View.GONE);
//                    collapsedView.setVisibility(View.VISIBLE);
//                } else {
//                    collapsedView.setVisibility(View.GONE);
//                    if(v > 0.01) {
//                        expandedView.setVisibility(View.VISIBLE);
//                    }
//                }
//            }
//        };
//        bottomSheetBehavior.addBottomSheetCallback(bottomSheetCallback);
//
//        ImageButton chevronDown = bottomSheet.findViewById(R.id.chevron_down);
//        chevronDown.setOnClickListener(v -> bottomSheetBehavior.setState(BottomSheetBehavior.STATE_COLLAPSED));
//
//        ImageButton chevronUp = bottomSheet.findViewById(R.id.chevron_up);
//        chevronUp.setOnClickListener(v -> bottomSheetBehavior.setState(BottomSheetBehavior.STATE_EXPANDED));
//
//        renderServerLocations(bottomSheet);
//    }

//    private void renderServerLocations(View bottomSheet) {
//        final Activity activity = getActivity();
//        if (activity == null)
//            return;
//
//        final RegionManager regionManager = Application.getRegionManager();
//        RadioGroup radioGroup = bottomSheet.findViewById(R.id.server_locations_radio_group);
//        radioGroup.setOnCheckedChangeListener((group, checkedId) -> {
//            final RadioButton checkedRadioButton = group.findViewById(checkedId);
//            if(checkedRadioButton != null) {
//                final String region = checkedRadioButton.getTag().toString();
//                regionManager.setSelectedRegion(region);
//
//                displaySelectedRegion(bottomSheet, region);
//
//                final ObservableTunnel tunnel = getRostamTunnel();
//                // Change tunnel endpoint
//                if(tunnel != null) {
//                    endpointManager = new EndpointManager(tunnel, region);
//                    final InetEndpoint endpoint = endpointManager.getNextEndpoint();
//                    if(endpoint == null) {
//                        getNewEndpoints(tunnel, region, false);
//                    } else {
//                        changeTunnelEndpoint(tunnel, endpoint);
//                    }
//                }
//
//                bottomSheetBehavior.setState(BottomSheetBehavior.STATE_COLLAPSED);
//            }
//        });
//
//        final String packageName = activity.getPackageName();
//        final ObservableTunnel tunnel = getRostamTunnel();
//        final String selectedRegion = regionManager.getSelectedRegion();
//        displaySelectedRegion(bottomSheet, selectedRegion);
//        regionManager.loadRegions(regions ->  {
//            Log.d(TAG, regions.toString());
//            radioGroup.removeAllViews();
//            for(Integer i = 0; i < regions.size(); i++) {
//                final String region = regions.get(i);
//                int drawableResId = getResources().getIdentifier("ic_" + region, "drawable", packageName);
//                Drawable flag = ContextCompat.getDrawable(activity, drawableResId);
//                RadioButton radioButton = new RadioButton(activity);
//                radioButton.setId(i);
//                radioButton.setTag(region);
//                radioButton.setGravity(Gravity.CENTER_VERTICAL);
//                int textResId = getResources().getIdentifier(region, "string", packageName);
//                radioButton.setText(getString(textResId));
//                boolean enabled = tunnel == null || tunnel.getRostamState() == RostamState.OFF;
//                int textColor = enabled ? Color.WHITE : ContextCompat.getColor(activity, R.color.brown_grey);
//                radioButton.setEnabled(enabled);
//                radioButton.setTextColor(textColor);
//                radioButton.setTextSize(TypedValue.COMPLEX_UNIT_SP, 20);
//                radioButton.setButtonDrawable(R.drawable.custom_radio_button);
//                radioButton.setCompoundDrawablesWithIntrinsicBounds(null, null, flag, null);
//                int drawablePadding = (int)getResources().getDimension(R.dimen.radio_button_drawable_padding);
//                radioButton.setCompoundDrawablePadding(drawablePadding);
//                int topPadding = (int)getResources().getDimension(R.dimen.radio_button_top_padding);
//                int bottomPadding = (int)getResources().getDimension(R.dimen.radio_button_bottom_padding);
//                radioButton.setPadding(0, topPadding, 0, bottomPadding);
//                if(region.equals(selectedRegion)) {
//                    radioButton.setChecked(true);
//                    radioButton.setTextColor(Color.WHITE);
//                    radioButton.setEnabled(true);
//                }
//
//                radioGroup.addView(radioButton, RadioGroup.LayoutParams.MATCH_PARENT, RadioGroup.LayoutParams.WRAP_CONTENT);
//            }
//
//            bottomSheet.setVisibility(View.VISIBLE);
//        });
//    }
//
//    private void displaySelectedRegion(View bottomSheet, final String region) {
//        final Activity activity = getActivity();
//        if (activity == null)
//            return;
//
//        final String packageName = activity.getPackageName();
//
//        int drawableResId = getResources().getIdentifier("ic_" + region, "drawable", packageName);
//        Drawable flag = ContextCompat.getDrawable(activity, drawableResId);
//        ImageView selectedRegionFlag = bottomSheet.findViewById(R.id.selected_region_flag);
//        selectedRegionFlag.setImageDrawable(flag);
//
//        int textResId = getResources().getIdentifier(region, "string", packageName);
//        TextView selectedRegionText = bottomSheet.findViewById(R.id.selected_region);
//        selectedRegionText.setText(textResId);
//    }

//    private void enableRegionSelection() {
//        final Activity activity = getActivity();
//        if (activity == null)
//            return;
//
//        RadioGroup radioGroup = activity.findViewById(R.id.server_locations_radio_group);
//        for(int i = 0; i < radioGroup.getChildCount(); i++) {
//            final RadioButton radioButton = (RadioButton)radioGroup.getChildAt(i);
//            radioButton.setEnabled(true);
//            radioButton.setTextColor(Color.WHITE);
//        }
//    }
//
//    private void disableRegionSelection() {
//        final Activity activity = getActivity();
//        if (activity == null)
//            return;
//
//        RadioGroup radioGroup = activity.findViewById(R.id.server_locations_radio_group);
//        for(int i = 0; i < radioGroup.getChildCount(); i++) {
//            final RadioButton radioButton = (RadioButton)radioGroup.getChildAt(i);
//            if(!radioButton.isChecked()) {
//                radioGroup.getChildAt(i).setEnabled(false);
//                radioButton.setTextColor(ContextCompat.getColor(activity, R.color.brown_grey));
//            }
//        }
//    }

    @Override
    public void onDestroyView() {
        stopVpnConnectivityCheck();
        getActivity().unregisterReceiver(networkChangeReceiver);

        if(noInternetCafeBar != null) {
            noInternetCafeBar.dismiss();
            noInternetCafeBar = null;
        }
        binding = null;

//        bottomSheetBehavior.removeBottomSheetCallback(bottomSheetCallback);

        super.onDestroyView();
    }

    @Override
    public void onPause() {
        super.onPause();
    }

    @Override
    public void onSelectedTunnelChanged(@Nullable final ObservableTunnel oldTunnel, @Nullable final ObservableTunnel newTunnel) {
        if (binding == null)
            return;
    }

    private void onTunnelImportFinished(final List<ObservableTunnel> tunnels, final Collection<Throwable> throwables) {
        String message;

        for (final Throwable throwable : throwables) {
            final String error = ErrorMessages.get(throwable);
            message = getString(R.string.import_error, error);
            Log.e(TAG, message, throwable);
        }

        if(throwables.size() > 0) {
            CafeBarUtils.build(requireContext(), CafeBarUtils.TYPE_ERROR, R.string.tunnel_import_error, CafeBarUtils.LENGTH_LONG).show();
        }
    }

    @Override
    public void onViewStateRestored(@Nullable final Bundle savedInstanceState) {
        super.onViewStateRestored(savedInstanceState);

        if (binding == null) {
            return;
        }
        binding.setFragment(this);
        Application.getTunnelManager().getTunnels().thenAccept(binding::setTunnels);
        binding.setRowConfigurationHandler((ObservableKeyedRecyclerViewAdapter.RowConfigurationHandler<TunnelListItemBinding, ObservableTunnel>) (binding, tunnel, position) -> {
            binding.setFragment(this);

            // Reduce the Rostam image size for smaller screens...
            if(getScreenHeight() < 1200) {
                RelativeLayout rostamImageLayout = ((LinearLayout)binding.getRoot()).findViewById(R.id.rostam_image_layout);
                LinearLayout.LayoutParams params = (LinearLayout.LayoutParams)rostamImageLayout.getLayoutParams();
                params.width = (int)getResources().getDimension(R.dimen.small_rostam_image_width);
                params.height = (int)getResources().getDimension(R.dimen.small_rostam_image_height);
                params.topMargin = params.topMargin / 2;
                rostamImageLayout.setLayoutParams(params);
                rostamImageLayout.requestLayout();
            }
        });
    }

    private int getScreenHeight() {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        ((Activity) requireContext()).getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);

        return displayMetrics.heightPixels;
    }

    private void showLandingPage(final ObservableTunnel tunnel, final String ipAddress) {
        LayoutInflater inflater = (LayoutInflater) getActivity().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View popupView = inflater.inflate(R.layout.popup_layout, null, false);
        final PopupWindow popupWindow = new PopupWindow(popupView, ViewGroup.LayoutParams.MATCH_PARENT,ViewGroup.LayoutParams.MATCH_PARENT, true);
        popupWindow.showAtLocation(getView(), Gravity.CENTER, 0, 0);

        ImageButton closeButton = popupView.findViewById(R.id.popup_close);
        TextView countDown = popupView.findViewById(R.id.countdown_text);
        closeButton.setOnClickListener(pv -> {
            popupWindow.dismiss();

            FragmentTransaction fragmentTransaction = getFragmentManager().beginTransaction();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                fragmentTransaction.setReorderingAllowed(false);
            }
            fragmentTransaction.detach(this).attach(this).commit();
        });

        WebView webView = popupView.findViewById(R.id.web_view);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setLoadWithOverviewMode(true);
        webView.getSettings().setUseWideViewPort(true);
        webView.setWebViewClient(new WebViewClient() {
            @SuppressWarnings("deprecation")
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                view.loadUrl(url);

                return true;
            }

            @RequiresApi(Build.VERSION_CODES.N)
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                String url = request.getUrl().toString();
                view.loadUrl(url);

                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                webView.setVisibility(View.VISIBLE);
                tunnel.setStateChanging(false);
                tunnel.setRostamState(RostamState.ON);
                showLandingPage = false;

                // Display the close button after 5 seconds
                countDown.setVisibility(View.VISIBLE);
                new CountDownTimer(5000, 1000) {
                    @Override
                    public void onTick(long millisUntilFinished) {
                        Long seconds = (millisUntilFinished / 1000) + 1;
                        countDown.setText(Long.toString(seconds));
                    }

                    @Override
                    public void onFinish() {
                        closeButton.setVisibility(View.VISIBLE);
                        countDown.setVisibility(View.INVISIBLE);
                    }
                }.start();
            }
        });

        final String landingPageUrl = LANDING_PAGE_URL + "?ip=" + ipAddress;
        webView.loadUrl(landingPageUrl);
    }
}
