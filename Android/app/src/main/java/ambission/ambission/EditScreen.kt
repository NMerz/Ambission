package ambission.ambission

import android.content.ContentValues
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.OptIn
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCut
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaItem.ClippingConfiguration
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.transformer.Composition
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import androidx.media3.ui.PlayerView
import kotlinx.serialization.Serializable
import okio.Path.Companion.toPath
import java.io.File


class EditViewModel: DatabaseAccess() {

}

@Serializable
class EditScreenArgs(val videoUid: String, val segmentUid: String) {
}

@OptIn(UnstableApi::class)
@Composable
fun EditScreen(args: EditScreenArgs, returnFunction: () -> Boolean, modifier: Modifier = Modifier, vm: EditViewModel = viewModel()) {
    val localContext = LocalContext.current
    val player = remember{mutableStateOf(ExoPlayer.Builder(localContext).build())}
    val currentUri = remember {
        mutableStateOf(vm.getSegmentUrls(args.videoUid)[args.segmentUid]!!)
    }
    val currentMediaItem =  MediaItem.fromUri(currentUri.value)

    currentMediaItem.let { player.value.setMediaItem(it) }
    player.value.prepare()
    Column {
        AndroidView(
            modifier = Modifier
                .width(100.dp)
                .height((100 * 16 / 9).dp),
            factory = { context ->

                player.value.play()
                val playerView = PlayerView(context)
                playerView.player = player.value
                playerView
            }
        )
        Row {
            IconButton(onClick = {
                //TODO: do cut
                Log.d(
                    "EditScreen",
                    "cutting at " + player.value.currentPosition
                ) // current time in millis
                var clipStart = 0L
                var clipEnd = player.value.currentPosition
                val newMediaItem = MediaItem.Builder().setUri(currentUri.value).setClippingConfiguration(ClippingConfiguration.Builder().setStartPositionMs(clipStart).setEndPositionMs(clipEnd).build()).build()



                val videoFileName = "video_" + System.currentTimeMillis()
                val resolver = localContext.contentResolver
                val contentValues = ContentValues()
                contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
                contentValues.put(MediaStore.Video.Media.TITLE, videoFileName)
                contentValues.put(MediaStore.Video.Media.DISPLAY_NAME, videoFileName)

                localContext.getExternalFilesDir(null)?.let { Log.d("EditScreen", it.absolutePath) }
                val newUri =
                    resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, contentValues)


                val newOutFile: File = File(localContext.externalCacheDir, videoFileName)

                val transformerListener: Transformer.Listener =
                    object : Transformer.Listener {
                        override fun onCompleted(composition: Composition, result: ExportResult) {
                            Log.d("EditScreen", "export success")
                            currentUri.value = newOutFile.absolutePath
                        }

                        override fun onError(composition: Composition, result: ExportResult,
                                             exception: ExportException
                        ) {
                            Log.d("EditScreen", "export failure $exception")

                        }
                    }

                // These current get saved to /sdcard/Android/data/ambission.ambission/cache

                Log.d("EditScreen", "new uri: " + newOutFile.absolutePath)

                Transformer.Builder(localContext).addListener(transformerListener)
                    .build().start(newMediaItem, newOutFile.absolutePath)

            }) {

                Icon(
                    imageVector = Icons.Default.ContentCut,
                    contentDescription = ""
                )
            }
            IconButton(onClick = {
                vm.setSegmentUrl(args.videoUid, args.segmentUid, currentUri.value)
                //TODO: set new url
                returnFunction()
            }) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = ""
                )
            }
        }
    }
}