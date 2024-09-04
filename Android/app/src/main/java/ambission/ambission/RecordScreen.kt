package ambission.ambission

import android.Manifest
import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
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
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asComposePath
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.graphics.shapes.RoundedPolygon
import androidx.graphics.shapes.toPath
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import kotlinx.serialization.Serializable
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Objects


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


fun Context.createImageFile(): File {
    // Create an image file name
    val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss").format(Date())
    val imageFileName = "MOV_" + timeStamp + "_"
    val movie = File.createTempFile(
        imageFileName, /* prefix */
        ".3gp", /* suffix */
        this.filesDir      /* directory */
    )
    return movie
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

    Box(
        modifier = Modifier
            .drawWithCache {
                val roundedPolygon = RoundedPolygon(
                    numVertices = 6,
                    radius = size.minDimension / 2,
                    centerX = size.width / 2,
                    centerY = size.height / 2
                )
                val roundedPolygonPath = roundedPolygon
                    .toPath()
                    .asComposePath()
                onDrawBehind {
                    drawPath(roundedPolygonPath, color = Color.Blue)
                }
            }
            .fillMaxSize()
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
    IconButton(onClick = {
        if (ActivityCompat.checkSelfPermission(
                localContext,
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)

            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
            return@IconButton
        }

        cameraController.setEnabledUseCases(VIDEO_CAPTURE)
        if (cameraController.isRecording() && recording.value != null) {
            // Stop the current recording session.
            Log.d("RecordScreen", "Stopping recording")
            recording.value?.stop()
        } else {
            Log.d("RecordScreen", "Starting recording")
            recording.value = cameraController.startRecording(fileOptions, AudioConfig.create(true), ContextCompat.getMainExecutor(localContext)) { videoRecordEvent ->
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

                    uri.let { vm.setSegmentUrl(args.videoUid, args.segmentId, it.toString()) }
                    returnFunction()
                }
            }
        }

    }) {
        Icon(
            imageVector = Icons.Default.CameraAlt,
            contentDescription = ""
        )
    }
}

@Composable
fun CameraPreview() {


}


@Composable
fun RecordScreenOverlayed(args: RecordScreenArgs, navFunction: (Any) -> Unit, returnFunction: () -> Boolean, modifier: Modifier, vm: RecordViewModel) {
    val localContext = LocalContext.current

    val file = localContext.createImageFile()
    val uri = FileProvider.getUriForFile(
        Objects.requireNonNull(localContext),
        localContext.packageName + ".provider", file
    )

    var capturedImageUri by remember {
        mutableStateOf<Uri>(Uri.EMPTY)
    }

    val cameraLauncher =
        rememberLauncherForActivityResult(ActivityResultContracts.CaptureVideo()) {wasSaved ->
            if (wasSaved) {
//                capturedImageUri = uri
                uri.lastPathSegment?.let { vm.setSegmentUrl(args.videoUid, args.segmentId, it) }
                returnFunction()
            }
        }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) {
        if (it) {
            Toast.makeText(localContext, "Permission Granted", Toast.LENGTH_SHORT).show()
            cameraLauncher.launch(uri)
        } else {
            Toast.makeText(localContext, "Permission Denied", Toast.LENGTH_SHORT).show()
        }
    }

    Column(
        Modifier
            .fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Button(onClick = {
            val permissionCheckResult =
                ContextCompat.checkSelfPermission(localContext, Manifest.permission.CAMERA)
            if (permissionCheckResult == PackageManager.PERMISSION_GRANTED) {
                cameraLauncher.launch(uri)
            } else {
                // Request a permission
                permissionLauncher.launch(Manifest.permission.CAMERA)
            }
        }) {
            Text(text = "Capture Image From Camera")
        }
    }

    if (capturedImageUri.path?.isNotEmpty() == true) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { context ->
                val player = ExoPlayer.Builder(localContext).build()
                MediaItem.fromUri(capturedImageUri)
                    .let { player.setMediaItem(it) }
                player.prepare()
                player.play()
                val playerView = PlayerView(context)
                playerView.player = player
                playerView
            }
        )

    }
}