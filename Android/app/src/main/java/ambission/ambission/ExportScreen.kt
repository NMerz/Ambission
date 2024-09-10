package ambission.ambission

import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import kotlinx.serialization.Serializable

class ExportScreenModel: ViewModel(){

}

@Serializable
class ExportScreenArgs(val videoUri: String) {
}

@Composable
fun ExportScreen(args: ExportScreenArgs, modifier: Modifier = Modifier, vm: ExportScreenModel = viewModel()) {
    val localContext = LocalContext.current
    AndroidView(
        modifier = Modifier
            .width(100.dp)
            .height((100 * 16 / 9).dp),
        factory = { context ->
            val player = ExoPlayer.Builder(localContext).build()
            MediaItem.fromUri(args.videoUri)
                .let { player.setMediaItem(it) }
            player.prepare()
            player.play()
            val playerView = PlayerView(context)
            playerView.player = player
            playerView
        }
    )
}