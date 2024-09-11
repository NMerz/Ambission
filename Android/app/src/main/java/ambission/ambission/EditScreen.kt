package ambission.ambission

import android.app.AlertDialog
import android.content.ContentValues
import android.content.Context
import android.provider.MediaStore
import android.text.Spannable
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.util.Log
import androidx.annotation.OptIn
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCut
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaItem.ClippingConfiguration
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.OverlaySettings
import androidx.media3.effect.TextOverlay
import androidx.media3.effect.TextureOverlay
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import androidx.media3.ui.PlayerView
import com.google.common.collect.ImmutableList
import kotlinx.serialization.Serializable
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

        val saveEdited = {keepSide: String ->
            var clipStart = 0L
            var clipEnd = player.value.duration
            if (keepSide == "start") {
                clipEnd = player.value.currentPosition
            }
            if (keepSide == "end") {
                clipStart = player.value.currentPosition
            }
            if (clipStart != clipEnd) {

                val newMediaItem = MediaItem.Builder().setUri(currentUri.value)
                    .setClippingConfiguration(
                        ClippingConfiguration.Builder().setStartPositionMs(clipStart)
                            .setEndPositionMs(clipEnd).build()
                    ).build()


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

                        override fun onError(
                            composition: Composition, result: ExportResult,
                            exception: ExportException
                        ) {
                            Log.d("EditScreen", "export failure $exception")

                        }
                    }

                // These current get saved to /sdcard/Android/data/ambission.ambission/cache

                Log.d("EditScreen", "new uri: " + newOutFile.absolutePath)

                Transformer.Builder(localContext).addListener(transformerListener)
                    .build().start(newMediaItem, newOutFile.absolutePath)
            }
        }

        Row {
            IconButton(onClick = {
                //TODO: do cut
                Log.d(
                    "EditScreen",
                    "cutting at " + player.value.currentPosition
                ) // current time in millis

                val builder: AlertDialog.Builder = AlertDialog.Builder(localContext)
                builder
                    .setMessage("Cut segment")
                    .setTitle("Choose kept side")
                    .setNegativeButton("Keep start") { dialog, which ->
                        saveEdited("start")
                    }.setNeutralButton("Cancel") {_, _ ->
                        return@setNeutralButton
                    }
                    .setPositiveButton("Keep end") { dialog, which ->
                        saveEdited("end")
                    }.setCancelable(true)

                val dialog: AlertDialog = builder.create()
                dialog.show()


            }) {

                Icon(
                    imageVector = Icons.Default.ContentCut,
                    contentDescription = ""
                )
            }
            IconButton(onClick = {
                addText(currentUri.value, localContext) { currentUri.value = it }
            }) {
                Icon(
                    imageVector = Icons.Default.TextFields,
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


//Apache 2.0 https://github.com/androidx/media/tree/release
@OptIn(UnstableApi::class)
fun addText(baseUri: String, localContext: Context, setNew: (String) -> Unit) {
    val mediaItem = MediaItem.Builder().setUri(baseUri).build()
    val editedMediaItemBuilder = EditedMediaItem.Builder(mediaItem)
    val effects: ImmutableList.Builder<Effect> = ImmutableList.Builder<Effect>()
    effects.add()
    val overlaySettings =
        OverlaySettings.Builder()
            .build()
    val overlayText =
        SpannableString("foobar")
    overlayText.setSpan(
        ForegroundColorSpan(Color.Red.toArgb()),  /* start= */
        0,
        overlayText.length,
        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
    )
    val textOverlay = TextOverlay.createStaticTextOverlay(overlayText, overlaySettings)
    val overlaysBuilder = ImmutableList.Builder<TextureOverlay>()
    effects.add(OverlayEffect(overlaysBuilder.add(textOverlay).build()))

    editedMediaItemBuilder.setEffects(Effects(ImmutableList.of(), effects.build()))
    val compositionBuilder =
        Composition.Builder(EditedMediaItemSequence(editedMediaItemBuilder.build()))

    val videoFileName = "video_" + System.currentTimeMillis()
    val newOutFile: File = File(localContext.externalCacheDir, videoFileName)

    val transformerListener: Transformer.Listener =
        object : Transformer.Listener {
            override fun onCompleted(composition: Composition, result: ExportResult) {
                Log.d("EditScreen", "export success")
                setNew(newOutFile.absolutePath)
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

    Transformer.Builder(localContext).addListener(transformerListener)
        .build().start(compositionBuilder.build(), newOutFile.absolutePath)
}