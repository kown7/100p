package ch.nordstroem.onehundertpercent

import android.Manifest
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.util.Log
import android.content.pm.PackageManager
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.annotation.RequiresPermission
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import ch.nordstroem.onehundertpercent.ui.theme.OneHundertPercentTheme
import java.util.Calendar
import java.util.Date

val defaultLocation = Location(LocationManager.GPS_PROVIDER).apply {
    latitude = 47.3769 // Zurich latitude
    longitude = 8.5417 // Zurich longitude
}



class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Check for location permissions
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            requestLocationPermission()
        } else {
            startLocationUpdates()
        }

        setContent {
            OneHundertPercentTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Greeting(
                        location = defaultLocation,
                        modifier = Modifier.padding(innerPadding),
                    )
                }
            }
        }

    private fun requestLocationPermission() {
        val requestPermissionLauncher = registerForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) { permissions ->
            if (permissions[Manifest.permission.ACCESS_FINE_LOCATION] == true ||
                permissions[Manifest.permission.ACCESS_COARSE_LOCATION] == true) {
                startLocationUpdates()
            } else {
                Toast.makeText(this, "Location permission denied", Toast.LENGTH_SHORT).show()
            }
        }
        requestPermissionLauncher.launch(
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
        )
    }

    @RequiresPermission(allOf = [Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION])
    private fun startLocationUpdates() {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        val locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                val twc = TwilightCalculator();
                twc.calculateTwilight(Calendar.getInstance().timeInMillis,
                    location.latitude, location.longitude);
                Toast.makeText(
                    this@MainActivity,
                    "A pikachu appeared nearby !" + location.latitude,
                    Toast.LENGTH_SHORT
                ).show()

                setContent {
                    OneHundertPercentTheme {
                        Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                            Greeting(
                                location = location,
                                modifier = Modifier.padding(innerPadding),
                            )
                        }
                    }
                }
            }
        }
        // Request location updates (ensure you have the necessary permissions)
        locationManager.requestLocationUpdates(
            LocationManager.GPS_PROVIDER,
            0L,
            0f,
            locationListener
        )
    }
}

@Composable
fun Greeting(location: Location, modifier: Modifier = Modifier) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier.fillMaxSize()
    ) {
        val currentTime: Long = Calendar.getInstance().timeInMillis;
        val startOfDay: Date = Calendar.getInstance().getTime()
        startOfDay.hours = 0;
        startOfDay.minutes = 0;
        startOfDay.seconds = 0;

        val delta = currentTime - startOfDay.toInstant().toEpochMilli();

        val twc = TwilightCalculator();
        twc.calculateTwilight(Calendar.getInstance().timeInMillis,
            location.latitude, location.longitude);

        var elapsedDay: Double = -1.0
        var centerText: String = "Es ist Zeit"

        if (twc.mState == TwilightCalculator.NIGHT) {
            elapsedDay = 1.0;
        } else {
            elapsedDay = (currentTime - twc.mSunrise).toDouble() / (twc.mSunset - twc.mSunrise).toDouble();
            Log.d("ADebugTag", "Value: " + elapsedDay.toString());
            centerText = String.format("%.1f", elapsedDay * 100.0) + "%";
        }

        CircularProgressIndicator(
            progress = { elapsedDay.toFloat() },
            modifier = Modifier.size(240.dp),
            strokeWidth = 30.dp,
//        color = ProgressIndicatorDefaults.circularColor,
//        trackColor = ProgressIndicatorDefaults.circularTrackColor,
            strokeCap = StrokeCap.Butt,
        )

        Text(
            text = centerText,
            modifier = modifier
        )
    }
    Box(
        contentAlignment = Alignment.TopEnd,
        modifier = Modifier.fillMaxSize()
    ) {
        Text(
            text = ("Location \n"
                    + "Lat  " + String.format("%.2f", location.latitude) + " N\n"
                    + "Long " + String.format("%.2f", location.longitude) + " E\n"
                    )
        )
    }
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    OneHundertPercentTheme {
        Greeting(
            defaultLocation
        )
    }
}
