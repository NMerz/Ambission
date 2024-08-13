package ambission.ambission

import ambission.ambission.utilities.Picker
import android.util.Log
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.LiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.firebase.functions.FirebaseFunctions
import kotlinx.serialization.Serializable
import java.util.UUID

open class DatabaseAccess: ViewModel() {
    private val dbdao = AppDatabase.getSharedDatabase().createdVideoDao()
    private fun getTypeSpecific(videoUid: String): Map<String, String> {
        return dbdao.getVideo(videoUid).typeSpecificInput
    }
    fun getJobUrl(videoUid: String): String {
        val jobUrl = getTypeSpecific(videoUid)["jobUrl"] ?: ""
        return jobUrl
    }

    fun getListingText(videoUid: String): String {
        val listingText = getTypeSpecific(videoUid)["listingText"] ?: ""
        return listingText
    }
    private fun updatingTypeSpecificInput(videoUid: String, key: String, value: String) {
        val newMap = dbdao.getVideoSnapshot(videoUid).typeSpecificInput.toMutableMap()
        newMap[key] = value
        dbdao.updateTypeSpecificInput(videoUid, newMap)
        Log.d("dbUpdate", "New $key: $newMap")
    }

    fun setJobUrl(videoUid: String, newJobUrl: String) {
        updatingTypeSpecificInput(videoUid, "jobUrl", newJobUrl)
    }

    fun setScript(videoUid: String, script: String) {
        dbdao.updateUnifiedScript(videoUid, script)
    }

    fun setListingText(videoUid: String, newListingText: String) {
        updatingTypeSpecificInput(videoUid, "listingText", newListingText)

    }

    fun getNominalType(videoUid: String): String {
        return dbdao.getVideo(videoUid).nominalType
    }

    fun getUnifiedScript(videoUid: String): String {
        return dbdao.getVideo(videoUid).unifiedScript
    }

    fun getVideoTitle(videoUid: String): String {
        return dbdao.getVideo(videoUid).videoTitle
    }

    fun setSegmentScripts(videoUid: String, segmentReturn: SegmentReturn) {
        dbdao.setSegmentScripts(videoUid, segmentReturn.ordering, segmentReturn.orderableMapping)
    }

    fun setSegmentUrls(videoUid: String, segmentUrls: Map<String, String>) {
        dbdao.setSegmentUrls(videoUid, segmentUrls)
    }

    fun getSegments(videoUid: String): List<String> {
        return dbdao.getVideo(videoUid).segments
    }

    fun getSegmentTexts(videoUid: String): Map<String, String> {
        return dbdao.getVideo(videoUid).segmentTexts
    }

    fun setSegmentTexts(videoUid: String, segmentTexts: Map<String, String>) {
        dbdao.setSegmentTexts(videoUid, segmentTexts)
    }
}

class ScriptGeneration: DatabaseAccess() {
    private val inputsdao = AppDatabase.getSharedDatabase().inputsDao()

    fun getResume(): LiveData<String> {
        return inputsdao.getResume().asLiveData()
    }

}

@Serializable
class ScriptGenerationScreenArgs(val uid: String) {
}

