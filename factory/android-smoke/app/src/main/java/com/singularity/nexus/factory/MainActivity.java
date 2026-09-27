package com.singularity.nexus.factory;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.view.Gravity;
import android.widget.TextView;

public final class MainActivity extends Activity {
    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        TextView v = new TextView(this);
        v.setText("NEXUS APP FACTORY\nANDROID GATE: ONLINE");
        v.setTextColor(Color.CYAN);
        v.setBackgroundColor(Color.rgb(1,1,3));
        v.setTextSize(22f);
        v.setGravity(Gravity.CENTER);
        setContentView(v);
    }
}
