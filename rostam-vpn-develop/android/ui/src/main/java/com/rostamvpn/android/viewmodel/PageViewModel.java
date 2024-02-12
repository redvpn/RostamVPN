package com.rostamvpn.android.viewmodel;

import com.rostamvpn.android.R;
import com.rostamvpn.util.NonNullForAll;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.Transformations;
import androidx.lifecycle.ViewModel;

@NonNullForAll
public class PageViewModel extends ViewModel {

    private MutableLiveData<Integer> mIndex = new MutableLiveData<>();
    private LiveData<Integer> mText = Transformations.map(mIndex, input -> {
        switch(input) {
//            case 1:
//                return R.string.onboarding_fast_servers;
            case 1:
                return R.string.onboarding_bypass_censorship;
            case 2:
                return R.string.onboarding_encrypt_online_communication;
            case 3:
                return R.string.onboarding_increase_digital_safety;
            default:
                return null;
        }
    });
    private LiveData<Integer> mImage = Transformations.map(mIndex, input -> {
       switch (input) {
//           case 1:
//               return R.drawable.illustration_globe;
           case 1:
               return R.drawable.illustration_banned;
           case 2:
               return R.drawable.illustration_lock;
           case 3:
               return R.drawable.illustration_digital_safety;
           default:
               return null;
       }
    });

    public void setIndex(int index) {
        mIndex.setValue(index);
    }

    public LiveData<Integer> getText() {
        return mText;
    }

    public LiveData<Integer> getImage() {
        return mImage;
    }
}