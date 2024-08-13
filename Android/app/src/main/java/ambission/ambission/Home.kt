package ambission.ambission

import android.net.Uri
import android.util.Log
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.LiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewmodel.compose.viewModel
import java.util.UUID


class Home: ViewModel() {
    private val dbdao = AppDatabase.getSharedDatabase().createdVideoDao()
    private val inputsdao = AppDatabase.getSharedDatabase().inputsDao()
    private val allVideos = dbdao.getAll().asLiveData()

    init {
        //TODO: make a thing to actuall set this
        inputsdao.setInput(Inputs("resume", """"Work Experience:	
"Software Engineer, Verily Life Sciences
Architected and implemented lifting of medical image processing service to Google Cloud Platform
Performed upgrade and state migration of production Terraform resources to allow for greater configuration flexibility and increased security
Architected, built, and refined Google Cloud-based data filtering service using Airflow, Cloud Runs, Dataflow, and Go
Maintained complex data pipeline with oncall support, data changes, and usability improvements
Received 10 peer-awarded bonuses for outstanding work and “significantly above expectations” ratings at every performance evaluation"	"June 2022
-
March 2024"
"Software Engineer Program Intern, J. P. Morgan Chase
Automated setup of new data pipelines using REST APIs to decrease onboarding time for new pipelines
Developed data processing Maven archetypes to decrease knowledge burden of custom tooling"	"June 2021
-
August 2021"
"Software Engineer, Milliman - PRM Analytics
Added and maintained models for predicting patient cost using LightGBM, Pandas, and Pyspark
Maintained and modernized data pipeline to deliver more reliable and secure data processing
Contributed to production troubleshooting and quality verification"	"May 2020
-
April 2021"
"Intern (Software), CME Group
Automated transfer of database policy management using Apache Ranger’s REST API
Adapted database schema management software for the Apache Hive database driver"	"May 2019
-
August 2019
"
"
Education:"	
"Purdue University - West Lafayette
Master of Science and Bachelor of Science in Computer Science

Software Lead & Treasurer, Lunabotics Robotics Team
Led software development including defining architecture, mentoring younger team members, and leading inter-team communication
Developed code and tests for robotic autonomy, computer vision,  communication, and motor control"	"August 2018
-
May 2022

May 2019
-
May 2020"""))
    }

    fun getResume(): LiveData<String> {
        return inputsdao.getResume().asLiveData()
    }

    fun getAllVideos(): LiveData<List<CreatedVideo>> {
        return allVideos
    }

    fun addVideo(newVideo: CreatedVideo) {
        dbdao.insertAll(newVideo)
    }

    fun deleteVideo(toDelete: CreatedVideo) {
        dbdao.delete(toDelete)
    }

}

@Composable
fun HomeScreen(name: String, navFunction: (Any) -> Unit, modifier: Modifier = Modifier, vm: Home = viewModel()) {
    val resume = vm.getResume().observeAsState()



    if ((resume.value ?: "")  == "") {
        val openResume = rememberLauncherForActivityResult(
            contract =
            ActivityResultContracts.OpenDocument()
        ) { uri: Uri? ->
            Log.d("MainActivity", "uri: $uri")
        }


        Text("Add your resume")
        Button(onClick = { //TODO: finish adding pdf; I was in the middle of this. Code here is untested. PDF to be read by pdfbox - see gradle
            openResume.launch(arrayOf("application/pdf"))
        }) {

        }

    } else {
        CreationScreen(name, navFunction, modifier, vm)
    }

}

@Composable
fun CreationScreen(name: String, navFunction: (Any) -> Unit, modifier: Modifier = Modifier, vm: Home) {
    val videos = vm.getAllVideos().observeAsState()
    Row {
        Button(onClick = {
            Log.i("AMB", "foobar3")
            vm.addVideo(CreatedVideo(UUID.randomUUID().toString(), "Untitled Video", "general", "", typeSpecificInput = mapOf()))
        }, modifier = modifier) {
            Text(
                text = "General Intro",
                modifier = modifier
            )
        }
        Button(onClick = {
            Log.i("AMB", "foobar3")
            val newId = UUID.randomUUID().toString()
            vm.addVideo(CreatedVideo(newId, "Untitled Video", "recruiter", "", typeSpecificInput = mapOf()))
            navFunction(ScriptGenerationScreenArgs(newId))
        }, modifier = modifier) {
            Text(
                text = "Recruiter Intro",
                modifier = modifier
            )
        }
    }
    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (videos.value != null) {
            for (video in videos.value!!) {
                Row (
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center) {
                    Text(video.videoTitle, modifier = Modifier.clickable { navFunction(ScriptGenerationScreenArgs(uid = video.uid)) })
                    Button(onClick = {
                        vm.deleteVideo(video)
                    }) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = ""
                        )
                    }
                }
            }
        }

    }
}