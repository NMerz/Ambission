package ambission.ambission

import android.content.Context
import android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION
import android.media.MediaPlayer
import android.net.Uri
import android.util.Log
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.ContentCut
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.FileProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import androidx.media3.ui.PlayerView
import kotlinx.serialization.Serializable
import java.io.File
import java.util.Objects

class SegmentsViewModel: DatabaseAccess() {

}

@Serializable
class SegmentsScreenArgs(val uid: String) {
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SegmentsScreen(args: SegmentsScreenArgs, navFunction: (Any) -> Unit, modifier: Modifier = Modifier, vm: SegmentsViewModel = viewModel()) {

    var segmentsState by rememberSaveable {
        mutableStateOf(vm.getSegments(args.uid))
    }

    var segmentTextsState by rememberSaveable {
        mutableStateOf(vm.getSegmentTexts(args.uid))
    }

    val segmentUrlsState = vm.getSegmentUrlsLive(videoUid = args.uid).observeAsState()

    Log.d("SegmentDisplay", segmentTextsState.toString())

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
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            val localContext = LocalContext.current
            Text(args.uid)
            for (segment in segmentsState) {
                Log.d("SegmentDisplay", segment)
                segmentTextsState[segment]?.let { Log.d("SegmentDisplay", it) }
                Log.d("SegmentDisplay", segmentTextsState[segment] ?: "")
                Row (modifier = modifier.padding(20.dp)) {
                    if (segmentUrlsState.value?.get(segment) != null ) {
                        //TODO: untested skeleton

//                        val uri = FileProvider.getUriForFile(
//                            Objects.requireNonNull(localContext),
//                            localContext.packageName + ".provider", localContext.filesDir.resolve(segmentUrlsState.value?.get(segment)!!)
//                        )


//                        Log.d("SegmentScreen",localContext.filesDir.resolve(segmentUrlsState.value?.get(segment)!!).absolutePath + "url is a file" + localContext.filesDir.resolve(segmentUrlsState.value?.get(segment)!!).isFile.toString())
//                        localContext.grantUriPermission(localContext.packageName, uri, FLAG_GRANT_READ_URI_PERMISSION)

                        Column {
                            Box(contentAlignment = Alignment.BottomCenter) {
                                AndroidView(
                                    modifier = Modifier
                                        .width(100.dp)
                                        .height((100 * 16 / 9).dp),
                                    factory = { context ->
                                        val player = ExoPlayer.Builder(localContext).build()
                                        MediaItem.fromUri(segmentUrlsState.value?.get(segment)!!)
                                            .let { player.setMediaItem(it) }
                                        player.prepare()
                                        player.play()
                                        val playerView = PlayerView(context)
                                        playerView.player = player
                                        playerView
                                    }
                                )
                                Row {
                                    IconButton(onClick = {
                                        navFunction(RecordScreenArgs(segment, videoUid = args.uid))
                                    }) {
                                        Icon(
                                            imageVector = Icons.Default.Refresh,
                                            contentDescription = ""
                                        )
                                    }
                                    IconButton(onClick = {
                                        val segmentUrls = vm.getSegmentUrls(args.uid).toMutableMap()
                                        segmentUrls.remove(segment)
                                        vm.setSegmentUrls(args.uid, segmentUrls)
                                    }) {
                                        Icon(
                                            imageVector = Icons.Default.Delete,
                                            contentDescription = ""
                                        )
                                    }
                                }


                            }
                            IconButton(onClick = {
                                navFunction(EditScreenArgs(videoUid = args.uid, segmentUid = segment))
                            }) {
                                Icon(
                                    imageVector = Icons.Default.ContentCut,
                                    contentDescription = ""
                                )
                            }
                        }

                    } else {
                        IconButton(onClick = {
                            navFunction(RecordScreenArgs(segment, videoUid = args.uid))
                        }) {
                            Icon(
                                imageVector = Icons.Default.CameraAlt,
                                contentDescription = ""
                            )
                        }
                    }
                    TextField(
                        value = segmentTextsState[segment] ?: "",
                        onValueChange = { newValue: String ->
                            val newSegmentTexts = segmentTextsState.toMutableMap()
                            newSegmentTexts[segment] = newValue
                            segmentTextsState = newSegmentTexts.toMap()
                            vm.setSegmentTexts(args.uid, segmentTextsState)
                            //TODO: set unified, probably in vm
                        })
                }
            }
            Button(onClick = {
                combineClips(localContext = localContext, segments = segmentsState, segmentUrls = segmentUrlsState.value.orEmpty(), navFunction = navFunction)
            }) {
                Text("Combine")
            }
        }
    }
}

@androidx.annotation.OptIn(UnstableApi::class)
fun combineClips(localContext: Context, segments: List<String>, segmentUrls: Map<String, String>,  navFunction: (Any) -> Unit) {
    val videoFileName = "combined_" + System.currentTimeMillis()
    val newOutFile: File = File(localContext.externalCacheDir, videoFileName)

    val transformerListener: Transformer.Listener =
        object : Transformer.Listener {
            override fun onCompleted(composition: Composition, result: ExportResult) {
                Log.d("EditScreen", "export success")
                navFunction(ExportScreenArgs(newOutFile.absolutePath))
            }

            override fun onError(
                composition: Composition, result: ExportResult,
                exception: ExportException
            ) {
                Log.d("EditScreen", "export failure $exception")

            }
        }

    // These current get saved to /sdcard/Android/data/ambission.ambission/cache

    Log.d("EditScreen", "new uri: " + newOutFile.absolutePath)

    val videoComponents = ArrayList<EditedMediaItem>()
    for (segment in segments) {
        segmentUrls[segment]
            ?.let { videoComponents.add(EditedMediaItem.Builder( MediaItem.fromUri(it)).build())}
    }

    Transformer.Builder(localContext).addListener(transformerListener)
        .build().start(Composition.Builder(EditedMediaItemSequence(videoComponents)).build(), newOutFile.absolutePath)
}