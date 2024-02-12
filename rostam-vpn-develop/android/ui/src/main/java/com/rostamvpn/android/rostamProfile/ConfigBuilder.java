package com.rostamvpn.android.rostamProfile;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Base64;
import android.util.Log;

import com.amplitude.api.Amplitude;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.JsonObjectRequest;

import com.rostamvpn.android.Application;
import com.rostamvpn.android.util.FilenameRequest;
import com.rostamvpn.config.BadConfigException;
import com.rostamvpn.config.Config;
import com.rostamvpn.crypto.KeyPair;
import com.rostamvpn.util.NonNullForAll;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.InetAddress;
import java.net.URL;
import java.net.UnknownHostException;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

@NonNullForAll
public class ConfigBuilder {
    private static final String TAG = "RostamVPN/" + ConfigBuilder.class.getSimpleName();
    private static final String API_DATA_TAG = "RostamVPNApiData";
    private static final String PROFILE_API_TAG = "RostamVPNProfileApi";
    private static final String API_DATA_KEY = "rostam_api_data";
    private static final String API_EXPIRY_KEY = "rostam_api_expiry";
    private static final String DEFAULT_API_URL = "https://docs.google.com/feeds/download/documents/export/Export?id=1eU2garmd4ZKLCEGDoqpQ8I2-C7llC8u1chJ3uo1OPt8&amp;exportFormat=html";
    private static String path;
    private static String host;
    private static String domainFront;
    private static String apiUrl;
    private static int expiry = 0;

    public static void build(final Context context, final KeyPair keyPair, final String region, ConfigBuilderCallback callback) {
        getApiData(context, new ApiDataCallback() {
            @Override
            public void onSuccess() {
                getProfileData(keyPair, region, new ProfileApiCallback() {
                    @Override
                    public void onSuccess(final String address, final String[] endpoints, final String serverPublicKey) {
                        final String endpoint = endpoints[0];
                        final String configText = createConfigText(keyPair.getPrivateKey().toBase64(), serverPublicKey, address, endpoint);

                        Amplitude.getInstance().logEvent("Call to profile API succeeded");

                        callback.onSuccess(configText);
                    }

                    @Override
                    public void onFail(final String errorMessage) {
                        try {
                            JSONObject eventProperties = new JSONObject();
                            eventProperties.put("error", errorMessage);
                            Amplitude.getInstance().logEvent("Call to profile API error", eventProperties);
                        }
                        catch (JSONException ex) {
                            Log.e(TAG, ex.getMessage());
                        }

                        Amplitude.getInstance().logEvent("Call to profile API failed");

                        callback.onFail();
                    }
                });
            }

            @Override
            public void onFail(final String errorMessage) {
                try {
                    JSONObject eventProperties = new JSONObject();
                    eventProperties.put("error", errorMessage);
                    Amplitude.getInstance().logEvent("Failed to obtain API data JSON", eventProperties);
                }
                catch (JSONException ex) {
                    Log.e(TAG, ex.getMessage());
                }

                callback.onFail();
            }
        });
    }

    public static Config parse(final KeyPair keyPair, final InputStream stream) throws IOException, JSONException, BadConfigException, InvalidKeyException {
        final StringBuilder builder = new StringBuilder();
        final BufferedReader reader = new BufferedReader(new InputStreamReader(stream));

        String line;
        while ((line = reader.readLine()) != null) {
            builder.append(line + System.lineSeparator());
        }

        final JSONObject json = new JSONObject(builder.toString());

        final String address = json.getString( "address");
        final String[] endpoints = getStringArray(json.getJSONArray( "endpoint"));
        final String clientPublicKey = json.getString("client_pubkey");
        final String serverPublicKey = json.getString( "pubkey");

        final String pubkey = keyPair.getPublicKey().toBase64();
        if(!clientPublicKey.equals(pubkey)) {
            throw new InvalidKeyException("Invalid public key!");
        }

        EndpointManager.storeEndpoints(endpoints, null);

        final String endpoint = endpoints[0];
        final String configText = createConfigText(keyPair.getPrivateKey().toBase64(), serverPublicKey, address, endpoint);
        final Config config = Config.parse(new ByteArrayInputStream(configText.getBytes(StandardCharsets.UTF_8)));

        return config;
    }

