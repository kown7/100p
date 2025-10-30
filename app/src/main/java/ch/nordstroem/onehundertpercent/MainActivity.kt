package ch.nordstroem.onehundertpercent

import android.Manifest
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.annotation.RequiresPermission
import androidx.compose.foundation.layout.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import ch.nordstroem.onehundertpercent.ui.theme.OneHundertPercentTheme
import java.util.Calendar
import java.util.Date
import kotlin.math.roundToInt

val defaultLocation = Location(LocationManager.GPS_PROVIDER).apply {
    latitude = 47.3769 // Zurich latitude
    longitude = 8.5417 // Zurich longitude
}

class MainActivity : ComponentActivity() {

    @RequiresPermission(allOf = [Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION])
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        var cLocation = defaultLocation;

        var progress = 12

        setContent {
            OneHundertPercentTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Greeting(
                        location = cLocation,
                        progress = progress,
                        modifier = Modifier.padding(innerPadding),
                    )
                }
            }
        }

        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        val locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                cLocation = location;
                Toast.makeText(
                    this@MainActivity,
                    "A pikachu appeared nearby !" + location.latitude,
                    Toast.LENGTH_SHORT
                ).show()

                setContent {
                    OneHundertPercentTheme {
                        Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                            Greeting(
                                location = cLocation,
                                progress = progress,
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
fun Greeting(location: Location, progress: Int, modifier: Modifier = Modifier) {
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
        val elapsedDay: Double = delta.toDouble() / (24.0 * 60 * 60 * 1000);

        CircularProgressIndicator(
//      progress = { progress / 100f },
            progress = { elapsedDay.toFloat() },
            modifier = Modifier.size(240.dp),
            strokeWidth = 30.dp,
//        color = ProgressIndicatorDefaults.circularColor,
//        trackColor = ProgressIndicatorDefaults.circularTrackColor,
            strokeCap = StrokeCap.Butt,
        )

        val percents: Float = (elapsedDay * 1000).roundToInt() / 10f

        Text(
            text = "${percents}%",
            modifier = modifier
        )
    }
    Box(
        contentAlignment = Alignment.TopEnd,
        modifier = Modifier.fillMaxSize()
    ) {
        Text(
            text = ("Location \n"
                    + "Lat ${location.latitude} N \n"
                    + "Long ${location.longitude} W\n"
                    )
        )
    }
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    OneHundertPercentTheme {
        Greeting(
            defaultLocation,
            progress = 75
        )
    }
}