fun getNewScript(resume: String, type: String, tone: String, callback: (String) -> Unit, listingText: String) {
    if (resume == "") {
        callback("Please upload a resume first. You can do so under the Me tab.")
        return
    }

    if (type == "recruiter") {
        if (listingText == "") {
            callback("Please input the url or contents of the targeted job listing at the top of this screen and wait for it to finish processing.")
            return
        }
        Log.d("FunctionCall", "Calling makeRecruiterScript")
        Firebase.shared.getFunctions().getHttpsCallable("makeRecruiterScript").call(
            mapOf("tone" to tone, "resume" to resume, "jobDescription" to listingText)
        ).addOnCompleteListener { result ->
            val newProposal = result.result.data.toString()
            Log.d("FunctionReturn", newProposal)
            callback(newProposal)
        }
    } else if (type == "general") {
        Log.d("FunctionCall", "Calling makeScript")
        Firebase.shared.getFunctions().getHttpsCallable("makeScript").call(
            mapOf("tone" to tone, "resume" to resume)
        ).addOnCompleteListener { result ->
            val newProposal = result.result.data.toString()
            Log.d("FunctionReturn", newProposal)
            callback(newProposal)
        }
    } else {
        callback("Sorry, an error occurred. We'd appreciate a bug report so we can fix it.")
        return
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScriptGenerationScreen(args: ScriptGenerationScreenArgs, navFunction: (Any) -> Unit, modifier: Modifier = Modifier, vm: ScriptGeneration = viewModel()) {
    var errorDisplay by rememberSaveable {
        mutableStateOf("")
    }
    var processingState by rememberSaveable {
        mutableStateOf("")
    }
    var scriptProposal by rememberSaveable {
        mutableStateOf(vm.getUnifiedScript(args.uid))
    }
    var tone by rememberSaveable {
        mutableStateOf("professional")
    }
    var manualEntry by rememberSaveable {
        mutableStateOf(false)
    }

    val resume = vm.getResume().value

    if (scriptProposal == "") {
        getNewScript(
            resume ?: "",
            vm.getNominalType(args.uid),
            tone,
            { newScript -> scriptProposal = newScript },
            vm.getListingText(args.uid)
        )
    }

    //Need this fake state for the UI to avoid lag messing with input during typing
    var jobUrlState by rememberSaveable {
        mutableStateOf(vm.getJobUrl(args.uid))
    }
    var listingTextState by rememberSaveable {
        mutableStateOf(vm.getListingText(args.uid))
    }

    var unifiedScriptState by rememberSaveable {
        mutableStateOf(vm.getUnifiedScript(args.uid))
    }


    Scaffold(
        topBar = {
            CenterAlignedTopAppBar (
                title = {
                    Text(vm.getVideoTitle(args.uid))
                }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = modifier.fillMaxSize().padding(innerPadding).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (vm.getNominalType(args.uid) == "recruiter") {
                TextField(value = jobUrlState, onValueChange = { newValue: String ->
                    jobUrlState = newValue
                    vm.setJobUrl(args.uid, newValue)
                    errorDisplay = ""
                    processingState = "processing"
                    Firebase.shared.getFunctions().getHttpsCallable("extractJobDescription").call(
                        mapOf("jobUrl" to newValue, "uselessAuth" to "FDKNE@!IORjr3kl23i23")
                    ).addOnCompleteListener { result ->
                        if (result.exception != null) {
                            errorDisplay = "Unable to load URL. Make sure it is valid. If the error persists, report a bug -- include the URL please."
                            return@addOnCompleteListener
                        }
                        val newListingText = result.result.data.toString()
                        Log.d("FunctionReturn", newListingText)
                        listingTextState = newListingText
                        vm.setListingText(args.uid, newListingText)
                        processingState = "Processing complete. Job description ready for use"
                        errorDisplay = ""
                    }

                }, placeholder = { Text("Enter LinkedIn job listing URL") })
                Text(processingState)
                if (errorDisplay != "") {
                    Text(errorDisplay, color = Color.Red)
                }
                Button(onClick = {
                    manualEntry = !manualEntry
                }, modifier = modifier) {
                    Text("Or paste in the job description")
                }
                if (manualEntry) {
                    TextField(value = listingTextState, onValueChange = { newValue: String ->
                        listingTextState = newValue
                        vm.setListingText(args.uid, newValue)
                    })
                }
            }
            val tones = listOf("fun", "professional", "technical")
            Picker(tones, tone, onChange = { selected: String ->
                tone = selected
            })
            if (scriptProposal == "") {
                CircularProgressIndicator(
                    modifier = Modifier.width(64.dp),
                    color = MaterialTheme.colorScheme.secondary,
                    trackColor = MaterialTheme.colorScheme.surfaceVariant,
                )
            } else {
                TextField(value = scriptProposal, onValueChange = { newValue: String ->
                    scriptProposal = newValue
                })
                Row {
                    Button(onClick = {
                        if ((unifiedScriptState == "") && (vm.getSegments(args.uid).isEmpty())) {
                            val segmentReturn = getScriptSegments(unifiedScriptState)
                            vm.setSegmentScripts(args.uid, segmentReturn)
                        }
                        unifiedScriptState = scriptProposal
                        vm.setScript(args.uid, scriptProposal)
                    }) {
                        Text("Save proposed script")
                    }
                    IconButton(onClick = {
                        scriptProposal = ""
                        getNewScript(resume ?: "", vm.getNominalType(args.uid), tone, {newScript -> scriptProposal = newScript}, vm.getListingText(args.uid))

                    }) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = ""
                        )
                    }
                }
            }

            TextField(value = unifiedScriptState, onValueChange = { newValue: String ->
                unifiedScriptState = newValue
                vm.setScript(args.uid, unifiedScriptState)
            })
            if (unifiedScriptState != "") {
                Button(onClick = {
                    val segmentReturn = getScriptSegments(unifiedScriptState)
                    Log.d("SegmentUpdate", segmentReturn.toString())
                    vm.setSegmentScripts(args.uid, segmentReturn)
                    vm.setSegmentUrls(args.uid, HashMap<String, String>())
                    navFunction(SegmentsScreenArgs(args.uid))
                }) {
                    Text("Replace progress with new script")
                }
            }
        }
    }
}

data class SegmentReturn(val ordering: List<String>, val orderableMapping: Map<String, String>) {
}

fun getScriptSegments(script: String): SegmentReturn {
    val scriptSentences = script.split("\n")

    var orderableMapping = HashMap<String, String>()
    val ordering = ArrayList<String>()
    for (scriptSentence in scriptSentences) {
        if (scriptSentence == "") {
            continue
        }
        val newId = UUID.randomUUID().toString()
        ordering.add(newId)
        orderableMapping[newId] = scriptSentence
    }
    return SegmentReturn(ordering, orderableMapping)
}