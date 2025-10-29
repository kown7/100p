package ch.nordstroem.onehundertpercent

import android.Manifest
import android.os.Bundle
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.annotation.RequiresPermission
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import ch.nordstroem.onehundertpercent.ui.theme.OneHundertPercentTheme

class MainActivity : ComponentActivity() {

    @RequiresPermission(allOf = [Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION])
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val defaultLocation = Location(LocationManager.GPS_PROVIDER).apply {
                  latitude = 47.3769 // Zurich latitude
                 longitude = 8.5417 // Zurich longitude
        }
        var cLocation = defaultLocation;

        var progress by remember { mutableStateOf(0.0f) }

        // Simulate progress update
        LaunchedEffect(Unit) {
            while (progress < 1.0f) {
                progress += 0.1f
                delay(1000L) // Simulate work
            }
        }

        setContent {
            OneHundertPercentTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Greeting(
                        name = "Android",
                        progress = progress,
                        onProgressComplete = {
                            Toast.makeText(this@MainActivity, "Progress Complete!", Toast.LENGTH_SHORT).show()
                        },
                        modifier = Modifier.padding(innerPadding),
                    )
                }
            }
        }

        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                cLocation = location;
                Toast.makeText(this@MainActivity, "A pikachu appeared nearby !" + location.latitude, Toast.LENGTH_SHORT).show()
            }
        }
        // Request location updates (ensure you have the necessary permissions)
        locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0L, 0f, locationListener)
    }
}

@Composable
fun Greeting(name: String, progress: Float, onProgressComplete: () -> Unit, modifier: Modifier = Modifier) {
    if (progress >= 1.0f) {
        onProgressComplete()
    }
    CircularProgressIndicator(progress = progress, modifier = modifier)
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    OneHundertPercentTheme {
        Greeting("Android")
    }
}
