package ambission.ambission

import com.google.firebase.functions.FirebaseFunctions


class Firebase {

    companion object {
        val shared = Firebase()


    }
    private var functions = FirebaseFunctions.getInstance()
    fun getFunctions(): FirebaseFunctions {
        return functions
    }
}