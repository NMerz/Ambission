package ambission.ambission.utilities

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.ripple.LocalRippleTheme
import androidx.compose.material.ripple.RippleAlpha
import androidx.compose.material.ripple.RippleTheme
import androidx.compose.material3.ButtonColors
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color

@Composable
fun Picker(choices: List<String>, initialChoice: String? = null, onChange: (String) -> Unit = {}) {
    var current = choices[0]
    if (initialChoice != null) {
        current = initialChoice
    }

    Row {
        CompositionLocalProvider(LocalRippleTheme provides NoRippleTheme) {
            for (choice in choices) {
                TextButton(
                    onClick = {
                        onChange(choice)
                    },
                    modifier = Modifier.background(
                        if (current == choice) Color.Gray else Color.White,
                        RoundedCornerShape(percent = 10)
                    ),
                    colors = ButtonColors(
                        Color.Transparent,
                        Color.Unspecified,
                        Color.Transparent,
                        Color.Unspecified
                    )
                ) {
                    Text(choice)
                }
            }
        }
    }
}

private object NoRippleTheme : RippleTheme {
    @Composable
    override fun defaultColor() = Color.Unspecified

    @Composable
    override fun rippleAlpha(): RippleAlpha = RippleAlpha(0.0f,0.0f,0.0f,0.0f)
}