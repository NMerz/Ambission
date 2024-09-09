package ambission.ambission

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import ambission.ambission.ui.theme.AmbissionTheme
import android.util.Log
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.material3.Button
import androidx.compose.ui.Alignment
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.google.firebase.functions.FirebaseFunctions
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import kotlinx.serialization.Serializable

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        PDFBoxResourceLoader.init(applicationContext);
        AppDatabase.getSharedDatabase(application)
        enableEdgeToEdge()
        setContent {
            AppRoot()
        }
    }
}

@Serializable
data class Greetable(val name: String, val num: Int)
@Serializable
data class Homeable(val name: String)

@Composable
fun AppRoot() {
    val navController = rememberNavController()

    AmbissionTheme {
            NavHost(
                navController = navController,
                startDestination = Greetable(name = "enter here", 123)
            ) {
                composable<Greetable> {backStackEntry ->
                    val greetable: Greetable = backStackEntry.toRoute()
                    Greeting(greetable.name, num = greetable.num, navFunction = navController::navigateSingleTopTo)
                }
                composable<Homeable> {backStackEntry ->
                    val homeable: Homeable = backStackEntry.toRoute()
                    HomeScreen(homeable.name, navFunction = navController::navigateSingleTopTo)
                }
                composable<ScriptGenerationScreenArgs> {navBackStackEntry ->
                    val scriptGenerationArgs: ScriptGenerationScreenArgs = navBackStackEntry.toRoute()
                    ScriptGenerationScreen(scriptGenerationArgs, navFunction = navController::navigateSingleTopTo)
                }
                composable<SegmentsScreenArgs> {navBackStackEntry ->
                    val segmentsScreenArgs: SegmentsScreenArgs = navBackStackEntry.toRoute()
                    SegmentsScreen(segmentsScreenArgs, navFunction = navController::navigateSingleTopTo)
                }
                composable<RecordScreenArgs> {navBackStackEntry ->
                    val recordScreenArgs: RecordScreenArgs = navBackStackEntry.toRoute()
                    RecordScreen(recordScreenArgs, modifier = Modifier.wrapContentHeight(unbounded = true), returnFunction = navController::popBackStack)
                }
                composable<EditScreenArgs> {navBackStackEntry ->
                    val editScreenArgs: EditScreenArgs = navBackStackEntry.toRoute()
                    EditScreen(editScreenArgs, modifier = Modifier.wrapContentHeight(unbounded = true), returnFunction = navController::popBackStack)
                }
            }
    }
}

fun NavHostController.navigateSingleTopTo(route: Any) =
    this.navigate(route) { launchSingleTop = true }

@Composable
fun Greeting(name: String, num: Int, navFunction: (Any) -> Unit, modifier: Modifier = Modifier) {

    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(num.toString())
        Button(onClick = {
            Log.i("AMB", "foobar")
            navFunction(Homeable(name = "Mr. Barius Fooious"))
        }, modifier = modifier) {
            Text(
                text = "Hello $name!",
                modifier = modifier
            )
        }
    }
}



@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    AmbissionTheme {
        Greeting("Android", num= 123, navFunction = {})
    }
}