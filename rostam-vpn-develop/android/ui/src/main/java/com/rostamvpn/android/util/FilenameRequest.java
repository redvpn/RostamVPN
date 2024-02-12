package com.rostamvpn.android.util;

import com.android.volley.NetworkResponse;
import com.android.volley.Response;
import com.android.volley.toolbox.HttpHeaderParser;
import com.android.volley.toolbox.StringRequest;

import com.rostamvpn.util.NonNullForAll;

@NonNullForAll
public class FilenameRequest extends StringRequest {

    public FilenameRequest(String url, Response.Listener<String>
            listener, Response.ErrorListener errorListener) {
        super(url, listener, errorListener);
    }

    @Override
    protected Response<String> parseNetworkResponse(NetworkResponse response) {
        String contentDisposition = response.headers.get("Content-Disposition");
        String split1[] = contentDisposition.split("filename=\"");
        String split2[] = split1[1].split(".html\";");
        String filename = split2[0];
        return Response.success(filename,
                HttpHeaderParser.parseCacheHeaders(response));
    }
}