    private static void getProfileData(final KeyPair keyPair, final String region, ProfileApiCallback callback) {
        final String profileApiUrl = "https://" + domainFront + path;

        // This is a hack for the UnknownHostException issue
        // https://stackoverflow.com/questions/3293659/android-java-net-unknownhostexception-host-is-unresolved-strategy-question
        Application.getAsyncWorker().runAsync(() -> {
            try {
                URL url = new URL(profileApiUrl);
                InetAddress inetAddress = InetAddress.getByName(url.getHost());
            } catch (UnknownHostException e) {
                Log.e(TAG, e.getMessage());
            }
        });

        // Get the RequestQueue.
        RequestQueue queue = Application.getRequestQueue();
        queue.getCache().clear();

        // Call the API to get the endpoint and address...
        Map<String, String> params = new HashMap<>();
        params.put("pubkey", keyPair.getPublicKey().toBase64());
        if(region != null) {
            params.put("region", region);
        }
        JSONObject parameters = new JSONObject(params);
        JsonObjectRequest jsonObjectRequest = new JsonObjectRequest
                (Request.Method.POST, profileApiUrl, parameters, response -> {
                    Log.d(TAG, "Profile API Response: " + response);

                    String status;
                    String message = "";
                    String address = "";
                    String[] endpoints = null;
                    String serverPublicKey = "";
                    try {
                        status = response.getString("status");
                        message = response.getString( "message");
                        address = response.getString( "address");
                        endpoints = getStringArray(response.getJSONArray( "endpoint"));
                        serverPublicKey = response.getString( "pubkey");
                    }
                    catch (JSONException e) {
                        Log.e(TAG, e.getMessage());
                        status = "fail";
                    }

                    if(status.equals("ok")) {
                        EndpointManager.storeEndpoints(endpoints, region);
                        callback.onSuccess(address, endpoints, serverPublicKey);
                    }
                    else {
                        Log.d(TAG, message);
                        callback.onFail(message);
                    }
                }, error -> {
                    Log.e(TAG, error.getMessage(), error);
                    final String message = error.getMessage() != null ? error.getMessage() : error.toString();
                    callback.onFail(message);
                }) {
            @Override
            public Map<String, String> getHeaders() {
                Map<String, String>  headers = new HashMap<>();
                headers.put("Host", host);

                return headers;
            }
        };

        // Add the request to the RequestQueue.
        jsonObjectRequest.setTag(PROFILE_API_TAG);
        jsonObjectRequest.setRetryPolicy(Application.getDefaultRetryPolicy());
        jsonObjectRequest.setShouldCache(false);
        queue.add(jsonObjectRequest);
    }

    private static void getApiData(final Context context, ApiDataCallback callback) {
        if(!isExpired()) {
            final String jsonString = Application.getSharedPreferences().getString(API_DATA_KEY, null);
            if(jsonString != null) {
                if(parseApiDataJson(jsonString) == true) {
                    callback.onSuccess();
                    return;
                }
            }
        }

        final String apiDataUrl = apiUrl == null ? DEFAULT_API_URL : apiUrl;
        RequestQueue queue = Application.getRequestQueue();
        queue.getCache().clear();

        FilenameRequest filenameRequest = new FilenameRequest
            (apiDataUrl, response -> {
                Log.d(TAG, "API data Response: " + response);

                byte[] decodedBytes = Base64.decode(response, Base64.DEFAULT);
                String jsonString = new String(decodedBytes);
                Log.d(TAG, "API data JSON: " + jsonString);

                if (parseApiDataJson(jsonString) == true) {
                    storeExpiry(expiry);
                    storeApiData(jsonString);
                    callback.onSuccess();
                } else {
                    callback.onFail("Failed to parse API data JSON");
                }
            }, error -> {
                final String message = error.getMessage() != null ? error.getMessage() : error.toString();
                Log.e(TAG, message);
                callback.onFail(message);
            });

        // Add the request to the RequestQueue.
        filenameRequest.setTag(API_DATA_TAG);
        filenameRequest.setRetryPolicy(Application.getDefaultRetryPolicy());
        filenameRequest.setShouldCache(false);
        queue.add(filenameRequest);
    }
    
    private static String createConfigText(final String privateKey, final String publicKey, final String address, final String endpoint) {
        final StringBuilder builder = new StringBuilder();
        builder.append("[Interface]");
        builder.append("\nPrivateKey = " + privateKey);
        builder.append("\nAddress = " + address);
        builder.append("\nDNS = 8.8.8.8");
        builder.append("\n\n[Peer]");
        builder.append("\nPublicKey = " + publicKey);
        builder.append("\nAllowedIPs = 0.0.0.0/0");
        builder.append("\nEndpoint = " + endpoint);
        builder.append("\nPersistentKeepalive = 25");

        return builder.toString();
    }

    private static String[] getStringArray(JSONArray jsonArray) {
        String[] stringArray = null;
        if (jsonArray != null) {
            int length = jsonArray.length();
            stringArray = new String[length];
            for (int i = 0; i < length; i++) {
                stringArray[i] = jsonArray.optString(i);
            }
        }

        return stringArray;
    }

    private static void storeApiData(final String json) {
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(API_DATA_KEY, json);
        editor.apply();
    }

    private static void storeExpiry(final int expiry) {
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        Date now = new Date();
        long expiryLong = now.getTime() + expiry * 1000;
        editor.putLong(API_EXPIRY_KEY, expiryLong);
        editor.apply();
    }

    private static boolean isExpired() {
        final long expiryLong = Application.getSharedPreferences().getLong(API_EXPIRY_KEY, 0);
        if(expiryLong == 0) return true;

        Date now = new Date();
        return now.getTime() > expiryLong;
    }

    private static boolean parseApiDataJson(final String jsonString) {
        final JSONObject json;
        try {
            json = new JSONObject(jsonString);

            path = json.getString( "path");
            host = json.getString( "host");
            domainFront = json.getString( "domain_front");
            apiUrl = json.getString( "apiURL");
            expiry = json.getInt( "expiry");

            Amplitude.getInstance().logEvent("Successfully obtained API data JSON", json);

            return true;
        } catch (JSONException e) {
            Log.e(TAG, e.getMessage());
            return false;
        }
    }
}