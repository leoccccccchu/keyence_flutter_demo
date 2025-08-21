package com.example.keyence_flutter_demo;

import androidx.annotation.NonNull;
import android.os.Bundle;
import android.util.Log;
import android.os.Handler;
import android.os.Looper;

import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;

import com.keyence.autoid.sdk.scan.ScanManager;
import com.keyence.autoid.sdk.scan.DecodeResult;
import com.keyence.autoid.sdk.scan.scanparams.ScanParams;
import com.keyence.autoid.sdk.scan.scanparams.CodeType;

public class KeyenceScannerActivity extends FlutterActivity implements ScanManager.DataListener {
    private static final String CHANNEL = "keyence_scanner/methods";
    private static final String EVENTS = "keyence_scanner/events";
    private final Handler main = new Handler(Looper.getMainLooper());

    private EventChannel.EventSink sink;
    private ScanManager mScanManager;
    private ScanParams mScanParams;
    private CodeType mCodeType;
    private MethodChannel methodChannel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    try {
                        String arg = (String) call.arguments;
                        switch (call.method) {
                            case "lockScanner":
                                lockScanner(arg);
                                result.success("Scanner set to " + arg);
                                break;
                            case "ScanMode":
                                setScanMode(arg);
                                result.success("Scan Mode set to " + arg);
                                break;
                            default:
                                result.notImplemented();
                                break;
                        }
                    } catch (Exception e) {
                        result.error("KEYENCE_ERR", e.getMessage(), null);
                    }
                });

        new EventChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                EVENTS).setStreamHandler(new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object args, EventChannel.EventSink events) {
                        sink = events;

                        // 🔎 Send a test event so you can see it's working
                        // sendScan("testscan");
                    }

                    @Override
                    public void onCancel(Object args) {
                        sink = null;
                    }
                });
    }

    // Create a read event.
    @Override
    public void onDataReceived(DecodeResult decodeResult) {
        List<Map<String, Object>> scans = new ArrayList<>();
        // Acquire the reading result.
        DecodeResult.Result result = decodeResult.getResult();

        if (result == DecodeResult.Result.CANCELED) {
            Log.d("KeyenceScan", "User clicked CANCEL / Invalid scan result");
            sendScan(scans);
        } else if (result == DecodeResult.Result.SUCCESS) {
            Log.d("KeyenceScan", "User clicked SEND / Scan completed successfully");

            // Get all scanned data as a list of Strings
            List<String> dataList = decodeResult.getDataList();
            // Get all scanned Code Type as a list of Strings
            List<String> codeTypeList = decodeResult.getCodeTypeList();
            // Loop through them
            for (int i = 0; i < dataList.size(); i++) {
                Map<String, Object> scan = new HashMap<>();
                scan.put("Index", i);
                scan.put("CodeType", codeTypeList.get(i));
                scan.put("Data", dataList.get(i));
                scans.add(scan);
            }
            sendScan(scans);
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            // Create a ScanManager class instance.
            // From here on, you can control reading using mScanManager.
            mScanManager = ScanManager.createScanManager(this);
            Log.d("KeyenceBridge", "Scan Manager created successfully");
            // Create a listener to receive a read event.
            mScanManager.addDataListener(this);
            Log.d("KeyenceBridge", "Data listener added successfully");

        } catch (Exception e) {
            Log.e("KeyenceBridge", "Error Create Scan Manager", e);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // Discard the ScanManager class instance to release the resources.
        try {
            // Discard the ScanManager class instance.
            mScanManager.removeDataListener(this);
            Log.d("KeyenceBridge", "Data listener removed successfully");
            mScanManager.releaseScanManager();
            Log.d("KeyenceBridge", "Scan Manager released successfully");
        } catch (Exception e) {
            Log.e("KeyenceBridge", "Error releasing Scan Manager", e);
        }
    }

    private void lockScanner(String arg) {
        try {
            if (arg.equals("Lock")) {
                mScanManager.lockScanner();
                Log.d("KeyenceBridge", "Scanner locked");
            } else if (arg.equals("Unlock")) {
                mScanManager.unlockScanner();
                Log.d("KeyenceBridge", "Scanner unlocked");
            } else {
                Log.e("KeyenceBridge", "Invalid argument for lockScanner: " + arg);
                return;
            }
        } catch (Exception e) {
            Log.e("KeyenceBridge", "Error locking scanner", e);
        }
    }

    private void setScanMode(String scanMode) {
        try {
            mScanParams = new ScanParams();
            // Reset to default first
            mScanParams.setDefault();
            mScanManager.setConfig(mScanParams);
            Log.d("KeyenceBridge", "Reset Scan Mode to default");
            if (scanMode.equals("Default")) {
                Log.d("KeyenceBridge", "Default scan mode requested, quit after reset.");
                return; // quit the method immediately
            }

            mCodeType = new CodeType();
            // Set all default true Code Type to false (others Code Type default is ture)
            mCodeType.upcEanJan = false;
            mCodeType.code128 = false;
            mCodeType.code39 = false;
            mCodeType.itf = false;
            mCodeType.gs1DataBar = false;
            mCodeType.datamatrix = false;
            mCodeType.qrCode = false;
            mCodeType.pdf417 = false;
            mCodeType.codabarNw7 = false;

            // Set the Scan Mode needed
            switch (scanMode) {
                case "EANOnly":
                    mCodeType.upcEanJan = true;
                    break;
                case "LLWR":
                    mCodeType.upcEanJan = true;
                    mCodeType.qrCode = true;
                    mCodeType.datamatrix = true;
                    mCodeType.code128 = true;
                    mScanParams.collection.codeCountAccumulate = 3;
                    break;
            }

            mScanParams.decoder.colorInversion = mScanParams.decoder.colorInversion.AUTO;
            mScanManager.setConfig(mScanParams);
            mScanManager.setConfig(mCodeType);
            Log.d("KeyenceBridge", "Scan Mode set to " + scanMode);

        } catch (Exception e) {
            Log.e("KeyenceBridge", "Error setting Scan Mode", e);
        }
    }

    /** Call this from your Keyence SDK callback. */
    private void sendScan(List<Map<String, Object>> scans) {
        if (sink == null)
            return;
        main.post(() -> sink.success(scans)); // send on main thread
    }
}
