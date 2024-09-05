package ambission.ambission

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.provider.MediaStore
import android.util.Log
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.video.MediaStoreOutputOptions
import androidx.camera.video.Recording
import androidx.camera.video.VideoRecordEvent
import androidx.camera.video.VideoRecordEvent.Finalize.ERROR_NONE
import androidx.camera.view.CameraController.VIDEO_CAPTURE
import androidx.camera.view.LifecycleCameraController
import androidx.camera.view.PreviewView
import androidx.camera.view.video.AudioConfig
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.serialization.Serializable
import kotlin.math.max


class RecordViewModel: DatabaseAccess() {


    fun setSegmentUrl(videoUid: String, segment: String, newUrl: String) {
        val oldUrls = getSegmentUrls(videoUid).toMutableMap()
        oldUrls[segment] = newUrl
        setSegmentUrls(videoUid, oldUrls)
    }
}

@Serializable
class RecordScreenArgs(val segmentId: String, val videoUid: String) {
}

@Composable
fun RecordScreen(args: RecordScreenArgs, navFunction: (Any) -> Unit, returnFunction: () -> Boolean, modifier: Modifier = Modifier, vm: RecordViewModel = viewModel()) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    val cameraController = remember {
        LifecycleCameraController(context).apply {
            bindToLifecycle(lifecycleOwner)
        }
    }

    cameraController.cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA


    AndroidView(
        modifier = Modifier.fillMaxSize(),
        factory = { ctx ->
            PreviewView(ctx).apply {
                scaleType = PreviewView.ScaleType.FILL_START
                implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                controller = cameraController
            }
        },
        onRelease = {
            cameraController.unbind()
        }
    )

    val isRecording = remember{ mutableStateOf(false) }
    var scrollSpeed by remember { mutableIntStateOf(0) }

    var textBoxSize by remember { mutableIntStateOf(0) }
    var textSize by remember { mutableIntStateOf(0) }

//    with(LocalDensity.current) { LocalConfiguration.current.screenHeightDp.dp.toPx() }
    val offset: Float by animateFloatAsState(
        targetValue = if (isRecording.value) textBoxSize.toFloat() * -1 else 0.0F,
        // Configure the animation duration and easing.
        animationSpec = tween(durationMillis = if (isRecording.value) max(scrollSpeed, 1000) else 1, easing = LinearEasing), label = ""
    )
    vm.getSegmentTexts(args.videoUid)[args.segmentId]?.let {
        textBoxSize = rememberTextMeasurer().measure(it, TextStyle(fontSize = max(textSize, 12).sp, fontFamily = LocalTextStyle.current.fontFamily, fontWeight = LocalTextStyle.current.fontWeight, fontStyle = LocalTextStyle.current.fontStyle, letterSpacing = LocalTextStyle.current.letterSpacing, textDecoration = LocalTextStyle.current.textDecoration), constraints = with(LocalDensity.current) { Constraints.fixedWidth(
            LocalConfiguration.current.screenWidthDp.dp.toPx().toInt()
        ) }, overflow = TextOverflow.Visible).size.height
        Text(text = it, modifier = Modifier.offset { IntOffset(0,
        offset.toInt()
    )}.onSizeChanged{
//        textBoxSize = it.height
    }, fontSize = max(textSize, 12).sp, lineHeight = max(textSize, 12).sp, overflow = TextOverflow.Visible) }
    Slider(
        value = scrollSpeed.toFloat() / 30000F,
        onValueChange = { scrollSpeed = (it * 30000).toInt() },
        modifier = Modifier.rotate(90F).offset((LocalConfiguration.current.screenHeightDp * 0.5).dp, (LocalConfiguration.current.screenWidthDp * -0.4).dp)
    )

    Slider(
        value = textSize.toFloat() / 192.0F,
        onValueChange = { textSize = (it * 192.0).toInt() },
        modifier = Modifier.offset(y = (LocalConfiguration.current.screenHeightDp * 0.1).dp)

    )

    val localContext = LocalContext.current

    val videoFileName = "video_" + System.currentTimeMillis()
    val resolver = localContext.contentResolver
    val contentValues = ContentValues()
    contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
    contentValues.put(MediaStore.Video.Media.TITLE, videoFileName)
    contentValues.put(MediaStore.Video.Media.DISPLAY_NAME, videoFileName)

    localContext.getExternalFilesDir(null)?.let { Log.d("RecordScreen", it.absolutePath) }
    val fileOptions = MediaStoreOutputOptions.Builder(resolver,  MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
        .setContentValues(contentValues)
        .build()


    val recording = remember {mutableStateOf<Recording?>(null)}
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) {
        if (it) {
            Toast.makeText(localContext, "Permission Granted", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(localContext, "Permission Denied", Toast.LENGTH_SHORT).show()
        }
    }
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
        IconButton(
            onClick = {
                if (ActivityCompat.checkSelfPermission(
                        localContext,
                        Manifest.permission.RECORD_AUDIO
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)

                    return@IconButton //TODO: resume instead
                }

                val permissionCheckResult =
                    ContextCompat.checkSelfPermission(localContext, Manifest.permission.CAMERA)
                if (permissionCheckResult != PackageManager.PERMISSION_GRANTED) {
                    // Request a permission
                    permissionLauncher.launch(Manifest.permission.CAMERA)
                    return@IconButton //TODO: resume instead
                }

                cameraController.setEnabledUseCases(VIDEO_CAPTURE)
                if (cameraController.isRecording() && recording.value != null) {
                    // Stop the current recording session.
                    isRecording.value = false
                    Log.d("RecordScreen", "Stopping recording")
                    recording.value?.stop()
                } else {
                    isRecording.value = true
                    Log.d("RecordScreen", "Starting recording")
                    recording.value = cameraController.startRecording(
                        fileOptions,
                        AudioConfig.create(true),
                        ContextCompat.getMainExecutor(localContext)
                    ) { videoRecordEvent ->
                        if (videoRecordEvent is VideoRecordEvent.Finalize) {
                            val finalize =
                                videoRecordEvent as VideoRecordEvent.Finalize
                            val uri = finalize.outputResults.outputUri

                            if (finalize.error == ERROR_NONE) {
                                Log.d("RecordScreen", "Video saved to: ${uri}")
                            } else {
                                var msg = "Saved uri ${uri}"
                                msg += " with code (" + finalize.error + ")" + finalize.cause
                                Log.d("RecordScreen", "Failed to save video: $msg")
                            }

                            uri.let {
                                vm.setSegmentUrl(
                                    args.videoUid,
                                    args.segmentId,
                                    it.toString()
                                )
                            }
                            returnFunction()
                        }
                    }
                }

            },
            modifier = Modifier.offset(y = (LocalConfiguration.current.screenHeightDp * 0.9).dp)
        ) {
            Icon(
                imageVector = Icons.Default.CameraAlt,
                contentDescription = ""
            )
        }
    }
}
